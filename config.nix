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
        type = types.str;
        default = "/etc/${name}.creds";
        #default = null;
        defaultText = default;
        description = "path the encrypted secret will be written to";
      };
      source = {
        vault = mkOption {
          type = types.str;
          default = "";
          defaultText = "";
          description = "vault the secret is stored in";
        };

        item = mkOption rec {
          type = types.str;
          #default = "${name}";
          default = "";
          defaultText = default;
          description = "item inside the vault the secret is stored in";
        };

        fields = mkOption {
          type = types.listOf types.str;
          default = [];
          defaultText = "[]";
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
     lines = attrValues (mapAttrs' (name: cfg: let
       path = "${cfg.path}" or "/etc/${name}.creds";
       item = cfg.item or name;
       secrets = "${package}/bin/secrets";
     in {
       inherit name;
       value = "${secrets} get ${cfg.valut} ${cfg.item} ${builtins.toString cfg.fields} --delimiter '${cfg.delimiter}' " +
               "| ${systemd-creds} encrypt - ${path}";
      }) config.secrets);
   in {
    environment.systemPackages = [
      (pkgs.writeScriptBin "import-secrets" ''
        ${foldl (a: b: a + b + "\n")  "# Add secrets to locl machine"}
      '')
    ];
  };
}
