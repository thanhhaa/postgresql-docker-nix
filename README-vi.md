# Môi trường phát triển PostgreSQL + Docker + Nix

## Tổng quan

Dự án này sử dụng **nix-shell** để quản lý dependencies và Docker để chạy PostgreSQL, tạo ra một môi trường phát triển hoàn toàn có thể tái tạo và nhất quán trên mọi máy tính. Chúng ta chọn nix-shell thay vì nix develop để đảm bảo khả năng tương thích tốt nhất và không yêu cầu hỗ trợ **flake**.

## Tại sao nix-shell?

**Ổn định & Tương thích:**

- Hoạt động với mọi bản cài đặt Nix, không cần bật tính năng thử nghiệm
- Tương thích ngược với các công cụ và script Nix cũ
- Được sử dụng rộng rãi trong ngành công nghiệp, nhiều tài liệu và ví dụ

**Đơn giản:**

- Không cần hiểu hệ sinh thái flake phức tạp để tùy chỉnh
- File cấu hình đơn giản và dễ bảo trì
- Dễ dàng cho lập trình viên mới làm quen với Nix

## Architecture

```bash
Project Structure:
├── init-scripts/             # Database initialization scripts
│   └── 01-init-database.sql  # Schema and sample data
├── scripts/
│   └── dev.sh                # Development management script
├── .env.dev                  # Environment variables for the development environment
├── .gitignore                # Specifies files/folders to exclude from Git commits
├── docker-compose.yml        # PostgreSQL container configuration  
├── LICENSE.md                  
├── README.md                 # This file  
├── README-vi.md                
├── shell.nix                 # Nix shell environment definition
└── Troubleshoot.md           # Notes and instructions for diagnosing and fixing issues
```

### Tại sao kiến trúc này hiệu quả

**Tách biệt trách nhiệm:**

- **Nix** quản lý công cụ và các phụ thuộc của host machine
- **Docker** cô lập database và đảm bảo tính di động
- **Scripts** tự động hóa workflow phổ biến

**Tính tái tạo:**

- Mọi developer sẽ có chính xác cùng phiên bản PostgreSQL, client tools, và môi trường
- Database schema được khởi tạo tự động và nhất quán

## Cài đặt lần đầu

### 1. Cài đặt Prerequisites

**macOS:**

```bash
# Cài đặt Nix với Determinate Nix Installer (khuyên dùng)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Cài đặt Docker Desktop
brew install --cask docker
```

**Linux:**

```bash
# Cài đặt Nix với Determinate Nix Installer (khuyên dùng)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Cài đặt Docker (Ubuntu/Debian)
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER  # Thêm user vào docker group
# Log out và log in lại để group có hiệu lực
```

### 2. Clone và Setup Project

```bash
# Clone repository
git clone <your-repo-url>
cd your-project-name

# Set script scripts/dev.sh có thể thực thi
chmod +x ./scripts/dev.sh 

# Tạo thư mục init-scripts nếu chưa có
mkdir -p init-scripts

# Test môi trường Nix shell
nix-shell --run "echo 'Nix shell is working!'"
```

**Giải thích về nix-shell workflow:**

Khi bạn chạy `nix-shell`, Nix sẽ đọc file `shell.nix`, tạo ra một môi trường cô lập với tất cả các dependency đã được định nghĩa, sau đó mở một phiên shell mới. Tất cả các công cụ như `docker`, `psql`, `pgcli` sẽ có sẵn trong PATH chỉ trong phiên làm việc này, và không ảnh hưởng đến các cài đặt trên toàn hệ thống (system-wide).

## Hai cách sử dụng nix-shell

### Phát triển tương tác

```bash
# Vào Nix shell environment
# nix-shell --run "echo 'Nix shell is working!'" 
nix-shell

# Bây giờ bạn có tất cả tools available
# Và có thể chạy multiple commands:
docker-compose up -d postgres-dev
pgcli -h localhost -p 5432 -U user -d postgres_dev_db
docker-compose logs -f
```

**Ưu điểm của chế độ Interactive:**

- Không cần tải lại môi trường cho mỗi command
- Thực thi nhanh hơn vì môi trường chỉ thiết lập 1 lần
- Có thể sử dụng lịch sử lệnh (shell history) và aliases
- Trải nghiệm phát triển tốt hơn nhờ phiên làm việc liên tục

### Tự động hóa Script

Cho automated tasks và scripts, sử dụng `--run` mode:

```bash
# Chạy single command
nix-shell --run "docker-compose ps"

# Chạy câu lệnh phức tạp với bash
nix-shell --run "docker-compose up -d && docker-compose logs -f postgres-dev"
```

Đây chính là cách script `scripts/dev.sh` hoạt động - mỗi lần gọi hàm đều sử dụng `nix-shell --run` để đảm bảo môi trường nhất quán.

