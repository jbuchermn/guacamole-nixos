{
  description = "guacamole-server";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, flake-utils, nixpkgs }:
    flake-utils.lib.eachDefaultSystem
      (
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
                  maintainers = with maintainers; [ ];
                  platforms = [ "x86_64-linux" "i686-linux" ];
                };
              };

          packages.guacamole-client = with pkgs;
            stdenv.mkDerivation
              rec {
                pname = "guacamole-client";
                version = "1.5.0";

                src = fetchurl {
                  url = "https://archive.apache.org/dist/guacamole/1.5.0/binary/guacamole-1.5.0.war";
                  sha256 = "sha256-nE6AeqcLwTjztsxmzES3XaqUSgFZRLmrb3gNeGhJhiA=";
                };

                dontUnpack = true;

                buildInputs = [
                ];

                propogatedBuildInputs = [
                ];

                buildPhase = ''
                '';

                installPhase = ''
                  mkdir $out
                  cp $src $out/${pname}-${version}.war
                '';

                meta = with lib;
                  {
                    description = "Clientless remote desktop gateway";
                    homepage = "https://guacamole.incubator.apache.org/";
                    license = licenses.asl20;
                    maintainers = with maintainers; [ ];
                    platforms = [ "x86_64-linux" "i686-linux" ];
                  };
              };

          nixosModules = {
            guacamole = { config, lib, pkgs, ... }:
              with lib;
              let
                cfg = config.services.guacamole;
              in
              {
                meta = {
                  maintainers = with maintainers; [ ];
                };

                options = {
                  services.guacamole = {
                    enable = mkEnableOption (lib.mdDoc "Apache Guacamole");

                    extraEnvironment = mkOption {
                      type = types.listOf types.str;
                      default = [ ];
                      example = [ "ENVIRONMENT=production" ];
                      description = lib.mdDoc "Environment Variables to pass to guacd";
                    };

                    baseDir = mkOption {
                      type = lib.types.path;
                      default = "/etc/guacamole";
                      description = lib.mdDoc ''
                        Location of GUACAMOLE_HOME
                      '';
                    };

                    guacdBindHost = mkOption {
                      type = types.str;
                      default = "127.0.0.1";
                      description = lib.mdDoc ''
                        bind_host parameter
                      '';
                    };

                    purifyOnStart = mkOption {
                      type = types.bool;
                      default = true;
                      description = lib.mdDoc ''
                        On startup, the `baseDir` directory is populated with various files,
                        subdirectories and symlinks. If this option is enabled, these items
                        are first removed. This prevents interference from remainders of an
                        old configuration, so it's recommended to enable this option.
                      '';
                    };

                    guacamoleProperties = mkOption {
                      type = types.lines;
                      default = "";
                      description = lib.mdDoc ''
                        Configuration written to GUACAMOLE_HOME/guacamole.properties
                      '';
                    };

                    logbackXml = mkOption {
                      type = types.lines;
                      default = "";
                      description = lib.mdDoc ''
                        Configuration written to GUACAMOLE_HOME/logback.xml
                      '';
                    };

                    userMapping = mkOption {
                      type = types.lines;
                      default = "";
                      description = lib.mdDoc ''
                        Configuration written to GUACAMOLE_HOME/user-mapping.xml
                      '';
                    };
                  };

                };

                config = mkIf cfg.enable {
                  systemd.services.guacd = {
                    description = "Apache Guacamole server";
                    wantedBy = [ "multi-user.target" ];
                    after = [ "network.target" ];

                    serviceConfig = {
                      Environment = [
                        "GUACAMOLE_HOME=${cfg.baseDir}"
                      ] ++ cfg.extraEnvironment;
                      ExecStart = "${pkgs.guacamole-server}/bin/guacd -f -b ${cfg.guacdBindHost}";
                    };

                    preStart = ''
                      # Create and clean the base directory
                      ${lib.optionalString cfg.purifyOnStart ''
                      rm -rf ${cfg.baseDir}/{guacamole.properties,logback.xml,extensions,lib,user-mapping.xml}
                      ''}
                      mkdir -p ${cfg.baseDir}

                      # Setup guacamole.properties
                      ${lib.optionalString (cfg.guacamoleProperties != "") ''
                        cat << EOF > ${cfg.baseDir}/guacamole.properties
                        ${cfg.guacamoleProperties}
                        EOF
                      ''}

                      # Setup logback.xml
                      ${lib.optionalString (cfg.logbackXml != "") ''
                        cat << EOF > ${cfg.baseDir}/logback.xml
                        ${cfg.logbackXml}
                        EOF
                      ''}

                      # Setup user-mapping.xml
                      ${lib.optionalString (cfg.userMapping != "") ''
                        cat << EOF > ${cfg.baseDir}/user-mapping.xml
                        ${cfg.userMapping}
                        EOF
                      ''}
                    '';
                  };


                  services.tomcat = {
                    enable = true;

                    webapps = [ (pkgs.guacamole-client + "/guacamole-client-1.5.0.war") ];
                    extraEnvironment = [ "GUACAMOLE_HOME=${cfg.baseDir}" ];
                  };
                };
              };
          };

        }
      );

}
