{ self, lib, ... }: {
  flake = {
    overlays.default = final: prev: {
      guacamole-server = prev.stdenv.mkDerivation (finalAttrs: {
        pname = "guacamole";
        version = "1.5.2";

        src = prev.fetchFromGitHub {
          owner = "apache";
          repo = "guacamole-server";
          rev = finalAttrs.version;
          hash = "sha256-L1hFZ24kwTSHwqCUslnt5cBKkNh1cpVxu1ntTN1gFr0=";
        };

        NIX_CFLAGS_COMPILE = [
          "-Wno-error=format-truncation"
          "-Wno-error=format-overflow"
        ];

        nativeBuildInputs = with prev.pkgs; [
          autoPatchelfHook
          autoreconfHook
          cairo
          ffmpeg_4-headless
          freerdp
          libjpeg_turbo
          libpng
          libossp_uuid
          libpulseaudio
          libssh2
          libtelnet
          libvncserver
          libvorbis
          libwebp
          libwebsockets
          makeBinaryWrapper
          openssl
          pango
          perl
          pkg-config
        ];

        configureFlags = [
          ''--with-freerdp-plugin-dir=${placeholder "out"}/lib''
        ];

        patchPhase = ''
          patchShebangs ./src/protocols/rdp/**/*.pl
        '';

        postInstall = ''
          ln -s ${prev.pkgs.freerdp}/lib/* $out/lib/
          wrapProgram $out/sbin/guacd --prefix LD_LIBRARY_PATH ":" $out/lib
        '';

        meta = {
          description = "Clientless remote desktop gateway";
          homepage = "https://guacamole.incubator.apache.org/";
          license = lib.licenses.asl20;
          maintainers = [ ];
          platforms = [ "x86_64-linux" "i686-linux" ];
          mainProgram = "guacd";
        };
      });

      guacamole-client = prev.stdenv.mkDerivation (finalAttrs: {
        pname = "guacamole-client";
        version = "1.5.2";

        src = prev.fetchurl {
          url = "https://archive.apache.org/dist/guacamole/1.5.2/binary/guacamole-1.5.2.war";
          hash = "sha256-hu/DABbkA4lI2MGlw3oLBeONrdMQTbbsA3VbxuMRHEA=";
        };

        dontUnpack = true;
        dontBuild = true;

        installPhase = ''
          mkdir -p $out/webapps
          cp $src $out/webapps/guacamole.war
        '';

        meta = {
          description = "Clientless remote desktop gateway";
          homepage = "https://guacamole.incubator.apache.org/";
          license = lib.licenses.asl20;
          maintainers = [ ];
          platforms = [ "x86_64-linux" "i686-linux" ];
        };
      });
    };
  };
}
