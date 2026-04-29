/*
    Parameters are defined in the dada2_NF_config.nf file
*/
log.info """
#####################################################################################################

_______                _______                      .-''-.
\\  ___ `'.             \\  ___ `'.                 .' .-.  )                    _..._
 ' |--.\\  \\             ' |--.\\  \\               / .'  / /                   .'     '.      _.._
 | |    \\  '            | |    \\  '             (_/   / /                   .   .-.   .   .' .._|
 | |     |  '    __     | |     |  '    __           / /      ,.----------. |  '   '  |   | '
 | |     |  | .:--.'.   | |     |  | .:--.'.        / /      //            \\|  |   |  | __| |__
 | |     ' .'/ |   \\ |  | |     ' .'/ |   \\ |      . '       \\\\            /|  |   |  ||__   __|
 | |___.' /' `" __ | |  | |___.' /' `" __ | |     / /    _.-')`'----------' |  |   |  |   | |
/_______.'/   .'.''| | /_______.'/   .'.''| |   .' '  _.'.-''               |  |   |  |   | |
\\_______|/   / /   | |_\\_______|/   / /   | |_ /  /.-'_.'                   |  |   |  |   | |
             \\ \\._,\\ '/             \\ \\._,\\ '//    _.'                      |  |   |  |   | |
              `--'  `"               `--'  `"( _.-'                         '--'   '--'   |_|


               Support: lars.schreiber@nrc-cnrc.gc.ca
             Home page: https://github.com/lschreib/DADA2-NF
               Version: 0.1
                  Note: Pipeline for running DADA2 pipeline through Nextflow
#####################################################################################################

 input reads  : ${params.DEFAULT.input_reads}
 outdir       : ${params.DEFAULT.outdir}
    """.stripIndent()

/*
  Import processes from external files
  It is common to name processes with UPPERCASE strings, to make
  the program more readable
*/
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SUB-MODULES: Short read pipeline
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { REMOVE_PRIMERS            } from './modules/short_read/remove_primers.nf'
include { TRIM_AND_FILTER           } from './modules/short_read/trim_and_filter.nf'
include { LEARN_ERRORS              } from './modules/short_read/learn_errors.nf'
include { INFER_SAMPLES             } from './modules/short_read/infer_samples.nf'
include { REMOVE_CHIMERA            } from './modules/short_read/remove_chimera.nf'
include { READ_TRACKING             } from './modules/short_read/read_tracking.nf'
include { CLASSIFY_TAXA_DECIPHER    } from './modules/short_read/classify_taxa_decipher.nf'
include { AGGREGATE_TAXONOMY_FLEX   } from './modules/short_read/aggregate_taxonomy_flex.nf'
include { BUILD_TAX_GUIDE_TREE      } from './modules/short_read/build_tax_guide_tree.nf'
include { MAFFT_ALIGNMENT           } from './modules/short_read/mafft_alignment.nf'
include { IQTREE_TREE               } from './modules/short_read/iqtree_tree.nf'
include { FASTTREE_TREE             } from './modules/short_read/fasttree_tree.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SUB-MODULES: Long read pipeline
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { REMOVE_PRIMERS_LONGREAD   } from './modules/long_read/remove_primers_longread.nf'
include { TRIM_AND_FILTER_LONGREAD  } from './modules/long_read/trim_and_filter_longread.nf'
include { DEREPLICATE               } from './modules/long_read/dereplicate.nf'
include { LEARN_ERRORS_LONGREAD     } from './modules/long_read/learn_errors_longread.nf'
include { DENOISE                   } from './modules/long_read/denoise.nf'
include { READ_TRACKING_LONGREAD    } from './modules/long_read/read_tracking_longread.nf'
include { REMOVE_CHIMERA_LONGREAD   } from './modules/long_read/remove_chimera_longread.nf'
include { CLASSIFY_TAXA_DADA2       } from './modules/long_read/classify_taxa_dada2.nf'
include { AGGREGATE_TAXONOMY_LONGREAD} from './modules/long_read/aggregate_taxonomy_longread.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SUB-MODULES: Picrust
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { PICRUST                    } from './modules/picrust/picrust.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SUB-MODULES: FUNGuild
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { FUNGUILD                    } from './modules/funguild/funguild.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WORKFLOW section
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Short read workflow
workflow short_read_decipher {
    //Populate input channel
    if (!params.DEFAULT.input_reads) {
        error "Parameter 'params.input_reads' is not defined. Please check your configuration."
    }
    dir_channel = Channel.fromPath(params.DEFAULT.input_reads, checkIfExists: true)

    main:
        // Initial QC of reads with FASTQC (still missing)

        REMOVE_PRIMERS(dir_channel)

        TRIM_AND_FILTER(REMOVE_PRIMERS.out.primers_removed_dir)

        LEARN_ERRORS(TRIM_AND_FILTER.out.filtered_reads_dir)

        INFER_SAMPLES(TRIM_AND_FILTER.out.filtered_reads_dir,
                      LEARN_ERRORS.out.forward_errors,
                      LEARN_ERRORS.out.reverse_errors)

        REMOVE_CHIMERA(TRIM_AND_FILTER.out.filtered_reads_dir,
                        INFER_SAMPLES.out.forward_sample,
                        INFER_SAMPLES.out.reverse_sample)

        READ_TRACKING(TRIM_AND_FILTER.out.filtered_reads_rds,
                      INFER_SAMPLES.out.forward_sample,
                      INFER_SAMPLES.out.reverse_sample,
                      REMOVE_CHIMERA.out.merged_reads_rds,
                      REMOVE_CHIMERA.out.seqtab_nochim_rds)

        CLASSIFY_TAXA_DECIPHER(REMOVE_CHIMERA.out.seqtab_nochim_rds)

        // Tree building for UniFrac
        if (params.DEFAULT.guide_tree) {
            BUILD_TAX_GUIDE_TREE(CLASSIFY_TAXA_DECIPHER.out.feature_table)
            MAFFT_ALIGNMENT(CLASSIFY_TAXA_DECIPHER.out.feature_refseqs)
            IQTREE_TREE(BUILD_TAX_GUIDE_TREE.out.output_tree, MAFFT_ALIGNMENT.out.output_aligned)
        } else {
            MAFFT_ALIGNMENT(CLASSIFY_TAXA_DECIPHER.out.feature_refseqs)
            FASTTREE_TREE(MAFFT_ALIGNMENT.out.output_aligned)
        }

        ch_aggregation_level = Channel.of(1, 2, 3, 4, 5, 6, 7)

        AGGREGATE_TAXONOMY_FLEX(ch_aggregation_level.combine(CLASSIFY_TAXA_DECIPHER.out.feature_table))
}

