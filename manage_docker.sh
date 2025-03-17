#!/bin/bash

# Script to manage the LaTeX Docker container
set -e  # Exit immediately if a command fails
trap 'echo "❌ ERROR: Command failed at line $LINENO. Exiting..."' ERR  # Catch errors and provide feedback

# Configuration
IMAGE_NAME="latex-environment"
CONTAINER_NAME="latex-container"
DEFAULT_WORK_DIR="$(pwd)"  # Default to current directory if no path provided

# Function to display usage
usage() {
    echo "Usage: $0 {build|run|stop|clean-container|clean-image|status|compile}"
    echo "  build          - Build the Docker image"
    echo "  run [path] [detached] - Run container (interactive or detached), mounting [path] to /app (default: current dir)"
    echo "  stop           - Stop the running container"
    echo "  clean-container - Remove the container"
    echo "  clean-image    - Remove the image (and dependent containers)"
    echo "  status         - Check the status of the container"
    echo "  compile [path] - Compile LaTeX project using 'make' at [path] (default: current dir)"
    exit 1
}

# Function to check if Docker is installed
check_docker() {
    if ! command -v docker &>/dev/null; then
        echo "ERROR: Docker is not installed. Please install Docker first."
        exit 1
    fi
}

# Function to build the Docker image
build_image() {
    echo "Building Docker image: $IMAGE_NAME..."
    docker build -t "$IMAGE_NAME" .
    echo "Image built successfully."
}

# Function to ensure the image exists, with user confirmation
ensure_image() {
    if [ -z "$(docker images -q $IMAGE_NAME)" ]; then
        echo "Image '$IMAGE_NAME' not found."
        read -p "Would you like to build it now? (y/N): " response
        case "$response" in
            [yY][eE][sS]|[yY])
                build_image
                ;;
            *)
                echo "Aborting. Please build the image manually with '$0 build' if needed."
                exit 1
                ;;
        esac
    fi
}

# Function to run the container interactively or detached
run_container() {
    local HOST_DIR="$1"
    local MODE="$2"

    ensure_image  # Check for image before proceeding

    [ -z "$HOST_DIR" ] && HOST_DIR="$DEFAULT_WORK_DIR"
    if [ ! -d "$HOST_DIR" ]; then
        echo "ERROR: Directory '$HOST_DIR' does not exist."
        exit 1
    fi
    HOST_DIR="$(realpath "$HOST_DIR")"
    echo "Mounting '$HOST_DIR' to /app in the container..."

    # Check if container exists (running or stopped)
    if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
        # Inspect the existing container's mount point (works for both running and stopped)
        CURRENT_MOUNT=$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/app"}}{{.Source}}{{end}}{{end}}' "$CONTAINER_NAME")
        if [ "$CURRENT_MOUNT" != "$HOST_DIR" ]; then
            echo "Existing container's mount ($CURRENT_MOUNT) does not match requested mount ($HOST_DIR). Recreating container..."
            # Stop and remove the container if running or stopped
            if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
                docker stop "$CONTAINER_NAME"
            fi
            docker rm "$CONTAINER_NAME"
        else
            # Mount matches, proceed based on state
            if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
                echo "Attaching to already running container with matching mount..."
                docker exec -it "$CONTAINER_NAME" bash
                return
            else
                echo "Starting existing container with matching mount..."
                docker start "$CONTAINER_NAME"
                docker exec -it "$CONTAINER_NAME" bash
                return
            fi
        fi
    fi

    # No container exists, or it was removed due to mismatch; create a new one
    echo "Running new container: $CONTAINER_NAME..."
    if [ "$MODE" = "detached" ]; then
        docker run -dit --name "$CONTAINER_NAME" -v "$HOST_DIR:/app" "$IMAGE_NAME"
        echo "Container started in detached mode."
    else
        docker run -it --name "$CONTAINER_NAME" -v "$HOST_DIR:/app" "$IMAGE_NAME"
    fi
}

# Function to compile LaTeX project using make
compile_project() {
    local HOST_DIR="$1"
    [ -z "$HOST_DIR" ] && HOST_DIR="$DEFAULT_WORK_DIR"

    ensure_image  # Check for image before proceeding

    if [ ! -d "$HOST_DIR" ]; then
        echo "ERROR: Directory '$HOST_DIR' does not exist on the host machine."
        exit 1
    fi

    HOST_DIR="$(realpath "$HOST_DIR")"
    echo "Compiling LaTeX project in '$HOST_DIR' using 'make'..."

    if [ ! -f "$HOST_DIR/Makefile" ] && [ ! -f "$HOST_DIR/makefile" ]; then
        echo "ERROR: No 'Makefile' or 'makefile' found in '$HOST_DIR'."
        exit 1
    fi

    docker run --rm \
        -v "$HOST_DIR:/app" \
        -w "/app" \
        "$IMAGE_NAME" \
        make
    echo "Compilation completed successfully."
}

# Function to stop the container
stop_container() {
    if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
        echo "Stopping container: $CONTAINER_NAME..."
        docker stop "$CONTAINER_NAME"
        echo "Container stopped successfully."
    else
        echo "No running container named $CONTAINER_NAME found."
    fi
}

# Function to clean up the container
clean_container() {
    if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
        echo "Removing container: $CONTAINER_NAME..."
        docker rm -f "$CONTAINER_NAME"
        echo "Container removed."
    else
        echo "No container named $CONTAINER_NAME found."
    fi
}

# Function to clean up the image
clean_image() {
    if [ "$(docker ps -aq -f ancestor=$IMAGE_NAME)" ]; then
        echo "Stopping and removing containers based on $IMAGE_NAME..."
        docker ps -aq -f ancestor=$IMAGE_NAME | xargs docker rm -f
    fi

    if [ "$(docker images -q $IMAGE_NAME)" ]; then
        echo "Removing image: $IMAGE_NAME..."
        docker rmi "$IMAGE_NAME"
        echo "Image removed."
    else
        echo "No image named $IMAGE_NAME found."
    fi
}

# Function to check container status
check_status() {
    echo "Checking container status..."
    if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
        echo "✅ Container '$CONTAINER_NAME' is running."
        docker ps -f name="$CONTAINER_NAME"
    elif [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
        echo "⚠️ Container '$CONTAINER_NAME' exists but is stopped."
        docker ps -a -f name="$CONTAINER_NAME"
    else
        echo "❌ No container named '$CONTAINER_NAME' found."
    fi

    if [ "$(docker images -q $IMAGE_NAME)" ]; then
        echo "✅ Image '$IMAGE_NAME' exists."
        docker images "$IMAGE_NAME"
    else
        echo "❌ No image named '$IMAGE_NAME' found."
    fi
}

# Main execution
check_docker

case "$1" in
    build)
        build_image
        ;;
    run)
        run_container "$2" "$3"
        ;;
    stop)
        stop_container
        ;;
    clean-container)
        clean_container
        ;;
    clean-image)
        clean_image
        ;;
    status)
        check_status
        ;;
    compile)
        compile_project "$2"
        ;;
    *)
        usage
        ;;
esac

exit 0
