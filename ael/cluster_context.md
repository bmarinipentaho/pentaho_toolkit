VM A = Hosting Pentaho PDI  
VM B = Hosting the AEL daemon, as well as Spark  
Cluster:  
    - Node 1: 172.16.11.127  
    - Node 2: 172.16.11.128  
    - Node 3: 172.16.11.129  
    - The cluster hosts HDFS, which is where the executor sits

---

## Troubleshooting Summary

- Verified HDFS connectivity across all cluster nodes using `hadoop fs -ls`.  
  - Node 1 could access HDFS; Nodes 2 and 3 initially retried connecting to the NameNode.
- Confirmed NameNode and SecondaryNameNode are running on Node 1 as the `hdfs` user.
- Checked for network/firewall issues:
  - Found port 8020 was not open on Node 1; added the rule with `sudo ufw allow 8020/tcp`.
  - After updating the firewall, tested connectivity from Nodes 2 and 3 using `nc -zv 172.16.11.127 8020`—connection succeeded.
  - Ping between nodes also confirmed network connectivity.
- Reviewed Hadoop configuration files (`core-site.xml`, `hdfs-site.xml`) on all nodes to ensure they point to the correct NameNode IP and port.
- Suggested verifying `/etc/hosts` entries for proper hostname resolution.
- Advised restarting DataNode services on Nodes 2 and 3 if configuration changes were made.
- Identified that Spark/YARN failures were likely due to HDFS connectivity issues between cluster nodes.
- Next, encountered YARN ResourceManager connectivity issues on Node 2 (`172.16.11.128:8032`).
  - Verified ResourceManager is running on Node 2.
  - Opened port 8032 on Node 2 with `sudo ufw allow 8032/tcp`.
  - Confirmed firewall rule is active for port 8032.
- Checked DataNode status on all nodes:
  - DataNode was running as `hdfs` on Node 2 and Node 3.
  - DataNode was **not running** on Node 1; attempted to start with `sudo -u hdfs hdfs --daemon start datanode`, but it did not appear in `jps`.
- Without a running DataNode on Node 1, HDFS cannot fully replicate or store data, causing Spark job failures.
- Next step: Investigate why DataNode is not starting on Node 1 (check logs in `/var/log/hadoop-hdfs` for errors, verify disk space, permissions, and configuration).
- Checked disk space on Node 1; all major partitions have sufficient free space except `/home`, which is 83% full but still has 727M available.
- Disk space is not likely the cause of DataNode startup failure.
- DataNode log on Node 1 shows log4j configuration errors and no DataNode startup messages.
- DataNode fails to start due to missing or misconfigured `log4j.properties`.
- Next step: Copy a working `log4j.properties` from Node 2 or 3 to Node 1, then restart the DataNode.

**Resolution:**  
- Opening port 8020 on Node 1 resolved HDFS connectivity; all nodes can now reach the NameNode.
- Opening port 8032 on Node 2 should resolve YARN ResourceManager connectivity for Spark job submission.
- Ensure DataNode is running on Node 1 to complete HDFS setup and allow Spark jobs to succeed.
- All nodes are now correctly configured for distributed Spark jobs.