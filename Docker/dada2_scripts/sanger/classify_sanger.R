#!/usr/bin/env Rscript

# Load necessary libraries
suppressMessages(library(optparse))
suppressMessages(library(ShortRead))
suppressMessages(library(Biostrings))
suppressMessages(library(R.utils))
suppressMessages(library(readr))
suppressMessages(library(DECIPHER))

# Define command-line options
option_list <- list(
    make_option(c("-i", "--input_file"),
        type = "character", default = NULL,
        help = "Path to input file containing multi-FASTA sequences that need to be classified.", metavar = "character"
    ),
    make_option(c("-s", "--strand"),
        type = "character", default = "both",
        help = "Strand to use for alignment ('top'|'bottom'|'both')(DEFAULT: 'both')", metavar = "character"
    ),
    make_option(c("-d", "--database"),
        type = "character", default = NULL,
        help = "Path to DECIPHER database file in RDS format", metavar = "character"
    ),
    make_option(c("-t", "--threads"),
        type = "integer", default = 1,
        help = "Number of threads to use (DEFAULT: 1)", metavar = "integer"
    ),
    make_option(c("-v", "--verbose"),
        type = "character", default = "TRUE", metavar = "character",
        help = "Print extra output ('TRUE'| 'FALSE')(DEFAULT: 'TRUE')"
    )
)

# Parse command-line arguments
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# Check if required arguments are provided
if (is.null(opt$input_file)) {
    stop("Error: Input file is required. Use -i or --input_file to specify the input file.")
}

if (is.null(opt$database)) {
    stop("Error: DECIPHER database is required. Use -d or --database to specify the DECIPHER database.")
}

# Main script logic
fasta_file <- opt$input_file
if (!file.exists(fasta_file)) {
    stop("Error: Input file does not exist.")
}

dna <- tryCatch(
    {
        readDNAStringSet(filepath = fasta_file, format = "fasta")
    },
    error = function(e) {
        stop(paste("Error: The file", fasta_file, "is not a valid FASTA file or could not be read."))
    }
)

# Load the training set that we have created before
trainingSet <- readRDS(file = opt$database)
if (is.null(trainingSet)) {
    stop("Error: DECIPHER database not loaded correctly. Please check the file path and format.")
}

# For amplicons we cannot really predict the orientation so let's do both
ids <- IdTaxa(dna, trainingSet, strand = "both", processors = opt$threads, verbose = as.logical(opt$verbose), type = "collapsed") # use all processors

write_tsv(
    cbind(
        names(ids),
        as.data.frame(ids)
    ),
    file = "classifications.tsv",
    col_names = FALSE
)
