process FASTTREE_TREE {
    errorStrategy 'finish'
    debug true
    publishDir "$params.DEFAULT.outdir/unifrac", mode: 'copy'
    cpus params.fasttree.cluster_cpus
    memory params.fasttree.cluster_memory
    time params.fasttree.cluster_time

    input:
        path(aligned_refseqs)

    output:
        path("fasttree_tree.nwk"), emit: output_tree

    script:
        """
        export OMP_NUM_THREADS=${params.fasttree.cluster_cpus}
        FastTree \
            -gtr \
            -nt \
            < ${aligned_refseqs} > fasttree_tree.nwk
        """
}
