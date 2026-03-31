# PostgreSQL 14 → 18 Changes & Compatibility Guide

**Note:** This document covers changes from PostgreSQL 14 through 18, including intermediate versions (15, 16, 17).

## Table of Contents
1. [Breaking Changes](#breaking-changes)
2. [Behavioral Changes](#behavioral-changes)
3. [New Features](#new-features)
4. [Performance Improvements](#performance-improvements)
5. [Security Changes](#security-changes)
6. [Deprecations & Removals](#deprecations--removals)
7. [Impact Assessment for First Due](#impact-assessment-for-first-due)

---

## Version History

- **PostgreSQL 15** (October 2022): VACUUM/ANALYZE inheritance changes, performance improvements
- **PostgreSQL 16** (September 2023): Query planner improvements, logical replication enhancements
- **PostgreSQL 17** (September 2024): Performance improvements, query planner enhancements
- **PostgreSQL 18** (October 2024): Full-text search collation, timezone changes, AIO subsystem

---

## Breaking Changes

### 1. NULLS NOT DISTINCT in Unique Constraints and Indexes

**Change:**
- PostgreSQL 18 allows `NULLS NOT DISTINCT` in `UNIQUE` constraints and indexes
- **However, PRIMARY KEY constraints cannot use `NULLS NOT DISTINCT`** - this is a breaking change if you try to create such a constraint

**Impact:**
- ❌ **No Impact**: Your codebase doesn't use `NULLS NOT DISTINCT` in PRIMARY KEY constraints
- ✅ **Safe**: Standard UNIQUE constraints and indexes work as before

**Example:**
```sql
-- This is now allowed in PG18 (but was already allowed in PG14)
CREATE UNIQUE INDEX idx_name ON table (col1, col2) NULLS NOT DISTINCT;

-- This is NOT allowed in PG18 (and wasn't in PG14 either)
CREATE TABLE test (id INT PRIMARY KEY NULLS NOT DISTINCT); -- ERROR
```

---

### 2. GENERATED ALWAYS AS IDENTITY Restrictions

**Change:**
- **Tightened restrictions on GENERATED expression for inherited and partitioned tables**
- Columns of parent/partitioned and child/partition tables must all have the same generation status
- The actual generation expressions can now be different (this is actually more flexible)

**Impact:**
- ⚠️ **Potential Impact**: Your codebase uses `GENERATED ALWAYS AS IDENTITY` extensively
- ✅ **Action Required**: Verify that inherited/partitioned tables with GENERATED columns are compatible

**What to Check:**
```sql
-- Find all GENERATED ALWAYS AS IDENTITY columns
SELECT 
    schemaname,
    tablename,
    attname,
    attidentity
FROM pg_attribute a
JOIN pg_class c ON a.attrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE attidentity = 'a'  -- 'a' = ALWAYS
AND schemaname IN ('app', 'rrule');
```

**Your Codebase:**
- Found 19+ tables with `GENERATED ALWAYS AS IDENTITY` columns
- Need to verify none are in inheritance/partitioning hierarchies

---

### 3. Interval Value Restrictions

**Change:**
- **Restrict `ago` to only appear at the end in interval values**
- **Prevent empty interval units from appearing multiple times**

**Examples:**
```sql
-- PG14: Allowed
INTERVAL '1 day 2 hours ago'  -- ✅ Works
INTERVAL 'ago 1 day'          -- ✅ Works

-- PG18: Restricted
INTERVAL '1 day 2 hours ago'  -- ✅ Still works (ago at end)
INTERVAL 'ago 1 day'          -- ❌ ERROR: ago must be at end
INTERVAL '1 day ago 2 hours' -- ❌ ERROR: ago not at end
```

**Impact:**
- ✅ **No Impact**: Your codebase uses standard interval syntax:
  - `INTERVAL '1 day'`
  - `INTERVAL '{$minutes} minutes'`
  - `interval '1 hour'`
- All your intervals are valid in PG18

**Verified Files:**
- `site/components/DispatchResponse.php`: Uses `INTERVAL '1 day'` ✅
- `site/components/dispatch_processors/templates/helpers/NfirsNotificationHelper.php`: Uses `INTERVAL '{$minutes} minutes'` ✅
- `site/components/event/ActivityLog.php`: Uses `interval '1 hour'` ✅

---

### 4. Timezone Abbreviation Resolution

**Change:**
- **The system will now favor the current session's time zone abbreviations before checking the server variable `timezone_abbreviations`**

**Impact:**
- ⚠️ **Low Impact**: May affect queries using timezone abbreviations
- ✅ **Action**: Test timezone-dependent queries

**What to Check:**
```sql
-- Queries using timezone abbreviations
SELECT * FROM table WHERE created_at AT TIME ZONE 'EST';
SELECT * FROM table WHERE created_at AT TIME ZONE 'PST';
```

**Your Codebase:**
- Uses `AT TIME ZONE` with timezone names (not abbreviations) in most places
- Configuration uses full timezone names: `'UTC'`, `'America/New_York'`, etc.

---

### 5. COPY FROM CSV Behavior

**Change:**
- **Prevent COPY FROM from treating `\.` as an end-of-file marker when reading CSV files**

**Impact:**
- ✅ **No Impact**: Your codebase uses the `Csv` PHP class for CSV processing
- CSV imports are handled in application code, not via PostgreSQL COPY

**Verified:**
- `site/components/Csv.php`: Handles CSV parsing in PHP
- No direct `COPY FROM` CSV commands in application code

---

### 6. Full-Text Search Collation Provider

**Change:**
- **Full-text search now uses ICU collation provider by default** (if available)
- **pg_trgm indexes require reindexing** after upgrade

**Impact:**
- ⚠️ **CRITICAL**: Your codebase uses `pg_trgm` extensively
- ✅ **Action Required**: Reindex all `gin_trgm_ops` indexes after migration

**What to Check:**
```sql
-- Count pg_trgm indexes
SELECT count(*) 
FROM pg_indexes 
WHERE indexdef LIKE '%gin_trgm_ops%';

-- List all pg_trgm indexes
SELECT schemaname, tablename, indexname
FROM pg_indexes
WHERE indexdef LIKE '%gin_trgm_ops%';
```

**Your Codebase:**
- Uses `pg_trgm` extension for fuzzy text search
- Multiple GIN indexes with `gin_trgm_ops` on location/address fields
- Example: `address_location_trgm_gin_idx` on `app.place`

**Required Action:**
```sql
-- After migration, reindex all pg_trgm indexes
REINDEX INDEX CONCURRENTLY app.address_location_trgm_gin_idx;
-- Repeat for all pg_trgm indexes
```

---

## Behavioral Changes

### 7. VACUUM and ANALYZE Inheritance Behavior (PostgreSQL 15)

**Change:**
- **VACUUM and ANALYZE now process inheritance child tables by default**
- Previously, these commands only processed the specified parent table unless explicitly directed to include child tables
- This change was introduced in PostgreSQL 15 and affects all subsequent versions

**Impact:**
- ⚠️ **Potential Impact**: Your codebase uses `ANALYZE` commands in migrations
- ✅ **Positive Impact**: Better statistics for inherited tables
- ⚠️ **Performance Consideration**: ANALYZE may take longer as it processes child tables automatically

**What Changed:**
```sql
-- PostgreSQL 14: Only analyzes parent table
ANALYZE parent_table;  -- Child tables NOT analyzed

-- PostgreSQL 15+: Analyzes parent AND all child tables
ANALYZE parent_table;  -- Child tables ARE analyzed automatically
```

**Your Codebase:**
- Found `ANALYZE` commands in migrations (e.g., `m251030_150001_cleanup_involved_tables.php`)
- Uses `ANALYZE VERBOSE` on individual tables
- ✅ **No inheritance hierarchies detected** in schema (verified: no `INHERITS` clauses)
- This change won't affect current migrations, but is important for future inheritance usage

**Verification:**
```sql
-- Check for table inheritance
SELECT 
    n.nspname as schema,
    c.relname as table_name,
    pg_get_expr(c.reloptions, c.oid) as options
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE c.relkind = 'r' 
  AND c.relispartition = false
  AND EXISTS (
      SELECT 1 FROM pg_inherits 
      WHERE inhrelid = c.oid
  );
```

**Action Required:**
- ✅ **No Immediate Action**: Your current ANALYZE commands will work correctly
- ⚠️ **Monitor Performance**: ANALYZE may take longer if inheritance is added in the future
- ✅ **Benefit**: Better query planning statistics for any inherited tables

**Example from Your Codebase:**
```php
// console/migrations/m251030_150001_cleanup_involved_tables.php
$this->execute('ANALYZE VERBOSE training_class;');
$this->execute('ANALYZE VERBOSE personnel;');
// These commands now automatically process child tables if they exist
```

---

### 8. Virtual Generated Columns (Default)

**Change:**
- Generated columns are now **virtual by default** (computed on read)
- Previously, generated columns were stored by default

**Impact:**
- ✅ **No Impact**: Your codebase doesn't use generated columns
- This is a new feature, not a breaking change

---

### 9. Query Planner Improvements (PostgreSQL 15, 16, 17, 18)

**Change:**
- Improved query planning for joins
- Better hash join performance
- Incremental sorts in merge joins
- Skip scan for multicolumn B-tree indexes

**Impact:**
- ✅ **Positive Impact**: Queries may run faster
- ⚠️ **Action**: Monitor query performance after migration
- Some queries may have different execution plans

---

### 10. Asynchronous I/O (AIO) (PostgreSQL 18)

**Change:**
- New AIO subsystem for better I/O performance
- Improves sequential scans, bitmap heap scans, vacuum operations

**Impact:**
- ✅ **Positive Impact**: Better performance for large table scans
- No code changes required

---

## New Features

### 11. UUIDv7 Function (PostgreSQL 18)

**Change:**
- New `uuidv7()` function generates timestamp-ordered UUIDs

**Impact:**
- ✅ **No Impact**: Optional new feature
- Can be used for better UUID indexing if desired

---

### 12. Temporal Constraints (PostgreSQL 18)

**Change:**
- Support for temporal constraints on PRIMARY KEY, UNIQUE, and FOREIGN KEY

**Impact:**
- ✅ **No Impact**: New feature, not used in your codebase

---

### 13. OLD and NEW in RETURNING Clauses (PostgreSQL 18)

**Change:**
- `RETURNING` clause now supports `OLD` and `NEW` references

**Impact:**
- ✅ **No Impact**: Optional new feature

---

### 14. JSON_TABLE Function (PostgreSQL 18)

**Change:**
- New `JSON_TABLE` function for relational-style querying of JSON data

**Impact:**
- ✅ **No Impact**: Optional new feature
- Your codebase uses JSONB extensively but doesn't require this feature

---

## Performance Improvements

### 15. Parallel GIN Index Builds (PostgreSQL 15+)

**Change:**
- GIN indexes can now be built in parallel

**Impact:**
- ✅ **Positive Impact**: Faster index creation for pg_trgm indexes
- No code changes required

---

### 16. Optimizer Statistics Retention (PostgreSQL 18)

**Change:**
- `pg_upgrade` now retains optimizer statistics during upgrade

**Impact:**
- ✅ **Positive Impact**: Faster post-upgrade performance
- Less need for immediate `ANALYZE` after upgrade

---

## Security Changes

### 17. Data Checksums Enabled by Default (PostgreSQL 18)

**Change:**
- New PostgreSQL 18 clusters have data checksums enabled by default

**Impact:**
- ✅ **Positive Impact**: Better data integrity
- ⚠️ **Note**: Slight performance overhead (~1-2%)

---

### 18. MD5 Password Authentication Deprecated (PostgreSQL 18)

**Change:**
- MD5 password authentication is deprecated
- Encouraged to use SCRAM-SHA-256

**Impact:**
- ⚠️ **Action Required**: Verify authentication method
- Your DDEV setup likely uses password authentication
- Check: `pg_hba.conf` or connection string

**Check:**
```sql
-- Check current authentication method
SHOW password_encryption;
```

---

## Deprecations & Removals

### 19. Logical Replication Improvements (PostgreSQL 15, 16, 17)

**Change:**
- **PostgreSQL 15**: Improved logical replication performance, better conflict resolution
- **PostgreSQL 16**: Enhanced logical replication with better monitoring and control
- **PostgreSQL 17**: Further logical replication performance improvements

**Impact:**
- ✅ **No Impact**: Your codebase doesn't use logical replication currently
- ✅ **Future Benefit**: If logical replication is needed, newer versions offer better performance

---

### 20. SQL/JSON Functions (PostgreSQL 16)

**Change:**
- New SQL/JSON standard functions: `json_array()`, `json_object()`, `json_object_agg()`, etc.
- Improved JSON querying capabilities

**Impact:**
- ✅ **No Impact**: Optional new features
- Your codebase uses JSONB extensively but doesn't require these specific functions

---

### 21. No Major Removals

**Change:**
- No major features removed between PG14 and PG18
- All PG14 features remain compatible

**Impact:**
- ✅ **No Impact**: Full backward compatibility maintained

---

## Impact Assessment for First Due

### Critical Actions Required

1. **Reindex pg_trgm Indexes** ⚠️ **CRITICAL** (PostgreSQL 18)
   - All GIN indexes using `gin_trgm_ops` must be reindexed
   - Required for correct full-text search behavior
   - Use `REINDEX INDEX CONCURRENTLY` to avoid downtime

2. **Verify GENERATED ALWAYS AS IDENTITY** ⚠️ **IMPORTANT** (PostgreSQL 18)
   - Check that no inherited/partitioned tables have incompatible GENERATED columns
   - Your codebase has 19+ tables with GENERATED columns

3. **Understand VACUUM/ANALYZE Behavior** ⚠️ **IMPORTANT** (PostgreSQL 15+)
   - ANALYZE now processes inheritance child tables automatically
   - Monitor ANALYZE performance if inheritance is used
   - Your migrations use ANALYZE commands - they will work correctly

4. **Test Timezone-Dependent Queries** ⚠️ **LOW PRIORITY** (PostgreSQL 18)
   - Verify timezone abbreviation resolution doesn't affect queries
   - Most queries use full timezone names (safe)

### No Action Required

1. ✅ **Interval Syntax**: All intervals are valid
2. ✅ **COPY FROM CSV**: Not used in application code
3. ✅ **NULLS NOT DISTINCT**: Not used in PRIMARY KEY constraints
4. ✅ **Views and Functions**: Should work without changes

### Performance Monitoring

1. ⚠️ **Monitor Query Performance**
   - Query plans may change (likely for the better)
   - Monitor slow queries after migration
   - Run `ANALYZE` on all tables after migration

2. ⚠️ **Monitor Full-Text Search**
   - Test fuzzy search functionality after reindexing
   - Verify `pg_trgm` indexes are working correctly

---

## Migration Checklist

### Pre-Migration
- [ ] Backup PostgreSQL 14 database
- [ ] Verify all extensions are compatible (PostGIS, pg_trgm)
- [ ] Check for GENERATED ALWAYS AS IDENTITY in partitioned tables
- [ ] Check for table inheritance (affects VACUUM/ANALYZE behavior in PG15+)
- [ ] Document current query performance baseline

### During Migration
- [ ] Import schema to PostgreSQL 18
- [ ] Import data to PostgreSQL 18
- [ ] Verify all extensions installed (PostGIS, pg_trgm)
- [ ] Run ANALYZE on all tables

### Post-Migration
- [ ] **Reindex all pg_trgm indexes** (CRITICAL)
- [ ] Test full-text search functionality
- [ ] Compare view/function results between PG14 and PG18
- [ ] Monitor query performance
- [ ] Verify timezone-dependent queries
- [ ] Test application functionality

---

## Summary

### Breaking Changes: **0 Critical**
- No breaking changes that affect your current codebase
- All changes are either new features or behavioral improvements

### Behavioral Changes: **3 Important**
1. **VACUUM/ANALYZE inheritance behavior** (PostgreSQL 15) - Now processes child tables automatically
   - ✅ No impact: Your schema has no table inheritance
   - ✅ Your ANALYZE commands will work correctly
2. **Full-text search collation** (PostgreSQL 18) - Requires reindexing pg_trgm indexes
   - ⚠️ **CRITICAL**: Must reindex all `gin_trgm_ops` indexes after migration
3. **Query planner improvements** (PostgreSQL 15-18) - May change execution plans
   - ✅ Positive: Queries may run faster
   - ⚠️ Monitor: Some queries may have different execution plans

### Key Changes by Version

**PostgreSQL 15 (October 2022):**
- ✅ VACUUM/ANALYZE now processes inheritance child tables (no impact - no inheritance in schema)
- ✅ Parallel GIN index builds (benefit for pg_trgm indexes)
- ✅ Improved logical replication (not used currently)

**PostgreSQL 16 (September 2023):**
- ✅ SQL/JSON standard functions (optional new features)
- ✅ Enhanced logical replication (not used currently)
- ✅ Query planner improvements (positive impact)

**PostgreSQL 17 (September 2024):**
- ✅ Further query planner improvements (positive impact)
- ✅ Logical replication enhancements (not used currently)

**PostgreSQL 18 (October 2024):**
- ⚠️ **CRITICAL**: Full-text search collation changes (requires reindexing)
- ⚠️ Timezone abbreviation resolution changes (no impact - uses full names)
- ✅ Asynchronous I/O (AIO) subsystem (performance benefit)
- ✅ Virtual generated columns default (not used currently)
- ✅ Data checksums enabled by default (security benefit)
- ✅ Optimizer statistics retention in pg_upgrade (performance benefit)

### Action Required: **1 Critical**
1. **Reindex pg_trgm indexes** after migration (PostgreSQL 18)

### Optional Improvements: **Multiple**
- Can leverage new features (UUIDv7, JSON_TABLE, SQL/JSON functions, etc.)
- Performance improvements available automatically
- Better query planning and execution

### Overall Risk: **LOW**
- Your codebase is compatible with PostgreSQL 14 through 18
- Main concern is reindexing pg_trgm indexes (PostgreSQL 18)
- No code changes required for compatibility
- All intermediate version changes are either beneficial or non-impactful

---

## References

### Official Documentation
- [PostgreSQL 15 Release Notes](https://www.postgresql.org/docs/release/15.0/)
- [PostgreSQL 16 Release Notes](https://www.postgresql.org/docs/release/16.0/)
- [PostgreSQL 17 Release Notes](https://www.postgresql.org/docs/release/17.0/)
- [PostgreSQL 18 Release Notes](https://www.postgresql.org/docs/release/18.0/)
- [PostgreSQL 18 Upgrade Guide](https://www.postgresql.org/docs/18/upgrading.html)

### Key Changes by Version

**PostgreSQL 15 (October 2022):**
- VACUUM/ANALYZE now processes inheritance child tables by default
- Parallel GIN index builds
- Improved logical replication
- Performance improvements

**PostgreSQL 16 (September 2023):**
- SQL/JSON standard functions
- Enhanced logical replication
- Query planner improvements
- Performance improvements

**PostgreSQL 17 (September 2024):**
- Further query planner improvements
- Logical replication enhancements
- Performance improvements

**PostgreSQL 18 (October 2024):**
- Full-text search collation changes (ICU by default)
- Timezone abbreviation resolution changes
- Asynchronous I/O (AIO) subsystem
- Virtual generated columns default
- Data checksums enabled by default
- Optimizer statistics retention in pg_upgrade

