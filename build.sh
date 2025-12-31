#!/bin/sh
set -eux

(cd example_project && gleam export erlang-shipment)

docker build . -t gleam-static-builder

mkdir -p build

docker run --rm \
    -v ./example_project/build/erlang-shipment:/virtual-beam/app \
    -v ./build:/build \
    gleam-static-builder