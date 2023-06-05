{
  description = "guacamole-server";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      imports = [
        ./overlay.nix
      ];

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        # TODO: Find a better way to do this.
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [ inputs.self.overlays.default ];
        };

        packages = {
          inherit (pkgs) guacamole-server guacamole-client;
        };
      };

      flake.nixosModules = {
        guacamole = import ./modules/guacamole.nix;
      };
    };
}
