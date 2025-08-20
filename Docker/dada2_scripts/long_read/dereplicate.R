#!/usr/bin/env Rscript

# Load necessary libraries
suppressMessages(library(optparse))
suppressMessages(library(dada2))

# Define command-line options
option_list <- list(
    make_option(c("-i", "--input_dir"),
        type = "character", default = NULL,
        help = "Path to input folder containing FASTQ files", metavar = "character"
    ),
    make_option(c("-t", "--threads"),
        type = "integer", default = 1,
        help = "Number of threads to use (DEFAULT: 1)", metavar = "integer"
    ),
    make_option(c("-v", "--verbose"),
        type = "character", default = "FALSE", metavar = "character",
        help = "Print extra output ('TRUE'| 'FALSE')(DEFAULT: 'FALSE')"
    )
)

# Parse command-line arguments
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# Check if required arguments are provided
if (is.null(opt$input_dir)) {
    stop("Error: Input directory is required. Use -i or --input to specify the input directory.")
}


# Main script logic
path <- opt$input_dir
if (!dir.exists(path)) {
    stop("Error: Input directory does not exist.")
}
all_files <- list.files(path, pattern = "\\.fastq(\\.gz)?$", recursive = TRUE)

if (grepl("\\.gz$", all_files[1])) {
    pattern_reads <- ".fastq.gz"
} else if (grepl("\\.fastq$", all_files[1])) {
    pattern_reads <- ".fastq"
} else {
    stop(paste(
        "Error: No valid paired-end FASTQ files found in the input directory.",
        "Ensure files are named with either '_R1_001.fastq(.gz)' and '_R2_001.fastq(.gz)',",
        "or '_R1.fastq(.gz)' and '_R2.fastq(.gz)'."
    ))
}

in_files <- sort(list.files(path, pattern = pattern_reads, full.names = TRUE, recursive = TRUE))

outdir <- opt$output_dir

drp <- derepFastq(in_files, verbose = as.logical(opt$verbose))

saveRDS(drp, file = "derep_output.rds")
