# Experimental Features

This directory contains experimental or incomplete features that are not yet ready for production use.

## configure-postgres.py

**Status:** Incomplete - requires JNDI datasource configuration

**Issue:** Pentaho's PostgreSQL configuration requires:
1. JNDI datasources defined in `tomcat/webapps/pentaho/META-INF/context.xml`
2. Repository.xml changes to reference JNDI datasources (not direct JDBC URLs)
3. Proper schema initialization in PostgreSQL

**Current State:** Script attempts to configure repository.xml but fails because:
- Default repository.xml uses LocalFileSystem (file-based), not database
- PostgreSQL sections are commented out and use JNDI references
- Requires Tomcat context.xml configuration that script doesn't handle

**Future Work:**
- Research proper Pentaho PostgreSQL setup with JNDI
- Add context.xml JNDI datasource configuration
- Properly uncomment and configure PostgreSQL sections
- Test with actual PostgreSQL databases

**For Now:** Use HSQLDB (default) which works perfectly out of the box.