// Classification-only workflow
// (mostly just used for downstream classification after combining seqtables of different runs)
// Requires a pre-existing seqtable in RDS format
// Adjust reference database in the config file as needed
workflow classify_only {
    //Populate input channel
    if (!params.DEFAULT.seqtable) {
         error "Parameter 'params.DEFAULT.seqtable' is not defined. Please check your configuration."
    }
    seqtable_channel = Channel.fromPath(params.DEFAULT.seqtable, checkIfExists: true)

    main:
        CLASSIFY_TAXA_DECIPHER(seqtable_channel)
        //CLASSIFY_TAXA_DADA2(seqtable_channel)

        AGGREGATE_TAXONOMY(CLASSIFY_TAXA_DECIPHER.out.feature_table)
}

// Sanger workflow (still to be implemented)
workflow sanger {
}

// Long read workflow
workflow long_read_dada2 {
  //Populate input channel
    if (!params.DEFAULT.input_reads) {
        error "Parameter 'params.input_reads' is not defined. Please check your configuration."
    }
    dir_channel = Channel.fromPath(params.DEFAULT.input_reads, checkIfExists: true)

    main:
        // Initial QC of reads with FASTQC (still missing)

        REMOVE_PRIMERS_LONGREAD(dir_channel)

        TRIM_AND_FILTER_LONGREAD(REMOVE_PRIMERS_LONGREAD.out.primers_removed_dir)

        DEREPLICATE(TRIM_AND_FILTER_LONGREAD.out.filtered_reads_dir)

        LEARN_ERRORS_LONGREAD(DEREPLICATE.out.dereplicated_rds)

        DENOISE(DEREPLICATE.out.dereplicated_rds,
                LEARN_ERRORS_LONGREAD.out.errors_output)

        REMOVE_CHIMERA_LONGREAD(DENOISE.out.denoised_output)

        READ_TRACKING_LONGREAD(REMOVE_PRIMERS_LONGREAD.out.primers_removed_rds,
                               TRIM_AND_FILTER_LONGREAD.out.filtered_reads_rds,
                               DENOISE.out.denoised_output,
                               REMOVE_CHIMERA_LONGREAD.out.seqtab_nochim_rds)

        CLASSIFY_TAXA_DADA2(REMOVE_CHIMERA_LONGREAD.out.seqtab_nochim_rds)

        AGGREGATE_TAXONOMY_LONGREAD(CLASSIFY_TAXA_DADA2.out.feature_table)
}

// Picrust workflow
workflow picrust {
  //Populate input channel
    if (!params.picrust.input_seqs) {
        error "Parameter 'params.picrust.input_seqs' is not defined. Please check your configuration."
    }
    ref_seq_channel = Channel.fromPath(params.picrust.input_seqs, checkIfExists: true)

    if (!params.picrust.input_table) {
        error "Parameter 'params.picrust.input_table' is not defined. Please check your configuration."
    }
    feature_table_channel = Channel.fromPath(params.picrust.input_table, checkIfExists: true)

    main:
        // Initial QC of reads with FASTQC (still missing)

        PICRUST(ref_seq_channel, feature_table_channel)
}


// FUNGuild workflow
workflow funguild {
  //Populate input channel
    if (!params.funguild.input_table) {
        error "Parameter 'params.funguild.input_table' is not defined. Please check your configuration."
    }
    feature_table_channel = Channel.fromPath(params.funguild.input_table, checkIfExists: true)

    main:
        // Initial QC of reads with FASTQC (still missing)

        FUNGUILD(feature_table_channel)
}
