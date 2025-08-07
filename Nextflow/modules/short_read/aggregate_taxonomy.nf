process AGGREGATE_TAXONOMY {
    errorStrategy 'finish'
    debug true
    publishDir "$params.DEFAULT.outdir/aggregation", mode: 'copy'
    cpus params.aggregate.cluster_cpus
    memory params.aggregate.cluster_memory
    time params.aggregate.cluster_time

    input:
        path(feature_table)

    output:
        path("read_tracking.tsv"), emit: read_tracking_summary

    script:
        """
        Rscript /dada2_scripts/aggregate_taxonomy.R \\
            -i ${feature_table} \\
            -l ${params.aggregate.aggregation_level} \\
            -n ${params.aggregate.na_remove} \\
            -o ${params.aggregate.output_prefix}
        """
}
