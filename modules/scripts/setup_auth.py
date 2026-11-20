#!/usr/bin/env python3
"""
setup_auth.py
-------------
One-time Google OAuth login for sync_playlist.py. Run it on a machine that
has a web browser (THEOCIDE, a laptop), NOT on the headless server. It writes
token.json (a long-lived refresh token) into the current directory.

Normal use, from an empty scratch directory containing client_secret.json
(OAuth client of type "Desktop app", YouTube Data API v3 enabled):

  nix run .#youtube-sync-auth

No browser on this machine (phone + SSH): print the URL instead, approve it
on any device, then deliver the failed redirect to the waiting listener from
a second shell on the same machine:

  nix run .#youtube-sync-auth -- --no-browser --port 8080
  # approve in the phone browser; it redirects to http://localhost:8080/?state=...&code=...
  # (the page will not load); copy that whole URL and, on this machine:
  curl 'http://localhost:8080/?state=...&code=...'

Then install token.json on MENTICIDE (docs/secrets.md 4.8) and delete the local copies
of token.json and client_secret.json.
"""

import argparse
import os
import sys

from google_auth_oauthlib.flow import InstalledAppFlow

SCOPES = ["https://www.googleapis.com/auth/youtube"]
CLIENT_SECRET_FILE = "client_secret.json"
TOKEN_FILE = "token.json"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--no-browser", action="store_true", help="print the authorization URL instead of opening a browser")
    parser.add_argument("--port", type=int, default=0, help="local redirect port (default: random; set it with --no-browser)")
    args = parser.parse_args()

    if not os.path.exists(CLIENT_SECRET_FILE):
        print(
            f"ERROR: {CLIENT_SECRET_FILE} not found in {os.getcwd()}.\n"
            "Download an OAuth 'Desktop app' client ID from Google Cloud "
            "Console (APIs & Services > Credentials) and save it here as "
            f"{CLIENT_SECRET_FILE}.",
            file=sys.stderr,
        )
        return 1

    flow = InstalledAppFlow.from_client_secrets_file(CLIENT_SECRET_FILE, SCOPES)
    # Spins up a local redirect listener, so this must run where the browser's
    # "localhost" is reachable (or use --no-browser and curl the redirect, see above).
    creds = flow.run_local_server(port=args.port, open_browser=not args.no_browser)

    # Owner-only from the first byte: the refresh token is a credential.
    fd = os.open(TOKEN_FILE, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        f.write(creds.to_json())

    print(f"Success. Wrote {os.path.abspath(TOKEN_FILE)}.")
    print("Install it on the server (docs/secrets.md 4.8), then delete this copy.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
