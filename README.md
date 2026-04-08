# DADA2-NF
Nextflow implementation of the R-based DADA2 pipeline

Inidividual steps of the pipeline:

1. Remove primers
2. Trim and filter reads
3. Learn errors
4. Infer samples
5. (Merge reads) and remove chimera
6. Track reads through pipeline
7. Taxonomic classifcation
8. Taxonomic level collapse (i.e. aggregation)
9. Basic diversity metrics (to be implemented)
10. Unit tests (to be implemented)

Seperate workflows available for short read (workflow = 'short_read_decipher') and long read ('long_read_dada2') sequencing data.

