#!/usr/bin/env python3
"""Two-way sync between the master feed list and a Miniflux server.

Master list : modules/system/rss-feeds.json  (consumed by modules/system/rss-sources.nix)
Snapshot    : modules/system/rss-feeds.synced.json  (feed URLs both sides agreed on
              at the last sync; this is what tells "deleted in Miniflux" apart from
              "never pushed yet")

Commands (every one is a dry run unless given its apply flag, except apply):
  status                 show what each command would do
  apply [--prune]        what the REDRUM `miniflux-rss-sync` unit runs on every switch:
                         push, then (with --prune) prune --yes
  push                   create feeds that are in the master list but not in Miniflux
  pull [--write]         add Miniflux-only feeds to the master list
       [--apply-removals]  also drop feeds that were deleted in Miniflux
  prune [--yes]          delete from Miniflux feeds that were dropped from the master list

Only feeds listed in the snapshot are ever deleted from Miniflux, so a feed added on
a phone is never lost before `pull` has seen it.

Config: MINIFLUX_URL (default https://feed.cqjro.ca). Auth, first match wins: an API
token from MINIFLUX_TOKEN or the per-user token file (Settings -> API Keys in
Miniflux), else HTTP basic auth from ADMIN_USERNAME/ADMIN_PASSWORD (the miniflux
admin.env the unit loads). RSS_SYNC_MASTER / RSS_SYNC_SNAPSHOT override the file
paths; RSS_SYNC_WAIT=<seconds> waits for Miniflux's /healthcheck before starting.
"""

import argparse
import base64
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

MAX_REMOVALS = 5  # --apply-removals and apply --prune refuse to drop more than this at once

config_dir = Path(os.environ.get("NIXOS_CONFIG_DIR", Path.home() / ".nixos"))
MASTER = Path(os.environ.get("RSS_SYNC_MASTER", config_dir / "modules/system/rss-feeds.json"))
SNAPSHOT = Path(os.environ.get("RSS_SYNC_SNAPSHOT", config_dir / "modules/system/rss-feeds.synced.json"))
TOKEN_FILE = Path.home() / ".config/rss-sync/api-token"
BASE_URL = os.environ.get("MINIFLUX_URL", "https://feed.cqjro.ca").rstrip("/")


def die(msg):
	print(f"error: {msg}", file=sys.stderr)
	sys.exit(1)


def norm(url):
	"""Compare feed URLs ignoring scheme/host case and a trailing slash."""
	p = urllib.parse.urlsplit(url.strip())
	path = p.path.rstrip("/")
	return urllib.parse.urlunsplit((p.scheme.lower(), p.netloc.lower(), path, p.query, ""))


# ---- local files -----------------------------------------------------------

def load_master():
	try:
		feeds = json.loads(MASTER.read_text())
	except (OSError, ValueError) as e:
		die(f"cannot read {MASTER}: {e}")
	for f in feeds:
		if "url" not in f or "title" not in f:
			die(f"{MASTER}: every entry needs url and title (got {f})")
	return feeds


def save_master(feeds):
	"""One key per line, lists inline, so diffs stay as small as the hand-written file."""
	dump = lambda v: json.dumps(v, ensure_ascii=False)
	entries = [
		"\t{\n" + ",\n".join(f"\t\t{dump(k)}: {dump(v)}" for k, v in f.items()) + "\n\t}"
		for f in feeds
	]
	MASTER.write_text("[\n" + ",\n".join(entries) + "\n]\n")


def load_snapshot():
	try:
		return set(json.loads(SNAPSHOT.read_text()))
	except FileNotFoundError:
		return set()
	except (OSError, ValueError) as e:
		die(f"cannot read {SNAPSHOT}: {e}")


def save_snapshot(urls):
	SNAPSHOT.write_text(json.dumps(sorted(urls), indent="\t") + "\n")


# ---- Miniflux API ----------------------------------------------------------

def auth_header():
	t = os.environ.get("MINIFLUX_TOKEN")
	if not t:
		try:
			t = TOKEN_FILE.read_text().strip()
		except OSError:
			pass
	if t:
		return "X-Auth-Token", t
	user, pw = os.environ.get("ADMIN_USERNAME"), os.environ.get("ADMIN_PASSWORD")
	if user and pw:
		return "Authorization", "Basic " + base64.b64encode(f"{user}:{pw}".encode()).decode()
	die(f"no credentials: set MINIFLUX_TOKEN, put a token in {TOKEN_FILE}, "
		"or provide ADMIN_USERNAME/ADMIN_PASSWORD")


