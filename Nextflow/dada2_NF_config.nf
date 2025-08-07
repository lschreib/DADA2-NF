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
    container = "file:///$INSTALL_HOME/software/imagefiles/dada2/dada2_v4.5.1.sif"
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
        input_reads = "$projectDir/reads_workdir/"
        outdir = "$projectDir/output/"
	}
    

    /*
        Customized parameters for individual processes
    */
    
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
        truncation_length_fwd = 230 // Forward reads will be truncated to this length
        truncation_length_rev = 230 // Reverse reads will be truncated to this length
        
        max_n = 0 // Maximum number of Ns allowed in reads
        max_ee_fwd = 2.0 // Maximum expected errors for forward reads   
        max_ee_rev = 2.0 // Maximum expected errors for reverse reads

        terminal_trunc_q = 20 // Quality score threshold for terminal truncation

        min_length = 100 // Minimum acceptable length of reads after trimming
    }

    learn_errors {
        cluster_time = 12.h
        cluster_cpus = 12
        cluster_memory = 36.GB

        // Whether to randomize the input reads ('TRUE'| 'FALSE')
        randomize = "TRUE"
    }

   infer_samples {
        cluster_time = 12.h
        cluster_cpus = 12
        cluster_memory = 36.GB
    }

    remove_chimeras {
        cluster_time = 12.h
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
        cluster_time = 12.h
        cluster_cpus = 12
        cluster_memory = 36.GB
        
        /*
            Parameters for taxonomic classification
        */

        //16S RNA reference database
        reference_database = "$INSTALL_HOME/databases/dada2/SILVA/SILVA_138.1_SSURef_NR99_tax_silva.rds"

        //ITS reference database
        //reference_database = "$INSTALL_HOME/databases/dada2/UNITE/UNITE_10.0.0.rds"
    }

    aggregate {
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
    CONFIG: Long read workflow (still TBD)
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    */
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

