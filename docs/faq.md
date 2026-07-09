# Frequently Asked Questions

## General

### Q: What is DADA2-NF?
A: DADA2-NF is a Nextflow-based pipeline implementing the DADA2 amplicon sequence processing workflow. It provides both short-read and long-read data processing capabilities with support for taxonomic classification, phylogenetic analysis, and donstream function prediction.

### Q: What sequencing platforms does it support?
A: 
- **Short-read**: Illumina MiSeq, NextSeq, NovaSeq (only paired-end supported for now)
- **Long-read**: PacBio
- **Sanger**: AB1 files (limited support, implementation still in progress)

## Installation & Setup

### Q: How do I install Nextflow?
A: Follow the [Installation Guide](installation.md#install-nextflow). Quick version:
```bash
curl -s https://get.nextflow.io | bash
chmod +x nextflow
```
### Q: How much disk space do I need?
A: Depends on dataset size:
- Input FASTQ: 1-100+ GB
- Intermediate files: 2-10x input size
- Results: 100 MB - 1 GB
- Recommend: 50+ GB free space

### Q: Can I use DADA2-NF on an HPC cluster?
A: Yes! Use the `singularity` profile and create a site-specific config. See [HPC Setup](installation.md#configuration-for-hpc-clusters) and `conf/nrc.config`.

## Running the Pipeline

### Q: What's the minimal command to run DADA2-NF?
A: 
```bash
nextflow run main.nf -profile docker \
  --input_reads /path/to/fastq \
  --outdir results
```

### Q: Can I run only taxonomic classification (skip preprocessing)?
A: Yes, provide a pre-existing sequence table:
```bash
nextflow run main.nf \
  --seqtable /path/to/seqtab.rds \
  --workflow_mode short_read
```

### Q: What does the `-profile` flag do?
A: Specifies execution configuration:
- `docker`: Run with Docker containers
- `singularity`: Run with Singularity containers
- `test`: Run with test data
- `nrc`: Use NRC HPC settings

Combine with commas: `-profile singularity,nrc`

## Parameter Selection

### Q: When should I use `guide_tree: true`?
A: 
- `true`: For ITS data (taxonomy-based guide tree)
- `false`: For 16S data (de novo guide tree)
- Set based on your marker gene

## Output & Analysis

### Q: Where are my results?
A: Check the output directory (default: `results/`). See [Output Documentation](output.md) for file descriptions.

## Advanced

### Q: How do I add custom database for classification?
A: Provide path in configuration:
```bash
nextflow run main.nf \
  --decipher_classify_taxa.reference_database /path/to/custom_db.RData
```

### Q: Can I modify the pipeline for custom analysis?
A: Yes. See module files in `modules/local/`. Extend by:
1. Creating new module in `modules/local/`
2. Including in subworkflow
3. Adding parameters to `conf/base.config`

### Q: How do I cite DADA2-NF?
A: Cite both the pipeline and DADA2:
- Pipeline: Schreiber, L. DADA2-NF. https://github.com/lschreib/DADA2-NF
- DADA2: Callahan et al. (2016) Nature Methods

## Still Have Questions?

- Check [Troubleshooting Guide](troubleshooting.md) for common errors
- Review [Usage Guide](usage.md) for detailed parameter documentation
- See [Output Documentation](output.md) for file format details
- Open an issue: https://github.com/lschreib/DADA2-NF/issues
