process FAPROTAX_INTERPRET {
    input:
        path(feature_table)

    output:
        path("faprotax"), emit: faprotax_output

    script:
        """
        mkdir -p faprotax
        cp ${feature_table} feature_table.tsv

        python ${params.faprotax.collapse_table_script} \
            -i feature_table.tsv \
            -o faprotax/faprotax_collapsed.tsv \
            -g ${params.faprotax.database_path}
        """
}
