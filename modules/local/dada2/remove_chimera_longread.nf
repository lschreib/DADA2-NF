process REMOVE_CHIMERA_LONGREAD {
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
            -t ${task.cpus} \\
            -v ${params.remove_chimera_longread.verbose}
        """
}
