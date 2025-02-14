# config.secrets.hetzner-robot = {
#   path = "/etc/hetzner-robot" # defaults to /etc/${name}
#   source = {
#     vault = "Business";
#     item = "hetzner-robot-api"; #defaults to ${name}
#     fields = [ "username" "credentials" ];
#   };
# }

{ package }: { config, lib, pkgs, ... }: 
with lib;
let 
  secretsInstance = name: let 
    crg = config.secrets.${name};
  in {
    options = {
      path = mkOption rec {
        type = types.nullOr types.str;
        # if this is uncommented name evals to the entire config! (wtf)
        default = null;
        description = "path the encrypted secret will be written to. Defaults to /etc/$name.creds";
      };
      source = {
        vault = mkOption {
          type = types.str;
          description = "vault the secret is stored in";
        };

        item = mkOption rec {
          type = types.nullOr types.str;
          default = null;
          description = "item inside the vault the secret is stored in. Defaults to $name";
        };

        fields = mkOption {
          type = lib.types.nonEmptyListOf lib.types.str;
          description = "list of fields in the item";
        };

        delimiter = mkOption {
          type = types.str;
          default = ",";
          defaultText = ",";
          description = "delimiter used when joining item values";
        };
      };
    };
  };
in {
  options.secrets = mkOption {
    type = types.attrsOf (types.submodule secretsInstance);
    default = {};
    description = "Named instances of secrets";
  };

  # Consume the submodule configurations
  config = let
    text = builtins.concatStringsSep "\n" ([ "# Add secrets to locl machine" ] ++ lines);
    lines = attrValues (mapAttrs' (name: cfg: let
      path = "${if cfg.path == null then "/etc/${name}.creds" else cfg.path}";
      item = if cfg.source.item == null then name else cfg.source.item;
      secrets = "${package}/bin/secrets";
      systemd-creds = "${pkgs.systemd}/bin/systemd-creds";
    in 
    with builtins; {
      inherit name;
      value = "${secrets} get '${cfg.source.vault}' '${item}' ${toString (map (x: "'${x}'") cfg.source.fields)} --delimiter '${cfg.source.delimiter}' " +
      "| ${systemd-creds} encrypt - '${path}'";
    }) config.secrets);
  in {
    warnings = [
      (builtins.trace "Secrets script:\n ${text}\n" "rendered secrets scripts")
    ];
    environment.systemPackages = [
      (pkgs.writeScriptBin "import-secrets" ''
      ${text}
      '')
    ];
  };
}
