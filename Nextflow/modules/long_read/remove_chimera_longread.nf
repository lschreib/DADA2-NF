process REMOVE_CHIMERA_LONGREAD {
    errorStrategy 'finish'
    debug true
    publishDir "$params.DEFAULT.outdir/chimera_removal", mode: 'copy'
    cpus params.remove_chimera_longread.cluster_cpus
    memory params.remove_chimera_longread.cluster_memory
    time params.remove_chimera_longread.cluster_time

    input:
        path(denoised_output)

    output:
        path("chimera_summary.txt"), emit: chinmera_removal_summary
        path("seqtab.nochim.rds"), emit: seqtab_nochim_rds
        path("seqtab.nochim.fasta"), emit: seqtab_nochim_fasta
        path("seqtab.nochim.tsv"), emit: seqtab_nochim_tsv

    script:
        """
        Rscript /dada2_scripts/long_read/remove_chimera.R \\
            -d ${denoised_output} \\
            -m ${params.remove_chimera_longread.method} \\
            -t ${params.remove_chimera_longread.cluster_cpus} \\
            -v ${params.remove_chimera_longread.verbose}
        """
}
