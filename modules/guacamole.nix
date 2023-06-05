{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.services.guacamole;
in
{
  options = {
    services.guacamole = {
      enable = lib.mkEnableOption (lib.mdDoc "Apache Guacamole");
      package = lib.mkPackageOptionMD pkgs "guacamole-server" { };

      extraEnvironment = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "ENVIRONMENT=production" ];
        description = lib.mdDoc "Environment Variables to pass to guacd";
      };

      baseDir = lib.mkOption {
        type = lib.types.path;
        default = "/etc/guacamole";
        description = lib.mdDoc ''
          Location of $GUACAMOLE_HOME
        '';
      };

      host = lib.mkOption {
        default = "127.0.0.1";
        description = lib.mdDoc ''
          The host name or IP address the server should listen to.
        '';
        type = lib.types.str;
      };

      port = lib.mkOption {
        default = 4822;
        description = lib.mdDoc ''
          The port the server should listen to.
        '';
        type = lib.types.port;
      };

      purifyOnStart = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = lib.mdDoc ''
          On startup, the `baseDir` directory is populated with various files,
          subdirectories and symlinks. If this option is enabled, these items
          are first removed. This prevents interference from remainders of an
          old configuration, so it's recommended to enable this option.
        '';
      };

      guacamoleProperties = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = lib.mdDoc ''
          Configuration written to $GUACAMOLE_HOME/guacamole.properties
        '';
      };

      logbackXml = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = lib.mdDoc ''
          Configuration written to $GUACAMOLE_HOME/logback.xml
        '';
      };

      userMapping = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = lib.mdDoc ''
          Configuration written to $GUACAMOLE_HOME/user-mapping.xml
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.guacd = {
      description = "Apache Guacamole server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Environment = [
          "GUACAMOLE_HOME=${cfg.baseDir}"
        ] ++ cfg.extraEnvironment;
        ExecStart = "${lib.getExe cfg.package} -f -b ${cfg.host} -l ${toString cfg.port}";
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
      purifyOnStart = true;
      webapps = [
        pkgs.guacamole-client
      ];
      extraEnvironment = [ "GUACAMOLE_HOME=${cfg.baseDir}" ];
    };
  };
}
