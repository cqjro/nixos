#!/usr/bin/env python3
"""
sync_playlist.py
----------------
Periodically syncs your YouTube subscription feed into a single
"driving queue" playlist:

  * Adds videos uploaded by channels you're subscribed to within the
    last `lookback_hours` (default 24h) that aren't already in the
    playlist.
  * Removes items from the playlist whose original publish date is
    older than that cutoff.

Designed to be run non-interactively (e.g. from a systemd timer / cron
job on a headless NixOS server) using a refresh token created once via
setup_auth.py on a machine with a browser.

Usage:
  python3 sync_playlist.py [--config config.json] [--dry-run] [--verbose]
"""

from __future__ import annotations

import argparse
import fcntl
import json
import logging
import os
import sys
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone
from typing import Iterable

import requests
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

SCOPES = ["https://www.googleapis.com/auth/youtube"]

log = logging.getLogger("sync_playlist")


# --------------------------------------------------------------------------
# Setup / config / auth
# --------------------------------------------------------------------------

def load_config(path: str) -> dict:
    with open(path) as f:
        cfg = json.load(f)
    cfg.setdefault("lookback_hours", 24)
    cfg.setdefault("max_results_per_channel", 5)
    cfg.setdefault("token_file", "token.json")
    cfg.setdefault("target_playlist_title", "Youtube Subscriptions Queue")
    cfg.setdefault("exclude_shorts", True)
    return cfg


def get_credentials(token_file: str) -> Credentials:
    if not os.path.exists(token_file):
        raise SystemExit(
            f"Token file '{token_file}' not found. Run setup_auth.py on a "
            "machine with a browser first, then copy the resulting "
            "token.json here (see README.md)."
        )

    creds = Credentials.from_authorized_user_file(token_file, SCOPES)

    if creds.valid:
        return creds

    if creds.expired and creds.refresh_token:
        log.info("Access token expired, refreshing...")
        creds.refresh(Request())
        # Persist the refreshed access token so we don't have to do this
        # every single run (not strictly required, refresh_token itself
        # doesn't expire in normal use, but this avoids an extra refresh
        # call next time within the same access-token lifetime).
        with open(token_file, "w") as f:
            f.write(creds.to_json())
        return creds

    raise SystemExit(
        "Stored credentials are invalid and have no usable refresh token. "
        "Re-run setup_auth.py and copy the new token.json to the server."
    )


# --------------------------------------------------------------------------
# YouTube API helpers
# --------------------------------------------------------------------------

def chunked(items: list, size: int) -> Iterable[list]:
    for i in range(0, len(items), size):
        yield items[i : i + size]


def get_subscribed_channel_ids(youtube) -> list[str]:
    channel_ids = []
    page_token = None
    while True:
        resp = (
            youtube.subscriptions()
            .list(
                part="snippet",
                mine=True,
                maxResults=50,
                pageToken=page_token,
                order="alphabetical",
            )
            .execute()
        )
        for item in resp.get("items", []):
            channel_ids.append(item["snippet"]["resourceId"]["channelId"])
        page_token = resp.get("nextPageToken")
        if not page_token:
            break
    log.info("Found %d subscribed channels", len(channel_ids))
    return channel_ids


def get_uploads_playlist_ids(youtube, channel_ids: list[str]) -> list[str]:
    """channels.list is batched 50 ids per call to keep quota usage low."""
    uploads_playlist_ids = []
    for batch in chunked(channel_ids, 50):
        resp = (
            youtube.channels()
            .list(part="contentDetails", id=",".join(batch), maxResults=50)
            .execute()
        )
        for item in resp.get("items", []):
            uploads_playlist_ids.append(
                item["contentDetails"]["relatedPlaylists"]["uploads"]
            )
    return uploads_playlist_ids


