/*
 * Long-read subworkflow for DADA2-NF
 * Uses existing long-read modules during migration.
 */

include { REMOVE_PRIMERS_LONGREAD } from '../../modules/local/dada2/remove_primers_longread.nf'
include { TRIM_AND_FILTER_LONGREAD } from '../../modules/local/dada2/trim_and_filter_longread.nf'
include { DEREPLICATE } from '../../modules/local/dada2/dereplicate.nf'
include { LEARN_ERRORS_LONGREAD } from '../../modules/local/dada2/learn_errors_longread.nf'
include { DENOISE } from '../../modules/local/dada2/denoise.nf'
include { REMOVE_CHIMERA_LONGREAD } from '../../modules/local/dada2/remove_chimera_longread.nf'
include { READ_TRACKING_LONGREAD } from '../../modules/local/dada2/read_tracking_longread.nf'
include { DADA2_CLASSIFY_TAXA } from '../../modules/local/dada2/classify_taxa.nf'
include { AGGREGATE_TAXONOMY_FLEX } from '../../modules/local/taxonomy/aggregate_taxonomy_flex.nf'

workflow LONG_READ_PIPELINE {
    take:
        reads_ch

    main:
        REMOVE_PRIMERS_LONGREAD(reads_ch)
        TRIM_AND_FILTER_LONGREAD(REMOVE_PRIMERS_LONGREAD.out.primers_removed_dir)

        DEREPLICATE(TRIM_AND_FILTER_LONGREAD.out.filtered_reads_dir)
        LEARN_ERRORS_LONGREAD(DEREPLICATE.out.dereplicated_rds)

        DENOISE(
            DEREPLICATE.out.dereplicated_rds,
            LEARN_ERRORS_LONGREAD.out.errors_output
        )

        REMOVE_CHIMERA_LONGREAD(DENOISE.out.denoised_output)

        READ_TRACKING_LONGREAD(
            REMOVE_PRIMERS_LONGREAD.out.primers_removed_rds,
            TRIM_AND_FILTER_LONGREAD.out.filtered_reads_rds,
            DENOISE.out.denoised_output,
            REMOVE_CHIMERA_LONGREAD.out.seqtab_nochim_rds
        )

        // As longread data typically yields fewer ASVs, we can use the
        // slower (but more accurate?) DADA2 classifier instead of DECIPHER used for shortread
        // data.
        DADA2_CLASSIFY_TAXA(REMOVE_CHIMERA_LONGREAD.out.seqtab_nochim_fasta)

        // Aggregate taxonomy at multiple levels to make downstream interpretation easier.
        ch_aggregation_level = Channel.of(1, 2, 3, 4, 5, 6, 7)
        AGGREGATE_TAXONOMY_FLEX(ch_aggregation_level.combine(DADA2_CLASSIFY_TAXA.out.feature_table))

    emit:
        feature_table = DADA2_CLASSIFY_TAXA.out.feature_table
        feature_refseqs = DADA2_CLASSIFY_TAXA.out.feature_refseqs
        read_tracking_summary = READ_TRACKING_LONGREAD.out.read_tracking_summary
}
