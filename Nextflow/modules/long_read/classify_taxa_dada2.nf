process CLASSIFY_TAXA_DADA2 {
    errorStrategy 'finish'
    debug true
    publishDir "$params.DEFAULT.outdir/classification", mode: 'copy'
    cpus params.classify_taxa_dada2.cluster_cpus
    memory params.classify_taxa_dada2.cluster_memory
    time params.classify_taxa_dada2.cluster_time

    input:
        path(sequence_table)

    output:
        path("decipher_ids.rds"), emit: classification_raw
        path("features.fna"), emit: feature_refseqs
        path("feature_table.tsv"), emit: feature_table

    script:
        """
        Rscript /dada2_scripts/long_read/classify_dada2.R \\
            -i ${sequence_table} \\
            -o ${params.classify_taxa_dada2.orientation} \\
            -d ${params.classify_taxa_dada2.reference_database} \\
            -t ${params.classify_taxa_dada2.cluster_cpus}
        """
}
