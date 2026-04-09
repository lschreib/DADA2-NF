/*
These following sections (env & executor) are so that the nextflow master
process itself does not run out of memory
*/

executor {
   name = 'slurm'
   cpus = 2
   memory = '8 GB'
   //salloc --time=72:00:00 --account=nrc_eme --mem=8GB --cpus-per-task=1 --ntasks=2
}

process {
    // executor can be either 'local' or 'slurm'
    executor = "slurm"
    clusterOptions = "--account=nrc_eme --export=ALL"

    /*
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONTAINER: DEFAULT
    (This is the standard singularity container to be used unless 
    the process requires a specific one)
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    */
    container = "file:///$INSTALL_HOME/software/imagefiles/dada2/dada2_v4.5.2.sif"

    //Now follow singularity containers for pipeline steps that require specific containers
    /*
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONTAINER: Picrust2
    (This container is used for Picrust2-based functional prediction)
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    */

    withName:PICRUST {
        container = "file:///$INSTALL_HOME/software/imagefiles/picrust2/picrust2_v2.6.2.sif"
    }
}

singularity {
    enabled = true
    autoMounts = true
    runOptions = '-B $TMPDIR -B $SINGULARITY_TMPDIR:/tmp -B $SINGULARITY_TMPDIR:/scratch -B $DATABASES --cleanenv'
    // Allow Singularity to access bashrc variables
    envWhitelist = ['TMPDIR','SINGULARITY_TMPDIR','DATABASES']
}

