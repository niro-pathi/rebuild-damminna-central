#!/usr/bin/env bash
# Enforces the rules in CLAUDE.md that can be checked mechanically.
set -uo pipefail
fail=0
note() { printf '  %s\n' "$1"; }

echo "== em dashes =="
# The docs legitimately name the character; only the site and workflows are checked.
if grep -n $'\u2014' index.html .github/workflows/*.yml 2>/dev/null; then
  note "FAIL: em dash found. House style is an en dash (U+2013)."; fail=1
else note "ok"; fi

echo "== raw hex outside :root =="
if python3 - <<'PY'
import re, sys
s = open('index.html').read()
root = re.search(r':root\{.*?\n\}', s, re.S).group(0)
stray = sorted(set(re.findall(r'#[0-9A-Fa-f]{6}', s.replace(root, ''))))
if stray:
    print('  FAIL: raw hex in component code:', ', '.join(stray)); sys.exit(1)
print('  ok'); sys.exit(0)
PY
then :; else fail=1; fi

echo "== synthesised font weights =="
if grep -nE 'font-weight:(500|600|700|800)' index.html; then
  note "FAIL: no brand font has these weights. Grift Black is 900; the others have no bold."; fail=1
else note "ok"; fi

echo "== fonts present =="
for f in grift-black juniper just-sans-light; do
  [ -f "fonts/$f.woff2" ] || { note "FAIL: fonts/$f.woff2 missing"; fail=1; }
done
[ $fail -eq 0 ] && note "ok"

echo "== placeholder domain =="
if grep -n "example.org" index.html >/dev/null; then
  note "WARN: example.org still present. CI replaces it at deploy time; confirm SITE_URL is set."
else note "ok"; fi

echo
[ $fail -eq 0 ] && echo "brand audit passed" || echo "brand audit FAILED"
exit $fail
