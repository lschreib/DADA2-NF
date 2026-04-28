process MAFFT_ALIGNMENT {
    errorStrategy 'finish'
    debug true
    publishDir "$params.DEFAULT.outdir/unifrac", mode: 'copy'
    cpus params.mafft_alignment.cluster_cpus
    memory params.mafft_alignment.cluster_memory
    time params.mafft_alignment.cluster_time

    input:
        path(ref_seq_fasta)

    output:
        path("aligned_refseqs.fna"), emit: output_aligned

    script:
        """
        mafft \
            --${params.mafft_alignment.algorithm} \
            --maxiterate ${params.mafft_alignment.max_iterate} \
            ${ref_seq_fasta} > aligned_refseqs.fna
        """
}
