#!/usr/bin/env python3
"""
Parse an xremap Nix config (Home Manager `services.xremap` module) into a
flat list of {chord, section, action, label} keybind records.

This is a *structural regex* parser tuned to the common xremap-nix pattern:

    super-X = {
        remap = {
            # Section Comment
            y.launch = ["cmd" "arg1" "arg2" ...];
        };
    };

It is NOT a general Nix parser (Nix is Turing-complete; a fully correct
parser would need `nix eval --json`). If your config stays close to this
shape it will work fine. For anything fancier, pipe the file through
`nix eval --json -f xremap.nix` first and adapt this script to read JSON
instead of regex.
"""
import re
import json
import sys
from pathlib import Path

def strip_comments(text: str) -> str:
    # Keep track of comment lines separately (used as section headers),
    # but strip them from the code we regex over so they don't confuse matches.
    return text

def parse(path: str):
    text = Path(path).read_text()
    lines = text.splitlines()

    records = []
    current_section = None
    # stack of active "super-X" (or other modifier) prefixes, with brace depth
    prefix_stack = []  # list of (brace_depth_when_opened, key_label)
    depth = 0

    # Top-level single-line binds like: super-t.remap.t.launch = ["ghostty"]; # Open terminal
    single_line_re = re.compile(
        r'^\s*([a-zA-Z0-9_]+(?:-[a-zA-Z0-9_]+)*)\.remap\.([a-zA-Z0-9_]+)\.launch\s*=\s*\[(.*?)\]\s*;\s*(?:#\s*(.*))?$'
    )
    # Opening a modifier block: super-o = {   or   super-o.remap = {
    open_prefix_re = re.compile(r'^\s*([a-zA-Z0-9_]+-[a-zA-Z0-9_]+)\s*=\s*\{')
    # A leaf bind inside a remap block: y.launch = ["cmd" ...]; # Description
    leaf_re = re.compile(r'^\s*([a-zA-Z0-9_]+)\.launch\s*=\s*\[(.*?)\]\s*;\s*(?:#\s*(.*))?$')

    for raw in lines:
        line = raw

        # capture section comment headers, e.g. "# Media Controls - Super+M"
        stripped = line.strip()
        if stripped.startswith('#'):
            comment = stripped.lstrip('#').strip()
            if comment:
                current_section = comment
            continue

        # single-line direct bind (e.g. super-t.remap.t.launch = [...])
        m = single_line_re.match(line)
        if m:
            prefix, leaf, argstr, inline_desc = m.groups()
            args = re.findall(r'"([^"]*)"', argstr)
            records.append({
                "chord": f"{prefix}+{leaf}",
                "section": current_section,
                "command": args,
                "description": inline_desc,
            })

        # opening a new "super-X = {" block
        m2 = open_prefix_re.match(line)
        if m2:
            prefix_stack.append((depth, m2.group(1)))

        # leaf inside currently-open prefix block
        m3 = leaf_re.match(line)
        if m3 and prefix_stack:
            leaf, argstr, inline_desc = m3.groups()
            args = re.findall(r'"([^"]*)"', argstr)
            active_prefix = prefix_stack[-1][1]
            records.append({
                "chord": f"{active_prefix}+{leaf}",
                "section": current_section,
                "command": args,
                "description": inline_desc,
            })

        # track brace depth to know when a prefix block closes
        depth += line.count('{') - line.count('}')
        while prefix_stack and depth <= prefix_stack[-1][0] and depth < prefix_stack[-1][0] + 1:
            # only pop if we've actually closed back to (or below) the depth
            # at which this prefix opened
            if depth <= prefix_stack[-1][0]:
                prefix_stack.pop()
            else:
                break

    return records

def humanize_chord(chord: str) -> str:
    # super-o+t  ->  Super+O, T
    parts = chord.split('+')
    out = []
    for p in parts:
        p = p.replace('super-', 'Super+').replace('super', 'Super')
        p = '+'.join(seg.capitalize() if len(seg) > 1 else seg.upper() for seg in p.split('+'))
        out.append(p)
    return ', '.join(out)

def humanize_action(cmd: list[str]) -> str:
    if not cmd:
        return ""
    if cmd[0] == 'noctalia' and len(cmd) >= 3 and cmd[1] == 'msg':
        return ' '.join(cmd[2:])
    if 'focus-window.sh' in ' '.join(cmd):
        # --by class/title NAME ...
        try:
            by_idx = cmd.index('--by')
            kind, needle = cmd[by_idx+1], cmd[by_idx+2]
            return f"Focus/launch {needle} ({kind})"
        except (ValueError, IndexError):
            return "Focus/launch window"
    return ' '.join(cmd)

if __name__ == '__main__':
    src = sys.argv[1] if len(sys.argv) > 1 else 'xremap.nix'
    recs = parse(src)
    out = []
    for r in recs:
        # An inline "# description" comment always wins over the
        # auto-guessed description from the command args.
        action = r.get("description") or humanize_action(r["command"])
        out.append({
            "chord": humanize_chord(r["chord"]),
            "raw_chord": r["chord"],
            "section": r["section"] or "General",
            "action": action,
            "raw_command": r["command"],
        })
    print(json.dumps(out, indent=2))
