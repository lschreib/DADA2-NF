process FUNGUILD_INTERPRET {
    input:
        path(feature_table)

    output:
        path("funguild"), emit: funguild_output

    script:
        """
        python3 /funguild/Guilds_v1.1.py \
            -otu ${feature_table} \
            -l ${params.funguild.database_path}
        mkdir -p funguild
        mv feature_table.guilds.txt funguild/funguild_output.txt
        """
}
