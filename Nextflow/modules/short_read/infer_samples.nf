process INFER_SAMPLES {
    errorStrategy 'finish'
    debug true
    publishDir "$params.DEFAULT.outdir/samples", mode: 'copy'
    cpus params.infer_samples.cluster_cpus
    memory params.infer_samples.cluster_memory
    time params.infer_samples.cluster_time

    input:
        path(filtered_reads_dir)
        path(forward_errors)
        path(reverse_errors)

    output:
        path("forward_sample.rds"), emit: forward_sample
        path("reverse_sample.rds"), emit: reverse_sample

    script:
        """
        Rscript /dada2_scripts/short_read/infer_samples.R \\
            -i ${filtered_reads_dir} \\
            -f ${forward_errors} \\
            -r ${reverse_errors} \\
            -t ${params.infer_samples.cluster_cpus}
        """
}

