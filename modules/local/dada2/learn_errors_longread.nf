process LEARN_ERRORS_LONGREAD {
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
            -t ${task.cpus} \\
            -v ${params.learn_errors_longread.verbose}
        """
}