params {

    clusterOptions = "--account=nrc_eme --export=ALL"

    DEFAULT {
        /* 
            IMPORTANT PARAMETERS - will determine the workflow configuration.
        */
        cluster_time = 2.h
        cluster_cpus = 1
        cluster_memory = 12.GB

        project_id = "dada2"

        // Other parameters that should usually stay the same from one project to another.
        input_reads = "$projectDir/reads_workdir"
        outdir = "$projectDir/output/"
        seqtable = "$projectDir/seqtable_manual/seqtable.rds" // Only needed for classification-only workflow
    }


    /*
        Customized parameters for individual processes
    */

    /*
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG: Unit test workflow
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    */
    unit_test {
        input_reads = "$projectDir/reads_workdir/unit_test"
    }

    /*
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG: Short read workflow
    (This is the standard configuration for short read amplicon sequencing data)
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    */
    remove_primers {
        cluster_time = 1.h
        cluster_cpus = 12
        cluster_memory = 36.GB

        /*
            Parameters for primer removal
        */
        //16S rRNA short (Earth Microbiome Project)
        fwd_primer = "GTGYCAGCMGCCGCGGTAA"  // 515F
        rev_primer = "CCGYCAATTYMTTTRAGTTT"  // 926R

        //16S rRNA long
        //fwd_primer = "AGRGTTYGATYMTGGCTCAG"  // 27F
        //rev_primer = "RGYTACCTTGTTACGACTT"  // 1468R

        //18S rRNA short (Earth Microbiome Project)
        //fwd_primer = "CCAGCASCYGCGGTAATTCC"  // 1391F
        //rev_primer = "ACTTTCGTTCTTGATYRAC"  // 1510R

        //ITS (Earth Microbiome Project)
        //fwd_primer = "CTTGGTCATTTAGAGGAAGTAA"  // ITS1F
        //rev_primer = "GCTGCGTTCTTCATCGATGC"  // ITS2

        min_length = 100 // Minimum acceptable length of reads after primer removal
    }

    trim_and_filter {
        cluster_time = 1.h
        cluster_cpus = 12
        cluster_memory = 36.GB

        /*
            Parameters for read trimming and filtering
        */
        // Reads will be truncated to these lengths;
        // Caution: reads shorter than these lengths will be discarded!!!
        // 0 means no truncation.
        truncation_length_fwd = 0 // Forward reads will be truncated to this length
        truncation_length_rev = 0 // Reverse reads will be truncated to this length

        max_n = 0 // Maximum number of Ns allowed in reads
        max_ee_fwd = 2.0 // Maximum expected errors for forward reads
        max_ee_rev = 2.0 // Maximum expected errors for reverse reads

        trunc_q = 2 // Quality score threshold for terminal truncation

        min_length = 100 // Minimum acceptable length of reads after trimming
    }

    learn_errors {
        cluster_time = 2.h
        cluster_cpus = 12
        cluster_memory = 36.GB

        // Whether to randomize the input reads ('TRUE'| 'FALSE')
        randomize = "TRUE"
    }

    infer_samples {
        cluster_time = 1.h
        cluster_cpus = 12
        cluster_memory = 36.GB
    }

    remove_chimera {
        cluster_time = 1.h
        cluster_cpus = 12
        cluster_memory = 36.GB

        // Method to use for chimera removal ('consensus'| 'pooled'| 'per-sample')
        method = "consensus" 
    }

    read_tracking {
        cluster_time = 1.h
        cluster_cpus = 1
        cluster_memory = 12.GB
    }

    classify_taxa_decipher {
        cluster_time = 1.h
        cluster_cpus = 12
        cluster_memory = 36.GB

        /*
            Parameters for taxonomic classification
        */

        strand = "both" // 'top' | 'bottom' | 'both'
        //16S RNA reference database
        reference_database = "$INSTALL_HOME/databases/dada2/decipher_classifier/silva/DECIPHER_SILVA_SSU_R138.2_NR99_20240918.rds"

        //ITS reference database
        //reference_database = "$INSTALL_HOME/databases/dada2/decipher_classifier/unite/DECIPHER_UNITE_v10.0_20241129.rds"
    }

    aggregate {
        cluster_time = 1.h
        cluster_cpus = 1
        cluster_memory = 12.GB

        // Whether to remove NA values from the aggregated table ('TRUE'| 'FALSE')
        na_remove = "FALSE"
    }

    /*
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG: Long read workflow (still TBD)
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    */

    remove_primers_longread {
        cluster_time = 4.h
        cluster_cpus = 12
        cluster_memory = 36.GB

        /*
            Parameters for primer removal
        */
        //16S rRNA short (Earth Microbiome Project)
        //fwd_primer = "GTGYCAGCMGCCGCGGTAA"  // 515F
        //rev_primer = "CCGYCAATTYMTTTRAGTTT"  // 926R

        //16S rRNA long
        fwd_primer = "AGRGTTYGATYMTGGCTCAG"  // 27F
        rev_primer = "RGYTACCTTGTTACGACTT"  // 1468R

        //16S rRNA long (Archaea - Dalhousie: Integrated Microbiome Resource)
		  //fwd_primer = "TCCGGTTGATCCYGCCGG" //  Arch21Ftrim
		  //rev_primer = "CRGTGWGTRCAAGGRGCA" //  A1401R

        //18S rRNA short (Earth Microbiome Project)
        //fwd_primer = "CCAGCASCYGCGGTAATTCC"  // 1391F
        //rev_primer = "ACTTTCGTTCTTGATYRAC"  // 1510R

        //ITS (Earth Microbiome Project)
        //fwd_primer = "CTTGGTCATTTAGAGGAAGTAA"  // ITS1F
        //rev_primer = "GCTGCGTTCTTCATCGATGC"  // ITS2
    }

    trim_and_filter_longread {
        cluster_time = 4.h
        cluster_cpus = 12
        cluster_memory = 36.GB

        /*
            Parameters for read trimming and filtering
        */
        // Reads will be truncated to these lengths;
        // Caution: reads shorter than these lengths will be discarded!!!
        // 0 means no truncation.
        min_length = 1000 // Minimum read length after trimming
        max_length = 1600 // Maximum read length after trimming

        max_n = 0 // Maximum number of Ns allowed in reads
        max_ee = 2.0 // Maximum expected errors for reads

        trunc_q = 2 // Quality score threshold for terminal truncation
        min_q = 3 // Minimum average quality score of reads after trimming

        verbose = "FALSE" // Whether to print out verbose output ('TRUE' | 'FALSE')
    }

    dereplicate {
        cluster_time = 2.h
        cluster_cpus = 12
        cluster_memory = 36.GB

        verbose = "FALSE" // Whether to print out verbose output ('TRUE' | 'FALSE')
    }

    learn_errors_longread {
        cluster_time = 6.h
        cluster_cpus = 36
        cluster_memory = 96.GB

        band_size = 32 // Band size for alignment (higher values increase sensitivity but also computation time)
        randomize = "TRUE" // Whether to randomize the input reads ('TRUE'| 'FALSE')
        error_function = "PacBioErrfun" // Error function to use ('PacBioErrfun' | 'NanoporeErrfun')
        verbose = "FALSE" // Whether to print out verbose output ('TRUE' | 'FALSE')
    }

    denoise {
        cluster_time = 6.h
        cluster_cpus = 12
        cluster_memory = 36.GB

        band_size = 32 // Band size for alignment (higher values increase sensitivity but also computation time)
        verbose = "FALSE" // Whether to print out verbose output ('TRUE' | 'FALSE')
    }

    remove_chimera_longread {
        cluster_time = 6.h
        cluster_cpus = 12
        cluster_memory = 36.GB

        // Method to use for chimera removal ('consensus'| 'pooled'| 'per-sample')
        method = "consensus" 
        verbose = "FALSE" // Whether to print out verbose output ('TRUE' | 'FALSE')
    }

    read_tracking_longread {
        cluster_time = 1.h
        cluster_cpus = 1
        cluster_memory = 12.GB
    }

    classify_taxa_dada2 {
        cluster_time = 12.h
        cluster_cpus = 12
        cluster_memory = 36.GB

        /*
            Parameters for taxonomic classification
        */

        orientation = "both" // 'forward' |'both'
        //16S RNA reference database (GTDB)
        //reference_database = "$INSTALL_HOME/databases//dada2/dada2_classifier/gtdb/ar53_bac120_ssu_reps_r226.dada2_fmt.fna.gz"

        //16S RNA reference database (SILVA)
        reference_database = "$INSTALL_HOME/databases//dada2/dada2_classifier/silva/silva_nr99_v138.2_toSpecies_trainset.fa.gz"

        //ITS reference database
        //reference_database = "$INSTALL_HOME/databases/dada2/dada2_classifier/unite/UNITE_QIIME_release_10.05.2021_sh_dynamic_all_97rep_set.fasta.gz"

        verbose = "FALSE" // Whether to print out verbose output ('TRUE' | 'FALSE')
    }

    aggregate_longread {
        cluster_time = 1.h
        cluster_cpus = 1
        cluster_memory = 12.GB

        /*
            Parameters for aggregation
        */
        // Level of taxonomy to aggregate (1-8):
        // 1 = domain, 2 = phylum, 3 = class,
        // 4 = order, 5 = family, 6 = genus,
        // 7 = species, 8 = strain/species hypothesis
        aggregation_level = 6

        // Whether to remove NA values from the aggregated table ('TRUE'| 'FALSE')
        na_remove = "FALSE"
    }

    /*
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG: Sanger workflow (still TBD)
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    */


    /*
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG: Picrust
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    */
    picrust {
        cluster_time = 6.h
        cluster_cpus = 12
        cluster_memory = 128.GB

        /*
            Parameters for Picrust2
        */
        // Input fasta file with reference sequences of features
        input_seqs = "$projectDir/output/classification/features.small.fna"
        // Input feature table in TSV format
        input_table = "$projectDir/output/classification/feature_table.small.tsv"
    }
}

manifest {
    name            = "DADA2-NF: Nextflow-powered DADA2 implementation"
    author          = """Lars Schreiber"""
    homePage        = "https://github.com/lschreib/DADA2-NF"
    description     = """Primer removal, read trimming, error and sample modelling, taxonomic classification and aggregation of amplicon sequencing data."""
    mainScript      = "dada2_nf_workflow.nf"
    nextflowVersion = "!>=23.04.3"
    version         = "0.1"
    doi             = "unpublished"
}

