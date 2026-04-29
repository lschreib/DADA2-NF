process FUNGUILD {
    errorStrategy 'finish'
    debug true
    publishDir "$params.DEFAULT.outdir/funguild", mode: 'copy'
    cpus params.funguild.cluster_cpus
    memory params.funguild.cluster_memory
    time params.funguild.cluster_time

    input:
        path(feature_table)

    output:
        path("*.function.txt"), emit: funguild_output

    script:
        """
        python3 /funguild/Guilds_v1.1.py \\
            -otu ${feature_table} \\
            -m \\
            -l /funguild/funguild_db.php
        """
}
