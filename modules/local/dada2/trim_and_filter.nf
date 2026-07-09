process TRIM_AND_FILTER {
    input:
        path(primers_removed_dir)

    output:
        path("filtered"), emit: filtered_reads_dir
        path("filtered/filter_and_trim_output.rds"), emit: filtered_reads_rds
        path("*.png"), emit: post_trim_profiles


    script:
        """
        Rscript /dada2_scripts/short_read/trim_and_filter.R \\
            -i ${primers_removed_dir} \\
            -o "filtered" \\
            -f ${params.trim_and_filter.truncation_length_fwd} \\
            -r ${params.trim_and_filter.truncation_length_rev} \\
            -n ${params.trim_and_filter.max_n} \\
            -d ${params.trim_and_filter.max_ee_fwd} \\
            -e ${params.trim_and_filter.max_ee_rev} \\
            -q ${params.trim_and_filter.trunc_q} \\
            -m ${params.trim_and_filter.min_length} \\
            -t ${task.cpus} \\
            -v TRUE
        mv filter_and_trim_output.rds filtered/filter_and_trim_output.rds
        """
}
