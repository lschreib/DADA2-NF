# Troubleshooting Guide

## Common Errors and Solutions

### 1. Installation Issues

#### Error: "Nextflow command not found"
**Solution**: Nextflow is not in your PATH.
```bash
# Option A: Add to PATH
export PATH=$PATH:/path/to/nextflow/directory

# Option B: Create symlink to /usr/local/bin
sudo ln -s /path/to/nextflow /usr/local/bin/nextflow

# Verify
nextflow -version
```

#### Error: "Java version is too old"
**Solution**: Upgrade Java to version 8+.
```bash
# Check current version
java -version

# Install Java 11 (recommended)
sudo apt-get install openjdk-11-jdk  # Ubuntu/Debian
brew install openjdk@11              # macOS
```

#### Error: "Docker daemon not running"
**Solution**: Start Docker daemon.
```bash
# Linux
sudo systemctl start docker

# macOS
open --application Docker

# Windows
# Use Docker Desktop application from Start Menu
```

### 2. Container/Environment Issues

#### Error: "Docker image not found"
**Solution**: Pull or build the container.
```bash
# Pull from registry
docker pull dada2-nf:latest

# Build from Dockerfile
cd assets/containers/dada2/
docker build -t dada2-nf:latest .
```

#### Error: "Singularity: authentication token required"
**Solution**: Generate Singularity token for remote images.
```bash
# Create ~/.singularity/docker-token
# See: https://docs.sylabs.io/guides/latest/user-guide/endpoint.html

# Or build locally first
singularity build dada2-nf.sif docker://dada2-nf:latest
```

### 3. Parameter Errors

#### Error: "Parameter 'workflow_mode' not recognized"
**Solution**: Check parameter syntax and schema.
```bash
# Correct syntax
nextflow run main.nf --workflow_mode short_read

# Not this
nextflow run main.nf --workflowmode short_read
nextflow run main.nf --workflow-mode short_read
```

#### Error: "Parameter 'input_reads' is not defined"
**Solution**: Provide the required parameter.
```bash
nextflow run main.nf \
  --input_reads /path/to/reads \
  --outdir results
```

#### Error: "input_reads: No such file or directory"
**Solution**: Check file path and permissions.
```bash
# Verify path exists
ls -la /path/to/reads

# Use absolute path
nextflow run main.nf --input_reads $(pwd)/reads

# Check read permissions
chmod +r /path/to/reads/*
```

### 4. Runtime Errors

#### Error: "java.lang.OutOfMemoryError"
**Solution**: Increase memory allocation.
```bash
# Method 1: Command line
nextflow run main.nf --max_memory 128.GB

# Method 2: Configuration file
echo 'params.max_memory = "128.GB"' >> params.config
nextflow run main.nf -c params.config

# Method 3: NF_JAVA_OPTS environment variable
export NF_JAVA_OPTS="-Xmx16g"
nextflow run main.nf ...
```

#### Error: "Process failed: R/Rscript not found"
**Solution**: Ensure R is installed or use containers.
```bash
# Check R installation
which Rscript

# Use Docker/Singularity
nextflow run main.nf -profile docker

# Or install R
sudo apt-get install r-base        # Ubuntu/Debian
brew install r                      # macOS
```

#### Error: "Timeout waiting for connection"
**Solution**: Increase timeout or reduce load.
```bash
# Increase timeout
export NF_SOCKET_TIMEOUT=120

# Or reduce parallel jobs
nextflow run main.nf -n 4
```

### 5. Data Processing Errors

#### Error: "No sequences found after primer removal"
**Possible causes**:
- Incorrect primer sequences
- Primers not in reads (different sequencing direction)
- File format not recognized

**Solution**:
```bash
# Verify primers with BLAST
# Check FASTQ file format
head reads/*.fastq | more

# Try reverse complement of primers
# Or check sequencing orientation in lab notes
```

#### Error: "Error in learn_errors(): no sequences"
**Solution**: Check filtering settings are not too stringent.
```bash
# Loosen QC thresholds
nextflow run main.nf \
  --trim_and_filter.max_ee_fwd 3.0 \
  --trim_and_filter.max_ee_rev 3.0 \
  --trim_and_filter.trunc_q 2
```

