process FASTTREE_TREE {
    input:
        path(aligned_refseqs)

    output:
        path("fasttree_tree.nwk"), emit: output_tree

    script:
        """
        export OMP_NUM_THREADS=${task.cpus}
        FastTree \
            -gtr \
            -nt \
            < ${aligned_refseqs} > fasttree_tree.nwk
        """
}
