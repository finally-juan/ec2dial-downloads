#!/bin/sh
# ec2dial installer script
set -e

# Configuration
GITHUB_REPO="tycoonlabs/ec2dial-downloads"
LATEST_VERSION="d4915f2-dirty"  # This could be dynamically determined in the future
INSTALL_DIR="/usr/local/bin"
TEMP_DIR=$(mktemp -d)
GITHUB_URL="https://tycoonlabs.github.io/ec2dial-downloads"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Clean up temp directory on exit
cleanup() {
  rm -rf "$TEMP_DIR" 2>/dev/null
}
trap cleanup EXIT

# Detect OS and architecture
detect_platform() {
  OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  ARCH=$(uname -m)
  
  # Map architectures to our naming convention
  case "$ARCH" in
    x86_64)
      ARCH="amd64"
      ;;
    aarch64|arm64)
      ARCH="arm64"
      ;;
    *)
      echo "${RED}Unsupported architecture: $ARCH${NC}"
      echo "ec2dial is available for amd64 and arm64 architectures."
      exit 1
      ;;
  esac
  
  # Map OS to our naming convention
  case "$OS" in
    darwin)
      # macOS
      ;;
    linux)
      # Linux
      ;;
    msys*|cygwin*|mingw*|nt|win*)
      # Windows variants
      OS="windows"
      ;;
    *)
      echo "${RED}Unsupported operating system: $OS${NC}"
      echo "ec2dial is available for macOS, Linux, and Windows."
      exit 1
      ;;
  esac
  
  if [ "$OS" = "windows" ]; then
    BIN_SUFFIX=".exe"
  else
    BIN_SUFFIX=""
  fi
  
  PLATFORM="${OS}-${ARCH}"
  BINARY_NAME="ec2dial.${PLATFORM}${BIN_SUFFIX}"
  CHECKSUM_FILE="${BINARY_NAME}.sha256"
}

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check for required tools
check_dependencies() {
  if ! command_exists curl; then
    echo "${RED}Error: curl is required but not installed.${NC}"
    exit 1
  fi
  
  # For checksum verification
  if ! command_exists sha256sum && ! command_exists shasum; then
    echo "${YELLOW}Warning: Neither sha256sum nor shasum found. Checksum verification will be skipped.${NC}"
    SKIP_CHECKSUM=true
  else
    SKIP_CHECKSUM=false
  fi
}

# Download a file
download_file() {
  URL="$1"
  OUTPUT="$2"
  echo "Downloading ec2dial..."
  
  if ! curl -fsSL "$URL" -o "$OUTPUT"; then
    echo "${RED}Failed to download ec2dial.${NC}"
    exit 1
  fi
}

# Verify checksum
verify_checksum() {
  BINARY="$1"
  CHECKSUM_FILE="$2"
  
  if [ "$SKIP_CHECKSUM" = "true" ]; then
    echo "${YELLOW}Skipping checksum verification.${NC}"
    return 0
  fi
  
  echo "Verifying integrity..."
  
  if command_exists sha256sum; then
    # Linux style
    cd "$(dirname "$CHECKSUM_FILE")" || exit 1
    if ! sha256sum -c "$CHECKSUM_FILE" >/dev/null 2>&1; then
      echo "${RED}Checksum verification failed. The downloaded binary may be corrupted.${NC}"
      exit 1
    fi
  elif command_exists shasum; then
    # macOS style
    cd "$(dirname "$CHECKSUM_FILE")" || exit 1
    EXPECTED=$(cat "$CHECKSUM_FILE" | awk '{print $1}')
    ACTUAL=$(shasum -a 256 "$BINARY" | awk '{print $1}')
    
    if [ "$EXPECTED" != "$ACTUAL" ]; then
      echo "${RED}Checksum verification failed. The downloaded binary may be corrupted.${NC}"
      echo "Expected: $EXPECTED"
      echo "Actual: $ACTUAL"
      exit 1
    fi
  fi
}

# Install binary
install_binary() {
  SRC="$1"
  DEST="$2"
  
  # Check if installation directory is writable
  if [ ! -w "$(dirname "$DEST")" ]; then
    USE_SUDO=true
  else
    USE_SUDO=false
  fi
  
  # Make binary executable
  chmod +x "$SRC"
  
  echo "Installing ec2dial..."
  
  if [ "$USE_SUDO" = "true" ]; then
    if ! command_exists sudo; then
      echo "${RED}Error: Cannot write to $DEST and sudo is not available.${NC}"
      echo "Please run this script with sudo or install ec2dial manually."
      exit 1
    fi
    
    if ! sudo cp "$SRC" "$DEST"; then
      echo "${RED}Installation failed.${NC}"
      exit 1
    fi
  else
    if ! cp "$SRC" "$DEST"; then
      echo "${RED}Installation failed.${NC}"
      exit 1
    fi
  fi
}

# Check installation
verify_installation() {
  if command_exists ec2dial; then
    echo "${GREEN}ec2dial successfully installed!${NC}"
    echo "Run 'ec2dial --help' to get started."
  else
    DEST_DIR=$(dirname "$INSTALL_DIR/ec2dial")
    echo "${YELLOW}Warning:${NC} $DEST_DIR is not in your PATH."
    echo "You may need to add it to your PATH or manually invoke $INSTALL_DIR/ec2dial"
  fi
}

# Main installation process
main() {
  echo "${BOLD}Installing ec2dial...${NC}"
  
  # Detect platform
  detect_platform
  
  # Check dependencies
  check_dependencies
  
  # Create temp directory structure
  DOWNLOAD_DIR="$TEMP_DIR/downloads"
  mkdir -p "$DOWNLOAD_DIR"
  
  # Download binary and checksum
  BINARY_URL="$GITHUB_URL/downloads/$BINARY_NAME"
  CHECKSUM_URL="$GITHUB_URL/downloads/$CHECKSUM_FILE"
  
  download_file "$BINARY_URL" "$DOWNLOAD_DIR/$BINARY_NAME"
  download_file "$CHECKSUM_URL" "$DOWNLOAD_DIR/$CHECKSUM_FILE" >/dev/null 2>&1
  
  # Verify checksum
  verify_checksum "$DOWNLOAD_DIR/$BINARY_NAME" "$DOWNLOAD_DIR/$CHECKSUM_FILE"
  
  # Install binary
  DEST_PATH="$INSTALL_DIR/ec2dial"
  install_binary "$DOWNLOAD_DIR/$BINARY_NAME" "$DEST_PATH"
  
  # Verify installation
  verify_installation
}

# Run the installer
main
