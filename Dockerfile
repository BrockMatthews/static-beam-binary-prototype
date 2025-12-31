FROM debian:bookworm-slim

ARG GO_VERSION=1.25.5
ARG OTP_RELEASE=maint-27

RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    build-essential \
    ca-certificates \
    clang \
    curl \
    git \
    libncurses-dev \
    libssl-dev \
    libtool \
    llvm \
    perl \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Go for virtual_fs
RUN curl -fsSL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz \
    | tar -C /usr/local -xz

ENV PATH=/usr/local/go/bin:$PATH


WORKDIR /virtual-beam

RUN git clone https://github.com/erlang/otp

WORKDIR /virtual-beam/otp

RUN git checkout ${OTP_RELEASE}

# Thanks to Yoshie for the configure arguments
RUN ./configure CC=clang CXX=clang \
    LIBS="-lncursesw -ltinfo -lcrypto -lssl -lstdc++" \
    LDFLAGS="-static-libgcc -static-libstdc++" \
    -disable-pie \
    --enable-builtin-zlib \
    --with-ssl \
    --enable-static-nifs \
    --enable-static-drivers
    # LDFLAGS="-static -static-libgcc -static-libstdc++" \
    # --disable-dynamic-ssl-lib \

# NOTE: currently using dynamic crypto. Someone will know how to statically link it

RUN make


WORKDIR /

RUN ln -s /virtual-beam/otp/bin/erl /usr/local/bin/erl

COPY docker/beam_arg_swiper.py /virtual-beam/otp/bin/x86_64-pc-linux-gnu/beam.smp
COPY docker/virtual_fs.go /
COPY docker/virtual_fs.patch /virtual-beam/otp/
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
