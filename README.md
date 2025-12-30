# cube

cube is simple python project used to showcase how to package python application in nix using `uv2nix`. It has the following dependencies:
1. `bertopic`
2. `kaleido`
3. `numpy`
4. `pandas`
5. `sentence-transformers`


## uv

**uv** is an extremely fast Python package and project manager, written in Rust. It is able to replace:
- `pip`
- `pip-tools`
- `pipx`
- `poetry`
- `pyenv`
- `twine`
- `virtualenv`

### Highlights

- 10-100x faster than pip.
- Provides comprehensive project management, with a universal lockfile.
- Runs scripts, with support for inline dependency metadata.
- Installs and manages Python versions.
- Runs and installs tools published as Python packages.
- Includes a pip-compatible interface for a performance boost with a familiar CLI.
- Supports Cargo-style workspaces for scalable projects.
- Disk-space efficient, with a global cache for dependency deduplication.
- Installable without Rust or Python via curl or pip.
- Supports macOS, Linux, and Windows.

### Creating projects with UV

To create a project with `uv` the command: `uv init foo`, where `foo` is the name of the project. It will create the following directory structure:

```bash
[nix-shell:~/code/python/test]$ tree
.
├── README.md
├── hello.py
└── pyproject.toml
```

The project will include a `pyproject.toml`, a sample file `main.py` and a readme and python version pin. A further `uv.lock` file will be generated upon running the script for the first time, which will pin the dependencies of the projects to specific versions. This structure is sufficient for most scripts which simply needs to pass around a locked set of dependencies to ensure reproducibility. The `pyproject.toml` includes the metadata of the project, including the projects listed dependencies. However, it is not a build system and it alone will not install any packages to the environment.

```pyproject.toml
[project]
name = "test"
version = "0.1.0"
description = "Add your description here"
readme = "README.md"
requires-python = ">=3.11"
dependencies = []
```

If the project is intended to be packaged as an application then the command `uv init --package foo` can be used. This generates the following directory structure. 

```bash
[nix-shell:~/code/python/test]$ tree
.
├── README.md
├── pyproject.toml
└── src
    └── test
        └── __init__.py
```

Here the source code for the package is moved into the `src` directory, with a module system and `__init__.py`. In the projects `pyproject.toml`, a build system is also defined allowing for the package to be installed into the environment.

```pyproject.toml
[project]
name = "test"
version = "0.1.0"
description = "Add your description here"
readme = "README.md"
authors = [
    { name = "ShilohAlleyne", email = "ShilohAlleyne@gmail.com" }
]
requires-python = ">=3.13"
dependencies = []

[project.scripts]
test = "test:main"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

```

A command section is also included, which can be executed using `uv run`

### Inline dependencies with UV

With `uv` it is also possible to inline dependencies as a comment header for a simple script, by wrapping the `uv` declaration in `/// script`. For example:

```python
# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "pandas",
#   "plotly",
#   "Kaleido",
# ]
# ///
```

Imports `pandas`, `plotly` and `Kaleido` which can then be accessed in the script when it is ran using `uv run`. Running a script with inline dependencies still generates a `uv.lock` file which maintains reproducibility.

