# Output Documentation

## Output Directory Structure

The pipeline generates results organized by processing step:

```
results/
├── remove_primers/
│   ├── reads/                          # Primer-trimmed FASTQ files
│   ├── removal_stats.tsv               # Primer removal statistics
│   └── qc_profiles.png                 # Quality control plots
├── trim_and_filter/
│   ├── reads/                          # Filtered FASTQ files
│   ├── filter_stats.tsv                # Filtering statistics
│   └── qc_plots.png                    # Quality plots
├── errors/
│   ├── forward_errors.rds              # Forward read error model
│   ├── reverse_errors.rds              # Reverse read error model
│   └── error_plots.png                 # Error rate visualizations
├── samples/
│   ├── forward_seqs.rds                # Forward inferred sequences
│   ├── reverse_seqs.rds                # Reverse inferred sequences
│   └── sequence_stats.tsv              # Sequence abundance statistics
├── chimera_removal/
│   ├── merged_reads.rds                # Merged read table
│   ├── seqtab_nochim.rds               # Chimera-removed sequence table
│   └── chimera_stats.tsv               # Chimera removal statistics
├── read_tracking.tsv                   # Pipeline read tracking through all steps
├── classification/
│   ├── taxa_assignments.rds            # DECIPHER taxonomy assignments
│   ├── taxa.tsv                        # Taxonomy in tabular format
│   └── confidence_scores.tsv           # Classification confidence metrics
├── taxonomy_aggregated/
│   ├── species_counts.tsv              # Species-level abundance table
│   ├── genus_counts.tsv                # Genus-level abundance table
│   ├── family_counts.tsv               # Family-level abundance table
│   └── ...                             # Other taxonomic ranks
├── alignment/
│   ├── sequences_aligned.fasta         # Multiple sequence alignment (MAFFT)
│   └── alignment_stats.txt             # Alignment statistics
├── phylogeny/
│   ├── tree.nwk                        # Phylogenetic tree (Newick format)
│   ├── tree_stats.txt                  # Tree statistics
│   └── tree_support_values.txt         # Bootstrap/support values (if IQ-TREE)
├── faprotax/
│   ├── faprotax_collapsed.tsv          # Function profile
│   └── faprotax_report.txt             # Taxon-to-function assignment
├── funguild/
│   ├── funguild_annotated.tsv          # FUNGuild annotations
│   └── function_summary.tsv            # Functional category summary
└── pipeline_execution/
    ├── execution_report.html           # Nextflow execution report
    ├── timeline.html                   # Execution timeline
    └── dag.svg                         # Directed acyclic graph (DAG)
```

## File Format Descriptions

### FASTQ Files (`*.fastq`, `*.fq`)
- Quality-filtered and primer-trimmed sequence reads
- Format: 4-line records (header, sequence, plus, quality scores)
- Located in: `remove_primers/reads/`, `trim_and_filter/reads/`

### RDS (R Data Serialization)
- Binary R object format preserving data structures
- Used for: error models, sequence tables, taxonomy assignments
- View in R:
  ```r
  library(readRDS)
  data <- readRDS("file.rds")
  ```

### TSV (Tab-Separated Values)
- Plain-text tabular data format
- Compatible with spreadsheet software and data analysis tools
- Examples: statistics files, abundance tables, taxonomy tables

### Taxonomy Files
- **taxa_assignments.rds**: Full taxonomy object (R format)
- **taxa.tsv**: Simplified tabular format with columns for each taxonomic rank:
  ```
  OTU_ID    Domain      Phylum           Class         Order            Family           Genus            Species
  ASV_001   Archaea     Euryarchaeota    ...
  ASV_002   Bacteria    Proteobacteria   ...
  ```

### Abundance Tables
- Rows: taxa (OTUs/ASVs)
- Columns: samples
- Values: read counts or relative abundances
- Format: compatible with phyloseq, vegan, and other R packages

### Sequence Files
- **FASTA format** (`*.fasta`, `*.fa`): Header + sequence lines
  ```
  >ASV_001
  AGCTAGCTAGCTAGCTAGCTAGC
  >ASV_002
  GCTAGCTAGCTAGCTAGCTAGCT
  ```
- **Aligned FASTA** (`*_aligned.fasta`): Multiple sequence alignment with gaps (-)

### Phylogenetic Trees
- **Newick format** (`*.nwk`, `*.tre`): Standard tree representation
  ```
  (ASV_001:0.1,ASV_002:0.15,(ASV_003:0.05,ASV_004:0.08):0.12)root;
  ```