## Quy trình làm việc hàng ngày được khuyến nghị

**Cách tiếp cận phát triển được khuyến nghị:**

```bash
# Bước 1: Vào interactive shell
nix-shell

source ./.env.dev

# Bước 2: Kết nối và làm việc(trong nix-shell)
./scripts/dev.sh              # Show all commands and usage
./scripts/dev.sh start-db     # Start PostgreSQL
./scripts/dev.sh start-admin  # Start with web interface
./scripts/dev.sh connect      # Connect to database
./scripts/dev.sh status       # Show service status
```

**Tại sao cách tiếp cận này hiệu quả:**

Ở chế độ interactive, bạn được sử dụng tất cả biến môi trường và alias được khai báo trong shell.nix.
Ví dụ, thay vì phải gõ `pgcli -h localhost -p 5432 -U developer -d myapp_dev` mỗi lần, bạn chỉ cần chạy `pgcli-dev`.
Shell cũng hiển thị một prompt tùy chỉnh để nhắc bạn rằng bạn đang ở trong môi trường Nix.

### Khởi động môi trường

```bash
# Khởi động chỉ database
./scripts/dev.sh start-db

# Hoặc khởi động database + pgAdmin GUI
./scripts/dev.sh start-admin
```

**Điều gì xảy ra khi chạy lệnh này:**

1. **Nix kiểm tra môi trường:** Nix đảm bảo tất cả công cụ cần thiết đều có sẵn (docker, PostgreSQL client, pgcli, v.v.)
2. **Docker khởi động PostgreSQL:** Container PostgreSQL được tải về (nếu chưa có) và khởi động
3. **Khởi tạo database:** Ở lần chạy đầu tiên, PostgreSQL sẽ thực thi `01-init-database.sql` để tạo schema và data mẫu
4. **Health check:** Hệ thống chờ đến khi PostgreSQL sẵn sàng nhận kết nối rồi mới báo thành công

### Kết nối và làm việc với Database

```bash
# Kết nối bằng pgcli (CLI đẹp với syntax highlighting)
./scripts/dev.sh  connect

# Xem trạng thái services
./scripts/dev.sh  status

# Xem logs realtime
./scripts/dev.sh  logs
```

**Trong pgcli, bạn có thể thử các query sau:**

```sql
-- Xem tất cả tables
\dt app_schema.*

-- Truy vấn users
SELECT username, email, full_name, created_at 
FROM app_schema.users;

-- Truy vấn bài viết đã publish
SELECT title, author_name, published_at 
FROM app_schema.published_posts;

-- Tìm kiếm full-text
SELECT title, content 
FROM app_schema.posts 
WHERE to_tsvector('english', title || ' ' || COALESCE(content, '')) 
      @@ to_tsquery('english', 'welcome');
```

### Quản lý dữ liệu

```bash
# Sao lưu database
./scripts/dev.sh  backup

# Reset database (xóa tất cả data và khởi tạo lại)
./scripts/dev.sh  reset

# Dừng tất cả services
./scripts/dev.sh  stop
```

## Thực hành tốt nhất

### Thiết kế database

1. **Luôn sử dụng transactions** cho các thao tác nhiều bước
2. **Tạo index hợp lý** tránh tạo quá nhiều index không cần thiết
3. **Sử dụng constraints** để đảm bảo tính toàn vẹn dữ liệu
4. **Normalize hợp lý** cân bằng giữa normalization và hiệu năng

### Quy Trình Phát Triển

1. **Commit thay đổi schema** vào version control
2. **Sử dụng migrations** khi triển khai lên production
3. **Test với dữ liệu gần giống production** về số lượng và phân bố
4. **Theo dõi hiệu năng truy vấn** thường xuyên

### Bảo mật

1. **Không commit mật khẩu** vào version control
2. **Dùng environment variables** cho dữ liệu nhạy cảm
3. **Giới hạn quyền truy cập của user database** trong production
4. **Thiết lập chiến lược backup định kỳ** và kiểm tra quá trình restore

## Mở rộng

Khi dự án phát triển, bạn có thể:

1. Thêm **Redis** để caching
2. Cấu hình **connection pooling**
3. Thiết lập **read replicas** để cải thiện hiệu năng
4. Áp dụng **database sharding** cho hệ thống lớn
5. Thêm **monitoring** với Grafana + Prometheus

---

## Kết luận

Cấu hình này cung cấp một nền tảng vững chắc cho việc phát triển ứng dụng sử dụng PostgreSQL. Sự kết hợp giữa Nix, Docker và các script tự động hóa giúp bất kỳ developer nào cũng có thể thiết lập môi trường nhanh chóng và bắt đầu làm việc hiệu quả ngay lập tức.
