-- 06-data-type-showcase.sql
-- PostgreSQL Data Type Showcase Database
-- Comprehensive coverage of all PostgreSQL data types for testing

\echo '=========================================='
\echo 'Creating Data Type Showcase Database'
\echo '=========================================='

-- Connect to postgres database to create new database
\c postgres postgres;

-- Create the showcase database
CREATE DATABASE data_type_showcase
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

-- Create a user for data type testing
CREATE USER datatype_user WITH
    LOGIN
    NOSUPERUSER
    INHERIT
    NOCREATEDB
    NOCREATEROLE
    NOREPLICATION
    PASSWORD 'datatype_user';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE data_type_showcase TO datatype_user;
GRANT CONNECT ON DATABASE data_type_showcase TO datatype_user;

-- Switch to the showcase database
\c data_type_showcase postgres;

-- Create schema for data type testing
CREATE SCHEMA data_types AUTHORIZATION datatype_user;
GRANT ALL ON SCHEMA data_types TO datatype_user;

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "hstore";
CREATE EXTENSION IF NOT EXISTS "ltree";

\echo 'Creating comprehensive data type tables...'

-- Main data types table with all PostgreSQL data types
CREATE TABLE data_types.all_data_types (
    -- Primary key and identifiers
    id SERIAL PRIMARY KEY,
    
    -- Numeric types
    tiny_int SMALLINT,
    regular_int INTEGER,
    big_int BIGINT,
    decimal_number DECIMAL(10,2),
    numeric_number NUMERIC(15,5),
    real_number REAL,
    double_number DOUBLE PRECISION,
    serial_number SERIAL,
    big_serial_number BIGSERIAL,
    
    -- Character/String types
    fixed_char CHAR(10),
    variable_char VARCHAR(255),
    unlimited_text TEXT,
    
    -- Binary data
    binary_data BYTEA,
    
    -- Date and Time types
    date_only DATE,
    time_only TIME,
    time_with_tz TIME WITH TIME ZONE,
    timestamp_val TIMESTAMP,
    timestamp_with_tz TIMESTAMPTZ,
    time_interval INTERVAL,
    
    -- Boolean type
    is_active BOOLEAN,
    
    -- Money type
    price MONEY,
    
    -- UUID type
    unique_id UUID DEFAULT uuid_generate_v4(),
    
    -- JSON types
    json_data JSON,
    jsonb_data JSONB,
    
    -- Array types
    integer_array INTEGER[],
    text_array TEXT[],
    date_array DATE[],
    
    -- Range types
    int_range INT4RANGE,
    big_int_range INT8RANGE,
    numeric_range NUMRANGE,
    timestamp_range TSRANGE,
    timestamp_tz_range TSTZRANGE,
    date_range DATERANGE,
    
    -- Geometric types
    point_data POINT,
    line_data LINE,
    line_segment LSEG,
    box_data BOX,
    path_data PATH,
    polygon_data POLYGON,
    circle_data CIRCLE,
    
    -- Network address types
    ip_address INET,
    cidr_network CIDR,
    mac_address MACADDR,
    mac_address8 MACADDR8,
    
    -- Bit string types
    fixed_bit BIT(8),
    variable_bit VARBIT(20),
    
    -- Text search types
    tsvector_data TSVECTOR,
    tsquery_data TSQUERY,
    
    -- XML type
    xml_data XML,
    
    -- Key-value store type
    hstore_data HSTORE,
    
    -- Label tree type
    ltree_path LTREE,
    
    -- Enumeration type (will be defined separately)
    -- enum_example color_enum,
    
    -- Created/Updated timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create an enumeration type
CREATE TYPE data_types.priority_level AS ENUM ('low', 'medium', 'high', 'critical');
CREATE TYPE data_types.status_type AS ENUM ('active', 'inactive', 'pending', 'archived');

-- Add enum columns to the main table
ALTER TABLE data_types.all_data_types 
ADD COLUMN priority data_types.priority_level,
ADD COLUMN status data_types.status_type;

-- Create a composite type
CREATE TYPE data_types.address_type AS (
    street VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    zip_code VARCHAR(10),
    country VARCHAR(50)
);

-- Create a table using composite types
CREATE TABLE data_types.customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    home_address data_types.address_type,
    billing_address data_types.address_type,
    phone_numbers TEXT[],
    preferences JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create a table for edge cases and special values
CREATE TABLE data_types.edge_cases (
    id SERIAL PRIMARY KEY,
    
    -- Null values
    null_integer INTEGER,
    null_text TEXT,
    null_date DATE,
    
    -- Extreme values
    max_bigint BIGINT,
    min_bigint BIGINT,
    max_numeric NUMERIC(1000,0),
    very_long_text TEXT,
    
    -- Unicode and special characters
    unicode_text TEXT,
    emoji_text TEXT,
    special_chars TEXT,
    
    -- Empty values
    empty_string VARCHAR(100),
    empty_array INTEGER[],
    
    -- Complex JSON
    complex_json JSONB
);

\echo 'Inserting comprehensive sample data...'

-- Insert sample data covering all data types
INSERT INTO data_types.all_data_types (
    tiny_int, regular_int, big_int, decimal_number, numeric_number, real_number, double_number,
    fixed_char, variable_char, unlimited_text,
    binary_data,
    date_only, time_only, time_with_tz, timestamp_val, timestamp_with_tz, time_interval,
    is_active, price, json_data, jsonb_data,
    integer_array, text_array, date_array,
    int_range, numeric_range, date_range,
    point_data, line_segment, box_data, circle_data,
    ip_address, cidr_network, mac_address,
    fixed_bit, variable_bit,
    tsvector_data, xml_data, hstore_data, ltree_path,
    priority, status
) VALUES 
(
    32767, 2147483647, 9223372036854775807, 99999.99, 123456.78901, 3.14159, 2.718281828459045,
    'FIXED_CHAR', 'Variable length string with special chars: àáâãäåæç', 'This is unlimited text that can be very long and contain any characters including newlines and tabs.',
    '\x48656C6C6F20576F726C64'::bytea,
    '2024-12-25', '14:30:00', '14:30:00+05:30', '2024-12-25 14:30:00', '2024-12-25 14:30:00+00', '1 year 2 months 3 days 4 hours 5 minutes 6 seconds',
    true, '$1,234.56', '{"name": "John", "age": 30}', '{"name": "John", "age": 30, "skills": ["PostgreSQL", "Python"]}',
    '{1,2,3,4,5}', '{"apple","banana","cherry"}', '{"2024-01-01","2024-06-15","2024-12-31"}',
    '[1,10]', '[0.0,100.5]', '[2024-01-01,2024-12-31)',
    '(1,2)', '[(0,0),(3,4)]', '((0,0),(3,4))', '<(2,3),5>',
    '192.168.1.1', '192.168.0.0/24', '08:00:2b:01:02:03',
    B'10101010', B'11110000111100001111',
    'the quick brown fox', '<person><name>John</name><age>30</age></person>', 'name=>John, age=>30', 'root.level1.level2',
    'high', 'active'
),
(
    -32768, -2147483648, -9223372036854775808, -99999.99, -123456.78901, -3.14159, -2.718281828459045,
    '          ', '', '',
    null,
    '1970-01-01', '00:00:00', '23:59:59-12:00', '1970-01-01 00:00:00', '2038-01-19 03:14:07+00', '-1 second',
    false, '$0.00', '[]', '{}',
    '{}', '{}', '{}',
    'empty', 'empty', 'empty',
    '(0,0)', '[(0,0),(0,0)]', '((0,0),(0,0))', '<(0,0),0>',
    '127.0.0.1', '127.0.0.0/8', '00:00:00:00:00:00',
    B'00000000', B'0',
    '', '<root/>', '', 'root',
    'low', 'inactive'
),
(
    null, null, null, null, null, null, null,
    null, null, null,
    null,
    null, null, null, null, null, null,
    null, null, null, null,
    null, null, null,
    null, null, null,
    null, null, null, null,
    null, null, null,
    null, null,
    null, null, null, null,
    null, null
);

-- Insert customer data with composite types
INSERT INTO data_types.customers (name, email, home_address, billing_address, phone_numbers, preferences) VALUES
('Alice Johnson', 'alice@example.com', 
 ROW('123 Main St', 'Anytown', 'CA', '12345', 'USA')::data_types.address_type,
 ROW('456 Business Ave', 'Commerce City', 'CA', '67890', 'USA')::data_types.address_type,
 '{"+1-555-0123","+1-555-0124"}',
 '{"newsletter": true, "theme": "dark", "language": "en"}'
),
('Bob Smith', 'bob@example.com',
 ROW('789 Oak Dr', 'Smallville', 'TX', '54321', 'USA')::data_types.address_type,
 ROW('789 Oak Dr', 'Smallville', 'TX', '54321', 'USA')::data_types.address_type,
 '{"+1-555-0200"}',
 '{"newsletter": false, "theme": "light", "timezone": "America/Chicago"}'
);

-- Insert edge case data
INSERT INTO data_types.edge_cases (
    null_integer, null_text, null_date,
    max_bigint, min_bigint, max_numeric, very_long_text,
    unicode_text, emoji_text, special_chars,
    empty_string, empty_array,
    complex_json
) VALUES
(
    null, null, null,
    9223372036854775807, -9223372036854775808, 
    123456789012345678901234567890123456789012345678901234567890,
    repeat('This is a very long text string that will be repeated many times to test large text handling. ', 100),
    'Iñtërnâtiônàlizætiøn and Ǔnicødé tëst with various âccénts and spëçial çhαracters ñoña',
    '😀 🎉 🚀 🌟 ⭐ 🎯 💡 🔥 ✨ 🎊 Hello World with Emojis! 🌍 🌎 🌏',
    E'Special chars: \n\t\r\b\f\\\'\"`,;[]{}()!@#$%^&*()+=<>?/|~',
    '',
    '{}',
    '{
        "nested": {
            "deep": {
                "array": [1,2,3,{"key": "value"}],
                "boolean": true,
                "null_value": null,
                "number": 42.42
            }
        },
        "simple_array": [1,2,3,4,5],
        "mixed_array": [1, "two", true, null, {"nested": "object"}]
    }'
);

