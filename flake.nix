{
  description = "sgx hash machine";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/23.05";
    alt-nixpkgs.url = "github:sbellem/nixpkgs/20ff746c79c5f0c10b8c4aa8e0b441e0b0ebd034";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    alt-nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachSystem ["x86_64-linux"] (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };
        sgx-sdk = (import alt-nixpkgs {
          inherit system;
        }).sgx-sdk;
      in
        with pkgs; {

          packages.enclave = stdenv.mkDerivation rec {
            pname = "sgx-hash-machine";
            version = "0.0.1";

            src = builtins.path {
              path = ./.;
              name = "${pname}-${version}";
            };

            SGX_SDK = "${sgx-sdk}/sgxsdk";

            preConfigure = ''
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
