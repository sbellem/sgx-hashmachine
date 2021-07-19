let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs { };
  sgx = import sources.sgx;
in
pkgs.stdenv.mkDerivation {
  name = "sgx-hashmachine";
  # FIXME not sure why but the build is non-deterministic if using src = ./.;
  # Possibly some untracked file(s) causing the problem ...?
  # src = ./.;
  # NOTE The commit (rev) cannot include this file, and therefore will at the very
  # best one commit behind the commit including this file.
  src = pkgs.fetchFromGitHub {
    owner = "sbellem";
    repo = "sgx-hashmachine";
    rev = "3cd6c8b64f593b220796b1299066cd24b2b7457b";
    # Command to get the sha256 hash (note the --fetch-submodules arg):
    # nix run -f '<nixpkgs>' nix-prefetch-github -c nix-prefetch-github --rev 3cd6c8b64f593b220796b1299066cd24b2b7457b sbellem sgx-hashmachine
    sha256 = "181lv5p574c8626dqzj18361rrsgamg0ik2pi79v634wsff2950j";
  };
  preConfigure = ''
    export SGX_SDK=${sgx.sgxsdk}/sgxsdk
    export PATH=$PATH:$SGX_SDK/bin:$SGX_SDK/bin/x64
    export PKG_CONFIG_PATH=$SGX_SDK/pkgconfig
    export LD_LIBRARY_PATH=$SGX_SDK/sdk_libs
    ./bootstrap
    '';
  configureFlags = ["--with-sgxsdk=$SGX_SDK"];
  buildInputs = with pkgs; [
    sgx.sgxsdk
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
    ${sgx.sgxsdk}/sgxsdk/bin/x64/sgx_sign dump -cssfile enclave_sigstruct_raw -dumpfile /dev/null -enclave $out/bin/Enclave.signed.so
    cp enclave_sigstruct_raw $out/bin/
    '';
  dontFixup = true;
}
