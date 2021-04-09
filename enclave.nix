let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs { };
  sgxsdk = /nix/store/znr7dg5bkv2kspcmqrak59hb88hcqv4k-sgxsdk;
in
pkgs.stdenv.mkDerivation {
  inherit sgxsdk;
  name = "sgx-hashmachine";
  src = ./.;
  preConfigure = ''
    export SGX_SDK=$sgxsdk/sgxsdk
    export PATH=$PATH:$SGX_SDK/bin:$SGX_SDK/bin/x64
    export PKG_CONFIG_PATH=$SGX_SDK/pkgconfig
    export LD_LIBRARY_PATH=$SGX_SDK/sdk_libs
    ./bootstrap
    '';
  configureFlags = ["--with-sgxsdk=$SGX_SDK"];
  buildInputs = with pkgs; [
    sgxsdk
    unixtools.xxd
    bashInteractive
    autoconf
    automake
    libtool
    file
    openssl
    which
  ];
  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp Enclave/Enclave.so $out/bin/
    cp Enclave/Enclave.signed.so $out/bin/

    runHook postInstall
  '';
  postInstall = ''
    $sgxsdk/sgxsdk/bin/x64/sgx_sign dump -cssfile enclave_sigstruct_raw -dumpfile /dev/null -enclave $out/bin/Enclave.signed.so
    cp enclave_sigstruct_raw $out/bin/
    '';
  dontFixup = true;
}
