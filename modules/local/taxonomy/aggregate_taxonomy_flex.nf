process AGGREGATE_TAXONOMY_FLEX {
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
