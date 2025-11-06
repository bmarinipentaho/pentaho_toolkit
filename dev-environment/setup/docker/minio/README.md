# Pentaho Minio S3 Storage

S3-compatible object storage for Pentaho development and testing.

## Quick Start

```bash
# Start Minio
./dev-environment/manage/minio.sh start

# Check status
./dev-environment/manage/minio.sh status

# View logs
./dev-environment/manage/minio.sh logs

# Stop Minio
./dev-environment/manage/minio.sh stop
```

## Access Information

| Service | Address | Username | Password |
|---------|---------|----------|----------|
| **Minio Console** | http://localhost:9001 | admin | password123 |
| **S3 API Endpoint** | http://localhost:9000 | - | - |

## Pre-configured Buckets

The following buckets are automatically created on first startup:

| Bucket | Purpose | Access |
|--------|---------|--------|
| `pentaho` | General Pentaho data storage | Public read |
| `spark-logs` | Spark event logs for AEL | Public read |
| `ael-artifacts` | AEL jars and dependencies | Public read |

## S3 Configuration

### Using AWS CLI

```bash
# Configure AWS CLI to use Minio
aws configure set aws_access_key_id admin
aws configure set aws_secret_access_key password123
aws configure set default.region us-east-1

# List buckets
aws --endpoint-url http://localhost:9000 s3 ls

# Upload file
aws --endpoint-url http://localhost:9000 s3 cp myfile.txt s3://pentaho/

# Download file
aws --endpoint-url http://localhost:9000 s3 cp s3://pentaho/myfile.txt .
```

### Using Minio Client (mc)

```bash
# Install mc (if not already installed)
# Linux: wget https://dl.min.io/client/mc/release/linux-amd64/mc && chmod +x mc && sudo mv mc /usr/local/bin/

# Configure alias
mc alias set local http://localhost:9000 admin password123

# List buckets
mc ls local

# Create new bucket
mc mb local/my-new-bucket

# Upload file
mc cp myfile.txt local/pentaho/

# Mirror directory
mc mirror ./my-data/ local/pentaho/data/
```

### Using Hadoop S3A

Add to `core-site.xml`:

```xml
<property>
  <name>fs.s3a.endpoint</name>
  <value>http://localhost:9000</value>
</property>
<property>
  <name>fs.s3a.access.key</name>
  <value>admin</value>
</property>
<property>
  <name>fs.s3a.secret.key</name>
  <value>password123</value>
</property>
<property>
  <name>fs.s3a.path.style.access</name>
  <value>true</value>
</property>
<property>
  <name>fs.s3a.connection.ssl.enabled</name>
  <value>false</value>
</property>
```

Then access with:
```bash
hadoop fs -ls s3a://pentaho/
```

### Using Spark

Add to `spark-defaults.conf`:

```properties
spark.hadoop.fs.s3a.endpoint=http://localhost:9000
spark.hadoop.fs.s3a.access.key=admin
spark.hadoop.fs.s3a.secret.key=password123
spark.hadoop.fs.s3a.path.style.access=true
spark.hadoop.fs.s3a.connection.ssl.enabled=false
spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem
```

Or set programmatically:
```python
spark = SparkSession.builder \
    .config("spark.hadoop.fs.s3a.endpoint", "http://localhost:9000") \
    .config("spark.hadoop.fs.s3a.access.key", "admin") \
    .config("spark.hadoop.fs.s3a.secret.key", "password123") \
    .config("spark.hadoop.fs.s3a.path.style.access", "true") \
    .getOrCreate()

df = spark.read.parquet("s3a://pentaho/data/")
```

## Integration with AEL

For AEL Spark event logs:

1. **Configure Spark to use S3 for event logs:**
   ```properties
   spark.eventLog.enabled=true
   spark.eventLog.dir=s3a://spark-logs/
   ```

2. **Configure Spark History Server:**
   ```properties
   spark.history.fs.logDirectory=s3a://spark-logs/
   ```

3. **Update AEL application.properties:**
   ```properties
   spark.eventLog.dir=s3a://spark-logs/
   ```

## Managing Buckets

### Via Web Console
1. Navigate to http://localhost:9001
2. Login with `admin` / `password123`
3. Use "Buckets" menu to create/manage buckets
4. Use "Access Keys" to create additional credentials

### Via mc CLI
```bash
# Create bucket
mc mb local/new-bucket

# Remove bucket
mc rb local/old-bucket

# Set policy (public, download, upload, etc.)
mc anonymous set download local/pentaho

# List bucket contents
mc ls local/pentaho
```

## Customization

Edit `dev-environment/setup/docker/minio/.env`:

```bash
# Change credentials
MINIO_ROOT_USER=myadmin
MINIO_ROOT_PASSWORD=mySecurePassword

# Change ports (if conflicts)
MINIO_API_PORT=9100
MINIO_CONSOLE_PORT=9101
```

Then restart:
```bash
./dev-environment/manage/minio.sh restart
```

## Troubleshooting

### Port already in use
```bash
# Check what's using the port
sudo lsof -i :9000
sudo lsof -i :9001

# Change ports in .env file
nano dev-environment/setup/docker/minio/.env
```

### Cannot connect to S3 endpoint
```bash
# Check Minio is running
./dev-environment/manage/minio.sh status

# Check logs
./dev-environment/manage/minio.sh logs

# Test endpoint
curl http://localhost:9000/minio/health/live
```

### Buckets not created
```bash
# Re-run minio-client container
cd dev-environment/setup/docker/minio
docker-compose up minio-client
```

### Reset all data
```bash
# Stop and remove containers
./dev-environment/manage/minio.sh stop

# Remove volumes
docker volume rm pentaho-minio_minio_data

# Start fresh
./dev-environment/manage/minio.sh start
```

## Data Persistence

Data is stored in Docker volume `pentaho-minio_minio_data`.

To backup:
```bash
docker run --rm -v pentaho-minio_minio_data:/data -v $(pwd):/backup \
  ubuntu tar czf /backup/minio-backup.tar.gz /data
```

To restore:
```bash
docker run --rm -v pentaho-minio_minio_data:/data -v $(pwd):/backup \
  ubuntu tar xzf /backup/minio-backup.tar.gz -C /
```

## External Access

To access from other machines on your network:

1. Find your VM/host IP:
   ```bash
   ip addr show | grep "inet "
   ```

2. Access Minio:
   - **Console:** http://YOUR_IP:9001
   - **S3 API:** http://YOUR_IP:9000

3. Update S3 endpoint in configs to use `YOUR_IP` instead of `localhost`

## Security Notes

**⚠️ Development Only**

The default credentials (`admin`/`password123`) are for **development purposes only**.

For production:
- Change credentials to strong passwords
- Use TLS/SSL (requires certificates)
- Restrict bucket policies
- Create individual access keys per application
- Enable audit logging

## Related Documentation

- [Minio Documentation](https://min.io/docs/minio/linux/index.html)
- [AWS S3 CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/s3/)
- [Hadoop S3A Documentation](https://hadoop.apache.org/docs/stable/hadoop-aws/tools/hadoop-aws/index.html)
- [Spark S3 Integration](https://spark.apache.org/docs/latest/cloud-integration.html)
