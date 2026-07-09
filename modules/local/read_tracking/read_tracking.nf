process READ_TRACKING {
    input:
        path(filter_output)
        path(forward_sample)
        path(reverse_sample)
        path(merged_reads)
        path(no_chimera_seq_table)

    output:
        path("read_tracking.tsv"), emit: read_tracking_summary

    script:
        """
        Rscript /dada2_scripts/short_read/read_tracking.R \\
            -f ${filter_output} \\
            -s ${forward_sample} \\
            -r ${reverse_sample} \\
            -m ${merged_reads} \\
            -c ${no_chimera_seq_table}
        """
}
