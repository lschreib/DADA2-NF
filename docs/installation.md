# Installation Guide

## Requirements

### System Requirements
- Linux or macOS operating system
- Nextflow >= 23.10.0
- Java 8 or higher (required for Nextflow)
- 16 GB RAM minimum (32 GB+ recommended)
- 50 GB+ free disk space

### Container Engine (choose one)
- **Docker**: For Docker containerization
- **Singularity**: For HPC environments

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

### 3. Install Container/Environment Manager

#### Option A: Docker
```bash
# Install Docker from https://docs.docker.com/get-docker/
# Then pull the DADA2 container
docker pull dada2-nf:latest
```

#### Option B: Singularity
```bash
# Install Singularity (https://sylabs.io/guides/latest/user-guide/)
# Then build the image
singularity build dada2-nf.sif docker://dada2-nf:latest
```

#### Option C: Conda/Mamba
```bash
# Install Mamba (recommended over Conda)
curl -L -O https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
bash Miniforge3-Linux-x86_64.sh

# Create environments for each component
mamba env create -f environments/dada2.yml
mamba env create -f environments/mafft.yml
mamba env create -f environments/iqtree.yml
mamba env create -f environments/fasttree.yml
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
    submitOptions = '--account=myaccount --qos=gpu'
    queue = 'gpu'
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
