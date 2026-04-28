process BUILD_TAX_GUIDE_TREE {
    errorStrategy 'finish'
    debug true
    publishDir "$params.DEFAULT.outdir/unifrac", mode: 'copy'
    cpus params.picrust.cluster_cpus
    memory params.picrust.cluster_memory
    time params.picrust.cluster_time

    input:
        path(feature_table)

    output:
        path("tax_guide_tree.nwk"), emit: output_tree

    script:
        """
        python3 /dada2_scripts/python/create_guide_tree_from_taxonomy.py \\
            -t ${feature_table} \\
            -o tax_guide_tree.nwk
        """
}
