#!/usr/bin/env Rscript

# Load necessary libraries
suppressMessages(library(optparse))
suppressMessages(library(dada2))

# Define command-line options
option_list <- list(
    make_option(c("-d", "--derep_file"),
        type = "character", default = NULL,
        help = "Path to input file in RDS format containing a DADA2 derep-class object and generated during the dereplication step", metavar = "character"
    ),
    make_option(c("-e", "--error_file"),
        type = "character", default = NULL,
        help = "Path to input file in RDS format containing a DADA2 error model object", metavar = "character"
    ),
    make_option(c("-b", "--band_size"),
        type = "integer", default = 32, metavar = "integer",
        help = "Band size for banded Needleman-Wunsch alignment (DEFAULT: 32)"
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
if (is.null(opt$derep_file)) {
    stop("Error: Dereplication file is required. Use -d or --derep_file to specify the dereplication file.")
}
if (is.null(opt$error_file)) {
    stop("Error: Error file is required. Use -e or --error_file to specify the error file.")
}


# Main script logic
if (!file.exists(opt$derep_file)) {
    stop("Error: Dereplication file does not exist.")
}
derep_file <- readRDS(opt$derep_file)

if (!file.exists(opt$error_file)) {
    stop("Error: Error file does not exist.")
}
error <- readRDS(opt$error_file)

denoised <- dada(derep_file,
    err = error,
    BAND_SIZE = opt$band_size,
    multithread = opt$threads,
    verbose = as.logical(opt$verbose)
)
saveRDS(denoised, file = "denoised_output.rds")
