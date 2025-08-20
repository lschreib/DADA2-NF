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
    make_option(c("-m", "--min_length"),
        type = "integer", default = 1000,
        help = "Remove reads with length less than min length (DEFAULT: 1000)", metavar = "integer"
    ),
    make_option(c("-x", "--max_length"),
        type = "integer", default = 1600,
        help = "Remove reads with length greater than max length (DEFAULT: 1600)", metavar = "integer"
    ),
    make_option(c("-n", "--max_n"),
        type = "integer", default = 0,
        help = "Maximum number of N's allowed in a read (DEFAULT: 0)", metavar = "integer"
    ),
    make_option(c("-d", "--max_ee"),
        type = "integer", default = 2,
        help = "Maximum expected errors allowed in a forward read (DEFAULT: 2)", metavar = "integer"
    ),
    make_option(c("-q", "--trunc_q"),
        type = "integer", default = 2,
        help = "Truncate reads at the first instance of a quality score less than or equal to trunc_q (DEFAULT: 2)", metavar = "integer"
    ),
    make_option(c("-y", "--min_q"),
        type = "integer", default = 3,
        help = "After truncation, reads contain a quality score less than min_q will be discarded (DEFAULT: 3)", metavar = "integer"
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

out_files <- file.path(outdir, ifelse(grepl("\\.gz$", basename(in_files)), basename(in_files), paste0(basename(in_files), ".gz"))) # Put trimmed files in output directory

out <- filterAndTrim(in_files, out_files,
    maxN = opt$max_n,
    maxEE = opt$max_ee,
    truncQ = opt$trunc_q,
    minQ = opt$min_q,
    minLen = opt$min_length,
    maxLen = opt$max_length,
    rm.phix = TRUE,
    compress = TRUE,
    multithread = opt$threads,
    verbose = as.logical(opt$verbose)
)

saveRDS(out, file = "filter_and_trim_output.rds")

# Forward and reverse fastq filenames have the format:
cuts <- sort(list.files(outdir, pattern = pattern_reads, full.names = TRUE))

# Let's save some plots of the resulting read quality stats
if (length(cuts) == 0) {
    stop("Error: No trimmed FASTQ files found. Please check the input directory and primer sequences.")
}

if (length(cuts) >= 2) {
    forward_qc_plot <- plotQualityProfile(cuts[1:2])
    ggsave("quality_profile.postTrim.png", forward_qc_plot, width = 8, height = 6)
} else if (length(cuts) == 1) {
    forward_qc_plot <- plotQualityProfile(cuts[1])
    ggsave("quality_profile.postTrim.png", forward_qc_plot, width = 8, height = 6)
} else {
    stop("No reads found for quality profile plotting.")
}
