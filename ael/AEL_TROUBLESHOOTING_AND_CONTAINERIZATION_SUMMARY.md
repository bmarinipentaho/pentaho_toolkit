# AEL Troubleshooting & Containerization Summary

_Date: 2025-10-20_

## 1. Objectives & Evolution
- Began with basic network and firewall validation (ping success, UFW rules).
- Progressed into Spark daemon connection failures (driver/executor ports refused).
- Diagnosed HDFS connectivity (only Node 1 accessible) and YARN submission retries.
- Resolved service port access (8020 NameNode, 8032 ResourceManager) via firewall changes.
- Investigated missing DataNode on Node 1 (logging misconfiguration / minimal `log4j.properties`).
- Shifted to Pentaho AEL daemon NoClassDefFoundError (`org/pentaho/di/i18n/BaseMessages`).
- Provided detailed functional breakdown of `scripts/setup_ael.sh` for future containerization.
- Culminated in full historical summary request (this document).

## 2. Hadoop / Spark / AEL Components
| Component | Role | Key Ports | Notes |
|-----------|------|-----------|-------|
| NameNode | HDFS metadata service | 8020 (RPC) | Must be reachable from all DataNodes & clients. |
| DataNode | Stores HDFS blocks | ephemeral (configured), 50010/50075 typical | Node 1 lacked startup due to logging config. |
| ResourceManager | YARN scheduling | 8032 | Needed firewall open to allow Spark/YARN submission. |
| NodeManager | YARN per-node executor | 8042 (UI), 8041 (RPC) | Verified running after port fixes. |
| Spark Driver | Coordinates job | dynamic (e.g. 530xx) | Connection refused when firewall blocked ephemeral driver port range. |
| Spark Executor | Performs tasks | dynamic | Launched under YARN or standalone. |
| AEL Daemon | Pentaho Spark execution harness | websocket + Spark submission | Failed due to missing Pentaho core classpath. |

## 3. Major Issues & Resolutions
### 3.1 Spark Connection Refused
- Symptom: Executors/drivers retry connecting to driver port; repeated refused connections.
- Cause: Firewall (UFW) not allowing required ephemeral port range or driver port.
- Action: Opened port range (`sudo ufw allow 10000:65535/tcp`) plus specific Hadoop/YARN ports.

### 3.2 HDFS Inaccessible from Nodes 2 & 3
- Symptom: `hdfs dfs -ls /` succeeds only on Node 1; others hang/retry to port 8020.
- Cause: Port 8020 blocked to NameNode.
- Action: Allowed 8020; confirmed remote list works; multi-node HDFS functional.

### 3.3 YARN Submission Retries
- Symptom: Spark job attempts connecting to ResourceManager on 8032; repeated retries.
- Cause: Port 8032 blocked.
- Action: Opened 8032; YARN resource negotiation succeeded.

### 3.4 Missing DataNode on Node 1
- Symptom: `jps` shows no DataNode for Node 1 though Node 2 & 3 have it.
- Observations: Minimal `log4j.properties` produced warnings; no DataNode log generated.
- Likely Cause: Logging configuration or startup script failing early (quiet failure) due to missing appenders.
- Action: Located full `log4j.properties` template (with RFA/DRFA/audit appenders); advised replacement in Hadoop `conf` & restart.
- Pending: Re-run DataNode start and verify via `sudo -u hdfs jps` and new log presence under `$HADOOP_HOME/logs`.

### 3.5 Pentaho Classpath Error
- Symptom: AEL daemon throws `NoClassDefFoundError: org/pentaho/di/i18n/BaseMessages`.
- Cause: Core Pentaho/Kettle libraries not on classpath when starting daemon.
- Required: Ensure `pentaho-kettle-core` (and related PDI i18n jars) are present in `lib/` or appended to daemon startup script/classpath env.
- Next Step: Identify jar (e.g. `kettle-core-<version>.jar`) in unpacked pdi-client-ee and add to CLASSPATH or Spark submission's `--jars`.

## 4. Network & Firewall Commands (Reference)
```bash
# List UFW status & rules
sudo ufw status verbose

# Allow Hadoop/YARN critical ports
sudo ufw allow 8020/tcp   # NameNode RPC
sudo ufw allow 8032/tcp   # ResourceManager
sudo ufw allow 10000:65535/tcp  # Wide ephemeral range for Spark driver/executors (coarse approach)

# Temporarily disable firewall (Ubuntu)
sudo ufw disable

# Check listening ports
sudo ss -ltnp | grep -E '(:8020|:8032|:53)'  # extend as needed

# Verify remote connectivity
nc -vz <namenode_host> 8020
nc -vz <rm_host> 8032
```

