/*
 * DADA2-NF
 * version: 0.2.0
 * description: nf-core-style amplicon sequencing pipeline for DADA2-based processing.
 * authors: Lars Schreiber
 */

nextflow.enable.dsl = 2

include { SHORT_READ_PIPELINE } from './subworkflows/local/short_read.nf'
include { LONG_READ_PIPELINE } from './subworkflows/local/long_read.nf'
include { DOWNSTREAM_INTERPRETATION } from './subworkflows/local/downstream_interpretation.nf'

def resolvePath(path) {
    if (path == null) {
        return null
    }

    def path_str = path.toString()

    if (
        path_str.startsWith('/') ||
        path_str.startsWith('s3://') ||
        path_str.startsWith('gs://') ||
        path_str.startsWith('az://') ||
        path_str.startsWith('http://') ||
        path_str.startsWith('https://')
    ) {
        return file(path_str, checkIfExists: true)
    }

    return file("${projectDir}/${path_str}", checkIfExists: true)
}

workflow {
    def mode = (params.workflow_mode ?: 'short_read').toString().trim().toLowerCase()
    def markerGene = (params.marker_gene ?: '').toString().trim().toUpperCase()
    def runFaprotax = params.run_faprotax as boolean
    def runFunguild = params.run_funguild as boolean
    def readsCh = null

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
                Version: 0.2.0
                    Note: Pipeline for running DADA2 pipeline through Nextflow
    #####################################################################################################

    workflow mode: ${mode}
    marker gene  : ${markerGene ?: '(not set)'}
    input reads  : ${params.input_reads}
    outdir       : ${params.outdir}
    downstream   : faprotax=${runFaprotax}, funguild=${runFunguild}
    """.stripIndent()

    if ((runFaprotax || runFunguild) && !markerGene) {
        error "When a downstream interpretation tool is selected, 'params.marker_gene' must be set to '16S' or 'ITS'."
    }

    if (markerGene && !(markerGene in ['16S', 'ITS'])) {
        error "Unsupported marker_gene='${params.marker_gene}'. Supported marker genes: '16S', 'ITS'."
    }

    if (markerGene == 'ITS' && runFaprotax) {
        error "FAPROTAX is only valid for marker_gene='16S'."
    }

    if (markerGene == '16S' && runFunguild) {
        error "FUNGuild is only valid for marker_gene='ITS'."
    }

    if (runFaprotax && !params.faprotax?.database_path) {
        error "FAPROTAX requested but 'params.faprotax.database_path' is not set."
    }

    if (mode in ['short_read', 'long_read']) {
        if (!params.input_reads) {
            error "Parameter 'params.input_reads' is not defined for workflow_mode='${mode}'."
        }
        readsCh = Channel.fromPath(params.input_reads, checkIfExists: true)
    }

    switch (mode) {
        case 'short_read':
            SHORT_READ_PIPELINE(readsCh)
            if (runFaprotax || runFunguild) {
                DOWNSTREAM_INTERPRETATION(
                    SHORT_READ_PIPELINE.out.feature_table,
                    SHORT_READ_PIPELINE.out.feature_refseqs
                )
            }
            break

        case 'long_read':
            LONG_READ_PIPELINE(readsCh)
            if (runFaprotax || runFunguild) {
                DOWNSTREAM_INTERPRETATION(
                    LONG_READ_PIPELINE.out.feature_table,
                    LONG_READ_PIPELINE.out.feature_refseqs
                )
            }
            break

        default:
            error "Unsupported workflow_mode='${params.workflow_mode}'. Supported modes: 'short_read', 'long_read'."
    }
}
