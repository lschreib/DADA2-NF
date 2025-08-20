process REMOVE_PRIMERS{
    errorStrategy 'finish'
    debug true
    publishDir "$params.DEFAULT.outdir/trimming", mode: 'copy', pattern: "*.png"
    publishDir "$params.DEFAULT.outdir/trimming", mode: 'copy', pattern: "*.tsv"
    cpus params.remove_primers.cluster_cpus
    memory params.remove_primers.cluster_memory
    time params.remove_primers.cluster_time

    input:
        path(fastq_dir)

    output:
        path("remove_primers"), emit: primers_removed_dir
        path("*.png"), emit: quality_overview
        path("*.tsv"), emit: primers_hits

    script:
        """
        Rscript /dada2_scripts/short_read/remove_primers.R \\
            -i ${fastq_dir} \\
            -o remove_primers \\
            -f ${params.remove_primers.fwd_primer} \\
            -r ${params.remove_primers.rev_primer} \\
            -m ${params.remove_primers.min_length} \\
            -t ${params.remove_primers.cluster_cpus}
        """
}

