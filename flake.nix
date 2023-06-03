{
  description = "guacamole-server";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, flake-utils, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (self: super: rec { })
          ];
        };
      in
      {
        packages.guacamole-server = with pkgs;
          stdenv.mkDerivation
            rec {
              pname = "guacamole";
              version = "1.5.0";

              src = fetchFromGitHub {
                owner = "apache";
                repo = "guacamole-server";
                rev = version;
                sha256 = "sha256-aG2Fcll0TgLokI2iAu5Gy7LKGr3FSX2tEFAEFiJCVkw=";
              };

              NIX_CFLAGS_COMPILE = [
                "-Wno-error=format-truncation"
                "-Wno-error=format-overflow"
              ];

              buildInputs = [
                freerdp
                autoreconfHook
                pkg-config
                cairo
                libpng
                libjpeg_turbo
                libossp_uuid
                pango
                libssh2
                libvncserver
                libpulseaudio
                openssl
                libvorbis
                libwebp
                libtelnet
                perl
                makeWrapper
              ];

              propogatedBuildInputs = [
                freerdp
                autoreconfHook
                pkg-config
                cairo
                libpng
                libjpeg_turbo
                libossp_uuid
                freerdp
                pango
                libssh2
                libvncserver
                libpulseaudio
                openssl
                libvorbis
                libwebp
                inetutils
              ];

              patchPhase = ''
                patchShebangs ./src/protocols/rdp/**/*.pl
                substituteInPlace ./configure.ac --replace "FREERDP2_PLUGIN_DIR=" "FREERDP2_PLUGIN_DIR=${placeholder "out"}/lib"

              '';

              postInstall = ''
                wrapProgram $out/sbin/guacd --prefix LD_LIBRARY_PATH ":" $out/lib
              '';

              meta = with lib; {
                description = "Clientless remote desktop gateway";
                homepage = "https://guacamole.incubator.apache.org/";
                license = licenses.asl20;
                maintainers = with maintainers; [ tomberek ];
                platforms = [ "x86_64-linux" "i686-linux" ];
              };
            };

        devShell =
          pkgs.mkShell {
            buildInputs = [ ];
          };
      }
    );

}
