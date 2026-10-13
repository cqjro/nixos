#!/usr/bin/env python3
# Rewrite QIDIStudio's hardcoded webview User-Agent in place (equal length).
#
# The non-Windows branch of src/slic3r/GUI/Widgets/WebView.cpp sets a UA with
# no browser token, so the login / online-model pages (which sniff the UA to
# populate the X-DeviceType header) send nothing and api.qidimaker.com replies
# "X-DeviceType missing in request header" (code 2010). Windows works because
# its UA contains "Chrome/... Safari/...". This injects a Chrome token without
# changing the string length, keeping the QDT-Slicer/QDT-Language markers.
#
# Upstream: QIDITECH/QIDIStudio#244
# Registry: AGENTS.md "Pending upstream fixes" row 5 (mirrored in README.md).
import sys

OLD = (b"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 "
       b"(KHTML, like Gecko) QDT-Slicer/v%s (%s) QDT-Language/%s")
DESIRED = (b"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.3 "
           b"(KHTML, like Gecko) Chrome/107.0.0.0 "
           b"QDT-Slicer/v%s (%s) QDT-Language/%s")


def main(path):
    assert DESIRED.count(b"%s") == OLD.count(b"%s") == 3
    assert len(DESIRED) <= len(OLD), "replacement must not grow the binary"
    new = DESIRED + b" " * (len(OLD) - len(DESIRED))
    with open(path, "rb") as fh:
        data = fh.read()
    count = data.count(OLD)
    assert count == 1, f"expected exactly one UA literal, found {count}"
    with open(path, "wb") as fh:
        fh.write(data.replace(OLD, new))


if __name__ == "__main__":
    main(sys.argv[1])
