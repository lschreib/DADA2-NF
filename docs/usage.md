# DADA2-NF Usage Guide

## Quick Start

### Minimal Example - Short Read Processing

```bash
nextflow run main.nf \
  -profile docker \
  --input_reads /path/to/reads \
  --outdir results
```

### Full Example - Short Read with All Options

```bash
nextflow run main.nf \
  -profile docker,nrc \
  --workflow_mode short_read \
  --input_reads /path/to/reads \
  --outdir results \
  --guide_tree true \
  --remove_primers.fwd_primer CTTGGTCATTTAGAGGAAGTAA \
  --remove_primers.rev_primer GCTGCGTTCTTCATCGATGC \
  --remove_primers.min_length 100 \
  --trim_and_filter.max_ee_fwd 2.0 \
  --trim_and_filter.max_ee_rev 2.0 \
  --trim_and_filter.trunc_q 2 \
  --remove_chimera.method consensus \
  --decipher_classify_taxa.reference_database /path/to/db
```

## Input Parameters

### Core Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `workflow_mode` | string | `short_read` | Workflow mode: `short_read` or `long_read` |
| `input_reads` | string | null | Path to input reads directory or samplesheet |
| `outdir` | string | `results` | Output directory path |
| `guide_tree` | boolean | true | Build taxonomy guide tree (true=ITS, false=16S) |
| `seqtable` | string | null | Pre-existing RDS sequence table (classification-only mode) |

### Short-Read Specific Parameters

#### Primer Removal
```bash
--remove_primers.fwd_primer CTTGGTCATTTAGAGGAAGTAA
--remove_primers.rev_primer GCTGCGTTCTTCATCGATGC
--remove_primers.min_length 100
```

Common primer sets:
- **ITS1/2 (EMP)**: `fwd=CTTGGTCATTTAGAGGAAGTAA` `rev=GCTGCGTTCTTCATCGATGC`
- **16S rRNA (short)**: `fwd=GTGYCAGCMGCCGCGGTAA` `rev=CCGYCAATTYMTTTRAGTTT`
- **16S rRNA (long)**: `fwd=AGRGTTYGATYMTGGCTCAG` `rev=RGYTACCTTGTTACGACTT`
- **18S rRNA**: `fwd=CCAGCASCYGCGGTAATTCC` `rev=ACTTTCGTTCTTGATYRAC`

#### Trim and Filter
```bash
--trim_and_filter.truncation_length_fwd 0
--trim_and_filter.truncation_length_rev 0
--trim_and_filter.max_n 0
--trim_and_filter.max_ee_fwd 2.0
--trim_and_filter.max_ee_rev 2.0
--trim_and_filter.trunc_q 2
--trim_and_filter.min_length 100
```

#### Error Learning
```bash
--learn_errors.randomize TRUE
```

#### Chimera Removal
```bash
--remove_chimera.method consensus  # consensus | pooled | per-sample
```

#### Taxonomic Classification (DECIPHER)
```bash
--decipher_classify_taxa.strand both              # top | bottom | both
--decipher_classify_taxa.remove_below_level 2     # 1=domain ... 7=species
--decipher_classify_taxa.reference_database /path/to/db
```

### Long-Read Specific Parameters

#### Primer Removal
```bash
--remove_primers_longread.fwd_primer AGRGTTYGATYMTGGCTCAG
--remove_primers_longread.rev_primer RGYTACCTTGTTACGACTT
```

#### Trim and Filter
```bash
--trim_and_filter_longread.min_length 1000
--trim_and_filter_longread.max_length 1600
--trim_and_filter_longread.max_n 0
--trim_and_filter_longread.max_ee 2.0
--trim_and_filter_longread.trunc_q 2
--trim_and_filter_longread.min_q 3
```

#### Error Learning (Long Read)
```bash
--learn_errors_longread.band_size 32
--learn_errors_longread.randomize TRUE
--learn_errors_longread.error_function PacBioErrfun  # PacBioErrfun | NanoporeErrfun
```

#### Denoising
```bash
--denoise.band_size 32
```

#### Taxonomic Classification (DADA2)
```bash
--dada2_classify_taxa.orientation both  # forward | both
--dada2_classify_taxa.reference_database /path/to/db
```

## Execution Examples

### Singularity Profile (HPC)
```bash
nextflow run main.nf -profile singularity \
  --input_reads /data/fastq \
  --outdir results
```

### Test Profile (Validate Setup)
```bash
export HOST_PROJECT_DIR="$(pwd -P)"
nextflow run main.nf -profile test_16S_short,singularity -params-file tests/params/short_16S_faprotax.yml
```

## Configuration File

Create `params.yaml` for reusable parameter sets:

```yaml
workflow_mode: short_read
input_reads: /path/to/reads
outdir: results

remove_primers:
  fwd_primer: CTTGGTCATTTAGAGGAAGTAA
  rev_primer: GCTGCGTTCTTCATCGATGC
  min_length: 100

trim_and_filter:
  max_ee_fwd: 2.0
  max_ee_rev: 2.0
  trunc_q: 2
```

Run with:
```bash
nextflow run main.nf -profile docker -params-file params.yaml
```

## Monitoring and Logs

### View Real-Time Execution
```bash
# Tail the Nextflow log
tail -f .nextflow.log

# View in the workflow directory
ls -la work/
```

### Reproduce a Previous Run
```bash
# List previous runs
nextflow log

# Reproduce with run ID
nextflow run main.nf -resume abc1234
```

### Generate Reports
```bash
# HTML execution report
nextflow run main.nf -profile nrc,singularity -with-report report.html

# Timeline visualization
nextflow run main.nf -profile nrc,singularity -with-timeline timeline.html

# DAG visualization
nextflow run main.nf -profile nrc,singularity -with-dag flowchart.svg
```

## Resource Limits

Adjust individual resource limits by editing the `conf/modules.config` file


## For More Information

- See [Output Documentation](output.md) for output file descriptions
- See [FAQ](faq.md) for common questions
- See [Troubleshooting](troubleshooting.md) for error solutions
