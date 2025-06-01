const { Pool } = require('pg');
const fs = require('fs');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://user:password@database:5432/dynamicsoft'
});

async function migrate() {
  try {
    console.log('Starting database migration...');
    
    // Create users table if not exists
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Insert sample data
    await pool.query(`
      INSERT INTO users (username, email, password_hash) 
      VALUES 
        ('admin', 'admin@dynamicsoft.hr', '$2a$10$example'),
        ('john.doe', 'john@example.com', '$2a$10$example'),
        ('jane.smith', 'jane@example.com', '$2a$10$example')
      ON CONFLICT (username) DO NOTHING
    `);
    
    console.log('Migration completed successfully');
    
    // Create success marker
    fs.writeFileSync('/tmp/migration-success', 'OK');
    
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

migrate();