FROM ghcr.io/initc3/sgx:2.19-jammy

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
