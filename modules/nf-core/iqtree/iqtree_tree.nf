process IQTREE_TREE {
    input:
        path(guide_tree)
        path(aligned_refseqs)

    output:
        path("iqtree_tree.nwk"), emit: output_tree
        path("iqtree_tree.log"), emit: output_log
        path("iqtree_tree.iqtree"), emit: output_report

    script:
        """
        # Clean the guide tree to avoid the double bracket error
        awk '{sub(/^\\(/,""); sub(/\\)\\;\$/,";"); print}' ${guide_tree} > cleaned_tree.nwk
        iqtree3 \
            -s ${aligned_refseqs} \
            -m GTR+I+G \
            -g cleaned_tree.nwk \
            -nt ${task.cpus} \
            --prefix iqtree_tree
        mv iqtree_tree.treefile iqtree_tree.nwk
        """
}
