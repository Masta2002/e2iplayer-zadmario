#!/bin/sh
# qjs: quickjs-ng at the SRCREV of oe-alliance quickjs_0.16.2.bb, cmake like the recipe
. "$(dirname "$0")/common.sh"

log "quickjs-ng $QUICKJS_VERSION"
fetch_git quickjs "$QUICKJS_GIT" "$QUICKJS_REV"
(
    cd "$WORK/src/quickjs"
    cmake_cross . build -DBUILD_SHARED_LIBS=OFF
    # target qjs is the library, qjs_exe the interpreter (output name qjs)
    cmake --build build --target qjs_exe -j"$JOBS"
    install_bin build/qjs
)
