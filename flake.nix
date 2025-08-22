{
  description = "An empty project that uses Zig.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zig = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zls-overlay = {
      url = "github:zigtools/zls";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }@inputs:
    let
      overlays = [
        # Other overlays
        (final: prev: {
          zigpkgs = inputs.zig.packages.${prev.system};
          zlspkgs = inputs.zls-overlay.packages.${prev.system};
        })
      ];

      # Our supported systems are the same supported systems as the Zig binaries
      systems = builtins.attrNames inputs.zig.packages;
    in
    flake-utils.lib.eachSystem systems (
      system:
      let
        pkgs = import nixpkgs { inherit overlays system; };
        zig = pkgs.zigpkgs.master;
        zls = pkgs.zlspkgs.zls.overrideAttrs (prev: {
          nativeBuildInputs = [ zig ];
        });
      in
      {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            zig
            zls
          ];
        };

        # For compatibility with older versions of the `nix` binary
        devShell = self.devShells.${system}.default;
      }
    );
}
