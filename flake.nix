{
    description = "An example flake packaging a Python application with uv2nix";

    inputs = {
        nixpkgs-stable.url                                   = "github:NixOS/nixpkgs";
        nixpkgs-unstable.url                                 = "github:NixOS/nixpkgs/nixos-unstable";
        flake-utils.url                                      = "github:numtide/flake-utils";

        # Core pyproject-nix ecosystem tools
        pyproject-nix.url                                    = "github:pyproject-nix/pyproject.nix";
        uv2nix.url                                           = "github:pyproject-nix/uv2nix";
        pyproject-build-systems.url                          = "github:pyproject-nix/build-system-pkgs";

        # Ensure consistent dependencies between these tools
        pyproject-nix.inputs.nixpkgs.follows                 = "nixpkgs-unstable";
        uv2nix.inputs.nixpkgs.follows                        = "nixpkgs-unstable";
        pyproject-build-systems.inputs.nixpkgs.follows       = "nixpkgs-unstable";
        uv2nix.inputs.pyproject-nix.follows                  = "pyproject-nix";
        pyproject-build-systems.inputs.pyproject-nix.follows = "pyproject-nix";
    };

    outputs = { self, nixpkgs-stable, nixpkgs-unstable, flake-utils, uv2nix, pyproject-nix, pyproject-build-systems, ... }:
        flake-utils.lib.eachDefaultSystem (system:
            let
                pkgs = import nixpkgs-unstable { 
                    inherit system; 
                    config = {
                        allowUnfree = true;
                    };
                };
                python = pkgs.python312;

                # Load workspace from pyproject.toml + uv.lock
                workspace = uv2nix.lib.workspace.loadWorkspace {
                    workspaceRoot = self;
                };

                # Generate overlay from uv.lock
                uvLockedOverlay = workspace.mkPyprojectOverlay {
                    sourcePreference = "wheel";
                };

                # Make sure that the tbb package is available as a project dependency 
                # via an overlay
                tbbOverlay = final: prev: {
                    numba = prev.numba.overrideAttrs (old: {
                        buildInputs = (old.buildInputs or []) ++ [ pkgs.tbb ];
                        propagatedBuildInputs = (old.propagatedBuildInputs or []) ++ [ pkgs.tbb ];
                    });
                };

                # Use a pre-packaged torch as a dependency
                torchOverlay = final: prev: {
                    torch = pkgs.libtorch-bin;
                };

                # Resolve file name collisions between dependencies by removing duplicate files
                collisionPatchOverlay = final: prev: {
                    choreographer = prev.choreographer.overrideAttrs (old: {
                        postInstall = (old.postInstall or "") + ''
                            rm -f $out/lib/python3.12/site-packages/tests/test_placeholder.py
                            rm -f $out/lib/python3.12/site-packages/tests/conftest.py
                        '';
                    });
                };

                # Compose overlays into pythonSet
                pythonSet = (
                    pkgs.callPackage pyproject-nix.build.packages { inherit python; }
                ).overrideScope (nixpkgs-unstable.lib.composeManyExtensions [
                    pyproject-build-systems.overlays.default
                    uvLockedOverlay
                    tbbOverlay
                    torchOverlay
                    collisionPatchOverlay
                ]);

                # Access project metadata AFTER overlays are applied
                projectNameInToml = "cube";
                thisProjectAsNixPkg = pythonSet.${projectNameInToml};

                # Create virtualenv from resolved deps
                appPythonEnv = pythonSet.mkVirtualEnv
                    (thisProjectAsNixPkg.pname + "-env")
                    workspace.deps.default;
            in
            {
                # Development enviroment
                devShells.default = pkgs.mkShell {
                    packages = [ 
                        appPythonEnv
                        pkgs.uv
                    ];
                };

                # Packaging the project via Nix and uv2nix
                packages.default = pkgs.stdenv.mkDerivation {
                    pname = thisProjectAsNixPkg.pname;
                    version = thisProjectAsNixPkg.version;
                    src = ./.;
                    nativeBuildInputs = [ 
                        pkgs.makeWrapper
                    ];
                    buildInputs = [ 
                        appPythonEnv
                    ];
                    installPhase = ''
                        mkdir -p $out/bin
                        makeWrapper ${appPythonEnv}/bin/cube $out/bin/${thisProjectAsNixPkg.pname}
                    '';
                };

                packages.${thisProjectAsNixPkg.pname} = self.packages.${system}.default;

                apps.default = {
                    type = "app";
                    program = "${self.packages.${system}.default}/bin/${thisProjectAsNixPkg.pname}";
                };

                apps.${thisProjectAsNixPkg.pname} = self.apps.${system}.default;
            }
        );
}    
