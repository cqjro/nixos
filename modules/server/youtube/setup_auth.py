#!/usr/bin/env python3
"""
setup_auth.py
-------------
Run this ONCE, on a machine that has a web browser (your laptop/desktop),
NOT on the headless NixOS server. It performs the Google OAuth consent
flow and writes a token.json file containing a refresh token.

After running this, copy the resulting token.json to your server (see
README.md for the recommended secure location and permissions), where
sync_playlist.py will use it to authenticate without ever needing a
browser again.

Prerequisites:
  1. Create a project in Google Cloud Console.
  2. Enable the "YouTube Data API v3" for that project.
  3. Create an OAuth Client ID of type "Desktop app".
  4. Download the JSON and save it as client_secret.json next to this
     script.

Usage:
  python3 setup_auth.py
"""

import os
import sys

from google_auth_oauthlib.flow import InstalledAppFlow

SCOPES = ["https://www.googleapis.com/auth/youtube"]
CLIENT_SECRET_FILE = "client_secret.json"
TOKEN_FILE = "token.json"


def main() -> int:
    if not os.path.exists(CLIENT_SECRET_FILE):
        print(
            f"ERROR: {CLIENT_SECRET_FILE} not found.\n"
            "Download an OAuth 'Desktop app' client ID from Google Cloud "
            "Console (APIs & Services > Credentials) and save it here as "
            f"{CLIENT_SECRET_FILE}.",
            file=sys.stderr,
        )
        return 1

    flow = InstalledAppFlow.from_client_secrets_file(CLIENT_SECRET_FILE, SCOPES)
    # Opens a browser tab on THIS machine and spins up a local redirect
    # listener. This is why setup_auth.py must be run somewhere with a
    # browser, not on the headless server.
    creds = flow.run_local_server(port=0)

    with open(TOKEN_FILE, "w") as f:
        f.write(creds.to_json())

    print(f"Success. Wrote {TOKEN_FILE}.")
    print("Copy this file to your server (keep it private, chmod 600) "
          "next to sync_playlist.py / at the path set in config.json.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
