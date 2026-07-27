#!/usr/bin/env python3
"""
Automatically adds new videos from YouTube subscriptions to a target playlist.
Designed for self-hosted deployment with periodic execution (cron/systemd).
"""

import os
import sys
import logging
from datetime import datetime, timedelta, timezone
from typing import List, Dict, Optional
import feedparser

try:
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError
    from google.oauth2.credentials import Credentials
    from google_auth_oauthlib.flow import InstalledAppFlow
    from google.auth.transport.requests import Request
except ImportError:
    print("Missing dependencies. Install with:")
    print("  pip install google-api-python-client google-auth-httplib2 google-auth-oauthlib")
    sys.exit(1)

# ──────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
# ──────────────────────────────────────────────────────────────────────────────

# Your YouTube channel IDs to monitor (get from subscription page URL or API)
CHANNEL_IDS = [
    "UCBJycsmduvYEL83R_U4JriQ",  # Example: Marques Brownlee (MKBHD)
    "UCXuqSBlHAE6Xw-yeJA0Tunw",  # Example: Linus Tech Tips
    # Add more channel IDs here
]

# Target playlist ID (create one in YouTube, then copy the ID from URL:
# https://www.youtube.com/playlist?list=PLAYLIST_ID)
TARGET_PLAYLIST_ID = "PLxxxxxxxxxxxxxxxxxxxx"  # Replace with your playlist ID

# Lookback window: add videos published within the last N hours
LOOKBACK_HOURS = 24

# YouTube API scope
SCOPES = ["https://www.googleapis.com/youtube/v3"]

# Logging configuration
LOG_FILE = "/var/log/youtube-subscription-sync.log"
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


def authenticate() -> Credentials:
    """Authenticate with Google OAuth and return credentials."""
    creds_path = "/home/user/.config/youtube-auto-creds.json"  # Adjust path
    token_path = "/home/user/.config/youtube-token.pickle"      # Adjust path
    
    creds = None
    
    if os.path.exists(token_path):
        creds = Credentials.from_authorized_user_file(token_path, SCOPES)
    
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            logger.info("Refreshing expired credentials...")
            creds.refresh(Request())
        else:
            logger.info("Running OAuth flow...")
            flow = InstalledAppFlow.from_client_secrets_file(creds_path, SCOPES)
            creds = flow.run_local_server(port=0)
        
        # Save credentials for next run
        os.makedirs(os.path.dirname(token_path), exist_ok=True)
        with open(token_path, "w") as token:
            token.write(creds.to_json())
        logger.info(f"Credentials saved to {token_path}")
    
    return creds


def get_channel_rss_feed(channel_id: str) -> feedparser.FeedParserDict:
    """Fetch the RSS feed for a YouTube channel."""
    rss_url = f"https://www.youtube.com/feeds/videos.xml?channel_id={channel_id}"
    feed = feedparser.parse(rss_url)
    
    if feed.bozo:
        logger.warning(f"Feed parsing error for channel {channel_id}: {feed.bozo_exception}")
    
    return feed


def get_existing_playlist_videos(youtube, playlist_id: str) -> set:
    """Get all video IDs currently in the target playlist."""
    video_ids = set()
    request = youtube.playlistItems().list(
        part="snippet,contentDetails",
        playlistId=playlist_id,
        maxResults=50
    )
    
    while request:
        response = request.execute()
        for item in response.get("items", []):
            video_id = item["snippet"]["resourceId"].get("videoId")
            if video_id:
                video_ids.add(video_id)
        request = youtube.playlistItems().list_next(
            previous_request=request,
            previous_response=response
        )
    
    return video_ids


