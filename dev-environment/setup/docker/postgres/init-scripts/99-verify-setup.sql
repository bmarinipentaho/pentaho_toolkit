-- 99-verify-setup.sql
-- Verify that the Pentaho PostgreSQL setup completed successfully

\echo '=========================================='
\echo 'Verifying Pentaho PostgreSQL Setup'
\echo '=========================================='

-- List all databases
\echo 'Databases:'
SELECT datname as "Database Name", 
       pg_encoding_to_char(encoding) as "Encoding",
       datcollate as "Collation"
FROM pg_database 
WHERE datname IN ('postgres', 'hibernate', 'quartz', 'jackrabbit')
ORDER BY datname;

-- List all users
\echo ''
\echo 'Users:'
SELECT usename as "Username", 
       CASE WHEN usesuper THEN 'Yes' ELSE 'No' END as "Superuser",
       CASE WHEN usecreatedb THEN 'Yes' ELSE 'No' END as "Create DB"
FROM pg_user 
WHERE usename IN ('postgres', 'hibuser', 'pentaho_user', 'jcr_user')
ORDER BY usename;

-- Check schemas in hibernate database
\c hibernate hibuser;
\echo ''
\echo 'Schemas in hibernate database:'
SELECT schema_name as "Schema Name", schema_owner as "Owner"
FROM information_schema.schemata 
WHERE schema_name IN ('public', 'pentaho_dilogs', 'pentaho_operations_mart')
ORDER BY schema_name;

-- Check table counts
\echo ''
\echo 'Table counts by schema:'
SELECT 
    schemaname as "Schema",
    COUNT(*) as "Table Count"
FROM pg_tables 
WHERE schemaname IN ('pentaho_dilogs', 'pentaho_operations_mart')
GROUP BY schemaname
ORDER BY schemaname;

-- Switch back to postgres database
\c postgres postgres;

-- Show connection info
\echo ''
\echo '=========================================='
\echo 'Setup Complete!'
\echo '=========================================='
\echo 'Connection Details:'
\echo '  Host: localhost'
\echo '  Port: 5432'
\echo '  Databases:'
\echo '    - hibernate (hibuser/password) - Main repository'
\echo '    - quartz (pentaho_user/password) - Scheduler'
\echo '    - jackrabbit (jcr_user/password) - Content repo'
\echo '  pgAdmin: http://localhost:8888'
\echo '  pgAdmin Login: admin@pentaho.com / admin'
\echo '=========================================='