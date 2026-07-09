process LEARN_ERRORS {
    input:
        path(filtered_reads_dir)

    output:
        path("forward_errors.rds"), emit: forward_errors
        path("reverse_errors.rds"), emit: reverse_errors
        path("forward_error_profile.png"), emit: forward_error_profile
        path("reverse_error_profile.png"), emit: reverse_error_profile

    script:
        """
        Rscript /dada2_scripts/short_read/learn_errors.R \\
            -i ${filtered_reads_dir} \\
            -r ${params.learn_errors.randomize} \\
            -t ${task.cpus}
        """
}
