process CLASSIFY_TAXA_DECIPHER {
    errorStrategy 'finish'
    debug true
    publishDir "$params.DEFAULT.outdir/classification", mode: 'copy'
    cpus params.classify_taxa_decipher.cluster_cpus
    memory params.classify_taxa_decipher.cluster_memory
    time params.classify_taxa_decipher.cluster_time

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
            -d ${params.classify_taxa_decipher.reference_database} \\
            -s ${params.classify_taxa_decipher.strand} \\
            -r ${params.classify_taxa_decipher.remove_below_level} \\
            -t ${params.classify_taxa_decipher.cluster_cpus}
        """
}