#### Error: "Chimera detection failed"
**Solution**: Try different method or skip.
```bash
# Use different method
nextflow run main.nf --remove_chimera.method pooled

# Or use consensus (more permissive)
nextflow run main.nf --remove_chimera.method consensus
```

### 6. HPC/Cluster Issues

#### Error: "Job submitted but never executes"
**Possible causes**:
- Incorrect scheduler settings
- Queue not available
- Resource limits too high

**Solution**:
```bash
# Check scheduler configuration
cat conf/nrc.config  # or your cluster config

# Verify queue availability
sinfo  # SLURM
qstat -q  # PBS

# Try with lower resource requirements
nextflow run main.nf \
  --max_cpus 8 \
  --max_memory 32.GB
```

#### Error: "Singularity image bind mount failed"
**Solution**: Add required mount points.
```groovy
// conf/my_cluster.config
singularity {
    enabled = true
    autoMounts = true
    runOptions = '-B /scratch -B /data -B /home'
}
```

#### Error: "Permission denied" (HPC)
**Solution**: Check file ownership and permissions.
```bash
# Make input files readable
chmod -R +r /path/to/data

# Verify output directory is writable
mkdir -p results
chmod +w results
ls -ld results
```

### 7. Reproducibility Issues

#### Different Results Between Runs
**Possible causes**:
- Random seed not fixed
- Different resource allocation affects order
- Different environment versions

**Solution**:
```bash
# Use fixed random seed
nextflow run main.nf \
  --learn_errors.randomize FALSE \
  -seed 12345

# Recreate exact environment
docker pull dada2-nf:v0.2.0  # Use specific version
```

### 8. Disk Space Issues

#### Error: "No space left on device"
**Solution**: Check and free disk space.
```bash
# Check disk usage
df -h

# Find largest directories
du -sh *

# Remove Nextflow work directory (keeps results)
rm -rf work/

# Or use symbolic links for space savings
nextflow run main.nf --publish_dir_mode symlink
```

#### Error: Work directory too large
**Solution**: Clean up or archive intermediate files.
```bash
# Remove work directory after successful run
rm -rf work/

# Archive results
tar -czf results_backup.tar.gz results/

# Only keep final outputs
nextflow run main.nf --publish_dir_mode copy
```

### 9. Logging and Debugging

#### Enable Verbose Logging
```bash
# Set debug mode
export NXF_DEBUG=1
nextflow run main.nf -profile docker

# Or use trace
nextflow run main.nf -profile docker -trace

# Generate DAG for debugging
nextflow run main.nf -profile docker -with-dag flowchart.svg
```

#### Check Nextflow Log
```bash
# View main log
cat .nextflow.log

# Follow in real-time
tail -f .nextflow.log

# Previous run info
nextflow log <run_id>
nextflow log <run_id> -fields name,status,duration
```

#### Reproduce Exact Run
```bash
# Resume a previous run
nextflow run main.nf -resume <run_id>

# Or check parameters used
nextflow log <run_id> -f params
```

### 10. Platform-Specific Issues

#### macOS: "cannot execute binary file"
**Solution**: Ensure correct architecture.
```bash
# Check CPU architecture
uname -m  # arm64 = M1/M2, x86_64 = Intel

# Use native Docker
brew install docker

# Or use correct container for architecture
docker pull --platform linux/arm64 dada2-nf:latest
```

#### Windows + WSL2: File access issues
**Solution**: Configure WSL2 mounts.
```bash
# In ~/.wslconfig
[interop]
enabled=true
appendWindowsPath=true

# Use /mnt/c for Windows paths
nextflow run main.nf --input_reads /mnt/c/Users/YourName/data
```

## Getting Help

If you still have issues:

1. **Check existing issues**: https://github.com/lschreib/DADA2-NF/issues
2. **Enable debug mode** and capture output
3. **Provide minimal reproducible example**:
   - Nextflow version: `nextflow -version`
   - Container info: `docker version` or `singularity version`
   - Command used
   - Error message (full stack trace)
   - Relevant logs

4. **Open new issue with**:
   - Title: Clear one-liner of problem
   - Description: What you tried, what happened, what you expected
   - Attachments: Error logs, minimal example

5. **Contact maintainers**: lars.schreiber@example.com
