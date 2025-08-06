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
SUB-MODULES to be imported
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { REMOVE_PRIMERS            } from './modules/remove_primers.nf'



/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WORKFLOW section
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow initial_qc {
    //Populate input channel
    if (!params.DEFAULT?.illumina_reads) {
        error "Parameter 'params.DEFAULT.illumina_reads' is not defined. Please check your configuration."
    }
    raw_reads_channel = Channel.fromFilePairs(params.DEFAULT.illumina_reads, checkIfExists:true)

    main:
        // Initial QC of reads with FASTQC
        FASTQC_RAW(raw_reads_channel)
}

workflow trimming_illumina {
    //Populate input channel
    if (!params.DEFAULT?.illumina_reads) {
        error "Parameter 'params.DEFAULT.illumina_reads' is not defined. Please check your configuration."
    }
    raw_reads_illumina_channel = Channel.fromFilePairs(params.DEFAULT.illumina_reads, checkIfExists:true)

    main:
        // Illumina trimming
        TRIMMOMATIC(raw_reads_illumina_channel)

        // Now send on the reads from Trimmomatic to bbduk for additional adapter removal
        BBDUK(TRIMMOMATIC.out.reads)

        // A final QC with FASTQC before we continue with the assembly
        FASTQC_TRIM(BBDUK.out.reads.map { it -> [it[0], [it[1], it[2]]] })
}

workflow trimming_pacbio {
    //Populate input channel
    if (!params.DEFAULT?.pacbio_reads) {
        error "Parameter 'params.DEFAULT.pacbio_reads' is not defined. Please check your configuration."
    }
    raw_reads_pacbio_channel = Channel.fromPath(params.DEFAULT.pacbio_reads, checkIfExists:true)

    main:
        // Initial QC of reads: LongQC
        LONGQC_RAW(raw_reads_pacbio_channel)

        // Read trimming and adpater removal: HIFIAdapterFilt
        HIFI_ADAPTER_FILT(raw_reads_pacbio_channel)

        // Read quality filtering: FiltLong
        FILTLONG(HIFI_ADAPTER_FILT.out.filtered_reads)

        // Post-trimming QC: LongQC
        LONGQC_TRIM(FILTLONG.out.filtered_reads)
}

workflow assembly_nuc {
    // Populate the input channel with the output of the trimming_and_filtering workflow
    if (!params.DEFAULT?.outdir) {
        error "Parameter 'params.DEFAULT.outdir' is not defined. Please check your configuration."
    }

    if (!file("$projectDir/output/qced_reads/filtlong/*.fastq.gz", checkIfExists: true)) {
        error "Output file of qced pacbio reads does not exist. Please run trimming_pacbio step before assembly."
    }
    qc_long_reads_channel = Channel.fromPath("$projectDir/output/qced_reads/filtlong/*.fastq.gz", checkIfExists:true)

    main:
        /*
            Assembly
        */
        // Assembly of nuclear genome: HIFIasm
        HIFIASM(qc_long_reads_channel)
}

workflow polishing_nuc {
    // Populate the input channel with the output of assembly workflow
    if (!params.DEFAULT?.outdir) {
        error "Parameter 'params.DEFAULT.outdir' is not defined. Please check your configuration."
    }

    //***Assembly channel***
    if (!file("$params.DEFAULT.outdir/assembly/nuc/*.asm.bp.p_ctg.fa", checkIfExists:true)) {
        error "Output file of genome assembly does not exist. Please run assembly step before polishing."
    }
    assembly_channel = Channel.fromPath("$params.DEFAULT.outdir/assembly/nuc/*.asm.bp.p_ctg.fa", checkIfExists:true)

    //***Pacbio reads channel***
    if (!file("$params.DEFAULT.outdir/qced_reads/filtlong/*.fastq.gz", checkIfExists: true)) {
        error "Output file of qced pacbio reads does not exist. Please run trimming_pacbio step before polishing."
    }
    qc_pacbio_reads_channel = Channel.fromPath("$params.DEFAULT.outdir/qced_reads/filtlong/*.fastq.gz", checkIfExists:true)

    //***Illumina reads channel***
    if (!file("$params.DEFAULT.outdir/qced_reads/*_paired_ncontam_R{1,2}.fastq.gz", checkIfExists: true)) {
        error "QC reads files do not exist. Please run the trimming workflow before assembly."
    }
    qc_illumina_reads_channel  = Channel.fromFilePairs("$params.DEFAULT.outdir/qced_reads/*_paired_ncontam_R{1,2}.fastq.gz", checkIfExists:true, flat:true)

    main:
        /*
            Genome polishing
        */
        // Step 1: Racon w/ filtered Pacbio reads
        // Note: The Hifiasm overlap output appears to be not be compatible with Racon,
        // so we will need to generate it separately first using minimap2.
        MINIMAP(qc_pacbio_reads_channel, assembly_channel)
        RACON(qc_pacbio_reads_channel, assembly_channel, MINIMAP.out.overlaps_sam)

        // Step 2: Medaka w/ filtered Pacbio reads
        MEDAKA(qc_pacbio_reads_channel, RACON.out.polished_racon_fa)

        // Step 3: Polca w/ illumina reads (reads generated for organelle assembly)
        POLCA(qc_illumina_reads_channel, MEDAKA.out.polished_medaka_fa)
}

workflow assembly_pt {
    // Populate the input channel with the output of the trimming workflow
    if (!params.DEFAULT?.outdir) {
        error "Parameter 'params.DEFAULT.outdir' is not defined. Please check your configuration."
    }
    if (!file("$params.DEFAULT.outdir/qced_reads/*_paired_ncontam_R{1,2}.fastq.gz", checkIfExists: true)) {
        error "QC reads files do not exist. Please run the trimming workflow before assembly."
    }

    qc_reads  = Channel.fromFilePairs("$params.DEFAULT.outdir/qced_reads/*_paired_ncontam_R{1,2}.fastq.gz", checkIfExists:true, flat:true)

    sample_id = qc_reads.collect{ it[0] }
    R1        = qc_reads.collect{ it[1] }
    R2        = qc_reads.collect{ it[2] }

    main:
        // Assembly of plastid genome: GetOrganelle
        GET_ORGANELLE_PT(sample_id, R1, R2)
}

workflow assembly_mt {
    if (!params.DEFAULT?.outdir) {
        error "Parameter 'params.DEFAULT.outdir' is not defined. Please check your configuration."
    }

    if (!file("$projectDir/output/qced_reads/filtlong/*.fastq.gz", checkIfExists: true)) {
        error "Output file of qced pacbio reads does not exist. Please run trimming_pacbio step before assembly."
    }
    qc_long_reads_channel = Channel.fromPath("$projectDir/output/qced_reads/filtlong/*.fastq.gz", checkIfExists:true)

    main:
        /*
            Assembly
        */
        // Assembly of mitochondrial genome: MITOHIFI
        FASTQ_TO_FASTA(qc_long_reads_channel)
        MITOHIFI(FASTQ_TO_FASTA.out.fasta)
}

workflow annotation_pt {
    if (!file("$params.DEFAULT.outdir/assembly/pt/final_assembly.fa", checkIfExists: true)) {
        error "FASTA file of assembled plastid genome does not exist. Please run assembly_pt step (and verify results) before genome annotation."
    }
    assembly_channel = Channel.fromPath("$params.DEFAULT.outdir/assembly/pt/final_assembly.fa", checkIfExists:true)

    main:
        // Annotation of plastid genome: CPGAVAS
        CPGAVAS(assembly_channel)
}