## 5. Process & Service Checks
```bash
# Hadoop daemons (run as hdfs user where needed)
sudo -u hdfs jps
# Expect: NameNode, SecondaryNameNode, DataNode

# YARN
jps | grep -E 'ResourceManager|NodeManager'

# Spark event log directory (HDFS)
hdfs dfs -ls /path/to/spark/eventLogDir

# DataNode restart (example paths)
$HADOOP_HOME/sbin/hadoop-daemon.sh start datanode
# or modern
$HADOOP_HOME/bin/hdfs --daemon start datanode
```

## 6. HDFS Path Clarification
- Local filesystem path `/home/devuser/...` differs from HDFS namespace `/user/devuser/...`.
- Default HDFS working directory for a user: `/user/<username>`.
- Use `hdfs dfs -pwd` and `hdfs dfs -ls .` to introspect.

## 7. `setup_ael.sh` Functional Breakdown
### Core Responsibilities
1. Acquire AEL/Pentaho artifacts (via API key + URLs, local zip files, or existing unpacked directory).
2. Build Spark application using `spark-app-builder.sh` (produces driver/executor zips).
3. Generate `application.properties` variants: `.local` (standalone) and `.yarn` (YARN client mode) via `generate_app_properties()`.
4. Upload `pdi-spark-executor.zip` to HDFS (ensures user home path exists; overwrites existing zip).
5. Set environment variables (`AEL_HOME`) into shell profile.
6. Start AEL daemon automatically in local mode (skips start for YARN by design).

### Property Mutation Highlights
- `hadoopConfDir`, `hbaseConfDir`: Point to config directories (siteFiles).
- `sparkHome`, `sparkMaster`, `sparkDeployMode`: Switch between `local[*]` and `yarn/client`.
- `assemblyZip`: Non-empty for local (driver side jar bundling); cleared for YARN (executor side handled differently).
- `sparkEventLogDir`: Ensures reproducible debugging (should exist in HDFS).
- `websocketURL`: Only set for YARN variant.
F577-50E5
### Execution Flows
| Input Pattern | Behavior |
|---------------|----------|
| `--regen-app-props` | Skips artifact logic; regenerates `.local` and `.yarn` properties; sets YARN as default active. |
| API Key only | Auto-download latest artifacts (driver/executor zips). |
| Two URLs + API Key | Fetch specified versions from Artifactory. |
| Two local zip paths | Extract both into same working folder, then build. |
| Unpacked folder path | Uses existing extracted artifact contents. |

### HDFS Interaction
```bash
hdfs dfs -mkdir -p /user/$USER
hdfs dfs -put -f pdi-spark-executor.zip /user/$USER/
```

### Daemon Startup (Local Mode)
- Ensures classpath includes necessary Pentaho libs and Spark driver jar.
- Needs augmentation to include missing i18n/core jars (see Section 3.5).

## 8. Containerization Considerations
### Goals
- Immutable image for AEL daemon + Spark client tooling.
- Externalize configuration (mount `application.properties`, Hadoop XML site files, and log4j).
- Avoid bundling cluster-specific paths (e.g., do not bake NameNode hostnames into image).

### Suggested Multi-Stage Docker Outline
1. Builder Stage:
   - Base: `ubuntu:22.04` (or slim + JDK 11/17 as required).
   - Install curl, unzip, bash tools.
   - Download Pentaho AEL artifacts via API key ARG (or accept mounted zips).
   - Run `spark-app-builder.sh` to produce zips.
   - Copy out built artifacts.
2. Runtime Stage:
   - Base: `eclipse-temurin:21-jre` (or version required by Pentaho build).
   - Add non-root user (e.g., `pentaho`).
   - COPY driver/executor zips and minimal launch scripts.
   - Provide entrypoint script that:
     - Unpacks if needed.
     - Exports `AEL_HOME`.
     - Validates mounted Hadoop config volume at `/hadoop-conf`.
     - Ensures presence of Pentaho core jars on classpath.
     - Launches daemon (local or YARN depending on env vars `AEL_MODE`, `SPARK_MASTER`).

