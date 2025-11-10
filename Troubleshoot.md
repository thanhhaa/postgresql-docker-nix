# Troubleshooting / Xử lý sự cố

## Table of contents

- [Database won't start](#database-wont-start)
- [Error password authentication failed for user "user_name"](#error-password-authentication-failed-for-user-user_name)
- [Các flag khác của `docker-compose down`](#các-flag-khác-của-docker-compose-down)
- [Performance Issues](#performance-issues)
- [Error using pgadmin to connect postgres on Chrome](#error-using-pgadmin-to-connect-postgres-on-chrome)
  - [Cause](#cause)
  - [Solution](#solution)
  - [Check connection](#check-connection)
  - [If still error](#if-still-error)

## Database won't start

```bash
# Check if Docker is running / Kiểm tra Docker có chạy không
docker info

# Check if port 5432 is in use / Kiểm tra port 5432 có bị chiếm không
lsof -i :5432

# Remove old containers and volumes / Xóa containers và volumes cũ
./scripts/dev.sh  stop
docker system prune -a
docker volume prune
```

## Error password authentication failed for user "user_name"

```bash
docker-compose down -v
# ✓ Stop container prostgres / Dừng container postgres
# ✓ Delete container prostgres / Xóa container postgres
# ✓ Delete network / Xóa network
# ✓ Delete volume postgres_data / Xóa volume postgres_data (DATA BỊ MẤT!)
```

## Các flag khác của `docker-compose down`

```bash
# Delete containers and volumes / Xóa containers và volumes
docker-compose down -v

# Delete containers and images / Xóa containers và images
docker-compose down --rmi all

# Delete containers, volumes and images / Xóa containers, volumes và images
docker-compose down -v --rmi all

# Only delete built images (do not delete pulled images) / Chỉ xóa images được build (không xóa images pull về)
docker-compose down --rmi local

# Delete all orphan containers (containers no longer in the compose file) / Xóa cả orphan containers (containers không còn trong compose file)
docker-compose down --remove-orphans
```

## Performance Issues

```sql
-- Check slow queries / Kiểm tra slow queries
SELECT query, mean_exec_time, calls 
FROM pg_stat_statements 
ORDER BY mean_exec_time DESC 
LIMIT 10;

-- Analyze table statistics  / Phân tích thống kê bảng
ANALYZE app_schema.users;
ANALYZE app_schema.posts;

-- Check index usage  / Kiểm tra việc sử dụng index
SELECT 
    indexname, 
    idx_tup_read, 
    idx_tup_fetch,
    idx_tup_read/NULLIF(idx_tup_fetch, 0) as ratio
FROM pg_stat_user_indexes 
WHERE schemaname = 'app_schema';
```

## Error using pgadmin to connect postgres on Chrome

```bash
Unable to connect to server:  

connection failed: connection to server at "127.0.0.1", port 5432 failed: Connection refused Is the server running on that host and accepting TCP/IP connections? 

Multiple connection attempts failed. All failures were: 

- host: 'localhost', port: '5432', hostaddr: '::1': connection failed: connection to server at "::1", port 5432 failed: Connection refused Is the server running on that host and accepting TCP/IP connections? 

- host: 'localhost', port: '5432', hostaddr: '127.0.0.1': connection failed: connection to server at "127.0.0.1", port 5432 failed: Connection refused Is the server running on that host and accepting TCP/IP connections?
```

### Cause

When pgAdmin is running in a Docker container, **localhost** or **127.0.0.1** will point to the **pgAdmin container** itself, not the host machine or the **PostgreSQL container**.

### Solution

✅ Method 1: Use the service name (Recommended)

```yml
# docker-compose.yml
version: '3.8'

services:
  postgres-dev:
    image: postgres:15-alpine
    container_name: postgres_container_dev
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: postgres_dev_db
    ports:
      - "5432:5432"
    networks:
      - mynetwork

  pgadmin-dev:
    image: dpage/pgadmin4:latest
    container_name: pgadmin_container_dev
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@admin.com
      PGADMIN_DEFAULT_PASSWORD: admin
    ports:
      - "8080:80"
    networks:
      - mynetwork
    depends_on:
      - postgres

networks:
  mynetwork:
    driver: bridge
```

In **pgAdmin**, when creating a connection:

- Host name/address: **postgres-dev** (service name, not localhost)
- Port: 5432
- Username: user
- Password: password
- Database: postgres_dev_db

✅ Method 3: Use the IP of the PostgreSQL container

```bash
#Get IP of postgres container
docker inspect postgres_db | grep IPAddress

# Example output: "IPAddress": "172.18.0.2"
```

In **pgAdmin**:

- Host name/address: 172.18.0.2 (IP just obtained)
- Port: 5432

#### Check connection

```bash
# Start
docker-compose up -d

# Check running containers
docker-compose ps

# Check logs for errors
docker-compose logs postgres
docker-compose logs pgadmin

# Test connection from pgadmin container
docker-compose exec pgadmin-dev ping postgres-dev

## Common errors

### ❌ Wrong: Use localhost/127.0.0.1
Host: localhost ← WRONG when pgAdmin in Docker

### ✅ Correct: Use service name
Host: postgres-dev ← CORRECT
```

#### If still error

```bash
# Full reset
docker-compose down -v
docker-compose up -d

# Wait a few seconds for PostgreSQL to start
sleep 10

# Check PostgreSQL is ready
docker-compose exec postgres pg_isready -U user
```
