process PICRUST2_INTERPRET {
    input:
        path(feature_refseqs)
        path(feature_table)

    output:
        path("picrust2"), emit: picrust2_output

    script:
        """
        mkdir -p picrust2
        cp ${feature_refseqs} rep_seqs.fna
        cp ${feature_table} feature_table.tsv

        picrust2_pipeline.py \
            -s rep_seqs.fna \
            -i feature_table.tsv \
            -o picrust2 \
            -p ${task.cpus}
        """
}
