# YouTube subscription -> driving playlist sync

Keeps one playlist stocked with your subscriptions' videos from the last
24 hours, and prunes anything older, so you always have fresh driving
listening without manual curation.

Files:
- `setup_auth.py` — one-time OAuth login (run on a machine with a browser)
- `sync_playlist.py` — the actual sync job (run on your NixOS server)
- `config.example.json` — copy to `config.json` and edit
- `nixos-module-example.nix` — systemd service + timer example
- `requirements.txt` — Python deps (only needed if not using the Nix env)

## 1. Google Cloud setup (one time)

1. Go to https://console.cloud.google.com/ and create (or pick) a project.
2. Enable the **YouTube Data API v3** for that project (APIs & Services > Library).
3. Configure the OAuth consent screen (External is fine; add your own
   Google account as a test user if the app stays in "Testing" mode).
4. Under APIs & Services > Credentials, create an **OAuth client ID** of
   type **Desktop app**. Download the JSON.
5. Save that file as `client_secret.json` next to `setup_auth.py`.

## 2. Authenticate (one time, on a machine with a browser)

```bash
pip install -r requirements.txt
python3 setup_auth.py
```

This opens a browser tab, you approve access, and it writes `token.json`
(which contains a long-lived refresh token — treat it like a password).

## 3. Configure

```bash
cp config.example.json config.json
```

Leave `target_playlist_id` blank/absent on the very first run and the
script will create a private playlist called "Driving Queue" for you and
log its id — copy that id into `config.json` so subsequent runs reuse the
same playlist instead of creating a new one each time.

## 4. Copy to the server

Copy `sync_playlist.py`, `config.json`, and `token.json` to your NixOS
server, e.g. `/var/lib/youtube-playlist-sync/`. Lock down the token:

```bash
chmod 600 token.json
```

## 5. Test it

```bash
python3 sync_playlist.py --config config.json --dry-run --verbose
```

`--dry-run` logs what it *would* add/remove without calling
insert/delete, so you can sanity check before it touches your playlist.

## 6. Run it periodically on NixOS

See `nixos-module-example.nix` for a full systemd service + timer. The
short version: it runs `sync_playlist.py` every 15 minutes using a Nix
Python environment with the three Google libraries, as a dedicated
unprivileged user. After adding it to your configuration:

```bash
sudo nixos-rebuild switch
systemctl status youtube-playlist-sync.timer
journalctl -u youtube-playlist-sync.service -f
```

If you'd rather not touch a NixOS module, a plain cron entry or user
systemd timer pointed at `sync_playlist.py` inside a
`nix-shell -p "python3.withPackages(ps: [ps.google-api-python-client ps.google-auth-httplib2 ps.google-auth-oauthlib])"`
works too.

## Notes on how it decides what's "recent"

- For each channel you're subscribed to, the script reads its uploads
  playlist (newest-first) and keeps videos whose original publish
  timestamp is within `lookback_hours` (default 24).
- Playlist items are removed once their *original video publish time*
  (not the time it was added to the playlist) falls outside that window.
- `max_results_per_channel` (default 5) caps how many of each channel's
  latest uploads it inspects — raise it if a channel might upload more
  than 5 videos within your lookback window.

## Filtering out Shorts

Set `"exclude_shorts": true` in `config.json` (this is the default) and
Shorts won't be added to the playlist at all.

The YouTube Data API has no official "is this a Short" field, so this
uses the same trick most third-party tools rely on: requesting
`youtube.com/shorts/<id>` without following redirects. YouTube serves
that URL as-is for Shorts, but 30x-redirects it to `youtube.com/watch?v=<id>`
for regular videos. It's unofficial behavior (not part of the API
contract) but currently the most reliable signal available — video
duration alone stopped being a reliable indicator once YouTube extended
the Shorts length limit to 3 minutes.

Practical implications:
- This adds one extra outbound HTTP request per candidate video (done
  concurrently, 8 at a time) beyond the YouTube Data API calls — it
  doesn't consume any of your API quota, but it does mean the server
  needs normal internet access to youtube.com, not just API access.
- If YouTube changes this redirect behavior in the future, the check
  could stop working; it fails safe (treats videos as non-Shorts, i.e.
  keeps them) if the request errors out or times out.
- Set `"exclude_shorts": false` to skip this check entirely and include
  everything, Shorts included.

## API quota

YouTube Data API v3 gives you 10,000 units/day by default. Rough costs
per sync run: 1 unit per page of `subscriptions.list`, 1 unit per batch
of `channels.list` (50 channels/call), 1 unit per `playlistItems.list`
call, and 50 units for each `playlistItems.insert`/`delete`. With a
typical subscription count this comfortably supports running every
15 minutes; if you have hundreds of subscriptions and want faster
polling, watch your usage in the Cloud Console (APIs & Services > YouTube
Data API v3 > Quotas).
