{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
      in
      with pkgs;
      {
        devShells.default = mkShell {
          buildInputs = [
            openssl
            pkg-config
            probe-rs
            elf2uf2-rs
            flip-link
            openocd-rp2040
            # (rust-bin.stable.latest.default.override {
            #   targets = ["thumbv6m-none-eabi"];
            #   extensions = ["rust-src"];
            # })
            (rust-bin.selectLatestNightlyWith (toolchain: toolchain.default.override {
              targets = ["thumbv6m-none-eabi"];
              extensions = ["rust-src"];
            }))
          ];

          BINDGEN_EXTRA_CLANG_ARGS = 
              # Includes normal include path
              (builtins.map (a: ''-I"${a}/include"'') [
                # add dev libraries here (e.g. pkgs.libvmi.dev)
                pkgs.glibc.dev 
              ])
              # Includes with special directory paths
              ++ [
                ''-I"${pkgs.llvmPackages_latest.libclang.lib}/lib/clang/${pkgs.llvmPackages_latest.libclang.version}/include"''
                ''-I"${pkgs.glib.dev}/include/glib-2.0"''
                ''-I${pkgs.glib.out}/lib/glib-2.0/include/''
              ];

        };
      }
    );

}
