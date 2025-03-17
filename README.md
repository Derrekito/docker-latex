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
- **Utilities**: `make`, `curl`, `wget`, `git`, `jq`, `perl`, `pandoc`, `python3`, `nodejs`, `chromium`
- **Fonts**: FiraCode variants (Retina, Light, Bold, Regular, SemiBold, Medium)
- **Python**: Virtual environment with `pandocfilters` and `pygments`
- **Node.js**: `puppeteer` (v24.4.0) and `@mermaid-js/mermaid-cli` (v11.4.2)
- **Default Working Directory**: `/app`
- **Default Command**: `bash`
- **Healthcheck**: Verifies `latexmk` functionality

## Manual Image Building

If you prefer not to use the script for building:

```bash
docker build -t latex-environment .
```

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
