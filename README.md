# PostgreSQL + Docker + Nix Development Environment / Môi trường phát triển PostgreSQL + Docker + Nix

## Overview / Tổng quan

This project uses **nix-shell** for dependency management and Docker to run PostgreSQL, creating a completely reproducible and consistent development environment across all machines. We choose nix-shell over nix develop to ensure the best compatibility and doesn't require flake support.

Dự án này sử dụng **nix-shell** để quản lý dependencies và Docker để chạy PostgreSQL, tạo ra một môi trường phát triển hoàn toàn có thể tái tạo và nhất quán trên mọi máy tính. Chúng ta chọn nix-shell thay vì nix develop để đảm bảo khả năng tương thích tốt nhất và không yêu cầu hỗ trợ **flake**.

## Why nix-shell / Tại sao nix-shell?

**Stability & Compatibility / Ổn định & Tương thích:**

- Works with any Nix installation, no need to enable experimental features / Hoạt động với mọi bản cài đặt Nix, không cần bật tính năng thử nghiệm
- Backward compatible với legacy Nix tooling và scripts / Tương thích ngược với các công cụ và script Nix cũ
- Widely used in the industry, with plenty of documentation and examples / Được sử dụng rộng rãi trong ngành công nghiệp, nhiều tài liệu và ví dụ

**Simplicity / Đơn giản:**

- No need to understand the complex flake ecosystem to customize / Không cần hiểu hệ sinh thái flake phức tạp để tùy chỉnh
- Simple and easy-to-maintain configuration file / File cấu hình đơn giản và dễ bảo trì
- Easier onboarding for new developers with Nix / Dễ dàng cho lập trình viên mới làm quen với Nix

## Architecture / Kiến trúc

```bash
Project Structure  / Cấu trúc dự án:
├── init-scripts /            # Database initialization scripts
│   └── 01-init-database.sql  # Schema and sample data
├── scripts /
│   └── dev.sh                # Development management script
├── .env.dev                  # Environment variables for the development environment
├── .gitignore                # Specifies files/folders to exclude from Git commits
├── docker-compose.yml        # PostgreSQL container configuration  
├── LICENSE.md                  
├── README.md                 # This file  
├── shell.nix                 # Nix shell environment definition
└── Troubleshoot.md           # Notes and instructions for diagnosing and fixing issues
```

### Why This Architecture Works / Tại sao kiến trúc này hiệu quả

**Separation of Concerns / Tách biệt trách nhiệm:**

- **Nix** manages tools and dependencies on the host machine / quản lý công cụ và các phụ thuộc của host machine
- **Docker** isolates the database and ensures portability / cô lập database và đảm bảo tính di động
- **Scripts** automate common workflows / tự động hóa workflow phổ biến

**Reproducibility / Tính tái tạo:**

- Every developer will have the exact same version of PostgreSQL, client tools, and environment / Mọi developer sẽ có chính xác cùng phiên bản PostgreSQL, client tools, và môi trường
- The database schema is initialized automatically and consistently across machines / Database schema được khởi tạo tự động và nhất quán

## First-time Setup / Cài đặt lần đầu

### 1. Install Prerequisites / Cài đặt Prerequisites

**macOS:**

```bash
# Install Nix using the Determinate Nix Installer (recommended) / Cài đặt Nix với Determinate Nix Installer (khuyên dùng)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Install Docker Desktop / Cài đặt Docker Desktop
brew install --cask docker
```

**Linux:**

```bash
# Install Nix using the Determinate Nix Installer (recommended) / Cài đặt Nix với Determinate Nix Installer (khuyên dùng)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Install Docker (Ubuntu/Debian) / Cài đặt Docker (Ubuntu/Debian)
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER  # Add the user to the docker group / Thêm user vào docker group
# Log out and log back in for the group change to take effect / Log out và log in lại để group có hiệu lực
```

### 2. Clone and Setup Project / Clone và Setup Project

```bash
# Clone repository
git clone <your-repo-url>
cd your-project-name

# Make scripts/dev.sh  executable / Làm script scripts/dev.sh  có thể thực thi
chmod +x ./scripts/dev.sh 

# Create init-scripts directory if not exists / Tạo thư mục init-scripts nếu chưa có
mkdir -p init-scripts

# Test Nix shell environment  / Test môi trường Nix shell
nix-shell --run "echo 'Nix shell is working!'"
```

**Nix-shell workflow explanation / Giải thích về nix-shell workflow:**

When you run `nix-shell`, Nix will read the `shell.nix` file, create an isolated environment with all defined dependencies, then spawn a new shell session. All tools like `docker`, `psql`, `pgcli` will be available in PATH only within this session, without affecting system-wide installations.