def get_recent_uploads(
    youtube, uploads_playlist_ids: list[str], cutoff: datetime, max_results: int
) -> list[dict]:
    """
    Returns a list of dicts: {"videoId": ..., "publishedAt": datetime, "title": ...}
    for videos published after `cutoff`, across all given uploads playlists.
    """
    recent = []
    for playlist_id in uploads_playlist_ids:
        try:
            resp = (
                youtube.playlistItems()
                .list(
                    part="contentDetails,snippet",
                    playlistId=playlist_id,
                    maxResults=max_results,
                )
                .execute()
            )
        except HttpError as e:
            # Channels with uploads disabled/deleted, or a playlist that's
            # gone, shouldn't kill the whole run.
            log.warning("Skipping playlist %s: %s", playlist_id, e)
            continue

        for item in resp.get("items", []):
            published_str = item["contentDetails"].get("videoPublishedAt")
            if not published_str:
                continue
            published_at = datetime.fromisoformat(
                published_str.replace("Z", "+00:00")
            )
            if published_at >= cutoff:
                recent.append(
                    {
                        "videoId": item["contentDetails"]["videoId"],
                        "publishedAt": published_at,
                        "title": item["snippet"].get("title", ""),
                    }
                )
            # playlistItems for the "uploads" playlist come back newest
            # first, so once we hit one older than the cutoff, the rest
            # of this channel's page will be older too.
            else:
                break
    log.info("Found %d recent uploads (< %s cutoff)", len(recent), cutoff.isoformat())
    return recent


def get_playlist_items(youtube, playlist_id: str) -> list[dict]:
    """
    Returns dicts: {"playlistItemId": ..., "videoId": ..., "publishedAt": datetime, "title": ...}
    for everything currently in the target playlist.
    """
    items = []
    page_token = None
    while True:
        resp = (
            youtube.playlistItems()
            .list(
                part="contentDetails,snippet",
                playlistId=playlist_id,
                maxResults=50,
                pageToken=page_token,
            )
            .execute()
        )
        for item in resp.get("items", []):
            published_str = item["contentDetails"].get("videoPublishedAt")
            published_at = (
                datetime.fromisoformat(published_str.replace("Z", "+00:00"))
                if published_str
                else None
            )
            items.append(
                {
                    "playlistItemId": item["id"],
                    "videoId": item["contentDetails"]["videoId"],
                    "publishedAt": published_at,
                    "title": item.get("snippet", {}).get("title", ""),
                }
            )
        page_token = resp.get("nextPageToken")
        if not page_token:
            break
    return items


def create_playlist(youtube, title: str) -> str:
    resp = (
        youtube.playlists()
        .insert(
            part="snippet,status",
            body={
                "snippet": {
                    "title": title,
                    "description": "Auto-synced recent subscription uploads for driving.",
                },
                "status": {"privacyStatus": "private"},
            },
        )
        .execute()
    )
    playlist_id = resp["id"]
    log.info("Created new playlist %r with id %s", title, playlist_id)
    return playlist_id


def add_video_to_playlist(
    youtube, playlist_id: str, video_id: str, title: str, dry_run: bool
) -> None:
    if dry_run:
        log.info(
            "[dry-run] would add: %r (https://youtu.be/%s)", title, video_id
        )
        return
    youtube.playlistItems().insert(
        part="snippet",
        body={
            "snippet": {
                "playlistId": playlist_id,
                "resourceId": {"kind": "youtube#video", "videoId": video_id},
            }
        },
    ).execute()
    log.info("Added: %r (https://youtu.be/%s)", title, video_id)


def remove_playlist_item(
    youtube, playlist_item_id: str, video_id: str, title: str, dry_run: bool
) -> None:
    if dry_run:
        log.info(
            "[dry-run] would remove: %r (https://youtu.be/%s)", title, video_id
        )
        return
    youtube.playlistItems().delete(id=playlist_item_id).execute()
    log.info("Removed: %r (https://youtu.be/%s)", title, video_id)


