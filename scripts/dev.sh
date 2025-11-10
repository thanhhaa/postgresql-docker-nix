#!/bin/bash

# Development Environment Management Script for PostgreSQL + Docker + Nix
# Script quản lý môi trường phát triển cho PostgreSQL + Docker + Nix
#
# This script provides easy commands to manage your development database
# Script này cung cấp các lệnh dễ sử dụng để quản lý database development của bạn

set -e  # Exit immediately if any command fails/ Thoát ngay lập tức nếu có lệnh nào thất bại

# Color definitions for better visual output/ Định nghĩa màu sắc để output đẹp hơn
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_PURPLE='\033[0;35m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_RESET='\033[0m'

source ./.env.dev

# Logging functions with colored output/ Các hàm log với màu sắc
log_info() {
    echo -e "${COLOR_BLUE} [INFO]    $1${COLOR_RESET}"
}

log_success() {
    echo -e "${COLOR_GREEN} [SUCCESS] $1${COLOR_RESET}"
}

log_warning() {
    echo -e "${COLOR_YELLOW} [WARNING] $1${COLOR_RESET}"
}

log_error() {
    echo -e "${COLOR_RED} [ERROR]  $1${COLOR_RESET}"
}

log_header() {
    echo -e "${COLOR_PURPLE} [HEADER]  $1${COLOR_RESET}"
}

docker_compose_env() {
    docker-compose --env-file .env.dev "$@"
}

start_postgres_service() {
    # docker-compose up -d postgres(service_name in docker-compose.yml)
    docker_compose_env up -d postgres-dev
}

start_pgadmin_service() {
    # docker-compose up -d ppgadmin-dev(service_name in docker-compose.yml)
    docker_compose_env up -d pgadmin-dev
}

check_connection_postgres_dev() {
    docker_compose_env exec postgres-dev pg_isready -U "$DEV_POSTGRES_USER" -d "$DEV_POSTGRES_PASSWORD" 
}

# Function to check if required tools are available/ Hàm kiểm tra các công cụ cần thiết có sẵn không
check_prerequisites() {
    # Kiểm tra điều kiện tiên quyết...
    log_info "Checking prerequisites"
    
    # Check Docker/ Kiểm tra Docker
    if ! command -v docker &> /dev/null; then
        # Docker chưa được cài đặt hoặc không có trong PATH
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    # Check Docker Compose/ Kiểm tra Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        # Docker Compose chưa được cài đặt hoặc không có trong PATH
        log_error "Docker Compose is not installed or not in PATH"
        exit 1
    fi
    
    # Check if Docker daemon is running/ Kiểm tra Docker daemon có đang chạy không
    if ! docker info &> /dev/null; then
        # Docker daemon không chạy. Vui lòng khởi động Docker Desktop trước.
        log_error "Docker daemon is not running. Please start Docker Desktop first."
        exit 1
    fi

    # Check if ./.env.dev file exists/ Kiểm tra file ./.env.dev tồn tại
    if [ ! -f ./.env.dev ]; then
        log_error "❌ Error: ./.env.dev not found!"
        exit 1
    fi
    
    # Check required environment variables/ Kiểm tra biến môi trường bắt buộc
    if [ -z "$DEV_POSTGRES_PASSWORD" ] || [ -z "$DEV_PGADMIN_DEFAULT_PASSWORD" ] || [ -z "$DEV_POSTGRES_USER" ]; then
        echo "❌ Error: Required environment variables are not set!"
        exit 1
    fi

    # Tất cả điều kiện tiên quyết đã được đáp ứng
    log_success "All prerequisites are met"
}

# Function to start PostgreSQL database service/ Hàm khởi động dịch vụ database PostgreSQL
start_database() {
    # Khởi động Database PostgreSQL
    log_header "🧪 Starting Development Environment..."
    log_header "Starting PostgreSQL Database"
    
    check_prerequisites

    # Start only the PostgreSQL service/ Chỉ khởi động service PostgreSQL
    # Đang khởi động container PostgreSQL...
    log_info "Starting PostgreSQL container..."
    # docker-compose up -d postgres(service_name in docker-compose.yml)
    start_postgres_service
    
    # Wait for PostgreSQL to be healthy/ Chờ PostgreSQL khỏe mạnh
    # Đang chờ PostgreSQL sẵn sàng (có thể mất 30-60 giây)...
    log_info "Waiting for PostgreSQL to be ready (this may take 30-60 seconds)..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if check_connection_postgres_dev &> /dev/null; then
            # PostgreSQL đã sẵn sàng và đang chấp nhận kết nối!
            log_success "PostgreSQL is ready and accepting connections!"
            break
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        # PostgreSQL không sẵn sàng trong thời gian mong đợi
        # Thử kiểm tra logs bằng: docker-compose logs postgres
        log_error "PostgreSQL did not become ready within expected time"
        log_info "Try checking logs with: docker-compose --env-file .env.dev logs postgres"
        exit 1
    fi
    
    # Show connection information/ Hiển thị thông tin kết nối
    # Thông tin kết nối Database:
    echo ""
    log_info "Database Connection Information:"
    echo "  Host: ${DEV_POSTGRES_HOST}"
    echo "  Port: ${DEV_POSTGRES_PORT}"
    echo "  Database: ${DEV_POSTGRES_DB_NAME}"
    echo "  Username: ${DEV_POSTGRES_USER}"
    echo "  Password: ${DEV_POSTGRES_PASSWORD}"
}

# Function to start both database and pgAdmin/ Hàm khởi động cả database và pgAdmin
start_with_admin() {
    # Khởi động PostgreSQL Database với pgAdmin
    log_header "Starting PostgreSQL Database with pgAdmin"
    
    check_prerequisites
    
    # Đang khởi động tất cả dịch vụ (PostgreSQL + pgAdmin)...
    log_info "Starting all services (PostgreSQL + pgAdmin)..."
    start_pgadmin_service
    
    # Wait for services to be ready/ Chờ các dịch vụ sẵn sàng
    # Đang chờ các dịch vụ sẵn sàng...
    log_info "Waiting for services to be ready..."
    sleep 10
    
    # Check PostgreSQL health / Kiểm tra sức khỏe PostgreSQL
    if check_connection_postgres_dev &> /dev/null; then
        # PostgreSQL đã sẵn sàng!
        log_success "PostgreSQL is ready!"
    else
        # PostgreSQL có thể vẫn đang khởi động...
        log_warning "PostgreSQL may still be starting up..."
    fi

    echo ""
    log_info "Access Information:"
    echo "  📊 pgAdmin Web Interface: http://localhost:8080"
    echo "      Email: ${DEV_PGADMIN_DEFAULT_EMAIL}"
    echo "      Password: ${DEV_PGADMIN_DEFAULT_PASSWORD}"
    echo ""
    echo "  🗄️  Direct Database Connection:"
    echo "      Host: ${DEV_POSTGRES_HOST}, Port: ${DEV_POSTGRES_PORT}"
    echo "      Database: ${DEV_POSTGRES_DB_NAME}, User: ${DEV_POSTGRES_USER}"
}

# Function to connect to database using psql/ Hàm kết nối database bằng psql
connect_database() {
    # Kết nối PostgreSQL Database
    log_header "Connecting to PostgreSQL Database"
    
    # Check if PostgreSQL container is running/ Kiểm tra PostgreSQL container có đang chạy không
    if ! docker_compose_env ps postgres-dev | grep -q "Up"; then
        # Container PostgreSQL chưa chạy. Hãy khởi động nó bằng lệnh sau:
        log_error "PostgreSQL container is not running. Start it first with:"
        echo "  $0 start-db"
        exit 1
    fi
    
    # Đang kết nối database bằng psql...
    log_info "Connecting to database using psql..."
    
    # Use environment variable for password to avoid password prompt
    # Sử dụng biến môi trường cho password để tránh nhắc nhập password
    PGPASSWORD="$DEV_POSTGRES_PASSWORD" psql -h "$DEV_POSTGRES_HOST" -p "$DEV_POSTGRES_PORT" -U "$DEV_POSTGRES_USER" -d "$DEV_POSTGRES_DB_NAME"
}

# Function to show status of all services/ Hàm hiển thị trạng thái của tất cả dịch vụ
show_status() {
    # Trạng thái Dịch vụ
    log_header "Service Status"
    
    echo ""
    log_info "Docker Compose Services:"
    docker_compose_env ps postgres-dev
    
    echo ""
    # Trạng thái sức khỏe Container:
    log_info "Container Health Status:"
    
    # Check PostgreSQL health/ Kiểm tra sức khỏe PostgreSQL
    if docker_compose_env ps postgres-dev | grep -q "Up.*healthy"; then
        log_success "PostgreSQL: Healthy and ready"
    elif docker_compose_env ps postgres-dev | grep -q "Up"; then
        log_warning "PostgreSQL: Running but health status unknown"
    else
        log_error "PostgreSQL: Not running"
    fi
    
    # Check pgAdmin status/ Kiểm tra trạng thái pgAdmin
    # if docker-compose ps pgadmin | grep -q "Up"; then
    #     log_success "pgAdmin: Running at http://localhost:8080"
    # else
    #     log_info "pgAdmin: Not running"
    # fi
}

# Function to stop all services/ Hàm dừng tất cả dịch vụ
stop_services() {
    log_header "Stopping Services"
    
    log_info "Stopping all containers..."
    docker_compose_env down
    
    log_success "All services have been stopped"
}

# Function to view logs/ Hàm xem logs
view_logs() {
    local service=${1:-""}  # Optional service name
    
    if [ -n "$service" ]; then
        log_info "Showing logs for service: $service"
        docker_compose_env logs -f "$service"
    else
        log_info "Showing logs for all services"
        docker_compose_env logs -f
    fi
}

# Function to backup database/ Hàm backup database
backup_database() {
    log_header "Backing Up Database"
    
    # Check if PostgreSQL is running/ Kiểm tra PostgreSQL có đang chạy không
    if ! get_service_postgres_status | grep -q "Up"; then
        log_error "PostgreSQL is not running. Please start it first."
        exit 1
    fi
    
    # Create backups directory if it doesn't exist/ Tạo thư mục backups nếu chưa có
    mkdir -p backups
    
    # Generate backup filename with timestamp/ Tạo tên file backup với timestamp
    local backup_file="backups/backup_${DB_NAME}_$(date +%Y%m%d_%H%M%S).sql"
    
    log_info "Creating backup: $backup_file"
    
    # Create database backup/ Tạo backup database
    if docker_compose_env exec postgres-dev pg_dump -U "$DB_USER" "$DB_NAME" > "$backup_file"; then
        log_success "Backup created successfully: $backup_file"
        
        # Show backup size/ Hiển thị kích thước backup
        local backup_size=$(ls -lh "$backup_file" | awk '{print $5}')
        log_info "Backup size: $backup_size"
    else
        log_error "Failed to create backup"
        exit 1
    fi
}

# Function to show help/ Hàm hiển thị trợ giúp
show_help() {
    echo -e "${COLOR_CYAN}"
    echo "Development Environment Management Script"
    echo "========================================"
    echo -e "${COLOR_RESET}"
    echo ""
    echo "Usage:"
    echo "  $0 [command] [options]"
    echo ""
    echo "Commands"
    echo "  start-db        Start PostgreSQL database only"
    echo "  start-admin     Start PostgreSQL + pgAdmin"
    echo "  connect         Connect to database with psql"
    echo "  status          Show service status"
    echo "  stop            Stop all services"
    echo "  logs [service]  Show logs (optionally for specific service)"
    echo "  backup          Create database backup"
    echo "  help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start-db                   # Start database only"
    echo "  $0 start-admin                # Start with web interface"
    echo "  $0 logs postgres              # Show PostgreSQL logs"
    echo "  $0 backup                     # Create backup"
    echo ""
    echo "Default database connection:"
    echo "  Host: $DEV_POSTGRES_HOST, Port: $DEV_POSTGRES_PORT"
    echo "  Database: $DEV_POSTGRES_DB_NAME, User: $DEV_POSTGRES_USER"
}

# Main command processing/ Xử lý lệnh chính
main() {
    case "${1:-help}" in
        "start-db"|"start")
            start_database
            ;;
        "start-admin"|"admin")
            start_with_admin
            ;;
        "connect"|"psql")
            connect_database
            ;;
        "status"|"ps")
            show_status
            ;;
        "stop"|"down")
            stop_services
            ;;
        "logs")
            view_logs "${2:-}"
            ;;
        "backup")
            backup_database
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Execute main function with all provided arguments/ Thực thi hàm main với tất cả arguments
main "$@"