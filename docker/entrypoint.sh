#!/bin/sh
set -eux

# -- Diabolically swipe BEAM args --

# beam.smp is overwritten with beam_arg_swiper.py
/virtual-beam/app/entrypoint.sh run dummy-arg > /virtual-beam/otp/erts/emulator/sys/unix/beam_args.h

# -- Build the Virtual Filesystem --
# TODO: need to slim down a lot!
mkdir -p /go/virtual-beam/otp/bin
cp /virtual-beam/otp/bin/start.boot /go/virtual-beam/otp/bin/start.boot
cp -r /virtual-beam/otp/lib /go/virtual-beam/otp
cp -r /virtual-beam/app /go/virtual-beam/

# Remove this directory, since it contains 'visible😀_file', which we can't currently handle
rm -r /go/virtual-beam/otp/lib/stdlib/test

go build -buildmode=c-archive /go/virtual_fs.go

mv virtual_fs.a /lib
mv virtual_fs.h /virtual-beam/otp/erts/emulator/nifs/common/

# -- Apply git patch to the BEAM --
cd /virtual-beam/otp

# ------ TEMP --------
# TODO: figure out how to add -l:virtual_fs.a to LIBS at make time
./configure CC=clang CXX=clang \
    LIBS="-lncursesw -ltinfo -lcrypto -lssl -lstdc++ -l:virtual_fs.a" \
    LDFLAGS="-static-libgcc -static-libstdc++" \
    -disable-pie \
    --enable-builtin-zlib \
    --with-ssl \
    --enable-static-nifs \
    --enable-static-drivers
# --------------------

git apply virtual_fs.patch

# -- Rebuild the BEAM --
make LDFLAGS="-l:virtual_fs.a"

# -- Copy out artefact --

# TODO: get package name in a better way
eval $(grep PACKAGE= /virtual-beam/app/entrypoint.sh)

cp /virtual-beam/otp/bin/x86_64-pc-linux-gnu/beam.smp /build/$PACKAGE

# TODO: improve this to owned by actual user GID:UID
chown 1000:1000 /build/$PACKAGE