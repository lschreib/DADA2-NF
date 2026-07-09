process FUNGUILD_INTERPRET {
    input:
        path(feature_table)

    output:
        path("funguild"), emit: funguild_output

    script:
        """
        mkdir -p funguild
        cp ${feature_table} otu_table.tsv

        python /funguild/Guilds_v1.2.py \
            -otu otu_table.tsv \
            ${params.funguild.local_db ? "-l ${params.funguild.local_db}" : ""}

        for f in otu_table*; do
            if [ -e "$f" ]; then
                mv "$f" funguild/
            fi
        done
        """
}