UV documentation can be found here: [uv](https://docs.astral.sh/uv/#projects)

## nix

Nix is a purely functional package manager. This means that it treats packages like values in purely functional programming languages such as Haskell — they are built by functions that don’t have side-effects, and they never change after they have been built. Nix stores packages in the Nix store, usually the directory /nix/store, where each package has its own unique subdirectory such as:

```
/nix/store/b6gvzjyb2pg0kjfwrjmg1vfhh54ad73z-firefox-33.1/
```

Where `b6gvzjyb2pg0…` is a unique identifier for the package that captures all its dependencies (it’s a cryptographic hash of the package’s build dependency graph). This enables many powerful features.

### Highlights

- **Reproducible**: Nix builds packages in isolation from each other. This ensures that they are reproducible and don’t have undeclared dependencies, so if a package works on one machine, it will also work on another.
- **Declarative**: Nix makes it trivial to share development and build environments for your projects, regardless of what programming languages and tools you’re using.
- **Reliable**: Nix ensures that installing or upgrading one package cannot break other packages. It allows you to roll back to previous versions, and ensures that no package is in an inconsistent state during an upgrade.
- **Flakes**: Nix flakes provide a standard way to write Nix expressions (and therefore packages) whose dependencies are version-pinned in a lock file, improving reproducibility of Nix installations.
- Nixpkgs is the largest, most up-to-date free software repository in the world.

### Distribution

The command `nix run` allows for the execution of applications or binaries provided by Nix packages or flakes. Making it a streamlined way to run software without installing it system-wide. To run this project binary in nix you can simply use the command:

```bash
nix run github:ShilohAlleyne/nix#cube
```

And the package will run on any nix system. Note that the `nix#cube` part of the command is a nix flake itself. This flake can expose the flakes for multiple projects at once and then can be selected by specifying the project you want to run after the `#`. For example, the command:

```bash
nix run github:ShilohAlleyne/nix#decoy
```

Will run my note taking CLI. Having a unified command makes (temporary) package installation much simpler for the less technically inclined or nix unfamiliar. The meta flake exposing all of my projects can be found here: 
- [ShilohAlleyne/nix](https://github.com/ShilohAlleyne/nix/tree/main)

Nix documentation can be found here:
- [nix](https://nix.dev/manual/nix/2.28/)
- [nixpkgs](https://nixos.org/manual/nixpkgs/stable/)

## uv2nix

`uv2nix` takes a `uv` workspace and generates Nix derivations dynamically using pure Nix code. It's designed to be used both as a development environment manager, and to build production packages for projects. A packaged project using `uv2nix` will produce a flake with similar inputs and outputs as:

```bash
git+file:///home/shiloh/code/python/cube
├───apps
│   ├───aarch64-darwin
│   │   ├───cube: app: no description
│   │   └───default: app: no description
│   ├───aarch64-linux
│   │   ├───cube: app: no description
│   │   └───default: app: no description
│   ├───x86_64-darwin
│   │   ├───cube: app: no description
│   │   └───default: app: no description
│   └───x86_64-linux
│       ├───cube: app: no description
│       └───default: app: no description
├───devShells
│   ├───aarch64-darwin
│   │   └───default omitted (use '--all-systems' to show)
│   ├───aarch64-linux
│   │   └───default omitted (use '--all-systems' to show)
│   ├───x86_64-darwin
│   │   └───default omitted (use '--all-systems' to show)
│   └───x86_64-linux
│       └───default: development environment 'nix-shell'
└───packages
    ├───aarch64-darwin
    │   ├───cube omitted (use '--all-systems' to show)
    │   └───default omitted (use '--all-systems' to show)
    ├───aarch64-linux
    │   ├───cube omitted (use '--all-systems' to show)
    │   └───default omitted (use '--all-systems' to show)
    ├───x86_64-darwin
    │   ├───cube omitted (use '--all-systems' to show)
    │   └───default omitted (use '--all-systems' to show)
    └───x86_64-linux
        ├───cube: package 'cube-0.1.0'
        └───default: package 'cube-0.1.0'
```

Here we can see that the platforms which the application is packaged for, not that for windows systems the package can simply be ran in `wsl`.

### How this flake works

This flake provides both a shell for a declarative development environment, as well as packaging the application itself.

1. First we declare the inputs for this flake
```nix
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
```
- Note: that by using `xxxx.follows` we are able to pipe in already defined inputs into other inputs, ensuring consistent dependencies between tools

2. Next we declare the flake outputs using the function:
```nix
outputs = { self, nixpkgs-stable, nixpkgs-unstable, flake-utils, uv2nix, pyproject-nix, pyproject-build-systems, ... }:
        flake-utils.lib.eachDefaultSystem (system:
```

Where: 
- `{ self, nixpkgs-stable, nixpkgs-unstable ...}` are the (already defined) inputs for this function.
- `flake-utils.lib.eachDefaultSystem (system:` will generate flakes for each of the default systems as shown prior.

3. In the `let ... in` block we define variables used for making both the devshell and the application package.
```nix
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
```

Here we define overlays, which extend the nix package set allowing for all of the project dependencies to resolve.
- They can be thought of as declarative patches
- We define each overlay before collecting them into a set, `pythonSet`, and applying them together (in order) 

## Alternatives to packaging with Nix

While packaging an installation with Nix allows for easy distribution on systems with Nix there are also alternatives.

### UV + nix-shells

One option to manage dependencies for a project is to allow `uv` to manage the python dependencies and allow nix to manage any external packages that are needed on the path for projects via a `nix-shell`. This is the simplest why to have declarative environments. UV ensures that a Given projects python dependencies are locked and Nix allows for the external dependencies such as chromium to also be declaratively version-pinned and available on system path. This allows a projects `flake.nix` to be very simple.

```nix
{
    description = "A simple dev env flake";

    inputs = {
        nixpkgs-stable.url   = "github:NixOS/nixpkgs";
        nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable"; 
    };

    Outputs = { self, core }:
    let
        system        = "x86_64-linux";
        pkgs-stable   = core.packages.${system}.pkgs-stable;
        pkgs-unstable = core.packages.${system}.pkgs-unstable;
    in
    {
        devShells.${system}.default = pkgs-stable.mkShell {
            packages = [
                pkgs-stable.chromium
                # Other nessary package exposed to path
            ];
        };
    };
}
```

A project's `flake.nix` can still expose a dev shell as part of its outputs, allow for the environments of different projects to be collected and re-exposed in a aggregate flake. For simple scripts, inline `uv` dependencies coupled with a flake exposing non python dependencies is a very lightweight solution to dependency management. 

### Docker

Docker, is a containerisation platform. Containerization allows for applications and their dependencies to be isolated. Each container contains everything need for the application to run, including the application’s code/binary, its required libraries and configuration file. Docker containers all share the kernel on the host machine, but isolate the filesystem, networking and application processes. Docker much like Nix, is the only requirement to run a Docker image of an application. 
