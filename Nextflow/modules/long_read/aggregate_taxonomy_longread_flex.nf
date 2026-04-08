process AGGREGATE_TAXONOMY_LONGREAD_FLEX {
    errorStrategy 'finish'
    debug true
    publishDir "$params.DEFAULT.outdir/aggregation", mode: 'copy'
    cpus params.aggregate_longread.cluster_cpus
    memory params.aggregate_longread.cluster_memory
    time params.aggregate.cluster_time

    input:
        tuple val(aggregation_level), path(feature_table)

    output:
        path("aggregated_taxonomy_*.reads.tsv"), emit: aggregated_reads
        path("aggregated_taxonomy_*.rel_abund.tsv"), emit: aggregated_relative_abundance

    script:
        """
        Rscript /dada2_scripts/aggregate_taxonomy.R \\
            -i ${feature_table} \\
            -l ${aggregation_level} \\
            -n ${params.aggregate_longread.na_remove} \\
            -o aggregated_taxonomy
        """
}
