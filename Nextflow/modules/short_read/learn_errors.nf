process LEARN_ERRORS {
    errorStrategy 'finish'
    debug true
    publishDir "$params.DEFAULT.outdir/errors", mode: 'copy'
    cpus params.learn_errors.cluster_cpus
    memory params.learn_errors.cluster_memory
    time params.learn_errors.cluster_time

    input:
        path(filtered_reads_dir)

    output:
        path("forward_errors.rds"), emit: forward_errors
        path("reverse_errors.rds"), emit: reverse_errors
        path("forward_error_profile.png"), emit: forward_error_profile
        path("reverse_error_profile.png"), emit: reverse_error_profile

    script:
        """
        Rscript /dada2_scripts/learn_errors.R \\
            -i ${filtered_reads_dir} \\
            -r ${params.learn_errors.randomize} \\
            -t ${params.learn_errors.cluster_cpus}
        """
}