def wait_ready():
	"""Poll /healthcheck for up to RSS_SYNC_WAIT seconds (the unit starts alongside Miniflux)."""
	deadline = time.monotonic() + float(os.environ.get("RSS_SYNC_WAIT", "0"))
	while True:
		try:
			with urllib.request.urlopen(BASE_URL + "/healthcheck", timeout=5):
				return
		except OSError:  # URLError is an OSError
			if time.monotonic() >= deadline:
				return  # let the first real request report the failure
			time.sleep(2)


def api(method, path, body=None):
	data = json.dumps(body).encode() if body is not None else None
	req = urllib.request.Request(BASE_URL + path, data=data, method=method)
	req.add_header(*auth_header())
	req.add_header("Content-Type", "application/json")
	# Cloudflare rejects urllib's default User-Agent (error 1010).
	req.add_header("User-Agent", "rss-sync/1.0")
	try:
		with urllib.request.urlopen(req, timeout=60) as r:
			raw = r.read()
	except urllib.error.HTTPError as e:
		detail = e.read().decode(errors="replace")
		try:
			detail = json.loads(detail).get("error_message", detail)
		except ValueError:
			pass
		raise RuntimeError(f"{method} {path}: HTTP {e.code} {detail.strip()[:200]}") from None
	except urllib.error.URLError as e:
		die(f"cannot reach {BASE_URL}: {e.reason}")
	return json.loads(raw) if raw else None


def miniflux_state():
	"""Return (feeds keyed by normalised URL, categories by id, default category id)."""
	wait_ready()
	cats = {c["id"]: c["title"] for c in api("GET", "/v1/categories")}
	if not cats:
		die("Miniflux returned no categories; refusing to continue")
	feeds = {norm(f["feed_url"]): f for f in api("GET", "/v1/feeds")}
	return feeds, cats, min(cats)


# ---- three-way comparison --------------------------------------------------

def plan():
	master = load_master()
	snap = {norm(u) for u in load_snapshot()}
	m_by = {norm(f["url"]): f for f in master}
	feeds, cats, default_cat = miniflux_state()
	m, s, x = set(m_by), snap, set(feeds)
	return {
		"master": master, "snap": snap, "feeds": feeds, "cats": cats,
		"default_cat": default_cat, "m_by": m_by,
		"to_push": sorted(m - x - s),               # new in Nix, not yet pushed
		"to_pull": sorted(x - m - s),               # new in Miniflux
		"deleted_remote": sorted((m & s) - x),      # deleted in Miniflux
		"to_prune": sorted((s - m) & x),            # dropped from Nix, still in Miniflux
	}


def tidy(snap, local, remote):
	"""Snapshot = feeds both sides hold. Adopt feeds present in both, and forget
	feeds that vanished from both (so re-adding one later is not mistaken for a
	removal from the master list). `local`/`remote` are the URL sets *after* the
	command ran."""
	return {u for u in snap | (local & remote) if u in local or u in remote}


def show(label, urls, lookup):
	print(f"{label}: {len(urls)}")
	for u in urls:
		print(f"  {lookup(u)}")


def cmd_status(args):
	p = plan()
	title = lambda u: f"{p['m_by'][u]['title']} <{u}>" if u in p["m_by"] else f"{p['feeds'][u]['title']} <{u}>"
	show("push  (in master, not in Miniflux)", p["to_push"], title)
	show("pull  (in Miniflux, not in master)", p["to_pull"], title)
	show("deleted in Miniflux (pull --apply-removals drops them from master)", p["deleted_remote"], title)
	show("prune (dropped from master, still in Miniflux)", p["to_prune"], lambda u: f"{p['feeds'][u]['title']} <{u}>")


def cmd_push(args):
	p = plan()
	if not p["to_push"]:
		print("nothing to push")
		save_snapshot(tidy(p["snap"], set(p["m_by"]), set(p["feeds"])))
		return 0
	cat_ids = {title: cid for cid, title in p["cats"].items()}
	pushed = set()
	failed = 0
	for u in p["to_push"]:
		f = p["m_by"][u]
		name = f.get("category")
		if name and name not in cat_ids:
			cat_ids[name] = api("POST", "/v1/categories", {"title": name})["id"]
			print(f"created category {name}")
		try:
			res = api("POST", "/v1/feeds", {
				"feed_url": f["url"],
				"category_id": cat_ids.get(name, p["default_cat"]),
			})
			api("PUT", f"/v1/feeds/{res['feed_id']}", {"title": f["title"]})
		except RuntimeError as e:
			failed += 1
			print(f"FAILED {f['title']}: {e}")
			continue
		pushed.add(u)
		print(f"pushed {f['title']}")
	save_snapshot(tidy(p["snap"], set(p["m_by"]), set(p["feeds"]) | pushed))
	return failed


