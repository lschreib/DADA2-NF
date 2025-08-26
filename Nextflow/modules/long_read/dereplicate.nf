process DEREPLICATE {
    errorStrategy 'finish'
    debug true
    publishDir "$params.DEFAULT.outdir/dereplicated", mode: 'copy'
    cpus params.dereplicate.cluster_cpus
    memory params.dereplicate.cluster_memory
    time params.dereplicate.cluster_time

    input:
        path(filtered_reads_dir)

    output:
        path("derep_output.rds"), emit: dereplicated_rds

    script:
        """
        Rscript /dada2_scripts/long_read/dereplicate.R \\
            -i ${filtered_reads_dir} \\
            -t ${params.infer_samples.cluster_cpus} \\
            -v ${params.dereplicate.verbose}
        """
}
