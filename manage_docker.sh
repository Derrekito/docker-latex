#!/bin/bash

set -e  # Exit immediately if a command fails
trap 'echo "❌ ERROR: Command failed at line $LINENO. Exiting..."' ERR  # Catch errors and provide feedback

IMAGE_NAME="latex-environment"
CONTAINER_NAME="latex-container"
DEFAULT_WORK_DIR="$(pwd)"  # Default to current directory if no path provided

# Function to build the Docker image
build_image() {
  echo "Building Docker image: $IMAGE_NAME..."
  docker build -t "$IMAGE_NAME" .
  echo "✅ Image built successfully."
}

# Function to ensure Docker image exists
ensure_image() {
  if [ -z "$(docker images -q "$IMAGE_NAME")" ]; then
    echo "❌ Image '$IMAGE_NAME' not found. Building now..."
    docker build -t "$IMAGE_NAME" . || { echo "❌ Build failed at line $LINENO"; exit 1; }
  fi
}

# Function to check and set write permissions for "others"
check_permissions() {
  local HOST_DIR="$1"
  # Check if "others" have write permission (last 3 bits of perms: rw- or rwx)
  if ! ls -ld "$HOST_DIR" | grep -q "......rw"; then
    echo "⚠️ 'Others' lack write permissions for '$HOST_DIR'. Attempting to fix..."
    chmod -R o+w "$HOST_DIR" || {
      echo "❌ Failed to set write permissions for others. Please run with sudo or fix permissions manually."
      exit 1
    }
    echo "✅ Write permissions for 'others' set successfully."
  else
    echo "✅ 'Others' already have write permissions for '$HOST_DIR'."
  fi
}

# Function to run the container interactively or detached
run_container() {
  local HOST_DIR="$1"
  local MODE="$2"

  ensure_image

  [ -z "$HOST_DIR" ] && HOST_DIR="$DEFAULT_WORK_DIR"
  if [ ! -d "$HOST_DIR" ]; then
    echo "❌ ERROR: Directory '$HOST_DIR' does not exist."
    exit 1
  fi
  HOST_DIR="$(realpath "$HOST_DIR")"
  check_permissions "$HOST_DIR"
  echo "📂 Mounting '$HOST_DIR' to /app in the container..."

  EXISTING_CONTAINER=$(docker ps -aq -f name="$CONTAINER_NAME")
  if [ "$EXISTING_CONTAINER" ]; then
    # Check if current mount matches requested directory
    CURRENT_MOUNT=$(docker inspect -f '{{range .Mounts}}{{.Source}}{{end}}' "$CONTAINER_NAME")
    if [ "$CURRENT_MOUNT" != "$HOST_DIR" ]; then
      echo "⚠️ Mount directory differs from existing container. Recreating..."
      docker stop "$CONTAINER_NAME" 2>/dev/null || true
      docker rm "$CONTAINER_NAME" || { echo "❌ Remove failed at line $LINENO"; exit 1; }
      EXISTING_CONTAINER=""
    else
      # Check if image needs updating
      CONTAINER_IMAGE_ID=$(docker inspect -f '{{.Image}}' "$CONTAINER_NAME" | cut -d: -f2 | cut -c 1-12)
      LATEST_IMAGE_ID=$(docker images -q "$IMAGE_NAME" | head -n 1)
      if [ "$CONTAINER_IMAGE_ID" != "$LATEST_IMAGE_ID" ]; then
        echo "⚠️ Container is outdated. Recreating..."
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
        docker rm "$CONTAINER_NAME" || { echo "❌ Remove failed at line $LINENO"; exit 1; }
        EXISTING_CONTAINER=""
      fi
    fi
  fi

  if [ -z "$EXISTING_CONTAINER" ]; then
    echo "🚀 Creating a new container..."
    if [ "$MODE" = "detached" ]; then
      docker run -dit --name "$CONTAINER_NAME" -v "$HOST_DIR:/app" "$IMAGE_NAME" || { echo "❌ Run failed at line $LINENO"; exit 1; }
      echo "✅ Container started in detached mode."
    else
      docker run -it --name "$CONTAINER_NAME" -v "$HOST_DIR:/app" "$IMAGE_NAME" || { echo "❌ Run failed at line $LINENO"; exit 1; }
    fi
    return 0
  fi

  if [ "$(docker ps -q -f name="$CONTAINER_NAME")" ]; then
    echo "✅ Attaching to running container..."
    docker exec -it "$CONTAINER_NAME" bash || { echo "❌ Exec failed at line $LINENO"; exit 1; }
  else
    echo "▶️ Starting existing container..."
    docker start "$CONTAINER_NAME" || { echo "❌ Start failed at line $LINENO"; exit 1; }
    if [ "$MODE" = "detached" ]; then
      echo "✅ Container started in detached mode."
    else
      docker exec -it "$CONTAINER_NAME" bash || { echo "❌ Exec failed at line $LINENO"; exit 1; }
    fi
  fi
}

# Function to stop the container
stop_container() {
  if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
    echo "🛑 Stopping container..."
    docker stop "$CONTAINER_NAME"
    echo "✅ Container stopped."
  else
    echo "⚠️ No running container found."
  fi
}

# Function to clean up the container
clean_container() {
  if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    echo "🗑 Removing container..."
    docker rm -f "$CONTAINER_NAME"
    echo "✅ Container removed."
  else
    echo "⚠️ No container found."
  fi
}

# Function to clean up the image
clean_image() {
  if [ "$(docker images -q $IMAGE_NAME)" ]; then
    echo "🗑 Removing image..."
    docker rmi "$IMAGE_NAME"
    echo "✅ Image removed."
  else
    echo "⚠️ No image found."
  fi
}

# Function to check container and image status
check_status() {
  echo "🔍 Checking container status..."
  if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
    echo "✅ Container '$CONTAINER_NAME' is running."
    docker inspect -f '   Mount: {{range .Mounts}}{{.Source}} -> {{.Destination}}{{end}}' "$CONTAINER_NAME"
  elif [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    echo "⚠️ Container '$CONTAINER_NAME' exists but is stopped."
    docker inspect -f '   Mount: {{range .Mounts}}{{.Source}} -> {{.Destination}}{{end}}' "$CONTAINER_NAME"
  else
    echo "❌ No container found."
  fi

  if [ "$(docker images -q $IMAGE_NAME)" ]; then
    echo "✅ Image '$IMAGE_NAME' exists."
  else
    echo "❌ No image found."
  fi
}

# Function to compile LaTeX project using make
compile_project() {
  local HOST_DIR="$1"
  [ -z "$HOST_DIR" ] && HOST_DIR="$DEFAULT_WORK_DIR"

  ensure_image

  if [ ! -d "$HOST_DIR" ]; then
    echo "❌ ERROR: Directory '$HOST_DIR' does not exist."
    exit 1
  fi

  HOST_DIR="$(realpath "$HOST_DIR")"
  check_permissions "$HOST_DIR"
  echo "🛠 Compiling LaTeX project in '$HOST_DIR'..."

  if [ ! -f "$HOST_DIR/Makefile" ] && [ ! -f "$HOST_DIR/makefile" ]; then
    echo "❌ ERROR: No 'Makefile' found in '$HOST_DIR'."
    exit 1
  fi

  docker run --rm -v "$HOST_DIR:/app" -w "/app" "$IMAGE_NAME" make || { echo "❌ Make failed at line $LINENO"; exit 1; }
  echo "✅ Compilation complete."
}

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

# Main execution
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
