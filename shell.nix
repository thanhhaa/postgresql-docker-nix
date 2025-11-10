# Traditional Nix shell environment for PostgreSQL + Docker development
# Môi trường Nix shell truyền thống cho phát triển PostgreSQL + Docker

# Development environment configuration for a Nix-based project
# This file creates an isolated environment with all neccessary tools and dependencies.

{ pkgs ? import <nixpkgs> {} }:

let
  # Detect if we're on Darwin(macOS)
  isDarwin = pkgs.stdenv.isDarwin || builtins.currentSystem == "x86_64-darwin";
  isLinux = pkgs.stdenv.isLinux;

in
pkgs.mkShell {
  # Tên cho shell environment (sẽ hiển thị trong prompt)
  # Name for the shell environment (will be shown in prompt)
  name = "postgres-docker-nix-dev";
  
  # Required dependencies and tools/ Dependencies và tools cần thiết
  buildInputs = with pkgs; [
    # Container orchestration tools/ Công cụ điều phối container
    docker
    docker-compose
    
    # PostgreSQL client and utilities/ PostgreSQL client và utilities
    postgresql_15         # PostgreSQL client tools (psql, pg_dump, etc.)
    pgcli                 # Enhanced PostgreSQL CLI and syntax highlighting
    
    # Essential development utilities/ Tiện ích phát triển cần thiết
    git                   # Version control
    tree                  # Directory structure visualization
    htop                  # Better process viewer
    
    # Text editors và IDE support/ Text editors and IDE support
    vim                   # Console text editor
    nano                  # Simple text editor for beginners
    
    # Optional database management tools/ Công cụ quản lý database tùy chọn
    # Uncomment these if you need GUI tools/ Bỏ comment nếu cần GUI tools:
    # dbeaver             # Universal database tool
    # pgadmin4            # PostgreSQL administration tool
  ];
  
  # Shell packages - Shell packages added to PATH/ các package sẽ được thêm vào PATH
  # This differs from buildInputs in that it only affects PATH, not the build process
  # Điều này khác với buildInputs ở chỗ nó chỉ affect PATH, không phải build process
  nativeBuildInputs = with pkgs; [
    # Build tools for native extensions/ Build tools nếu cần compile native extensions
    gcc
    gnumake
    pkg-config
  ];
  
  # Script to run when entering the shell/ Script chạy khi vào shell
  shellHook = ''
    # Colors for prettier output/ Màu sắc cho output đẹp hơn
    export GREEN='\033[0;32m'
    export BLUE='\033[0;34m'
    export YELLOW='\033[1;33m'
    export NC='\033[0m' # No Color

    # Welcome message/ Thông điệp chào mừng
    printf "🐳$BLUE PostgreSQL + Docker Development Environment$NC\n"
    printf "📦$GREEN Nix Shell Environment Activated$NC\n"
    
    # macOS specific settings
    # Locale fix
    export LANG="en_US.UTF-8"
    export LC_ALL="en_US.UTF-8"
    export LC_CTYPE="en_US.UTF-8"
    export LC_COLLATE="en_US.UTF-8"

    # PostgreSQL library paths
    export DYLD_LIBRARY_PATH="${pkgs.postgresql_15}/lib:$DYLD_LIBRARY_PATH"
    # Additional paths for runtime linking
    export LD_LIBRARY_PATH="${pkgs.postgresql_15}/lib:$LD_LIBRARY_PATH"
    # Critical environment variable that solves the issue
    export PKG_CONFIG_PATH="${pkgs.postgresql_15}/lib/pkgconfig:$PKG_CONFIG_PATH"
    
    printf "$YELLOW 💻 MacOS:$NC\n"
    echo "   ✅ Current locale: $LANG"
    echo "   ✅ LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
    echo "   ✅ DYLD_LIBRARY_PATH: $DYLD_LIBRARY_PATH"
    echo "   ✅ PKG_CONFIG_PATH: $PKG_CONFIG_PATH"
    echo ""

    # Mark variables for export and source the .env file
    source ./.env.dev

    # Display available tools info/ Hiển thị thông tin về tools có sẵn
    printf "$YELLOW 📋 Available Tools:$NC\n"
    echo "   🐘 PostgreSQL client: $(psql --version | head -n1)"
    echo "   🐳 Docker: $(docker --version)"
    echo "   📦 Docker Compose: $(docker-compose --version)"
    echo "   ✨ pgcli: Enhanced PostgreSQL CLI"
    echo ""
    
    # Check Docker daemon/ Kiểm tra Docker daemon
    printf "$YELLOW 🔍 System Checks:$NC\n"
    if ! docker info > /dev/null 2>&1; then
      printf "   ⚠️  Docker is not running. Start Docker first.\n"
    else
      printf "   ✅ Docker daemon is running\n"
    fi
    
    # Check for running containers/ Kiểm tra xem có containers đang chạy không
    if docker ps -q --filter "name=$DEV_POSTGRES_CONTAINER_NAME" | grep -q .; then
      printf "   ✅ PostgreSQL container is running\n"
    else
      printf "   ⚠️  PostgreSQL container not running. Use './scripts/dev.sh  start-db' to start.\n"
    fi
    
    echo ""
    
    # Quick usage guide/ Hướng dẫn sử dụng nhanh
    printf "$YELLOW 🚀 Quick Start:$NC\n"
    echo "   ./scripts/dev.sh              # Show all commands and usage"
    echo "   ./scripts/dev.sh start-db     # Start PostgreSQL"
    echo "   ./scripts/dev.sh start-admin  # Start with web interface"
    echo "   ./scripts/dev.sh connect      # Connect to database"
    echo "   ./scripts/dev.sh status       # Show service status"
    echo ""
    
    # Set up convenience aliases/ Set up aliases cho convenience
    alias ll='ls -la'
    alias la='ls -A'
    alias l='ls -CF'
    alias ..='cd ..'
    alias ...='cd ../..'
  '';
}