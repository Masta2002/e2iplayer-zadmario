#!/bin/sh
# rtmpdump 2.6 + the three oe-alliance patches (KSV 2015-12-15, OpenSSL fix, movecast).
# meta-multimedia builds it against GnuTLS; the static build uses OpenSSL.
. "$(dirname "$0")/common.sh"

log "rtmpdump $RTMPDUMP_VERSION"
fetch_git rtmpdump "$RTMPDUMP_GIT" "$RTMPDUMP_REV"
apply_patches "$WORK/src/rtmpdump" "$FEED/patches/rtmpdump"
(
    cd "$WORK/src/rtmpdump"
    make -j"$JOBS" SYS=posix CRYPTO=OPENSSL SHARED= XCFLAGS="$CFLAGS" XLDFLAGS="$LDFLAGS" rtmpdump
    install_bin rtmpdump
)
