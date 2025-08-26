process DENOISE {
    errorStrategy 'finish'
    debug true
    publishDir "$params.DEFAULT.outdir/denoise", mode: 'copy'

    cpus params.denoise.cluster_cpus
    memory params.denoise.cluster_memory
    time params.denoise.cluster_time

    input:
        path(infile_dereplicated)
        path(infile_errors)


    output:
        path("denoised_output.rds"), emit: denoised_output

    script:
        """
        Rscript /dada2_scripts/long_read/denoise.R \\
            -d ${infile_dereplicated} \\
            -e ${infile_errors} \\
            -b ${params.denoise.band_size} \\
            -t ${params.denoise.cluster_cpus} \\
            -v ${params.denoise.verbose}
        """
}
