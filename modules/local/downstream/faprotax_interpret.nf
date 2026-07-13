process FAPROTAX_INTERPRET {
    input:
        path(feature_table)

    output:
        path("faprotax"), emit: faprotax_output

    script:
        """
        mkdir -p faprotax

        python3 /app_home/collapse_table.py \
            -i feature_table.tsv \
            -o faprotax/faprotax_collapsed.tsv \
            -r faprotax/faprotax_report.txt \
            -n columns_after_collapsing \
            -g ${params.faprotax.database_path} \
            -d "taxonomy" \
            --omit_columns 0 \
            -v
        """
}
