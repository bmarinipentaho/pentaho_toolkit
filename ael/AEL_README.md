# AEL_AUTOMATION
***DISCLAIMER:*** *This was developed to target a newly-created, default Valhalla Ubuntu 22 VM. For all other use-cases: YMMV<br><br> -> Pay attention to the fact that we are changing ssh parameters in `/scripts/setup_java_and_ssh.sh`<br> The script isn't particularly rude, but it was developed with the use case of "if this vm gets screwed up I will just dispose of it and make a new one".*
***
This project automates the setup and deployment of a Pentaho Application Event Logging (AEL) environment using Hadoop and Spark. It ensures Java 21 (OpenJDK) is installed (auto-installs if missing) and configures `JAVA_HOME` (persisted in `~/.bashrc` with idempotent markers), then installs Hadoop 3.4.1, Spark 3.5.4, and AEL. A utility script compresses and sends project files to a remote server via SFTP. Versions for Hadoop and Spark can be overridden with flags; Java is currently fixed at 21 for consistency.

It was developed with copilot and based upon [Mike Bodkin's AEL guide](https://hv-eng.atlassian.net/wiki/spaces/~michael.bodkin/pages/18467520581/AEL+Debugging+Java+1.8+Pre+Pentaho+9.3), updated with notes from Sourav's AEL modernization work [(summaries here)](https://hitachivantara-eng.slack.com/archives/C07TCSKSPCZ/p1737991794016489)

## Quick Start

```bash
git clone https://github.com/bmarinipentaho/ael-automation.git
cd ael-automation
chmod -R +x .
# Deploy using two local artifact zips (example)
./deploy_ael.sh /path/to/pdi-ee-client.zip /path/to/pdi-ee-client-spark-execution-addon.zip
```

If you only have an unpacked folder of the PDI client:
```bash
./deploy_ael.sh /path/to/unpacked/pdi-client-folder
```

Java 21 will be installed automatically if not present. Hadoop & Spark will be downloaded to `/usr/local/{hadoop,spark}`. AEL is placed under `~/ael_deployment/AEL`.

## Verifying the Deployment

After a successful run:
```bash
jps            # Should show NameNode, DataNode, SecondaryNameNode, HistoryServer, DaemonMain
hadoop fs -ls /user/$USER | grep pdi-spark-executor.zip
ps -p $(pgrep -f DaemonMain) -o pid,cmd
```

Check daemon configuration:
```bash
grep -E '^(sparkMaster|assemblyZip|sparkEventLogDir)' \
  ~/ael_deployment/AEL/data-integration/spark-execution-daemon/config/application.properties
```

Spark event logs (local) may appear under `/tmp/spark-events` while the daemon uses HDFS path `hdfs:///spark-events`.

## Known Limitations / Current State

* The provided PDI client zip used in early testing did not include standard CLI scripts (`pan.sh`, `kitchen.sh`, `spoon.sh`). If your distribution includes them, they should appear under `~/ael_deployment/AEL/data-integration/`. Without them, you can still run the daemon but cannot execute a transformation via Pan/Kitchen directly.
* Containerization notes are in `AEL_TROUBLESHOOTING_AND_CONTAINERIZATION_SUMMARY.md` but no Dockerfile is yet provided.
* No GitHub Actions / CI pipeline is configured (potential future step: shellcheck + basic smoke script).
* Environment variable persistence uses both `~/.bashrc` and `~/.profile` to accommodate non-interactive shells.

## Command Choice: `hadoop fs` vs `hdfs dfs`

Basic file operations now use `hadoop fs` for portability (works across default FS implementations). Administrative HDFS commands would still require `hdfs dfsadmin` etc. If you prefer the explicit HDFS command style, you can change `HDFS_CMD` in `scripts/setup_hadoop.sh`.

## Cleanup & Redeploy

```bash
./remove_ael.sh --help
```
Flags supported (summary):
* `--purge-hdfs` Remove executor zip & spark-events directory from HDFS (skips if Hadoop not installed).
* `--purge-pdi` Remove local Pentaho metadata dirs (`~/.kettle`, `~/.pentaho`).
* `--dry-run` Show actions without executing.
* `--force` Skip interactive confirmation.

Typical full cleanup:
```bash
./remove_ael.sh --purge-hdfs --purge-pdi --force
```
Then redeploy with artifacts:
```bash
./deploy_ael.sh /path/to/pdi-ee-client.zip /path/to/pdi-ee-client-spark-execution-addon.zip
```

## Regenerating Daemon Application Properties

If Hadoop/Spark paths change or you want to switch local vs YARN mode:
```bash
./scripts/setup_ael.sh --regen-app-props
```
Generates local + yarn variants; sets yarn as default (can be edited manually afterward).

## Next Steps / Roadmap Ideas

* Add full PDI client distribution & verify Pan/Kitchen execution.
* Provide a `env_check.sh` script to summary-print service status.
* Add Dockerfile (multi-stage) with pre-baked Java 21 + Spark + Hadoop config.
* Introduce GitHub Actions workflow running shellcheck & basic smoke tests.
* Optional: create a wrapper around Pan main class if scripts are missing.

Feel free to adapt or prune sections for personal use; this README includes operational notes helpful during iterative development.

## Project Structure
```
AEL_AUTOMATION/ 
├── compress_and_send.sh
├── deploy_ael.sh
├── remove_ael.sh
├── jars/ 
│ ├── log4j-api-2.17.1.jar 
│ └── slf4j-api-1.7.35.jar 
└── scripts/ 
  ├── setup_ael.sh 
  ├── setup_hadoop.sh 
  ├── setup_java_and_ssh.sh 
  └── setup_spark.sh
```

## Main Scripts

### `deploy_ael.sh`

To use this script, it is best to just: download the whole project, chmod the whole directory, and run it as the signed in user (not sudo).

This script orchestrates the installation of Java, Hadoop, Spark, and AEL. It accepts a parameter that can be either a URL or a local file path to the AEL ZIP archive [(AEL branch pdi-client-ee-osgi)](https://ciren.orl.eng.hitachivantara.com/job/test-pipelines/job/test7/).

for Ubuntu, it is best to get the zip directly from the [repository](https://repo-cache.orl.eng.hitachivantara.com/artifactory/pntprv-maven-snapshot-custom7/com/pentaho/di/pdi-ee-client/10.3.0.0-SNAPSHOT/) like:

https://repo-cache.orl.eng.hitachivantara.com/artifactory/pntprv-maven-snapshot-custom7/com/pentaho/di/pdi-ee-client/10.3.0.0-SNAPSHOT/pdi-ee-client-10.3.0.0-20250124.184045-31-osgi.zip

#### Usage

```bash
./deploy_ael.sh -h
```
Prints usage/help for all deployment flows.

```bash
# Specify Hadoop and Spark versions (optional)
./deploy_ael.sh --hadoop-version 3.4.1 --spark-version 3.5.4 <other-args>

# For JFrog API key (downloads latest artifacts automatically)
./deploy_ael.sh <JFROG_API_KEY>

# For URL-based deployment (requires API key and both artifact URLs)
./deploy_ael.sh <PDI_EE_CLIENT_ZIP_URL> <SPARK_EXECUTION_ADDON_ZIP> <API_KEY>

# For two local zip files (both extracted into the same folder)
./deploy_ael.sh /path/to/pdi-client-ee.zip /path/to/spark-execution-addon.zip

# For local, unpacked folder
./deploy_ael.sh /path/to/unpacked/pdi-client-ee-folder

# Regenerate only the application.properties files (no artifact handling, generates local and yarn versions, sets yarn as default)
./scripts/setup_ael.sh --regen-app-props
```

### `remove_ael.sh`

This script will remove Hadoop, Spark, and AEL folders, along with the envvars added to .profile
It will not currently cleanup Java nor ssh config changes.
I haven't tested it much, but figured it could be a nice to have. We can improve it as needed.

#### Usage

```bash
./remove_ael.sh
```

Run with `--help` for additional flags (purge HDFS artifacts, metadata, dry-run, force).

### `compress_and_send.sh`

To compress and send the project files to a remote server, run the following command.
I created this utility to rapidly deploy my local changes to a test machine while I'm developing this script. Others may find it useful too.
I've mostly just passed one argument, the IP of the host I want to send this project to.

#### Usage

```bash
./compress_and_send.sh my_host my_user /remote/path my_project.tgz
```

If you only specify the host, defaults attempt to use your current user and a standard remote path (see script header for details). Useful for rapid sync to a test VM.

## /scripts

I have mostly modularized the individual component installation and setup, so you can run each of these individually if you'd like.

The most useful may be the `setup_ael.sh` script to deploy the latest version of ael onto an environment that already has Java, Hadoop, and Spark. See [deploy_ael](#deploy_aelsh) for more information on commandline argument as that script passes its argument to this one.

```bash
# URL-based deployment
./setup_ael.sh <PDI_EE_CLIENT_ZIP_URL> <SPARK_EXECUTION_ADDON_ZIP> <API_KEY>
# or
./setup_ael.sh /path/to/pdi-client-ee.zip
# or
./setup_ael.sh /path/to/unpacked/pdi-client-ee-folder
# or regenerate only the application.properties files (generates local and yarn versions, sets yarn version as default)
./setup_ael.sh --regen-app-props
```
