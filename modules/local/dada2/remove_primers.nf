process REMOVE_PRIMERS{
    input:
        path(fastq_dir)

    output:
        path("remove_primers"), emit: primers_removed_dir
        path("*.tsv"), emit: removal_stats
        path("*.png"), emit: qc_profiles

    script:
        """
        Rscript /dada2_scripts/short_read/remove_primers_cutadapt.R \\
            -i ${fastq_dir} \\
            -o remove_primers \\
            -f ${params.remove_primers.fwd_primer} \\
            -r ${params.remove_primers.rev_primer} \\
            -m ${params.remove_primers.min_length} \\
            -t ${task.cpus}
        """
}
