/*
 * Short-read subworkflow for DADA2-NF
 * This is the first nf-core-style workflow layer built on the existing modules.
 */

include { REMOVE_PRIMERS } from '../../modules/local/dada2/remove_primers.nf'
include { TRIM_AND_FILTER } from '../../modules/local/dada2/trim_and_filter.nf'
include { LEARN_ERRORS } from '../../modules/local/dada2/learn_errors.nf'
include { INFER_SAMPLES } from '../../modules/local/dada2/infer_samples.nf'
include { REMOVE_CHIMERA } from '../../modules/local/dada2/remove_chimera.nf'
include { READ_TRACKING } from '../../modules/local/read_tracking/read_tracking.nf'
include { DECIPHER_CLASSIFY_TAXA } from '../../modules/local/decipher/classify_taxa.nf'
include { AGGREGATE_TAXONOMY_FLEX } from '../../modules/local/taxonomy/aggregate_taxonomy_flex.nf'
include { BUILD_TAX_GUIDE_TREE } from '../../modules/local/guide_tree/build_tax_guide_tree.nf'
include { MAFFT_ALIGNMENT } from '../../modules/nf-core/mafft/mafft_alignment.nf'
include { IQTREE_TREE } from '../../modules/nf-core/iqtree/iqtree_tree.nf'
include { FASTTREE_TREE } from '../../modules/nf-core/fasttree/fasttree_tree.nf'

workflow SHORT_READ_PIPELINE {
    take:
        reads_ch

    main: 
        REMOVE_PRIMERS(reads_ch)
        TRIM_AND_FILTER(REMOVE_PRIMERS.out.primers_removed_dir)
        LEARN_ERRORS(TRIM_AND_FILTER.out.filtered_reads_dir)

        INFER_SAMPLES(
            TRIM_AND_FILTER.out.filtered_reads_dir,
            LEARN_ERRORS.out.forward_errors,
            LEARN_ERRORS.out.reverse_errors
        )

        REMOVE_CHIMERA(
            TRIM_AND_FILTER.out.filtered_reads_dir,
            INFER_SAMPLES.out.forward_sample,
            INFER_SAMPLES.out.reverse_sample
        )

        READ_TRACKING(
            TRIM_AND_FILTER.out.filtered_reads_rds,
            INFER_SAMPLES.out.forward_sample,
            INFER_SAMPLES.out.reverse_sample,
            REMOVE_CHIMERA.out.merged_reads_rds,
            REMOVE_CHIMERA.out.seqtab_nochim_rds
        )

        /*
         * Define safe default outputs in case workflow is run without taxonomy classification.
        */
        ch_feature_table  = Channel.empty()
        ch_feature_refseqs = Channel.empty()


        if (params.classify_taxa) {
            DECIPHER_CLASSIFY_TAXA(REMOVE_CHIMERA.out.seqtab_nochim_rds)

            ch_feature_table   = DECIPHER_CLASSIFY_TAXA.out.feature_table
            ch_feature_refseqs = DECIPHER_CLASSIFY_TAXA.out.feature_refseqs

            // ITS amplicons do not allow a resolution beyond genus level, to overocme
            // this, we can build a guide tree from the taxonomy and then only use the
            // ITS distances to infer leaf lengths in the phylogenetic tree.
            // This is not necessary or useful when working with ribosomal (16S, 18S, 23S) RNA genes.
            if (params.guide_tree) {
                BUILD_TAX_GUIDE_TREE(ch_feature_table)
                MAFFT_ALIGNMENT(ch_feature_refseqs)
                IQTREE_TREE(BUILD_TAX_GUIDE_TREE.out.output_tree, MAFFT_ALIGNMENT.out.output_aligned)
            } else {
                MAFFT_ALIGNMENT(ch_feature_refseqs)
                FASTTREE_TREE(MAFFT_ALIGNMENT.out.output_aligned)
            }

            ch_aggregation_level = Channel.of(1, 2, 3, 4, 5, 6, 7)
            AGGREGATE_TAXONOMY_FLEX(ch_aggregation_level.combine(DECIPHER_CLASSIFY_TAXA.out.feature_table))
        }

    emit:
        feature_table = ch_feature_table
        feature_refseqs = ch_feature_refseqs
        read_tracking_summary = READ_TRACKING.out.read_tracking_summary
}
