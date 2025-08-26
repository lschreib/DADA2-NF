process LEARN_ERRORS_LONGREAD {
    errorStrategy 'finish'
    debug true
    publishDir "$params.DEFAULT.outdir/errors", mode: 'copy'
    cpus params.learn_errors_longread.cluster_cpus
    memory params.learn_errors_longread.cluster_memory
    time params.learn_errors_longread.cluster_time

    input:
        path(dereplicated_rds)

    output:
        path("learn_error_output.rds"), emit: errors_output
        path("error_profile.png"), emit: error_profile

    script:
        """
        Rscript /dada2_scripts/long_read/learn_errors.R \\
            -i ${dereplicated_rds} \\
            -b ${params.learn_errors_longread.band_size} \\
            -r ${params.learn_errors_longread.randomize} \\
            -e ${params.learn_errors_longread.error_function} \\
            -t ${params.learn_errors_longread.cluster_cpus} \\
            -v ${params.learn_errors_longread.verbose}
        """
}
