#!/bin/sh
# Entry point inside the Alpine build container: install the toolchain,
# build every tool for $PLAT, run the tests.
set -eu
cd "$(dirname "$0")/../.."

apk add --no-cache build-base linux-headers cmake samurai git curl patch perl xz \
    pkgconf openssl-dev openssl-libs-static zlib-dev zlib-static python3

# run <script>: on failure the end of its log also goes out as one annotation
# (annotations can be read without logging in, the job log cannot)
run() {
    if ! sh "feed/scripts/$1.sh" > "/tmp/$1.log" 2>&1; then
        cat "/tmp/$1.log"
        printf '::error title=%s failed::%s\n' "$1" "$(tail -n 40 "/tmp/$1.log" | sed 's/%/%25/g' | awk '{printf "%s%%0A", $0}')"
        exit 1
    fi
    cat "/tmp/$1.log"
}

for s in build-deps build-duk build-qjs build-wget build-rtmpdump build-uchardet test; do
    run "$s"
done
