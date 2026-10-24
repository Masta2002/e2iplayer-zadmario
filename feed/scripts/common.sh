# Shared helpers for the feed build scripts (sourced, POSIX sh).
# Environment: PLAT (armv7, ...), optional WORK (scratch dir) and OUT (result dir).
set -eu

FEED=$(cd "$(dirname "$0")/.." && pwd)
. "$FEED/sources.lock"

PLAT=${PLAT:?PLAT is not set}
WORK=${WORK:-/tmp/feed-work}
OUT=${OUT:-$FEED/../out/$PLAT}
JOBS=$(nproc 2>/dev/null || echo 2)

# every tool is linked statically against musl: it runs on any image of the
# platform, whatever libc / OpenSSL / libcurl the image has
CFLAGS="-Os -ffunction-sections -fdata-sections"
LDFLAGS="-static -Wl,--gc-sections"
export CFLAGS LDFLAGS

mkdir -p "$WORK/dl" "$WORK/src" "$OUT"

log() { printf '\n=== %s\n' "$*"; }

# fetch_tar <name> <url> <sha256>: download, check, unpack to $WORK/src/<name>
fetch_tar() {
    _f="$WORK/dl/$(basename "$2")"
    [ -f "$_f" ] || curl -fsSL --retry 3 -o "$_f" "$2"
    echo "$3  $_f" | sha256sum -c -
    rm -rf "$WORK/src/$1"
    mkdir -p "$WORK/src/$1"
    tar -xf "$_f" -C "$WORK/src/$1" --strip-components=1
}

# fetch_git <name> <url> <commit>: check out exactly that commit to $WORK/src/<name>
fetch_git() {
    rm -rf "$WORK/src/$1"
    git init -q "$WORK/src/$1"
    git -C "$WORK/src/$1" remote add origin "$2"
    # not every server hands out a single commit, then take the whole history
    git -C "$WORK/src/$1" fetch -q --depth 1 origin "$3" || git -C "$WORK/src/$1" fetch -q origin
    git -C "$WORK/src/$1" checkout -q "$3"
    test "$(git -C "$WORK/src/$1" rev-parse HEAD)" = "$3"
}

# apply_patches <srcdir> <patchdir>: all *.patch in name order, -p1
apply_patches() {
    for _p in $(ls "$2"/*.patch | sort); do
        echo "patch: $(basename "$_p")"
        patch -d "$1" -p1 --no-backup-if-mismatch < "$_p"
    done
}

# install_bin <file> [name]: strip and copy to $OUT
install_bin() {
    strip -s "$1"
    install -m 0755 "$1" "$OUT/${2:-$(basename "$1")}"
    ls -l "$OUT/${2:-$(basename "$1")}"
}
