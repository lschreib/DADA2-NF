process TRIM_AND_FILTER_LONGREAD {
    errorStrategy 'finish'
    debug true
    publishDir "$params.DEFAULT.outdir/filtered", mode: 'copy', pattern: '*.rds'
    publishDir "$params.DEFAULT.outdir/filtered", mode: 'copy', pattern: '*.png'

    cpus params.trim_and_filter_longread.cluster_cpus
    memory params.trim_and_filter_longread.cluster_memory
    time params.trim_and_filter_longread.cluster_time

    input:
        path(primers_removed_dir)

    output:
        path("filtered"), emit: filtered_reads_dir
        path("filter_and_trim_output.rds"), emit: filtered_reads_rds
        path("quality_profile.postTrim.png"), emit: quality_profile_post


    script:
        """
        Rscript /dada2_scripts/long_read/trim_and_filter.R \\
            -i ${primers_removed_dir} \\
            -o "filtered" \\
            -m ${params.trim_and_filter_longread.min_length} \\
            -x ${params.trim_and_filter_longread.max_length} \\
            -n ${params.trim_and_filter_longread.max_n} \\
            -d ${params.trim_and_filter_longread.max_ee} \\
            -q ${params.trim_and_filter_longread.trunc_q} \\
            -y ${params.trim_and_filter_longread.min_q} \\
            -t ${params.trim_and_filter_longread.cluster_cpus} \\
            -v ${params.trim_and_filter_longread.verbose}
        """
}
