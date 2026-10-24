#!/bin/sh
# SHA256SUMS and index.json for $OUT (the files of one platform)
. "$(dirname "$0")/common.sh"

cd "$OUT"
rm -f SHA256SUMS index.json
sha256sum * > SHA256SUMS
cat SHA256SUMS

python3 - "$PLAT" "$FEED/sources.lock" "${GITHUB_SHA:-local}" <<'EOF'
import hashlib, json, os, sys, time
plat, lock, commit = sys.argv[1:4]
src = {}
for line in open(lock):
    line = line.strip()
    if line and not line.startswith('#') and '=' in line:
        k, v = line.split('=', 1)
        src[k] = v
version = {
    'hlsdl': 'e2iplayer-deps ' + src['DEPS_REV'][:7], 'lsdir': 'e2iplayer-deps ' + src['DEPS_REV'][:7],
    'cmdwrap': 'e2iplayer-deps ' + src['DEPS_REV'][:7], 'f4mdump': 'e2iplayer-deps ' + src['DEPS_REV'][:7],
    'duk': src['DUKTAPE_VERSION'], 'qjs': src['QUICKJS_VERSION'], 'wget': src['WGET_VERSION'],
    'rtmpdump': src['RTMPDUMP_VERSION'], 'uchardet': src['UCHARDET_VERSION'],
    'curl-impersonate': src['CURLIMP_VERSION'],
}
files = {}
for name in sorted(os.listdir('.')):
    if name in ('SHA256SUMS', 'index.json'):
        continue
    data = open(name, 'rb').read()
    files[name] = {'version': version.get(name, ''), 'size': len(data),
                   'sha256': hashlib.sha256(data).hexdigest()}
json.dump({'platform': plat, 'commit': commit, 'date': time.strftime('%Y-%m-%d'),
           'files': files}, open('index.json', 'w'), indent=1, sort_keys=True)
EOF
cat index.json
