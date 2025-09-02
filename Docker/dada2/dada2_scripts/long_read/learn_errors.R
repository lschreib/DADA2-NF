#!/usr/bin/env Rscript

# Load necessary libraries
suppressMessages(library(optparse))
suppressMessages(library(dada2))
suppressMessages(library(ggplot2))

# Define command-line options
option_list <- list(
    make_option(c("-i", "--input_file"),
        type = "character", default = NULL,
        help = "Path to input file in RDS format containing a DADA2 derep-class object and generated during the dereplication step", metavar = "character"
    ),
    make_option(c("-b", "--band_size"),
        type = "integer", default = 32, metavar = "integer",
        help = "Band size for banded Needleman-Wunsch alignment (DEFAULT: 32)"
    ),
    make_option(c("-e", "--error_function"),
        type = "character", default = "PacBioErrfun", metavar = "character",
        help = "Error function to use (DEFAULT: 'PacBioErrfun')"
    ),
    make_option(c("-r", "--randomize"),
        type = "character", default = "TRUE", metavar = "character",
        help = "Randomize read order ('TRUE'| 'FALSE')(DEFAULT: 'TRUE')"
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
if (is.null(opt$input_file)) {
    stop("Error: Input file is required. Use -i or --input_file to specify the input file.")
}


# Main script logic
if (!file.exists(opt$input_file)) {
    stop("Error: Input file does not exist.")
}
derep_file <- readRDS(opt$input_file)

error <- learnErrors(derep_file,
    randomize = opt$randomize,
    errorEstimationFunction = get(opt$error_function),
    BAND_SIZE = opt$band_size,
    multithread = opt$threads,
    verbose = as.logical(opt$verbose)
)
saveRDS(error, file = "learn_error_output.rds")

error_plot <- plotErrors(error, nominalQ = TRUE)
ggsave("error_profile.png", error_plot, width = 8, height = 6)
