process REMOVE_PRIMERS_LONGREAD {
    errorStrategy 'finish'
    debug true
    publishDir "$params.DEFAULT.outdir/remove_primers", mode: 'copy', pattern: '*.rds'
    publishDir "$params.DEFAULT.outdir/remove_primers", mode: 'copy', pattern: '*.png'
    publishDir "$params.DEFAULT.outdir/remove_primers", mode: 'copy', pattern: 'primer_hits*.tsv'

    cpus params.remove_primers_longread.cluster_cpus
    memory params.remove_primers_longread.cluster_memory
    time params.remove_primers_longread.cluster_time

    input:
        path(fastq_dir)

    output:
        path("remove_primers"), emit: primers_removed_dir
        path("read_length_distribution.pre.png"), emit: read_length_pre
        path("primer_hits.pre.tsv"), emit: primer_stats_before
        path("primer_hits.post.tsv"), emit: primer_stats_after
        path("removed_primers_output.rds"), emit: primers_removed_rds
        path("quality_profile.preTrim.png"), emit: quality_profile_pre

    script:
        """
        Rscript /dada2_scripts/long_read/remove_primers_dada2.R \\
            -i ${fastq_dir} \\
            -o remove_primers \\
            -f ${params.remove_primers_longread.fwd_primer} \\
            -r ${params.remove_primers_longread.rev_primer} \\
            -v TRUE
        """
}