### Environment Variables to Externalize
| Variable | Purpose | Container Default |
|----------|---------|-------------------|
| `AEL_HOME` | Root of unpacked AEL artifacts | `/opt/ael` |
| `SPARK_HOME` | Spark install (client libs) | Mounted or baked `/opt/spark` |
| `HADOOP_CONF_DIR` | Hadoop site files | `/hadoop-conf` (volume) |
| `AEL_CONFIG` | Path to active `application.properties` | `/config/application.properties` |
| `AEL_MODE` | `local` or `yarn` | `local` |
| `SPARK_EVENT_LOG_DIR` | HDFS path | Must be provided |
| `JFROG_API_KEY` | Optional for on-build downloads | (ARG/secret) |

### Volumes
- `/config` for properties.
- `/hadoop-conf` for Hadoop XMLs.
- `/logs` for daemon logs.

### Health Check
- Script verifies daemon process & optional websocket port responsive.

## 9. Pending Actions (Operational Checklist)
| Task | Status | Action Needed |
|------|--------|---------------|
| Replace Node 1 `log4j.properties` with full template | Pending | Copy template, restart DataNode, verify `jps` & logs. |
| Resolve Pentaho NoClassDefFoundError | Pending | Identify missing jar(s); add to classpath or supply via `--jars`. |
| Validate YARN mode end-to-end job run | Pending | After classpath fix, submit test transformation. |
| Create Dockerfile & entrypoint | Not Started | Implement multi-stage build strategy. |
| Parameterize `application.properties` for container | Not Started | Convert sed mutations to env-driven templating. |

## 10. Recommended Next Steps
1. Classpath Fix: List contents of `pdi-ee-client` lib directory and ensure jars (including `kettle-core`, `pentaho-di-i18n`, `pentaho-platform-core`) are referenced.
2. DataNode Verification: Deploy full `log4j.properties`, restart DataNode, confirm replication factor healthy.
3. Property Externalization: Replace sed in container with templating (e.g., envsubst or simple shell substitution on startup).
4. Create Dockerfile (begin with local mode) and test launching daemon connecting to external Hadoop cluster.
5. Add minimal health check & logging rotation config.
6. Extend to YARN mode: Parameterize `sparkMaster=yarn`, ensure Hadoop/YARN client libs present in image.

## 11. Reference Commands (Jar Inspection)
```bash
# List jar contents
jar tf pentaho-kettle-core-*.jar | grep BaseMessages

# Find missing class in all jars
for f in *.jar; do if jar tf "$f" | grep -q 'org/pentaho/di/i18n/BaseMessages.class'; then echo "FOUND in $f"; fi; done
```

## 12. Lessons Learned
- Open required service ports before deep application debugging to avoid misleading connection failures.
- A minimal Hadoop log4j configuration may appear to work but silently inhibit daemon/log initialization sequences.
- Spark/YARN failures often cascade from HDFS unavailability—establish storage layer health first.
- Classpath completeness is critical: presence of artifact zips does not guarantee daemon runtime viability without explicit jar inclusion.

## 13. Glossary
| Term | Definition |
|------|------------|
| AEL | Application Event Logging; Pentaho component enabling Spark-based transformation execution. |
| Driver | Spark process coordinating tasks and executors. |
| Executor | Spark worker JVM running tasks. |
| NameNode | HDFS master storing filesystem metadata. |
| ResourceManager | YARN master orchestrating cluster resources. |
| UFW | Uncomplicated Firewall (Ubuntu). |
| Classpath | Set of locations (jars/directories) JVM searches for classes. |

## 14. Risks & Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| Overly wide firewall port allowance | Security exposure | Narrow to needed Spark/YARN ranges after stabilizing (configure `spark.driver.port`, `spark.blockManager.port`). |
| Missing Pentaho core jars | Daemon crash | Audit lib directory; enforce startup classpath check. |
| Hard-coded paths in properties | Image portability issues | Externalize via env vars & runtime substitution. |
| DataNode absence | Under-replicated blocks | Monitor `hdfs dfsadmin -report`; ensure Node 1 healthy. |

## 15. Minimal Startup Checklist (Local Mode)
1. Ports 8020/8032 reachable from container host.
2. `HADOOP_CONF_DIR` mounted with correct XML files.
3. All required Pentaho jars present in `AEL_HOME/lib` and on classpath.
4. `application.properties` points to valid event log dir (exists in HDFS).
5. Daemon process started; logs appear under `/logs`.
6. Submit sample transformation and observe successful Spark job completion.

---
_This document consolidates the full troubleshooting narrative and provides a launch pad for containerization._