def is_short(video_id: str, timeout: float = 8.0) -> bool:
    """
    Best-effort check for whether a video is a YouTube Short.

    The Data API has no official "is this a Short" field, so this uses the
    same trick most third-party tools rely on: YouTube serves
    youtube.com/shorts/<id> as-is for Shorts, but redirects it to
    youtube.com/watch?v=<id> for regular videos. This is unofficial
    behavior and could change, but it's currently the most reliable
    signal available (duration alone stopped being reliable once YouTube
    extended the Shorts length limit to 3 minutes).
    """
    url = f"https://www.youtube.com/shorts/{video_id}"
    try:
        resp = requests.get(url, allow_redirects=False, timeout=timeout, stream=True)
        resp.close()
    except requests.RequestException as e:
        log.warning(
            "Couldn't check Shorts status for %s (%s); treating as a regular video",
            video_id,
            e,
        )
        return False

    if resp.status_code in (301, 302, 303, 307, 308):
        # Redirected away from /shorts/<id> -> it's a normal video.
        location = resp.headers.get("Location", "")
        return "/shorts/" in location
    # No redirect -> the Shorts URL served the Shorts player -> it is one.
    return resp.status_code == 200


def filter_out_shorts(videos: list[dict], max_workers: int = 8) -> list[dict]:
    if not videos:
        return videos
    with ThreadPoolExecutor(max_workers=max_workers) as pool:
        short_flags = list(pool.map(lambda v: is_short(v["videoId"]), videos))
    kept = [v for v, is_s in zip(videos, short_flags) if not is_s]
    skipped = len(videos) - len(kept)
    if skipped:
        log.info("Filtered out %d Short(s)", skipped)
    return kept


# --------------------------------------------------------------------------
# Locking (avoid overlapping cron/timer runs)
# --------------------------------------------------------------------------

class SingleInstance:
    def __init__(self, lock_path: str):
        self.lock_path = lock_path
        self._fh = None

    def __enter__(self):
        self._fh = open(self.lock_path, "w")
        try:
            fcntl.flock(self._fh, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise SystemExit("Another instance is already running; exiting.")
        return self

    def __exit__(self, *exc):
        if self._fh:
            fcntl.flock(self._fh, fcntl.LOCK_UN)
            self._fh.close()


# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", default="config.json", help="Path to config.json")
    parser.add_argument("--dry-run", action="store_true", help="Don't actually add/remove anything")
    parser.add_argument("--verbose", action="store_true", help="Debug logging")
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
    )

    cfg = load_config(args.config)

    lock_path = os.path.join(os.path.dirname(os.path.abspath(args.config)) or ".", ".sync_playlist.lock")
    with SingleInstance(lock_path):
        creds = get_credentials(cfg["token_file"])
        youtube = build("youtube", "v3", credentials=creds)

        target_playlist_id = cfg.get("target_playlist_id")
        if not target_playlist_id:
            target_playlist_id = create_playlist(youtube, cfg["target_playlist_title"])
            log.warning(
                "No target_playlist_id was set in config. Created playlist "
                "id %s -- add this to config.json as 'target_playlist_id' "
                "so future runs reuse the same playlist instead of "
                "creating a new one each time.",
                target_playlist_id,
            )

        cutoff = datetime.now(timezone.utc) - timedelta(hours=cfg["lookback_hours"])

        channel_ids = get_subscribed_channel_ids(youtube)
        uploads_playlist_ids = get_uploads_playlist_ids(youtube, channel_ids)
        recent_uploads = get_recent_uploads(
            youtube, uploads_playlist_ids, cutoff, cfg["max_results_per_channel"]
        )

        if cfg["exclude_shorts"]:
            recent_uploads = filter_out_shorts(recent_uploads)

        current_items = get_playlist_items(youtube, target_playlist_id)
        current_video_ids = {item["videoId"] for item in current_items}

        # --- remove stale items ---
        removed = 0
        for item in current_items:
            if item["publishedAt"] is not None and item["publishedAt"] < cutoff:
                remove_playlist_item(
                    youtube,
                    item["playlistItemId"],
                    item["videoId"],
                    item["title"],
                    args.dry_run,
                )
                removed += 1

        # --- add new items ---
        added = 0
        for video in recent_uploads:
            if video["videoId"] not in current_video_ids:
                add_video_to_playlist(
                    youtube,
                    target_playlist_id,
                    video["videoId"],
                    video["title"],
                    args.dry_run,
                )
                added += 1

        log.info("Done. Added %d, removed %d.", added, removed)

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except HttpError as e:
        log.error("YouTube API error: %s", e)
        raise SystemExit(1)
