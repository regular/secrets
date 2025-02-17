{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    secrets-service = {
      url = "github:regular/secrets-service";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs@{ self, nixpkgs, secrets-service }:
    let
      system =  "x86_64-linux";
      pkgs = import nixpkgs { 
        inherit system; 
        config.allowUnfree = true;
      };
    in
  {
    nixosModules.default  = self.nixosModules.secrets;
    nixosModules.secrets = (import ./config.nix) {
      package = self.packages.${system}.default;
    };

    nixosConfigurations.demo = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        self.nixosModules.secrets 
        {
          secrets.my-secret = {
            path = "/etc/bla";
            source = {
              vault = "my-vault";
              fields = ["user" "pass"];
            };
          };
        }
      ];
    };
    
    packages.${system} = rec {
      default = pkgs.buildNpmPackage rec {
        name = "secrets";
        src = ./.;
        npmDepsHash = "sha256-2YPdDdxRG5AgpS0MruQ8aFkoUN5OKESHI9QYGXzNVK8=";
        dontNpmBuild = true;
        makeCacheWritable = true;
        nativeBuildInputs = with pkgs; [
          makeWrapper
        ];
        postInstall = ''
          wrapProgram $out/bin/${name} \
          --set ${name}_bin__shell ${pkgs.stdenv.shell} \
          --set ${name}_bin__cat ${pkgs.coreutils}/bin/cat \
          --set ${name}_bin__op ${pkgs._1password-cli}/bin/op
        '';
      };
    };

    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        nodejs
        python3
      ];
    };
  };
}
