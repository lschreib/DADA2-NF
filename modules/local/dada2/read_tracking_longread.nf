process READ_TRACKING_LONGREAD {
    input:
        path(removed_primers_rds)
        path(filter_output_rds)
        path(denoised_output_rds)
        path(no_chimera_seqtab_rds)

    output:
        path("read_tracking.tsv"), emit: read_tracking_summary

    script:
        """
        Rscript /dada2_scripts/long_read/read_tracking.R \\
            -r ${removed_primers_rds} \\
            -f ${filter_output_rds} \\
            -d ${denoised_output_rds} \\
            -c ${no_chimera_seqtab_rds}
        """
}
