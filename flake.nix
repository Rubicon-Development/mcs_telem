{
  nixConfig = {
    extra-substituters = [ "https://blueberry.cachix.org" ];
    extra-trusted-public-keys = [
      "blueberry.cachix.org-1:bKQSogfrL/S6ceUZAkVqWl/vLc6QqUl4B8va0C7wL7k="
    ];
  };

  inputs = {
    opam-nix.url = "github:tweag/opam-nix";
    opam-repository = {
      url = "github:ocaml/opam-repository/master";
      flake = false;
    };
    opam-nix.inputs.opam-repository.follows = "opam-repository";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.follows = "opam-nix/nixpkgs";
  };
  outputs =
    {
      self,
      flake-utils,
      opam-nix,
      nixpkgs,
      ...
    }@inputs:
    # Don't forget to put the package name instead of `throw':
    let
      package = "mcs_telem";
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        on = opam-nix.lib.${system};
        project = pkgs.lib.cleanSourceWith {
          src = ./.;
          filter =
            path: type:
            let
              name = baseNameOf path;
            in
            !(type == "directory" && (name == "_build" || name == ".direnv"));
        };
        devPackagesQuery = {
          # You can add "development" packages here. They will get added to the devShell automatically.
          ocaml-lsp-server = "*";
          ocamlformat = "*";
        };
        query = devPackagesQuery // {
          ## You can force versions of certain packages here, e.g:
          ## - force the ocaml compiler to be taken from opam-repository:
          # ocaml-base-compiler = "*";
          ## - or force the compiler to be taken from nixpkgs and be a certain version:
          ocaml-system = "5.3.0";
          ## - or force ocamlfind to be a certain version:
          # ocamlfind = "1.9.2";
        };
        scope = on.buildOpamProject' { resolveArgs.dev = false; } project query;
        overlay = final: prev: {
          # You can add overrides here
          ${package} = prev.${package}.overrideAttrs (_: {
            # Prevent the ocaml dependencies from leaking into dependent environments
            doNixSupport = false;
          });
        };
        scope' = scope.overrideScope overlay;
        # The main package containing the executable
        main = scope'.${package};
        # Packages from devPackagesQuery
        devPackages = builtins.attrValues (pkgs.lib.getAttrs (builtins.attrNames devPackagesQuery) scope');
      in
      {
        legacyPackages = scope';

        packages.default = main;

        devShells.default = pkgs.mkShell {
          inputsFrom = [ main ];
          buildInputs = devPackages ++ [
            # You can add packages from nixpkgs here
          ];
        };
      }
    );
}
