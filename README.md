# PostgreSQL + Docker + Nix Development Environment

## Overview

This project uses **nix-shell** for dependency management and Docker to run PostgreSQL, creating a completely reproducible and consistent development environment across all machines. We choose nix-shell over nix develop to ensure the best compatibility and doesn't require flake support.

## Why nix-shell

**Stability & Compatibility:**

- Works with any Nix installation, no need to enable experimental features
- Backward compatible with legacy Nix tooling and scripts
- Widely used in the industry, with plenty of documentation and examples

**Simplicity:**

- No need to understand the complex flake ecosystem to customize
- Simple and easy-to-maintain configuration file
- Easier onboarding for new developers with Nix

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

### Why This Architecture Works

**Separation of Concerns:**

- **Nix** manages tools and dependencies on the host machine
- **Docker** isolates the database and ensures portability
- **Scripts** automate common workflows

**Reproducibility:**

- Every developer will have the exact same version of PostgreSQL, client tools, and environment
- The database schema is initialized automatically and consistently across machines

## First-time Setup

### 1. Install Prerequisites

**macOS:**

```bash
# Install Nix using the Determinate Nix Installer (recommended)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Install Docker Desktop
brew install --cask docker
```

**Linux:**

```bash
# Install Nix using the Determinate Nix Installer (recommended)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Install Docker (Ubuntu/Debian)
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER  # Add the user to the docker group
# Log out and log back in for the group change to take effect
```

### 2. Clone and Setup Project

```bash
# Clone repository
git clone <your-repo-url>
cd your-project-name

# Make scripts/dev.sh  executable
chmod +x ./scripts/dev.sh 

# Create init-scripts directory if not exists
mkdir -p init-scripts

# Test Nix shell environment
-shell --run "echo 'Nix shell is working!'"
```

**Nix-shell workflow explanation:**

When you run `nix-shell`, Nix will read the `shell.nix` file, create an isolated environment with all defined dependencies, then spawn a new shell session. All tools like `docker`, `psql`, `pgcli` will be available in PATH only within this session, without affecting system-wide installations.

## Two Ways to Use nix-shell

### Interactive Development

For the best development experience, we recommend interactive mode:

```bash
# Enter Nix shell environment
# nix-shell --run "echo 'Nix shell is working!'" 
nix-shell

# Now you have all tools available
# And can run multiple commands
docker-compose up -d postgres-dev
pgcli -h localhost -p 5432 -U user -d postgres_dev_db
docker-compose logs -f
```

**Advantages of Interactive Mode:**

- No need to reload the environment for each command
- Faster execution because the environment is only set up once
- Can use shell history and aliases
- Better development experience with a persistent session

### Script Automation

For automated tasks and scripts, use `--run` mode:

```bash
# Run single command
nix-shell --run "docker-compose ps"

# Run complex command with bash
nix-shell --run "docker-compose up -d && docker-compose logs -f postgres-dev"
```

This is exactly how our `scripts/dev.sh` script works - each function call uses `nix-shell --run` to ensure environment consistency.

## Recommended Daily Workflow

**Recommended Development Approach:**

```bash
# Step 1: Enter interactive shell
nix-shell

source ./.env.dev

# Step 2: Connect and work(within nix-shell)
./scripts/dev.sh              # Show all commands and usage
./scripts/dev.sh start-db     # Start PostgreSQL
./scripts/dev.sh start-admin  # Start with web interface
./scripts/dev.sh connect      # Connect to database
./scripts/dev.sh status       # Show service status
```

**Why this approach is effective:**

In interactive mode, you benefit from all environment variables and aliases defined in `shell.nix`.
For example, instead of typing `pgcli -h localhost -p 5432 -U developer -d myapp_dev` each time, you just need to run `pgcli-dev`.
The shell also displays a custom prompt to remind you that you're inside a Nix environment.

### Starting the Environment

```bash
# Start database only
./scripts/dev.sh start-db

# Or start database + pgAdmin GUI
./scripts/dev.sh start-admin
```

**What happens when you run this:**

1. **Nix environment check:** Nix ensures all required tools are available (docker, PostgreSQL client, pgcli, etc.)
2. **Docker starts PostgreSQL:** The PostgreSQL container is pulled (if not already) and started
3. **Database initialization:** On first run, PostgreSQL executes `01-init-database.sql` to create the schema and seed sample data
4. **Health check:** The system waits for PostgreSQL to be ready to accept connections before reporting success

### Connecting and Working with Database

```bash
# Connect using pgcli (a nice CLI with syntax highlighting)
./scripts/dev.sh  connect

# Check service status
./scripts/dev.sh  status

# View realtime logs
./scripts/dev.sh  logs
```

**In pgcli, you can try these queries:**

```sql
-- List all tables
\dt app_schema.*

-- Query users
SELECT username, email, full_name, created_at 
FROM app_schema.users;

-- Query published posts
SELECT title, author_name, published_at 
FROM app_schema.published_posts;

-- Full-text search example
SELECT title, content 
FROM app_schema.posts 
WHERE to_tsvector('english', title || ' ' || COALESCE(content, '')) 
      @@ to_tsquery('english', 'welcome');
```

### Data Management

```bash
# Backup database
./scripts/dev.sh  backup

# Reset database (delete all data and reinitialize)
./scripts/dev.sh  reset

# Stop all services
./scripts/dev.sh  stop
```

## Best Practices

### Database Schema Design

1. **Always use transactions** for multiple operations
2. **Index wisely** — avoid creating unnecessary indexes
3. **Use constraints** to ensure data integrity
4. **Normalize appropriately** — balance normalization with performance

### Development Workflow

1. **Commit schema changes** to version control
2. **Use migrations** for production deployments
3. **Test with production-like data** volume
4. **Monitor query performance** regularly

### Security Considerations

1. **Never commit passwords** to version control
2. **Use environment variables** for sensitive data
3. **Limit database user permissions** in production
4. **Have a regular backup strategy** and test the restore process

## Scaling Up

As the project grows, you can:

1. Add **Redis** for caching
2. Configure **connection pooling**
3. Set up **read replicas** for performance
4. Implement **database sharding** for large-scale applications
5. Add **monitoring** using tools like Grafana + Prometheus

---

## Conclusion

This setup provides a solid foundation for developing applications with PostgreSQL. The combination of Nix, Docker, and automation scripts enables any developer to set up the environment quickly and become productive immediately.

## License

See the [LICENSE](LICENSE.md) file for license rights and limitations (MIT).