def get_recent_videos(feed: feedparser.FeedParserDict, lookback_hours: int) -> List[Dict]:
    """Filter feed entries to only those published within the lookback window."""
    now = datetime.now(timezone.utc)
    cutoff = now - timedelta(hours=lookback_hours)
    recent_videos = []
    
    for entry in feed.entries:
        # Parse published date (format: "2024-01-15T10:30:00+00:00")
        published = entry.published_parsed
        pub_datetime = datetime(*published[:6], tzinfo=timezone.utc)
        
        if pub_datetime >= cutoff:
            video_id = entry.id.split("/")[-1]  # Extract video ID from URL
            recent_videos.append({
                "id": video_id,
                "title": entry.title,
                "published": entry.published,
                "channel": feed.feed.title,
                "url": f"https://www.youtube.com/watch?v={video_id}"
            })
            logger.debug(f"Found recent video: {entry.title}")
    
    return recent_videos


def add_videos_to_playlist(youtube, playlist_id: str, video_ids: List[str]) -> int:
    """Add videos to a playlist. Returns count of successfully added videos."""
    added = 0
    
    for video_id in video_ids:
        try:
            youtube.playlistItems().insert(
                part="snippet",
                body={
                    "snippet": {
                        "playlistId": playlist_id,
                        "resourceId": {
                            "kind": "youtube#video",
                            "videoId": video_id
                        }
                    }
                }
            ).execute()
            
            added += 1
            logger.info(f"Added video: {video_id}")
            
        except HttpError as e:
            # Check for duplicate (already in playlist)
            if e.resp.status == 409:
                logger.debug(f"Video {video_id} already in playlist (skipped)")
            else:
                logger.error(f"Failed to add video {video_id}: {e}")
    
    return added


def main():
    """Main execution flow."""
    logger.info("=" * 60)
    logger.info(f"Starting YouTube subscription sync at {datetime.now(timezone.utc)}")
    logger.info(f"Channels monitored: {len(CHANNEL_IDS)}")
    logger.info(f"Target playlist: {TARGET_PLAYLIST_ID}")
    logger.info(f"Lookback window: {LOOKBACK_HOURS} hours")
    logger.info("=" * 60)
    
    # Authenticate
    creds = authenticate()
    youtube = build("youtube", "v3", credentials=creds)
    
    # Get existing playlist videos (for deduplication)
    existing_video_ids = get_existing_playlist_videos(youtube, TARGET_PLAYLIST_ID)
    logger.info(f"Existing videos in playlist: {len(existing_video_ids)}")
    
    # Collect recent videos from all channels
    new_videos = []
    
    for channel_id in CHANNEL_IDS:
        logger.info(f"Fetching feed for channel {channel_id}...")
        feed = get_channel_rss_feed(channel_id)
        
        if feed.entries:
            channel_title = feed.feed.get("title", "Unknown")
            logger.info(f"  Channel: {channel_title} ({len(feed.entries)} entries)")
            
            recent = get_recent_videos(feed, LOOKBACK_HOURS)
            # Filter out videos already in playlist
            fresh = [v for v in recent if v["id"] not in existing_video_ids]
            new_videos.extend(fresh)
            
            logger.info(f"  New videos found: {len(recent)}, unique: {len(fresh)}")
        else:
            logger.warning(f"  No entries found for channel {channel_id}")
    
    if not new_videos:
        logger.info("No new videos to add.")
        logger.info("Sync complete.")
        return
    
    # Log summary before adding
    logger.info("-" * 60)
    logger.info(f"Videos to add: {len(new_videos)}")
    for video in new_videos:
        logger.info(f"  • {video['title']}")
    logger.info("-" * 60)
    
    # Add to playlist
    added_count = add_videos_to_playlist(youtube, TARGET_PLAYLIST_ID, [v["id"] for v in new_videos])
    
    logger.info("=" * 60)
    logger.info(f"Sync complete: {added_count}/{len(new_videos)} videos added")
    logger.info(f"Total playlist size: {len(existing_video_ids) + added_count}")
    logger.info("=" * 60)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        logger.info("Interrupted by user")
        sys.exit(0)
    except Exception as e:
        logger.exception(f"Unhandled error: {e}")
        sys.exit(1)
