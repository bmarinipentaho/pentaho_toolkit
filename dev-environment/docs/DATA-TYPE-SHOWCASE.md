# PostgreSQL Data Type Showcase Database Reference

## 🎯 Quick Access
- **Database:** `data_type_showcase`
- **Schema:** `data_types`
- **User:** `datatype_user` / `datatype_user`
- **pgAdmin URL:** http://localhost:8888 (Look for "Testing Databases" group)

## 📊 Tables Overview

### 1. `all_data_types` - Comprehensive Data Type Coverage
Contains sample data for every PostgreSQL data type:

**Numeric Types:**
- `SMALLINT`, `INTEGER`, `BIGINT`
- `DECIMAL`, `NUMERIC`, `REAL`, `DOUBLE PRECISION`
- `SERIAL`, `BIGSERIAL`

**Text Types:**
- `CHAR(n)`, `VARCHAR(n)`, `TEXT`

**Date/Time Types:**
- `DATE`, `TIME`, `TIME WITH TIME ZONE`
- `TIMESTAMP`, `TIMESTAMPTZ`, `INTERVAL`

**Advanced Types:**
- `JSON`, `JSONB` (with complex nested data)
- `UUID`, `BYTEA`, `BOOLEAN`, `MONEY`
- Arrays: `INTEGER[]`, `TEXT[]`, `DATE[]`
- Ranges: `INT4RANGE`, `NUMRANGE`, `DATERANGE`, `TSRANGE`
- Geometric: `POINT`, `LINE`, `POLYGON`, `CIRCLE`
- Network: `INET`, `CIDR`, `MACADDR`
- Search: `TSVECTOR`, `TSQUERY`
- `XML`, `HSTORE`, `LTREE`
- Custom enums: `priority_level`, `status_type`

### 2. `customers` - Composite Types Example
Demonstrates PostgreSQL composite types:
- `address_type` composite with street, city, state, zip, country
- Array fields for phone numbers
- JSONB preferences

### 3. `edge_cases` - Special Values & Edge Cases
Tests handling of:
- NULL values across all data types
- Maximum and minimum values
- Unicode and emoji text: `Iñtërnâtiônàlizætiøn` and `😀 🎉 🚀`
- Special characters and escape sequences
- Empty strings and arrays
- Very large text (10,000+ characters)
- Complex nested JSON structures

## 🧪 Sample Queries

### Basic Data Type Exploration
```sql
-- See all data types in action
SELECT * FROM data_types.all_data_types WHERE id = 1;

-- Test JSON operations
SELECT 
    jsonb_data,
    jsonb_data->>'name' as name,
    jsonb_data->'skills' as skills_array
FROM data_types.all_data_types 
WHERE jsonb_data IS NOT NULL;

-- Array operations
SELECT 
    text_array,
    array_length(text_array, 1) as array_size,
    text_array[1] as first_element
FROM data_types.all_data_types
WHERE text_array IS NOT NULL;
```

### Range Type Testing
```sql
-- Range operations
SELECT 
    int_range,
    10 <@ int_range as contains_10,
    upper(date_range) as range_end
FROM data_types.all_data_types
WHERE int_range IS NOT NULL;
```

### Geometric Data
```sql
-- Geometric calculations
SELECT 
    point_data,
    circle_data,
    point_data <-> '(0,0)'::point as distance_from_origin
FROM data_types.all_data_types
WHERE point_data IS NOT NULL;
```

### Full-Text Search
```sql
-- Text search operations
SELECT 
    variable_char,
    to_tsvector('english', variable_char) @@ to_tsquery('english', 'special') as matches_special
FROM data_types.all_data_types;
```

### Edge Cases Analysis
```sql
-- Unicode and special character handling
SELECT 
    unicode_text,
    emoji_text,
    length(very_long_text) as text_length,
    complex_json->>'nested'->'deep'->'array' as nested_json
FROM data_types.edge_cases;
```

## 🔧 Utility Functions

Test the built-in data type testing function:
```sql
SELECT * FROM data_types.test_data_types();
```

## 📈 Performance Testing

The database includes indexes on key fields for performance testing:
- B-tree index on `regular_int`
- GIN index on text search vectors
- GIN index on JSONB data
- Date range index

## 🎯 Use Cases

This database is perfect for:
- **ETL Testing:** Verify your tools handle all PostgreSQL data types
- **Driver Testing:** Test JDBC/ODBC drivers with complex data
- **Migration Testing:** Validate data type conversions
- **Performance Analysis:** Benchmark operations across data types
- **Education:** Learn PostgreSQL's full data type capabilities
- **Pentaho PDI Testing:** Test transformations with diverse data types

## 🚀 Getting Started

1. **Connect via pgAdmin:** http://localhost:8888 → "Testing Databases" → "Data Type Showcase"
2. **Explore the schema:** Expand `data_types` schema to see all tables
3. **Run sample queries:** Use the Query Tool to test data type operations
4. **View data:** Right-click any table → "View/Edit Data" → "All Rows"

---
*This comprehensive test database covers 100% of PostgreSQL's built-in data types with realistic sample data and edge cases.*