process DECIPHER_CLASSIFY_TAXA {
    input:
        path(sequence_table)

    output:
        path("decipher_ids.rds"), emit: classification_raw
        path("features.fna"), emit: feature_refseqs
        path("feature_table.tsv"), emit: feature_table

    script:
        """
        Rscript /dada2_scripts/short_read/classify_decipher.R \\
            -i ${sequence_table} \\
            -d ${params.decipher_classify_taxa.reference_database} \\
            -s ${params.decipher_classify_taxa.strand} \\
            -r ${params.decipher_classify_taxa.remove_below_level} \\
            -t ${task.cpus}
        """
}
