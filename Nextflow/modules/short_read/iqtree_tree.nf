process IQTREE_TREE {
    errorStrategy 'finish'
    debug true
    publishDir "$params.DEFAULT.outdir/unifrac", mode: 'copy'
    cpus params.iqtree.cluster_cpus
    memory params.iqtree.cluster_memory
    time params.iqtree.cluster_time

    input:
        path(guide_tree)
        path(aligned_refseqs)

    output:
        path("iqtree_tree.nwk"), emit: output_tree

    script:
        """
        iqtree \
            -s ${aligned_refseqs} \
            -m GTR+I+G \
            -g ${guide_tree} \
            -nt ${params.iqtree.cluster_cpus} \
            --prefix iqtree_tree
        mv iqtree_tree.iqtree iqtree_tree.nwk
        """
}
