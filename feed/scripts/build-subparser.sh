#!/bin/sh
# _subparser.so (Python extension of e2iplayer-deps) for Python $PYVER.
# Runs natively in a container of the target platform with an old glibc
# (images in .github/workflows/feed-build.yml): a Python module cannot be static, it
# needs the libc and the Python ABI of the image. Compiler call as in do_compile()
# of enigma2-plugin-extensions-e2iplayer-deps.bb (SOURCE_FILES1); libpython is not
# linked, its symbols come from the enigma2 process.
. "$(dirname "$0")/common.sh"
PYVER=${PYVER:?PYVER is not set}

log "e2isubparser for Python $PYVER"
fetch_git deps "$DEPS_GIT" "$DEPS_REV"
(
    cd "$WORK/src/deps/e2isubparser"
    EXPAT=src/expat
    [ -d "$EXPAT" ] || EXPAT=src/expat-2.2.0
    EXPAT_RANDOM=""
    [ -f "$EXPAT/random_dev_urandom.c" ] && EXPAT_RANDOM="$EXPAT/random_dev_urandom.c"
    # INCLUDEPY: Debian's Python 2 sysconfig paths point to /usr/local
    PYINC=$(python$PYVER -c "import sysconfig; print(sysconfig.get_config_var('INCLUDEPY'))")
    ls "$PYINC/Python.h"
    $CC src/subparsermodule.c src/vlc/src/subtitle.c src/ffmpeg/src/htmlsubtitles.c \
        $EXPAT/xmlparse.c $EXPAT/xmlrole.c $EXPAT/xmltok.c $EXPAT/xmltok_impl.c $EXPAT/xmltok_ns.c \
        $EXPAT_RANDOM src/ttml/src/ttmlparser.c src/html/src/htmlcleaner.c \
        -shared -pipe -D_FILE_OFFSET_BITS=64 -D_LARGEFILE64_SOURCE -D_LARGEFILE_SOURCE \
        -D_GNU_SOURCE=1 -DNDEBUG -Os -Wall -Wstrict-prototypes -fPIC \
        -DMAJOR_VERSION=0 -DMINOR_VERSION=2 -DHAVE_EXPAT_CONFIG_H \
        -Isrc -Isrc/vlc/include -Isrc/ffmpeg/include -I$EXPAT -Isrc/ttml/include \
        -Isrc/html/include -I"$PYINC" -lm -o _subparser.so -Wl,--gc-sections -Wl,-Bsymbolic
    "$STRIP" -s _subparser.so
    install -m 0644 _subparser.so "$OUT/_subparser.so_py$PYVER"
    ls -l "$OUT/_subparser.so_py$PYVER"

    log "test"
    # needed glibc symbol versions, must stay below the oldest image's glibc
    objdump -T _subparser.so | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -n 1
    mkdir -p "$WORK/subtest"
    cp _subparser.so "$WORK/subtest/"
    cd "$WORK/subtest"
    python$PYVER - <<'PY'
import _subparser
print("version: %s" % _subparser.version())
assert float(_subparser.version()) >= 0.5, "the setup wants >= 0.5"
srt = "1\n00:00:01,000 --> 00:00:02,000\nHello world\n\n2\n00:00:03,000 --> 00:00:04,500\n<i>second</i> cue\n\n"
r = _subparser.parse(srt, 0, 1, 1, 12, 138)
print("srt: %r" % (r,))
assert len(r["list"]) == 2 and r["list"][1]["start"] == 3000 and r["list"][1]["end"] == 4500
ttml = ('<?xml version="1.0" encoding="UTF-8"?>'
        '<tt xmlns="http://www.w3.org/ns/ttml"><body><div>'
        '<p begin="00:00:01.000" end="00:00:03.000">Ampersand &amp; entity</p>'
        '<p begin="00:00:04.000" end="00:00:06.000">second cue</p>'
        '</div></body></tt>')
r = _subparser.parse(ttml, 0, 1, 1, 12, 138)
print("ttml: %r" % (r,))
assert len(r["list"]) == 2 and "&" in r["list"][0]["text"]
PY
)
