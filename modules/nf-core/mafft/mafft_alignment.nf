process MAFFT_ALIGNMENT {
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
