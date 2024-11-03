{
  description = "Templates for my Nix devShells";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      overlays = [
        (final: prev:
          let
            getSystem = "SYSTEM=$(nix eval --impure --raw --expr 'builtins.currentSystem')";
            forEachDir = exec: ''
              for dir in */; do
                (
                  cd "''${dir}"

                  ${exec}
                )
              done
            '';
          in
          {
            format = final.writeShellApplication {
              name = "format";
              runtimeInputs = with final; [ nixpkgs-fmt ];
              text = "nixpkgs-fmt '**/*.nix'";
            };

            # only run this locally, as Actions will run out of disk space
            build = final.writeShellApplication {
              name = "build";
              text = ''
                ${getSystem}

                ${forEachDir ''
                  echo "building ''${dir}"
                  nix build ".#devShells.''${SYSTEM}.default"
                ''}
              '';
            };

            check = final.writeShellApplication {
              name = "check";
              text = forEachDir ''
                echo "checking ''${dir}"
                nix flake check --all-systems --no-build
              '';
            };

            dvt = final.writeShellApplication {
              name = "dvt";
              text = ''
                if [ -z "''${1}" ]; then
                  echo "no template specified"
                  exit 1
                fi

                TEMPLATE=$1

                nix \
                  --experimental-features 'nix-command flakes' \
                  flake init \
                  --template \
                  "github:the-nix-way/dev-templates#''${TEMPLATE}"
              '';
            };

            update = final.writeShellApplication {
              name = "update";
              text = forEachDir ''
                echo "updating ''${dir}"
                nix flake update
              '';
            };
          })
      ];
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit overlays system; };
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [ build check format update nixpkgs-fmt ];
        };
      });

      packages = forEachSupportedSystem ({ pkgs }: rec {
        default = dvt;
        inherit (pkgs) dvt;
      });
    }

    //

    {
      templates = rec {
        default = empty;

        empty = {
          path = ./empty;
          description = "Empty dev template that you can customize at will";
        };

        jupyter = {
          path = ./jupyter;
          description = "Jupyter development environment";
        };

        latex = {
          path = ./latex;
          description = "LaTeX development environment";
        };

        nix = {
          path = ./nix;
          description = "Nix development environment";
        };

        python = {
          path = ./python;
          description = "Python development environment";
        };

        r = {
          path = ./r;
          description = "R development environment";
        };

        shell = {
          path = ./shell;
          description = "Shell script development environment";
        };

        # Aliases
        p = python;
      };
    };
}
