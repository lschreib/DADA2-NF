process REMOVE_CHIMERA {
    errorStrategy 'finish'
    debug true
    publishDir "$params.DEFAULT.outdir/chimera_removal", mode: 'copy'
    cpus params.remove_chimera.cluster_cpus
    memory params.remove_chimera.cluster_memory
    time params.remove_chimera.cluster_time

    input:
        path(filtered_reads_dir)
        path(forward_sample)
        path(reverse_sample)

    output:
        path("merged_reads.rds"), emit: merged_reads_rds
        path("seqtab.rds"), emit: seqtab_rds
        path("seqtab.nochim.rds"), emit: seqtab_nochim_rds
        path("seqtab.nochim.fasta"), emit: seqtab_nochim_fasta
        path("seqtab.nochim.tsv"), emit: seqtab_nochim_tsv
        path("seqtab_dimensions.raw.tsv"), emit: seqtab_dimensions_before
        path("seqtab_dimensions.nochim.tsv"), emit: seqtab_dimensions_after
        path("seqtab_length_distribution.raw.tsv"), emit: seqtab_length_distribution_before
        path("seqtab_length_distribution.nochim.tsv"), emit: seqtab_length_distribution_after

    script:
        """
        Rscript /dada2_scripts/short_read/remove_chimera.R \\
            -i ${filtered_reads_dir} \\
            -f ${forward_sample} \\
            -r ${reverse_sample} \\
            -m ${params.remove_chimera.method} \\
            -t ${params.remove_chimera.cluster_cpus}
        """
}
