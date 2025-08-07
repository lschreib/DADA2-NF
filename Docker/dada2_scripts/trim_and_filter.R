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
    make_option(c("-o", "--output_dir"),
        type = "character", default = NULL,
        help = "Path to output directory", metavar = "character"
    ),
    make_option(c("-f", "--trunc_len_fwd"),
        type = "integer", default = 0,
        help = "Truncation length for forward reads (DEFAULT: 0). 0 = no truncation", metavar = "integer"
    ),
    make_option(c("-r", "--trunc_len_rev"),
        type = "integer", default = 0,
        help = "Truncation length for reverse reads (DEFAULT: 0). 0 = no truncation", metavar = "integer"
    ),
    make_option(c("-n", "--max_n"),
        type = "integer", default = 0,
        help = "Maximum number of N's allowed in a read (DEFAULT: 0)", metavar = "integer"
    ),
    make_option(c("-d", "--max_ee_fwd"),
        type = "integer", default = 2,
        help = "Maximum expected errors allowed in a forward read (DEFAULT: 2)", metavar = "integer"
    ),
    make_option(c("-e", "--max_ee_rev"),
        type = "integer", default = 2,
        help = "Maximum expected errors allowed in a reverse read (DEFAULT: 2)", metavar = "integer"
    ),
    make_option(c("-q", "--trunc_q"),
        type = "integer", default = 2,
        help = "Quality score threshold for truncation (DEFAULT: 2)", metavar = "integer"
    ),
    make_option(c("-m", "--min_length"),
        type = "integer", default = 100,
        help = "Minimum length of reads after trimming (DEFAULT: 100)", metavar = "integer"
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

if (is.null(opt$output_dir)) {
    stop("Error: Output directory is required. Use -o or --output to specify the output directory.")
}

# Main script logic
path <- opt$input_dir
if (!dir.exists(path)) {
    stop("Error: Input directory does not exist.")
}
all_files <- list.files(path, pattern = "\\.fastq(\\.gz)?$", recursive = TRUE)

if (grepl("_001\\.", all_files[1])) {
    pattern_FWD <- "_R1_001.fastq.gz"
    pattern_REV <- "_R2_001.fastq.gz"
} else if ((grepl("_R1.", all_files[1]))) {
    pattern_FWD <- "_R1.fastq.gz"
    pattern_REV <- "_R2.fastq.gz"
} else {
    stop(paste(
        "Error: No valid paired-end FASTQ files found in the input directory.",
        "Ensure files are named with either '_R1_001.fastq' and '_R2_001.fastq',",
        "or '_R1.fastq' and '_R2.fastq'."
    ))
}

inFs <- list.files(path, pattern = pattern_FWD, full.names = TRUE)
inRs <- list.files(path, pattern = pattern_REV, full.names = TRUE)

outFs <- file.path(paste0("filtered/", basename(inFs)))
outRs <- file.path(paste0("filtered/", basename(inRs)))

out <- filterAndTrim(inFs, outFs, inRs, outRs,
    truncLen = c(opt$trunc_len_fwd, opt$trunc_len_rev),
    maxN = opt$max_n, maxEE = c(opt$max_ee_fwd, opt$max_ee_rev), truncQ = opt$trunc_q, minLen = opt$min_length, rm.phix = TRUE,
    compress = TRUE, multithread = opt$threads, verbose = as.logical(opt$verbose)
)

saveRDS(out, file = "filter_and_trim_output.rds")

# Let's save the plots of the resulting read quality stats
if (length(outFs) == 0 || length(outRs) == 0) {
    stop("Error: No trimmed FASTQ files found. Please check the input directory and primer sequences.")
}

if (length(outFs) >= 2) {
    forward_qc_plot <- plotQualityProfile(outFs[1:2])
    ggsave("forward_quality_profile.postTrim.png", forward_qc_plot, width = 8, height = 6)
} else if (length(outFs) == 1) {
    forward_qc_plot <- plotQualityProfile(outFs[1])
    ggsave("forward_quality_profile.postTrim.png", forward_qc_plot, width = 8, height = 6)
} else {
    stop("No forward reads found for quality profile plotting.")
}

if (length(outRs) >= 2) {
    reverse_qc_plot <- plotQualityProfile(outRs[1:2])
    ggsave("reverse_quality_profile.postTrim.png", reverse_qc_plot, width = 8, height = 6)
} else if (length(outRs) == 1) {
    reverse_qc_plot <- plotQualityProfile(outRs[1])
    ggsave("reverse_quality_profile.postTrim.png", reverse_qc_plot, width = 8, height = 6)
} else {
    stop("No reverse reads found for quality profile plotting.")
}
