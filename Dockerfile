##############################################################################
#                                                                            #
#                            Build enclave (trusted)                         #
#                                                                            #
##############################################################################
FROM  nixpkgs/nix AS build-enclave

WORKDIR /usr/src

COPY nix /usr/src/nix
COPY default.nix /usr/src/default.nix

RUN mkdir -p ~/.config/nixpkgs && mv /usr/src/nix/config.nix ~/.config/nixpkgs/

RUN nix-build


FROM ghcr.io/initc3/sgx:2.19-jammy as run-app

RUN apt-get update && apt-get install -y \
                autotools-dev \
                automake \
                xxd \
                iputils-ping \
                python3.11 \
                python3.11-dev \
                python3-pip \
                python-is-python3 \
                vim \
        && rm -rf /var/lib/apt/lists/*

RUN pip install ipython requests pyyaml

WORKDIR /usr/src/hashmachine

ENV PATH ${PATH}:${SGX_SDK}/bin:${SGX_SDK}/bin/x64
ENV PKG_CONFIG_PATH ${SGX_SDK}/pkgconfig
ENV LD_LIBRARY_PATH ${SGX_SDK}/sdk_libs

COPY . .

RUN set -eux; \
    ./bootstrap; \
    ./configure --with-sgxsdk=${SGX_SDK}; \
    make;

# Copy reproducible signed enclave build from build-enclave stage
COPY --from=build-enclave /usr/src/result/bin/Enclave.signed.so Enclave/Enclave.signed.so
