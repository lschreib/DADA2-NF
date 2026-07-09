process DADA2_CLASSIFY_TAXA {
    input:
        path(sequence_table)

    output:
        path("dada2_tax.rds"), emit: classification_raw
        path("features.fna"), emit: feature_refseqs
        path("feature_table.tsv"), emit: feature_table

    script:
        """
        Rscript /dada2_scripts/long_read/classify_dada2.R \\
            -i ${sequence_table} \\
            -o ${params.dada2_classify_taxa.orientation} \\
            -d ${params.dada2_classify_taxa.reference_database} \\
            -t ${task.cpus}
        """
}
