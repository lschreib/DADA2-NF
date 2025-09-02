#!/usr/bin/env Rscript

# Load necessary libraries
suppressMessages(library(optparse))
suppressMessages(library(dada2))
suppressMessages(library(ggplot2))

# Define command-line options
option_list <- list(
    make_option(c("-i", "--input_dir"),
        type = "character", default = NULL,
        help = "Path to input folder containing FASTQ files", metavar = "character"
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
    if (grepl("_001\\.", all_files[1])) {
        pattern_FWD <- "_R1_001.fastq.gz"
        pattern_REV <- "_R2_001.fastq.gz"
    } else if (grepl("_R1.", all_files[1])) {
        pattern_FWD <- "_R1.fastq.gz"
        pattern_REV <- "_R2.fastq.gz"
    }
} else if (grepl("\\.fastq$", all_files[1])) {
    if (grepl("_001\\.", all_files[1])) {
        pattern_FWD <- "_R1_001.fastq"
        pattern_REV <- "_R2_001.fastq"
    } else if (grepl("_R1.", all_files[1])) {
        pattern_FWD <- "_R1.fastq"
        pattern_REV <- "_R2.fastq"
    }
} else {
    stop(paste(
        "Error: No valid paired-end FASTQ files found in the input directory.",
        "Ensure files are named with either '_R1_001.fastq(.gz)' and '_R2_001.fastq(.gz)',",
        "or '_R1.fastq(.gz)' and '_R2.fastq(.gz)'."
    ))
}

inFs <- list.files(path, pattern = pattern_FWD, full.names = TRUE)
inRs <- list.files(path, pattern = pattern_REV, full.names = TRUE)

errF <- learnErrors(inFs, randomize = opt$randomize, multithread = opt$threads, verbose = as.logical(opt$verbose))
saveRDS(errF, file = "forward_errors.rds")

errR <- learnErrors(inRs, randomize = opt$randomize, multithread = opt$threads, verbose = as.logical(opt$verbose))
saveRDS(errR, file = "reverse_errors.rds")

forward_error_plot <- plotErrors(errF, nominalQ = TRUE)
ggsave("forward_error_profile.png", forward_error_plot, width = 8, height = 6)

reverse_error_plot <- plotErrors(errR, nominalQ = TRUE)
ggsave("reverse_error_profile.png", reverse_error_plot, width = 8, height = 6)
