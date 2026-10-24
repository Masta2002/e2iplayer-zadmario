#!/bin/sh
# qjs: quickjs-ng at the SRCREV of oe-alliance quickjs_0.16.2.bb, cmake like the recipe
. "$(dirname "$0")/common.sh"

log "quickjs-ng $QUICKJS_VERSION"
fetch_git quickjs "$QUICKJS_GIT" "$QUICKJS_REV"
(
    cd "$WORK/src/quickjs"
    cmake -S . -B build -DCMAKE_BUILD_TYPE=MinSizeRel -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_EXE_LINKER_FLAGS="$LDFLAGS"
    cmake --build build --target qjs -j"$JOBS"
    install_bin build/qjs
)
