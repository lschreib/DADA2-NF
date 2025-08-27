process PICRUST {
    errorStrategy 'finish'
    debug true
    publishDir "$params.DEFAULT.outdir/picrust", mode: 'copy'
    cpus params.picrust.cluster_cpus
    memory params.picrust.cluster_memory
    time params.picrust.cluster_time

    input:
        path(feature_refseqs)
        path(feature_table)

    output:
        path("picrust2_out_pipeline"), emit: output_dir

    script:
        """
        # Reformat the feature table to make it compatible with PICRUSt2
        awk -F'\t' 'NR==1 {NF--; print "#" \$0; next} {NF--; print}' OFS='\t' ${feature_table} > ${feature_table}.picrust.tsv
        picrust2_pipeline.py \\
            -s ${feature_refseqs} \\
            -i ${feature_table}.picrust.tsv \\
            -o picrust2_out_pipeline \\
            -p ${params.picrust.cluster_cpus} \\
            --verbose
        """
}