Khi bạn chạy `nix-shell`, Nix sẽ đọc file `shell.nix`, tạo ra một môi trường cô lập với tất cả các dependency đã được định nghĩa, sau đó mở một phiên shell mới. Tất cả các công cụ như `docker`, `psql`, `pgcli` sẽ có sẵn trong PATH chỉ trong phiên làm việc này, và không ảnh hưởng đến các cài đặt trên toàn hệ thống (system-wide).

## Two Ways to Use nix-shell / Hai cách sử dụng nix-shell

### Interactive Development / Phát triển tương tác

For the best development experience, we recommend interactive mode / Để có trải nghiệm development tốt nhất, khuyên dùng interactive mode:

```bash
# Enter Nix shell environment / Vào Nix shell environment
# nix-shell --run "echo 'Nix shell is working!'" 
nix-shell

# Now you have all tools available / Bây giờ bạn có tất cả tools available
# And can run multiple commands / Và có thể chạy multiple commands:
docker-compose up -d postgres-dev
pgcli -h localhost -p 5432 -U user -d postgres_dev_db
docker-compose logs -f
```

**Advantages of Interactive Mode / Ưu điểm của chế độ Interactive:**

- No need to reload the environment for each command / Không cần tải lại môi trường cho mỗi command
- Faster execution because the environment is only set up once / Thực thi nhanh hơn vì môi trường chỉ thiết lập 1 lần
- Can use shell history and aliases / Có thể sử dụng lịch sử lệnh (shell history) và aliases
- Better development experience with a persistent session / Trải nghiệm phát triển tốt hơn nhờ phiên làm việc liên tục

### Script Automation  / Tự động hóa Script

For automated tasks and scripts, use `--run` mode / Cho automated tasks và scripts, sử dụng `--run` mode:

```bash
# Run single command / Chạy single command
nix-shell --run "docker-compose ps"

# Run complex command with bash / Chạy câu lệnh phức tạp với bash
nix-shell --run "docker-compose up -d && docker-compose logs -f postgres-dev"
```

This is exactly how our `scripts/dev.sh` script works - each function call uses `nix-shell --run` to ensure environment consistency / Đây chính là cách script `scripts/dev.sh` hoạt động - mỗi lần gọi hàm đều sử dụng `nix-shell --run` để đảm bảo môi trường nhất quán.

## Recommended Daily Workflow / Quy trình làm việc hàng ngày được khuyến nghị

**Recommended Development Approach / Cách tiếp cận phát triển được khuyến nghị:**

```bash
# Step 1: Enter interactive shell / Bước 1: Vào interactive shell
nix-shell

source ./.env.dev

# Step 2: Connect and work(within nix-shell) / Bước 4: Kết nối và làm việc(trong nix-shell)
./scripts/dev.sh              # Show all commands and usage
./scripts/dev.sh start-db     # Start PostgreSQL
./scripts/dev.sh start-admin  # Start with web interface
./scripts/dev.sh connect      # Connect to database
./scripts/dev.sh status       # Show service status
```

**Why this approach is effective / Tại sao cách tiếp cận này hiệu quả:**

In interactive mode, you benefit from all environment variables and aliases defined in `shell.nix`.
For example, instead of typing `pgcli -h localhost -p 5432 -U developer -d myapp_dev` each time, you just need to run `pgcli-dev`.
The shell also displays a custom prompt to remind you that you're inside a Nix environment.

Ở chế độ interactive, bạn được sử dụng tất cả biến môi trường và alias được khai báo trong shell.nix.
Ví dụ, thay vì phải gõ `pgcli -h localhost -p 5432 -U developer -d myapp_dev` mỗi lần, bạn chỉ cần chạy `pgcli-dev`.
Shell cũng hiển thị một prompt tùy chỉnh để nhắc bạn rằng bạn đang ở trong môi trường Nix.

### Starting the Environment / Khởi động môi trường

```bash
# Start database only / Khởi động chỉ database
./scripts/dev.sh start-db

# Or start database + pgAdmin GUI / Hoặc khởi động database + pgAdmin GUI
./scripts/dev.sh start-admin
```

**What happens when you run this / Điều gì xảy ra khi chạy lệnh này:**

