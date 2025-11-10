-- Database initialization script / Script khởi tạo cơ sở dữ liệu
-- Chạy tự động khi PostgreSQL container khởi động lần đầu

-- Create necessary extensions / Tạo extension cần thiết
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";  -- Used for generating UUID values
CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- Used for password encryption
CREATE EXTENSION IF NOT EXISTS "pg_trgm";    -- Used for improved text search

-- Create application schema / Tạo schema cho ứng dụng
CREATE SCHEMA IF NOT EXISTS app_schema;

-- Create users table / Tạo bảng users
CREATE TABLE IF NOT EXISTS app_schema.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,  -- Luôn hash password, không bao giờ lưu plain text
    full_name VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create posts table / Tạo bảng posts
CREATE TABLE IF NOT EXISTS app_schema.posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    content TEXT,
    author_id UUID NOT NULL REFERENCES app_schema.users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    published_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance optimization / Tạo index để tối ưu hiệu suất
CREATE INDEX IF NOT EXISTS idx_users_email ON app_schema.users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON app_schema.users(username);
CREATE INDEX IF NOT EXISTS idx_posts_author ON app_schema.posts(author_id);
CREATE INDEX IF NOT EXISTS idx_posts_status ON app_schema.posts(status);
CREATE INDEX IF NOT EXISTS idx_posts_published_at ON app_schema.posts(published_at) WHERE published_at IS NOT NULL;

-- Create index for full-text search / Tạo index cho full-text search
CREATE INDEX IF NOT EXISTS idx_posts_title_content_search 
    ON app_schema.posts 
    USING gin(to_tsvector('english', title || ' ' || COALESCE(content, '')));

-- Function to automatically update updated_at / Function để tự động cập nhật updated_at
CREATE OR REPLACE FUNCTION app_schema.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for automatic updated_at updates / Tạo trigger để tự động cập nhật updated_at
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON app_schema.users 
    FOR EACH ROW EXECUTE FUNCTION app_schema.update_updated_at_column();

CREATE TRIGGER update_posts_updated_at 
    BEFORE UPDATE ON app_schema.posts 
    FOR EACH ROW EXECUTE FUNCTION app_schema.update_updated_at_column();

-- Insert 20 users  / Thêm 20 người dùng
DO $$
DECLARE
    i INT;
BEGIN
    FOR i IN 1..20 LOOP
        INSERT INTO app_schema.users (username, email, password_hash, full_name, is_active)
        VALUES (
            'user_' || i,
            'user' || i || '@example.com',
            crypt('password123', gen_salt('bf')),
            'User Number ' || i,
            CASE WHEN i % 5 = 0 THEN FALSE ELSE TRUE END  -- Every 5th user will be inactive
        )
        ON CONFLICT (username) DO NOTHING;
    END LOOP;
END $$;

-- Insert 100 posts for each user / Thêm 100 post cho mỗi user
DO $$
DECLARE
    user_record RECORD;
    post_num INT;
    random_status TEXT;
    random_days INT;
BEGIN
    FOR user_record IN SELECT id, username FROM app_schema.users LOOP
        FOR post_num IN 1..100 LOOP

            -- Choose a random post status
            random_status := CASE 
                WHEN random() < 0.7 THEN 'published'
                WHEN random() < 0.9 THEN 'draft'
                ELSE 'archived'
            END;
            
            -- Pick a random day in the past 365 days
            random_days := floor(random() * 365)::INT;
            
            INSERT INTO app_schema.posts (title, content, author_id, status, published_at, created_at)
            VALUES (
                'Post #' || post_num || ' by ' || user_record.username,
                'This is the content of post number ' || post_num || '. ' ||
                'Written by ' || user_record.username || '. ' ||
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. ' ||
                'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ' ||
                'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.',
                user_record.id,
                random_status,
                CASE 
                    WHEN random_status = 'published' 
                    THEN CURRENT_TIMESTAMP - (random_days || ' days')::INTERVAL
                    ELSE NULL
                END,
                CURRENT_TIMESTAMP - (random_days || ' days')::INTERVAL
            );
        END LOOP;
    END LOOP;
END $$;

-- Create view for easier querying / Tạo view để dễ dàng query
CREATE OR REPLACE VIEW app_schema.published_posts AS
SELECT 
    p.id,
    p.title,
    p.content,
    u.username as author_username,
    u.full_name as author_name,
    p.published_at,
    p.created_at,
    p.updated_at
FROM app_schema.posts p
JOIN app_schema.users u ON p.author_id = u.id
WHERE p.status = 'published'
  AND p.published_at IS NOT NULL
ORDER BY p.published_at DESC;

-- Create statistics view / Tạo view thống kê
CREATE OR REPLACE VIEW app_schema.user_stats AS
SELECT 
    u.id,
    u.username,
    u.full_name,
    u.is_active,
    COUNT(p.id) as total_posts,
    COUNT(CASE WHEN p.status = 'published' THEN 1 END) as published_posts,
    COUNT(CASE WHEN p.status = 'draft' THEN 1 END) as draft_posts,
    COUNT(CASE WHEN p.status = 'archived' THEN 1 END) as archived_posts,
    MAX(p.published_at) as last_published_at
FROM app_schema.users u
LEFT JOIN app_schema.posts p ON u.id = p.author_id
GROUP BY u.id, u.username, u.full_name, u.is_active
ORDER BY total_posts DESC;