{
  description = "sgx hash machine";

  inputs = {
    nixpkgs.url = "github:sbellem/nixpkgs/3eaaa55ac9c6d7c0c913217ff85c2bf7a8a337f0";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachSystem ["x86_64-linux"] (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
        with pkgs; {

          packages.enclave = stdenv.mkDerivation rec {
            pname = "sgx-hash-machine";
            version = "0.0.1";

            src = builtins.path {
              path = ./.;
              name = "${pname}-${version}";
            };
            #src = fetchFromGitHub {
            #  owner = "sbellem";
            #  repo = "sgx-hashmachine";
            #  rev = "200923d96ece58cf53d2e2c1047872ea6a418311";
            #  # Command to get the sha256 hash (note the --fetch-submodules arg):
            #  # nix run -f '<nixpkgs>' nix-prefetch-github -c nix-prefetch-github \
            #  #   --rev 200923d96ece58cf53d2e2c1047872ea6a418311 sbellem sgx-hashmachine
            #  sha256 = "1in0byp3bfcz5j3byil4ppz4i0vb9jhxrwj9qbbi6d3hp5psiwiz";
            #};

            #SGX_SDK = "${sgx-sdk}/sgxsdk";

            preConfigure = ''
              export SGX_SDK=${sgx-sdk}/sgxsdk
              export PATH=$PATH:$SGX_SDK/bin:$SGX_SDK/bin/x64
              export PKG_CONFIG_PATH=$SGX_SDK/pkgconfig
              export LD_LIBRARY_PATH=$SGX_SDK/sdk_libs
              ./bootstrap
              '';
            configureFlags = ["--with-sgxsdk=$SGX_SDK"];
            buildInputs = [
              sgx-sdk
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
              ${sgx-sdk}/sgxsdk/bin/x64/sgx_sign dump -cssfile enclave_sigstruct_raw -dumpfile /dev/null -enclave $out/bin/Enclave.signed.so
              cp enclave_sigstruct_raw $out/bin/
              '';
            dontFixup = true;
          };
          
          defaultPackage = self.packages.${system}.enclave;
          
          devShell = mkShell {

            buildInputs = [
              b2sum
              bashInteractive
              autoconf
              automake
              libtool
              exa
              fd
              file
              openssl
              sgx-sdk
              unixtools.whereis
              unixtools.xxd
              which
            ];

            SGX_SDK = "${sgx-sdk}/sgxsdk";

            shellHook = ''
              alias ls=exa
              alias find=fd
            '';
          };
        }
    );
}