1. **Nix environment check / Nix kiểm tra môi trường:** Nix ensures all required tools are available (docker, PostgreSQL client, pgcli, etc.) / Nix đảm bảo tất cả công cụ cần thiết đều có sẵn (docker, PostgreSQL client, pgcli, v.v.)
2. **Docker starts PostgreSQL / Docker khởi động PostgreSQL:** The PostgreSQL container is pulled (if not already) and started / Container PostgreSQL được tải về (nếu chưa có) và khởi động
3. **Database initialization / Khởi tạo database:** On first run, PostgreSQL executes `01-init-database.sql` to create the schema and seed sample data / Ở lần chạy đầu tiên, PostgreSQL sẽ thực thi `01-init-database.sql` để tạo schema và data mẫu
4. **Health check:** The system waits for PostgreSQL to be ready to accept connections before reporting success / Hệ thống chờ đến khi PostgreSQL sẵn sàng nhận kết nối rồi mới báo thành công

### Connecting and Working with Database / Kết nối và làm việc với Database

```bash
# Connect using pgcli (a nice CLI with syntax highlighting) / Kết nối bằng pgcli (CLI đẹp với syntax highlighting)
./scripts/dev.sh  connect

# Check service status / Xem trạng thái services
./scripts/dev.sh  status

# View realtime logs / Xem logs realtime
./scripts/dev.sh  logs
```

**In pgcli, you can try these queries / Trong pgcli, bạn có thể thử các query sau:**

```sql
-- List all tables / Xem tất cả tables
\dt app_schema.*

-- Query users  / Truy vấn users
SELECT username, email, full_name, created_at 
FROM app_schema.users;

-- Query published posts  / Truy vấn bài viết đã publish
SELECT title, author_name, published_at 
FROM app_schema.published_posts;

-- Full-text search example / Tìm kiếm full-text
SELECT title, content 
FROM app_schema.posts 
WHERE to_tsvector('english', title || ' ' || COALESCE(content, '')) 
      @@ to_tsquery('english', 'welcome');
```

### Data Management / Quản lý dữ liệu

```bash
# Backup database  / Sao lưu database
./scripts/dev.sh  backup

# Reset database (delete all data and reinitialize) / Reset database (xóa tất cả data và khởi tạo lại)
./scripts/dev.sh  reset

# Stop all services /  Dừng tất cả services
./scripts/dev.sh  stop
```

## Best Practices / Thực hành tốt nhất

### Database Schema Design / Thiết kế database

1. **Always use transactions / Luôn sử dụng transactions** for multiple operations / cho các thao tác nhiều bước
2. **Index wisely / Tạo index hợp lý** — avoid creating unnecessary indexes / tránh tạo quá nhiều index không cần thiết
3. **Use constraints / Sử dụng constraints** to ensure data integrity / để đảm bảo tính toàn vẹn dữ liệu
4. **Normalize appropriately / Normalize hợp lý*** — balance normalization with performance / cân bằng giữa normalization và hiệu năng

### Development Workflow / Quy Trình Phát Triển

1. **Commit schema changes / vào version control** to version control / vào version control
2. **Use migrations / Sử dụng migrations** for production deployments / khi triển khai lên production
3. **Test with production-like data / Test với dữ liệu gần giống production** volume / về số lượng và phân bố
4. **Monitor query performance / Theo dõi hiệu năng truy vấn** regularly / thường xuyên

### Security Considerations / Bảo mật

1. **Never commit passwords / Không commit mật khẩu** to version control / vào version control
2. **Use environment variables / Dùng environment variables** for sensitive data / cho dữ liệu nhạy cảm
3. **Limit database user permissions / Giới hạn quyền truy cập của user database** in production / trong production
4. **Have a regular backup strategy / Thiết lập chiến lược backup định kỳ** and test the restore process / và kiểm tra quá trình restore

## Scaling Up / Mở rộng

As the project grows, you can / Khi dự án phát triển, bạn có thể:

1. Add **Redis** for caching / Thêm **Redis** để caching
2. Configure **connection pooling** / Cấu hình **connection pooling**
3. Set up **read replicas** for performance / Thiết lập **read replicas** để cải thiện hiệu năng
4. Implement **database sharding** for large-scale applications / Áp dụng **database sharding** cho hệ thống lớn
5. Add **monitoring** using tools like Grafana + Prometheus / Thêm **monitoring** với Grafana + Prometheus

---

## Conclusion / Kết luận

This setup provides a solid foundation for developing applications with PostgreSQL. The combination of Nix, Docker, and automation scripts enables any developer to set up the environment quickly and become productive immediately.

Cấu hình này cung cấp một nền tảng vững chắc cho việc phát triển ứng dụng sử dụng PostgreSQL. Sự kết hợp giữa Nix, Docker và các script tự động hóa giúp bất kỳ developer nào cũng có thể thiết lập môi trường nhanh chóng và bắt đầu làm việc hiệu quả ngay lập tức.

## License

See the [LICENSE](LICENSE.md) file for license rights and limitations (MIT).
