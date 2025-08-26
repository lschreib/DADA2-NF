#!/usr/bin/env Rscript

# Load necessary libraries
suppressMessages(library(optparse))
suppressMessages(library(dada2))
suppressMessages(library(readr))
suppressMessages(library(ShortRead))

# Define command-line options
option_list <- list(
    make_option(c("-r", "--removed_primer"),
        type = "character", default = "removed_primers_output.rds",
        help = "Path to removed primers output file in RDS format (DEFAULT: removed_primers_output.rds)", metavar = "character"
    ),
    make_option(c("-f", "--filter_output"),
        type = "character", default = "filter_and_trim_output.rds",
        help = "Path to filtering output file in RDS format (DEFAULT: filter_and_trim_output.rds)", metavar = "character"
    ),
    make_option(c("-d", "--denoised_output"),
        type = "character", default = "denoised_output.rds",
        help = "Path to denoised output file in RDS format (DEFAULT: denoised_output.rds)", metavar = "character"
    ),
    make_option(c("-c", "--removed_chimera"),
        type = "character", default = "removed_chimera.rds",
        help = "Path to removed chimera sequence table file in RDS format (DEFAULT: removed_chimera.rds)", metavar = "character"
    )
)

# Parse command-line arguments
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)


# Main script logic
getN <- function(x) sum(getUniques(x))

removed_primer_output <- readRDS(opt$removed_primer)
filtered_output <- readRDS(opt$filter_output)
denoised_output <- readRDS(opt$denoised_output)
seqtab.nochim <- readRDS(opt$removed_chimera)

track <- as.data.frame(cbind(
    raw = removed_primer_output[, 1],
    primer_removal = removed_primer_output[, 2],
    filtered = filtered_output[, 2],
    denoised = sapply(denoised_output, function(x) sum(x$denoised)),
    chimera_removal = rowSums(seqtab.nochim)
))

sample.names <- rownames(filtered_output)
track$sample <- sample.names

write_tsv(track, file = "read_tracking.tsv")