-- Create indexes for performance testing
CREATE INDEX idx_all_data_types_regular_int ON data_types.all_data_types(regular_int);
CREATE INDEX idx_all_data_types_text ON data_types.all_data_types USING gin(to_tsvector('english', variable_char));
CREATE INDEX idx_all_data_types_jsonb ON data_types.all_data_types USING gin(jsonb_data);
CREATE INDEX idx_all_data_types_date ON data_types.all_data_types(date_only);
CREATE INDEX idx_customers_email ON data_types.customers(email);

-- Create views for common queries
CREATE VIEW data_types.active_records AS
SELECT * FROM data_types.all_data_types WHERE is_active = true;

CREATE VIEW data_types.recent_records AS
SELECT * FROM data_types.all_data_types WHERE created_at >= CURRENT_DATE - INTERVAL '30 days';

-- Grant permissions to datatype_user
GRANT ALL ON ALL TABLES IN SCHEMA data_types TO datatype_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA data_types TO datatype_user;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA data_types TO datatype_user;

\echo 'Creating test functions and procedures...'

-- Create a function that exercises various data types
CREATE OR REPLACE FUNCTION data_types.test_data_types()
RETURNS TABLE(
    test_name TEXT,
    test_result TEXT,
    data_type TEXT,
    sample_value TEXT
) 
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'Integer Test'::TEXT,
        CASE WHEN regular_int IS NOT NULL THEN 'PASS' ELSE 'FAIL' END::TEXT,
        'INTEGER'::TEXT,
        regular_int::TEXT
    FROM data_types.all_data_types
    WHERE id = 1
    
    UNION ALL
    
    SELECT 
        'JSON Test'::TEXT,
        CASE WHEN jsonb_data IS NOT NULL THEN 'PASS' ELSE 'FAIL' END::TEXT,
        'JSONB'::TEXT,
        jsonb_data::TEXT
    FROM data_types.all_data_types
    WHERE id = 1
    
    UNION ALL
    
    SELECT 
        'Array Test'::TEXT,
        CASE WHEN array_length(integer_array, 1) > 0 THEN 'PASS' ELSE 'FAIL' END::TEXT,
        'INTEGER[]'::TEXT,
        integer_array::TEXT
    FROM data_types.all_data_types
    WHERE id = 1;
END;
$$;

\echo ''
\echo '=========================================='
\echo 'Data Type Showcase Database Created!'
\echo '=========================================='
\echo 'Database: data_type_showcase'
\echo 'Schema: data_types'
\echo 'User: datatype_user / datatype_user'
\echo 'Tables created:'
\echo '  - all_data_types (comprehensive data type coverage)'
\echo '  - customers (composite types example)'
\echo '  - edge_cases (null values, extremes, Unicode)'
\echo 'Data types covered:'
\echo '  ✓ All numeric types (SMALLINT to NUMERIC)'
\echo '  ✓ All text types (CHAR, VARCHAR, TEXT)'
\echo '  ✓ All date/time types including intervals'
\echo '  ✓ JSON and JSONB with complex data'
\echo '  ✓ Arrays of various types'
\echo '  ✓ Range types for all numeric/date types'
\echo '  ✓ Geometric types (POINT, POLYGON, etc.)'
\echo '  ✓ Network types (INET, CIDR, MACADDR)'
\echo '  ✓ Binary data (BYTEA)'
\echo '  ✓ UUID, XML, HSTORE, LTREE'
\echo '  ✓ Enums and composite types'
\echo '  ✓ Edge cases and special values'
\echo '=========================================='