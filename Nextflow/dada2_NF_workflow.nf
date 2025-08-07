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
include { AGGREGATE_TAXONOMY        } from './modules/short_read/aggregate_taxonomy.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SUB-MODULES: Long read pipeline (still TBD)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


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
        // Initial QC of reads with FASTQC
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

        AGGREGATE_TAXONOMY(CLASSIFY_TAXA_DECIPHER.out.feature_table)
}

// Sanger workflow (still to be implemented)
workflow sanger {
}

// Long read workflow (still to be implemented)
workflow long_read_decipher {
}

