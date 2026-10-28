# LaTeX Docker Environment Manager

A simple but powerful toolset for managing a LaTeX development environment in Docker, consisting of a management script (`manage_docker.sh`) and a customized `Dockerfile`.

## Overview

- **`manage_docker.sh`**: Bash script to build, run, stop, and manage your LaTeX Docker container
- **`Dockerfile`**: Creates a custom LaTeX environment based on `texlive/texlive:latest` with additional tools

## Prerequisites

- Docker installed on your system
- Bash-compatible shell
- Proper permissions (either sudo privileges or membership in the `docker` group)

## Usage

```bash
./manage_docker.sh {build|run|stop|clean-container|clean-image|status|compile}
```

### Commands

#### `build`
Builds the Docker image named `latex-environment`.

```bash
./manage_docker.sh build
```

#### `run [path] [detached]`
Runs the container, mounting `[path]` (default: current directory) to `/app` inside the container.

- Creates a new container if none exists or if the mount path differs
- Optional `detached` parameter runs the container in the background

```bash
# Interactive, mount current directory
./manage_docker.sh run

# Interactive, mount specific directory
./manage_docker.sh run /path/to/dir

# Detached mode, mount current directory
./manage_docker.sh run . detached
```

#### `stop`
Stops the running container.

```bash
./manage_docker.sh stop
```

#### `clean-container`
Removes the container (stops it first if running).

```bash
./manage_docker.sh clean-container
```

#### `clean-image`
Removes the image and any dependent containers.

```bash
./manage_docker.sh clean-image
```

#### `status`
Checks the status of both the container and image.

```bash
./manage_docker.sh status
```

#### `compile [path]`
Compiles a LaTeX project using `make`. Requires a Makefile in the directory.

```bash
# Compile project in current directory
./manage_docker.sh compile

# Compile project in specific directory
./manage_docker.sh compile /path/to/dir
```

## Example Workflow

```bash
# Build the image
./manage_docker.sh build

# Run the container interactively
./manage_docker.sh run

# Compile a LaTeX project
./manage_docker.sh compile /path/to/latex/project

# Stop the container when finished
./manage_docker.sh stop
```

## Dockerfile Details

The environment includes:

- **Base**: `texlive/texlive:latest`
- **Utilities**: `make`, `curl`, `wget`, `git`, `jq`, `perl`, `pandoc` (pinned 3.11), `python3`, `nodejs`, `chromium`, `poppler-utils`, `qpdf`
- **Fonts**: Fira Code, Hack, Roboto, JetBrains Mono, Special Gothic Condensed One, Liberation
- **Beamer theme**: RosePineMoon (`\usetheme{RosePineMoon}`), installed in the local TeX tree from `texmf/`
- **Python**: Virtual environment with `pandocfilters`, `pygments`, notebook/plotting packages (numpy, pandas, scipy, matplotlib, seaborn, openpyxl, joblib, jinja2, nbformat, ipython, pyyaml), and `custom_pygments` from `python/` (the `pseudocode` lexer and `rosepinemoon` style for minted)
- **Node.js**: `puppeteer` (v25.16.0) and `@mermaid-js/mermaid-cli` (v12.0.0)
- **manual-pipeline**: cloned to `/opt/manual-pipeline` with its Node dependencies installed; `MANUAL_PIPELINE_DIR` points to it
- **Default Working Directory**: `/app`
- **Default Command**: `bash`
- **Healthcheck**: Verifies `latexmk` functionality
- **LuaLaTeX font cache**: prebuilt at `/var/cache/texlive/texmf-var` (`TEXMFVAR`), writable by any UID

The RosePineMoon theme and `custom_pygments` are copied from SlideForge.

## Manual Image Building

If you prefer not to use the script for building:

```bash
docker build -t latex-environment .
```

### Using manual-pipeline

In a project's `manual/Makefile`, use the baked-in copy:

```makefile
PIPELINE_DIR := $(MANUAL_PIPELINE_DIR)
include $(PIPELINE_DIR)/Makefile.include
```

or override it for one build: `make pdf PIPELINE_DIR=$MANUAL_PIPELINE_DIR`.

Each rebuild fetches the latest `main`. To pin a branch, tag or commit:

```bash
docker build --build-arg MANUAL_PIPELINE_REF=<ref> -t latex-environment .
```

## VirtualBox VM

`vm/` holds a Vagrant setup that installs the same toolchain (including manual-pipeline) on a Debian 13 VM. Requires VirtualBox and Vagrant.

```bash
cd vm
vagrant up      # first boot installs everything; full TeX Live takes a while
vagrant ssh     # starts in /app, the mounted documents directory
```

Environment overrides for `vagrant up`:

- `LATEX_DIR`: host directory mounted at `/app` (default: this repo). Run `vagrant reload` after changing it.
- `VM_MEMORY` / `VM_CPUS`: RAM in MB and CPU count (default: 4096 / 2)
- `TEXLIVE_SCHEME`: e.g. `scheme-medium` for a smaller install (default: `scheme-full`)

Re-run provisioning (e.g. to update manual-pipeline) with `vagrant provision`.

## Notes

- The script uses `set -e` and traps to catch errors and provide feedback
- If the specified image doesn't exist, you'll be prompted to build it
- Mount paths are checked for consistency; mismatched mounts trigger container recreation
- Container name (`latex-container`) and image name (`latex-environment`) are fixed

## Troubleshooting

- **Docker not found**: Install Docker or ensure it's in your PATH
- **Permission denied**: Run with sudo or add your user to the docker group

## License

This project is unlicensed (public domain). Use it as you see fit!
