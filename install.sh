#!/bin/bash
set -e

# social.sh installer
# Usage: curl -fsSL https://github.com/senturySH/social.sh-installer/releases/download/v0.0.0/install.sh | bash

INSTALL_DIR="${SOCIAL_SH_INSTALL:-$HOME/.social-sh}"
BIN_DIR="$INSTALL_DIR/bin"
VERSION="${SOCIAL_SH_VERSION:-v0.0.0}"
GITHUB_REPO="senturySH/social.sh-installer"
RELEASE_BASE_URL="https://github.com/$GITHUB_REPO/releases/download/$VERSION"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[info]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[warn]${NC} $1"
}

error() {
    echo -e "${RED}[error]${NC} $1"
    exit 1
}

# Spinner animation
show_spinner() {
    local pid=$1
    local message=$2
    local delay=0.08
    local spinner=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )

    while kill -0 $pid 2>/dev/null; do
        for i in "${spinner[@]}"; do
            echo -ne "\r${GREEN}[•]${NC} $message ${BLUE}$i${NC}  "
            sleep $delay
        done
    done
    echo -ne "\r"
}

# Detect OS and architecture
detect_platform() {
    OS="$(uname -s)"
    ARCH="$(uname -m)"

    case "$OS" in
        Linux*)     OS="linux" ;;
        Darwin*)    OS="darwin" ;;
        *)          error "Unsupported OS: $OS" ;;
    esac

    case "$ARCH" in
        x86_64)     ARCH="x64" ;;
        aarch64)    ARCH="arm64" ;;
        arm64)      ARCH="arm64" ;;
        *)          error "Unsupported architecture: $ARCH" ;;
    esac

    echo "$OS-$ARCH"
}

# Create installation directory
setup_dirs() {
    info "Creating installation directory at $INSTALL_DIR"
    mkdir -p "$BIN_DIR"
}

# Download the CLI binary
download_cli() {
    local platform="$1"
    local binary_name="social.sh-${VERSION}-${platform}"
    local download_url="${RELEASE_BASE_URL}/${binary_name}"

    echo -n ""
    # Start download in background
    curl -fsSL "$download_url" -o "$BIN_DIR/social.sh" &
    local curl_pid=$!

    # Show spinner while downloading
    show_spinner $curl_pid "Downloading social.sh for $platform"

    # Wait for curl to finish
    wait $curl_pid
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        error "Failed to download binary from $download_url"
    fi

    # Make the binary executable
    chmod +x "$BIN_DIR/social.sh"
    echo -e "${GREEN}[✓]${NC} Binary installed successfully at $BIN_DIR/social.sh"
}

# Add to PATH
setup_path() {
    SHELL_NAME="$(basename "$SHELL")"
    PROFILE=""

    case "$SHELL_NAME" in
        bash)
            if [[ -f "$HOME/.bashrc" ]]; then
                PROFILE="$HOME/.bashrc"
            elif [[ -f "$HOME/.bash_profile" ]]; then
                PROFILE="$HOME/.bash_profile"
            fi
            ;;
        zsh)
            PROFILE="$HOME/.zshrc"
            ;;
        fish)
            PROFILE="$HOME/.config/fish/config.fish"
            ;;
    esac

    PATH_EXPORT="export PATH=\"$BIN_DIR:\$PATH\""

    if [[ -n "$PROFILE" ]]; then
        if ! grep -q "$BIN_DIR" "$PROFILE" 2>/dev/null; then
            info "Adding $BIN_DIR to PATH in $PROFILE"
            echo "" >> "$PROFILE"
            echo "# social.sh" >> "$PROFILE"
            echo "$PATH_EXPORT" >> "$PROFILE"
        fi
    fi
}

main() {
    echo ""
    echo -e "  ${BLUE}social.sh installer${NC}"
    echo -e "  ${BLUE}===================${NC}"
    echo ""

    local platform=$(detect_platform)
    setup_dirs
    download_cli "$platform"
    setup_path

    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✓ Installation complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  ${BLUE}Run 'social.sh --help' to get started${NC}"
    echo ""
    echo "  You may need to restart your shell or run:"
    echo -e "    ${YELLOW}export PATH=\"$BIN_DIR:\$PATH\"${NC}"
    echo ""
}

main
