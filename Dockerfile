##############################################################################
#                                                                            #
#                            Build enclave (trusted)                         #
#                                                                            #
##############################################################################
FROM  nixpkgs/nix AS build-enclave

WORKDIR /usr/src

COPY nix /usr/src/nix
COPY default.nix /usr/src/default.nix

RUN nix-build

FROM initc3/linux-sgx:2.13.3-ubuntu20.04

RUN apt-get update && apt-get install -y \
                autotools-dev \
                automake \
                xxd \
                iputils-ping \
                python3.9 \
                python3.9-dev \
                python3-pip \
                vim \
        && rm -rf /var/lib/apt/lists/*

# symlink python3.9 to python
RUN cd /usr/bin \
    && ln -s pydoc3.9 pydoc \
    && ln -s python3.9 python \
    && ln -s python3.9-config python-config

# pip
# taken from:
# https://github.com/docker-library/python/blob/4bff010c9735707699dd72524c7d1a827f6f5933/3.10-rc/buster/Dockerfile#L71-L95
ENV PYTHON_PIP_VERSION 21.0.1
ENV PYTHON_GET_PIP_URL https://github.com/pypa/get-pip/raw/29f37dbe6b3842ccd52d61816a3044173962ebeb/public/get-pip.py
ENV PYTHON_GET_PIP_SHA256 e03eb8a33d3b441ff484c56a436ff10680479d4bd14e59268e67977ed40904de

RUN set -ex; \
	\
    apt-get update; \
	wget -O get-pip.py "$PYTHON_GET_PIP_URL"; \
	echo "$PYTHON_GET_PIP_SHA256 *get-pip.py" | sha256sum --check --strict -; \
	\
	python get-pip.py \
		--disable-pip-version-check \
		--no-cache-dir \
		"pip==$PYTHON_PIP_VERSION" \
	; \
	pip --version; \
	\
	find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
			-o \
			\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' +; \
	rm -f get-pip.py

RUN pip install ipython requests pyyaml

WORKDIR /usr/src/hashmachine

ENV SGX_SDK /opt/sgxsdk
ENV PATH $PATH:$SGX_SDK/bin:$SGX_SDK/bin/x64
ENV PKG_CONFIG_PATH $SGX_SDK/pkgconfig
ENV LD_LIBRARY_PATH $SGX_SDK/sdk_libs

COPY . .

RUN set -eux; \
    ./bootstrap; \
    ./configure --with-sgxsdk=/opt/sgxsdk; \
    make;

# Copy reproducible signed enclave build from build-enclave stage
COPY --from=build-enclave /usr/src/result/bin/Enclave.signed.so Enclave/Enclave.signed.so



# install nix
#ARG UID=1000
#ARG GID=1000
#
#RUN apt-get update && apt-get install --yes git curl wget sudo xz-utils
#RUN groupadd --gid $GID --non-unique photon \
#    && useradd --create-home --uid $UID --gid $GID --non-unique --shell /bin/bash photon \
#    && usermod --append --groups sudo photon \
#    && echo "photon ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/photon \
#    && mkdir -p /etc/nix \
#    && echo 'sandbox = false' > /etc/nix/nix.conf
#
#ENV USER photon
#USER photon
#
#WORKDIR /home/photon
#
##COPY --chown=photon:photon ./nix.conf /home/photon/.config/nix/nix.conf
#
#RUN curl -L https://nixos.org/nix/install | sh
#
#RUN . /home/photon/.nix-profile/etc/profile.d/nix.sh && \
#  nix-channel --add https://nixos.org/channels/nixos-21.05 nixpkgs && \
#  nix-channel --update && \
#  nix-env -iA cachix -f https://cachix.org/api/v1/install && \
#  cachix use initc3
#
#ENV NIX_PROFILES "/nix/var/nix/profiles/default /home/photon/.nix-profile"
#ENV NIX_PATH /home/photon/.nix-defexpr/channels
#ENV NIX_SSL_CERT_FILE /etc/ssl/certs/ca-certificates.crt
#ENV PATH /home/photon/.nix-profile/bin:$PATH