- Compatible with: QIIME 2, R (ape package), FigTree, ARB

### Statistics Files (TSV)
- **read_tracking.tsv**: Read counts through each pipeline step
  ```
  Sample    Input    After_Primer_Removal    After_Filter    Inferred    Merged    Non_Chimeric
  Sample_1  50000    48000                   45000           42000       41000     40500
  ```
- **chimera_stats.tsv**: Chimera filtering statistics
- **confidence_scores.tsv**: Taxonomic classification confidence

## Long-Read Specific Outputs

For `--workflow_mode long_read`:

```
results/
├── remove_primers_longread/
│   ├── reads/                          # Primer-removed FASTQ
│   └── removal_stats.tsv
├── trim_and_filter_longread/
│   ├── reads/                          # Filtered FASTQ
│   └── filter_stats.tsv
├── dereplicate/
│   ├── derep_seqs.rds                  # Dereplicated sequences
│   └── dereplicate_stats.tsv           # Dereplication statistics
├── denoise/
│   ├── seqtab_dadaQ.rds                # Denoised sequence table (DADA2-Q)
│   └── denoise_stats.tsv
└── [rest same as short-read]
```

## Functional Prediction Outputs

### FUNGuild
- **funguild_annotated.tsv**: Functional guild assignments
- Columns: taxon, guild, trophic mode, growth morphology
- Example:
  ```
  taxon           guild                  trophic_mode    growth_form
  Aspergillus     Saprotroph-Symbiotroph Heterotroph     Mycelium
  Saccharomyces   Saprotroph             Heterotroph     Yeast
  ```

### FAPROTAX
- **faprotax_collapsed.tsv**: Functional guild profiles
- Columns: group, sample_ids
- Example:
```
group	Sample1.fastq.gz	Sample2.fastq.gz	Sample3.fastq.gz
methanotrophy	0	0	0
acetoclastic_methanogenesis	0.0004115932087	0.0005664202242	0.0002692369824
methanogenesis_by_disproportionation_of_methyl_groups	0	0	0
methanogenesis_using_formate	0	0	0
```

- **faprotax_report.txt**: Functional guild assignments
- Example:
```
# methanotrophy (0 records):

# acetoclastic_methanogenesis (2 records):
    k__Archaea;p__Halobacteriota;c__Methanosarcinia;o__Methanosarcinales;f__Methanosaetaceae;g__Methanothrix;
    k__Archaea;p__Halobacteriota;c__Methanosarcinia;o__Methanosarcinales;f__Methanosaetaceae;g__Methanothrix;s__uncultured Methanosaeta sp.;```
```


## Quality Control Output

### Plots (PNG format)
- **qc_profiles.png**: Read length distributions, quality score profiles
- **error_plots.png**: Error rate vs. quality score for forward/reverse
- **tree_visualization.pdf**: Phylogenetic tree with taxon labels

### Text Reports
- HTML reports can be opened in any web browser
- Include execution statistics, resource usage, and timing information

## Accessing Results

### In R
```r
library(dada2)
library(phyloseq)

# Read sequence table
seqtab.nochim <- readRDS("results/chimera_removal/seqtab_nochim.rds")

# Read taxonomy
taxa <- read.table("results/classification/taxa.tsv", sep="\t", header=TRUE, row.names=1)

# Create phyloseq object
ps <- phyloseq(otu_table(seqtab.nochim, taxa_are_rows=FALSE),
               tax_table(as.matrix(taxa)))
```

### In Python
```python
import pandas as pd
import numpy as np

# Read abundance tables
abundance = pd.read_csv("results/taxonomy_aggregated/species_counts.tsv", sep="\t", index_col=0)

# Read taxonomy
taxonomy = pd.read_csv("results/classification/taxa.tsv", sep="\t", index_col=0)

# Read read tracking
tracking = pd.read_csv("results/read_tracking.tsv", sep="\t", index_col=0)
```

## Output Preservation

By default, all outputs are published using `mode: 'copy'`. To save disk space:
- Set `publish_dir_mode = 'symlink'` in configuration (creates symbolic links)
- Set `publish_dir_mode = 'rellink'` (relative symbolic links)

Example:
```bash
nextflow run main.nf --publish_dir_mode symlink
```

## Downstream Analysis

Recommended tools for downstream analysis:

- **Phyloseq (R)**: Statistical analysis, ordination
- **FigTree**: Tree visualization
