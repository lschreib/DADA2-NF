/*
 * Short-read subworkflow for DADA2-NF
 * This is the first nf-core-style workflow layer built on the existing modules.
 */
include { DECIPHER_CLASSIFY_TAXA } from '../../modules/local/decipher/classify_taxa.nf'
include { AGGREGATE_TAXONOMY_FLEX } from '../../modules/local/taxonomy/aggregate_taxonomy_flex.nf'
include { BUILD_TAX_GUIDE_TREE } from '../../modules/local/guide_tree/build_tax_guide_tree.nf'
include { MAFFT_ALIGNMENT } from '../../modules/nf-core/mafft/mafft_alignment.nf'
include { IQTREE_TREE } from '../../modules/nf-core/iqtree/iqtree_tree.nf'
include { FASTTREE_TREE } from '../../modules/nf-core/fasttree/fasttree_tree.nf'

workflow SEQ_TABLE_PIPELINE {
    take:
        seqtable_ch

    main:
        DECIPHER_CLASSIFY_TAXA(seqtable_ch)
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

    emit:
        feature_table = ch_feature_table
        feature_refseqs = ch_feature_refseqs
}