def cmd_apply(args):
	"""Unattended sync for the REDRUM unit: push new feeds, optionally prune dropped ones.
	A feed that fails to subscribe is not recorded, so the next run retries it."""
	failed = cmd_push(args)
	if args.prune:
		# Nobody confirms an unattended prune, so apply the same guards as
		# `pull --apply-removals`: a mangled or empty list must not wipe Miniflux.
		p = plan()
		if not p["master"]:
			print("master list is empty; refusing to prune")
			return failed or 1
		if len(p["to_prune"]) > MAX_REMOVALS:
			print(f"{len(p['to_prune'])} prunes exceeds the cap of {MAX_REMOVALS}; "
				"run `rss-sync prune --yes` by hand if that is intended")
			return failed or 1
		args.yes = True
		cmd_prune(args)
	return failed


def cmd_pull(args):
	p = plan()
	master = p["master"]
	changed = False

	for u in p["to_pull"]:
		f = p["feeds"][u]
		entry = {"url": f["feed_url"], "title": f["title"]}
		cat = f["category"]
		if cat["id"] != p["default_cat"]:
			entry["category"] = cat["title"]
			entry["tags"] = [cat["title"].lower()]
		print(f"{'adding' if args.write else 'would add'} {f['title']} <{f['feed_url']}>")
		master.append(entry)
		changed = True

	if p["deleted_remote"]:
		if not args.apply_removals:
			show("deleted in Miniflux (rerun with --apply-removals to drop from master)",
				p["deleted_remote"], lambda u: f"{p['m_by'][u]['title']} <{u}>")
		elif not p["feeds"]:
			die("Miniflux has no feeds at all; refusing to remove anything")
		elif len(p["deleted_remote"]) > MAX_REMOVALS:
			die(f"{len(p['deleted_remote'])} removals exceeds the cap of {MAX_REMOVALS}; edit the master list by hand")
		else:
			drop = set(p["deleted_remote"])
			for u in sorted(drop):
				print(f"{'removing' if args.write else 'would remove'} {p['m_by'][u]['title']} <{u}>")
			master[:] = [f for f in master if norm(f["url"]) not in drop]
			changed = True

	if not changed:
		print("nothing to pull")
	elif not args.write:
		print("dry run; pass --write to apply")
	if args.write:
		if changed:
			save_master(master)
			print(f"updated {MASTER.name}; commit it and rebuild")
		save_snapshot(tidy(p["snap"], {norm(f["url"]) for f in master}, set(p["feeds"])))


def cmd_prune(args):
	p = plan()
	if not p["to_prune"]:
		print("nothing to prune")
		if args.yes:
			save_snapshot(tidy(p["snap"], set(p["m_by"]), set(p["feeds"])))
		return
	deleted = set()
	for u in p["to_prune"]:
		f = p["feeds"][u]
		if not args.yes:
			print(f"would delete {f['title']} <{u}>")
			continue
		api("DELETE", f"/v1/feeds/{f['id']}")
		deleted.add(u)
		print(f"deleted {f['title']}")
	if args.yes:
		save_snapshot(tidy(p["snap"], set(p["m_by"]), set(p["feeds"]) - deleted))
	else:
		print("dry run; pass --yes to delete (this also removes the feed's entries)")


def main():
	ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
	sub = ap.add_subparsers(dest="cmd")
	sub.add_parser("status")
	sub.add_parser("push")
	pl = sub.add_parser("pull")
	pl.add_argument("--write", action="store_true")
	pl.add_argument("--apply-removals", action="store_true")
	pr = sub.add_parser("prune")
	pr.add_argument("--yes", action="store_true")
	pa = sub.add_parser("apply")
	pa.add_argument("--prune", action="store_true")
	args = ap.parse_args()
	cmd = {"push": cmd_push, "pull": cmd_pull, "prune": cmd_prune, "apply": cmd_apply}.get(args.cmd, cmd_status)
	if cmd(args):
		sys.exit(1)


if __name__ == "__main__":
	main()
