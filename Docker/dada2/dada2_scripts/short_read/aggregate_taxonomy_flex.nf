process AGGREGATE_TAXONOMY_FLEX {
    errorStrategy 'finish'
    debug true
    publishDir "$params.DEFAULT.outdir/aggregation", mode: 'copy'
    cpus params.aggregate.cluster_cpus
    memory params.aggregate.cluster_memory
    time params.aggregate.cluster_time

    input:
        tuple val(aggregation_level), path(feature_table)

    output:
        path("aggregated_taxonomy_*.reads.tsv"), emit: aggregated_reads
        path("aggregated_taxonomy_*.rel_abund.tsv"), emit: aggregated_relative_abundance

    script:
        """
        Rscript /dada2_scripts/short_read/aggregate_taxonomy.R \\
            -i ${feature_table} \\
            -l ${aggregation_level} \\
            -n ${params.aggregate.na_remove} \\
            -o aggregated_taxonomy
        """
}
