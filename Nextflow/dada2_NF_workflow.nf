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
}

