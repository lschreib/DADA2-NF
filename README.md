# DADA2-NF

[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A523.04.0-brightgreen.svg)](https://www.nextflow.io/)
[![nf-core](https://img.shields.io/badge/built_with-nf--core%20style-lightblue.svg)](https://nf-co.re)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **Nextflow-powered DADA2 implementation**
> 
> A comprehensive, production-ready amplicon sequencing pipeline for DADA2-based processing of short-read, long-read, and Sanger sequencing data with integrated taxonomic classification, phylogenetic inference, and functional prediction.

## Overview

DADA2-NF is an nf-core-compliant Nextflow pipeline that implements the DADA2 amplicon sequence processing workflow with support for:

- **Short-read sequencing**: Illumina MiSeq, NextSeq, NovaSeq (paired-end only)
- **Long-read sequencing**: PacBio
- **Sanger sequencing**: AB1 files (development in progress)
- **Taxonomic classification**: DECIPHER (short-read) and DADA2 (long-read)
- **Phylogenetic analysis**: Automated tree construction with MAFFT + IQ-TREE/FastTree
- **Functional prediction**: FAPROTAX (16S rRNA) and FUNGuild (ITS) integration
- **Container support**: Singularity

## Quick Start

### Minimal Example
```bash
nextflow run main.nf -profile docker \
  --input_reads /path/to/reads \
  --outdir results
```

### With Custom Parameters
```bash
nextflow run main.nf -profile docker \
  --input_reads /path/to/reads \
  --outdir results \
  --remove_primers.fwd_primer CTTGGTCATTTAGAGGAAGTAA \
  --remove_primers.rev_primer GCTGCGTTCTTCATCGATGC
```

### Test Profile (Validate Setup)
```bash
nextflow run main.nf -profile test_short_16S,singularity -params-file tests/params/short_16S_faprotax.yml
```

See [Installation Guide](docs/installation.md) and [Usage Guide](docs/usage.md) for detailed instructions.

## Pipeline Steps

### Short-Read Workflow
1. **Remove primers** - Strip primer sequences with cutadapt
2. **Trim and filter** - Quality filtering and read truncation
3. **Learn errors** - Build error model from high-quality reads
4. **Infer samples** - Identify unique sequence variants (ASVs) per sample
5. **Remove chimera** - Detect and remove chimeric sequences
6. **Track reads** - Monitor read attrition through pipeline
7. **Classify taxa** - Assign taxonomy with DECIPHER
8. **Aggregate taxonomy** - Collapse to desired taxonomic rank
9. **Build guide tree** - Generate phylogenetic tree (ITS only)
10. **Calculate phylogenetic tree** -  Phylogenetic inference with FastTree or IQTree (ITS only)
11. **Functional prediction** - FAPROTAX or FUNGuild

### Long-Read Workflow
1. **Remove primers** - Strip primer sequences
2. **Trim and filter** - Quality and length filtering
3. **Dereplicate** - Collapse identical sequences
4. **Learn errors** - Error model for long reads (PacBio/Nanopore-specific)
5. **Denoise** - DADA2-Q denoising for long reads
6. **Remove chimera** - Chimera detection and removal
7. **Classify taxa** - DADA2 taxonomy assignment
8. **Aggregate taxonomy** - Rank-based aggregation
9.  **Calculate phylogenetic tree** - Phylogenetic inference
10. **Functional prediction** - FAPROTAX

## Documentation

- **[Installation Guide](docs/installation.md)** - System requirements, setup, and container configuration
- **[Usage Guide](docs/usage.md)** - Parameter descriptions, examples, and execution profiles
- **[Output Documentation](docs/output.md)** - File formats and output directory structure
- **[Testing Guide](docs/testing.md)** - Local validation matrix and test-case commands
- **[FAQ](docs/faq.md)** - Frequently asked questions and common use cases
- **[Troubleshooting](docs/troubleshooting.md)** - Error solutions and debugging

## Key Features

### 🔧 Flexible Configuration
- Easy parameter customization via CLI or config files
- HPC cluster integration with Slurm/PBS schedulers

### 📊 Comprehensive QC
- Per-step read tracking statistics
- Error rate analysis and plotting

### 🌳 Advanced Analysis
- Taxonomy-based and de novo guide tree construction
- Integrated functional prediction (PiCrust2, FUNGuild)
- Support for multiple reference databases

### ♻️ Reproducibility
- Nextflow DAG visualization
- Execution timeline and resource reports
- Configuration versioning
- Resumable workflows

### 📦 nf-core Compliant
- Follows nf-core standards and best practices (as closely as is reasonable)
- Modular design for extensibility
- Comprehensive parameter schema
- Standardized documentation

## Parameters

### Essential Parameters
```bash
--workflow_mode       # 'short_read' or 'long_read' (default: short_read)
--input_reads         # Path to FASTQ directory
--outdir              # Output directory (default: results)
```

### Primer Removal (Short-read)
```bash
--remove_primers.fwd_primer       # Forward primer sequence
--remove_primers.rev_primer       # Reverse primer sequence
--remove_primers.min_length       # Minimum read length post-removal (default: 100)
```

### Quality Filtering
```bash
--trim_and_filter.max_ee_fwd      # Max expected errors forward (default: 2.0)
--trim_and_filter.max_ee_rev      # Max expected errors reverse (default: 2.0)
--trim_and_filter.trunc_q         # Truncate at Q score (default: 2)
```

### Classification
```bash
--decipher_classify_taxa.reference_database    # DECIPHER reference (short-read)
--dada2_classify_taxa.reference_database       # DADA2 reference (long-read)
```

See [Usage Guide](docs/usage.md) for complete parameter documentation.

## Execution Examples

### Docker (Local)
```bash
nextflow run main.nf -profile docker \
  --input_reads ./data/fastq \
  --outdir results
```

### Singularity (HPC)
```bash
nextflow run main.nf -profile singularity,nrc \
  --input_reads ./data/fastq \
  --outdir results
```

### With Execution Reports
```bash
nextflow run main.nf -profile docker \
  --input_reads ./data/fastq \
  --outdir results \
  -with-report report.html \
  -with-timeline timeline.html \
  -with-dag flowchart.svg
```

## System Requirements

| Component | Minimum | Recommended |
|-----------|---------|------------|
| CPU Cores | 4 | 16+ |
| RAM | 16 GB | 64-128 GB |
| Disk Space | 50 GB | 500+ GB |
| Java Version | 8 | 11+ |
| Nextflow Version | ??? | 23.04.3 |

## Output

Results are organized by processing step in the output directory:

- `remove_primers/` - Primer removal results
- `trim_and_filter/` - Quality filtering results
- `errors/` - Error model outputs
- `samples/` - Inferred sequences per sample
- `chimera_removal/` - Chimera-free sequence table
- `classification/` - Taxonomic assignments
- `phylogeny/` - Phylogenetic tree
- `read_tracking.tsv` - Read count statistics through pipeline

See [Output Documentation](docs/output.md) for detailed file descriptions.

## Citation

If you use DADA2-NF in your research, please cite:

**DADA2-NF Pipeline:**
```
Schreiber, L. DADA2-NF: Nextflow-powered DADA2 implementation.
https://github.com/lschreib/DADA2-NF
```

**DADA2 Method:**
```
Callahan BJ, et al. (2016) DADA2: High-resolution sample inference from 
Illumina amplicon data. Nature Methods 13:581-583.
```

**Nextflow:**
```
Di Tommaso P, et al. (2017) Nextflow enables reproducible computational 
workflows. Nature Biotechnology 35:316-319.
```

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.

## Community

- **Issues & Questions**: [GitHub Issues](https://github.com/lschreib/DADA2-NF/issues)
- **Code of Conduct**: [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
- **Changelog**: [CHANGELOG.md](CHANGELOG.md)

## Author

**Lars Schreiber** - Pipeline development and maintenance

## Acknowledgments

- DADA2 team for the foundational methodology
- nf-core community for standards and best practices

---

**Version**: 0.2.0 | **Last Updated**: July 2026 | **Status**: Active Development

