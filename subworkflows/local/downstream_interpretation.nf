/*
 * Downstream interpretation subworkflow.
 * Optional tools are gated by user parameters.
 */

include { PICRUST2_INTERPRET } from '../../modules/local/downstream/picrust2_interpret.nf'
include { FAPROTAX_INTERPRET } from '../../modules/local/downstream/faprotax_interpret.nf'
include { FUNGUILD_INTERPRET } from '../../modules/local/downstream/funguild_interpret.nf'

workflow DOWNSTREAM_INTERPRETATION {
    take:
        feature_table_ch
        feature_refseqs_ch

    main:
        if (params.run_picrust2) {
            PICRUST2_INTERPRET(feature_refseqs_ch, feature_table_ch)
        }

        if (params.run_faprotax) {
            FAPROTAX_INTERPRET(feature_table_ch)
        }

        if (params.run_funguild) {
            FUNGUILD_INTERPRET(feature_table_ch)
        }

    emit:
        picrust2 = params.run_picrust2 ? PICRUST2_INTERPRET.out.picrust2_output : Channel.empty()
        faprotax = params.run_faprotax ? FAPROTAX_INTERPRET.out.faprotax_output : Channel.empty()
        funguild = params.run_funguild ? FUNGUILD_INTERPRET.out.funguild_output : Channel.empty()
}
