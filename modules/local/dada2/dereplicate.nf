process DEREPLICATE {
    input:
        path(filtered_reads_dir)

    output:
        path("derep_output.rds"), emit: dereplicated_rds

    script:
        """
        Rscript /dada2_scripts/long_read/dereplicate.R \\
            -i ${filtered_reads_dir} \\
            -t ${task.cpus} \\
            -v ${params.dereplicate.verbose}
        """
}
