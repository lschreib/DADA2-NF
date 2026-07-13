# Installation Guide

## Requirements

### System Requirements
- Linux or macOS operating system
- Nextflow >= 23.10.0
- Java 8 or higher (required for Nextflow)
- 16 GB RAM minimum (32 GB+ recommended)
- 50 GB+ free disk space

### Container Engine
- **Singularity** (with Docker base): For HPC environments

## Installation Steps

### 1. Install Nextflow

```bash
# Download and install Nextflow
curl -s https://get.nextflow.io | bash

# Make it executable
chmod +x nextflow

# Move to a directory in your PATH (optional)
sudo mv nextflow /usr/local/bin/
```

### 2. Clone the DADA2-NF Repository

```bash
git clone https://github.com/lschreib/DADA2-NF.git
cd DADA2-NF
```

### 3. Install Container Manager and Required Containers

#### 3.1.Create Docker images
```bash
# Install Docker from https://docs.docker.com/get-docker/
# Build the Docker images
docker build -f assets/containers/dada2/Dockerfile --progress=plain -t user_name/dada2:latest
docker build -f assets/containers/iqtree/Dockerfile --progress=plain -t user_name/iqtree:latest
docker build -f assets/containers/fasttree/Dockerfile --progress=plain -t user_name/fasttree:latest
docker build -f assets/containers/mafft/Dockerfile --progress=plain -t user_name/mafft:latest
# (Optional, if function prediction is wanted:)
docker build -f assets/containers/faprotax/Dockerfile --progress=plain -t user_name/faprotax:latest
docker build -f assets/containers/funguild/Dockerfile --progress=plain -t user_name/funguild:latest
# Bundle the Docker images
docker save user_name/dada2:latest | pigz > dada2_latest_DockerImage.tar.gz
docker save user_name/iqtree:latest | pigz > iqtree_latest_DockerImage.tar.gz
docker save user_name/fasttree:latest | pigz > fasttree_latest_DockerImage.tar.gz
docker save user_name/mafft:latest | pigz > mafft_latest_DockerImage.tar.gz
docker save user_name/faprotax:latest | pigz > faprotax_latest_DockerImage.tar.gz
docker save user_name/funguild:latest | pigz > funguild_latest_DockerImage.tar.gz
```

#### 3.1. Convert Docker images to Singularity images
```bash
# Install Singularity (https://sylabs.io/guides/latest/user-guide/)
# Unzip Docker tar.gz file
gunzip -k dada2_latest_DockerImage.tar.gz
gunzip -k iqtree_latest_DockerImage.tar.gz
gunzip -k fasttree_latest_DockerImage.tar.gz
gunzip -k mafft_latest_DockerImage.tar.gz
gunzip -k faprotax_latest_DockerImage.tar.gz
gunzip -k funguild_latest_DockerImage.tar.gz
# Set Singularity build directories to a user-specific directory to avoid storage issues, e.g.
export APPTAINER_CACHEDIR=/gpfs/fs7/grdi/genarcc/grdi_eco/bioinfo-tools/nrc_nf/software/imagefiles/tmp
export SINGULARITY_TMPDIR=/gpfs/fs7/grdi/genarcc/grdi_eco/bioinfo-tools/nrc_nf/software/imagefiles/tmp
# Build Singularity image only using a single sqashfs process to avoid ressource overrun 
singularity build --mksquashfs-args="-processors 1" dada2_latest.sif docker-archive://dada2_latest_DockerImage.tar
singularity build --mksquashfs-args="-processors 1" iqtree_latest.sif docker-archive://iqtree_latest_DockerImage.tar
singularity build --mksquashfs-args="-processors 1" fasttree_latest.sif docker-archive://fasttree_latest_DockerImage.tar
singularity build --mksquashfs-args="-processors 1" mafft_latest.sif docker-archive://mafft_latest_DockerImage.tar
singularity build --mksquashfs-args="-processors 1" faprotax_latest.sif docker-archive://faprotax_latest_DockerImage.tar
singularity build --mksquashfs-args="-processors 1" funguild_latest.sif docker-archive://funguild_latest_DockerImage.tar
```

## Verification

Test your installation:

```bash
# Test with the provided test data
nextflow run main.nf -profile test,docker

# Or with Singularity
nextflow run main.nf -profile test,singularity
```

## Configuration for HPC Clusters

For HPC environments, create a site-specific configuration file following the example in `conf/nrc.config`:

```groovy
// conf/my_cluster.config
process {
    submitOptions = '--account=myaccount'
}

executor {
    name = 'slurm'
    queueSize = 100
    pollInterval = '30 sec'
}
```

Then run:
```bash
nextflow run main.nf -profile my_cluster -c conf/my_cluster.config
```

## Troubleshooting

### Issue: "Nextflow not found"
```bash
# Add Nextflow to PATH
export PATH=$PATH:/path/to/nextflow
```

### Issue: Docker daemon not running
```bash
# Start Docker (on macOS/Linux)
sudo systemctl start docker
# or
open --application Docker
```

### Issue: Singularity permission denied
```bash
# Ensure singularity is in PATH
which singularity

# Or use full path
/path/to/singularity run <image>
```

For additional help, see [Troubleshooting Guide](troubleshooting.md).
