#!/usr/bin/env Rscript

# Load necessary libraries
suppressMessages(library(optparse))
suppressMessages(library(dada2))
suppressMessages(library(readr))
suppressMessages(library(ShortRead))

# Define command-line options
option_list <- list(
    make_option(c("-f", "--filter_output"),
        type = "character", default = "filter_and_trim_output.rds",
        help = "Path to filtering output file in RDS format (DEFAULT: filter_and_trim_output.rds)", metavar = "character"
    ),
    make_option(c("-s", "--forward_sample"),
        type = "character", default = "forward_sample.rds",
        help = "Path to forward sample model file in RDS format (DEFAULT: forward_sample.rds)", metavar = "character"
    ),
    make_option(c("-r", "--reverse_sample"),
        type = "character", default = "reverse_sample.rds",
        help = "Path to reverse sample model file in RDS format (DEFAULT: reverse_sample.rds)", metavar = "character"
    ),
    make_option(c("-m", "--merged_reads"),
        type = "character", default = "merged_reads.rds",
        help = "Path to merged reads file in RDS format (generated during chimera removal)(DEFAULT: merged_reads.rds)", metavar = "character"
    ),
    make_option(c("-c", "--no_chimera_seq_table"),
        type = "character", default = "seqtab.nochim.rds",
        help = "Path to chimera sequence table file in RDS format (DEFAULT: seqtab.nochim.rds)", metavar = "character"
    )
)

# Parse command-line arguments
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)


# Main script logic
getN <- function(x) sum(getUniques(x))

out <- readRDS(opt$filter_output)
dadaFs <- readRDS(opt$forward_sample)
dadaRs <- readRDS(opt$reverse_sample)
mergers <- readRDS(opt$merged_reads)
seqtab.nochim <- readRDS(opt$no_chimera_seq_table)

track <- as.data.frame(cbind(out, sapply(dadaFs, getN), sapply(dadaRs, getN), sapply(mergers, getN), rowSums(seqtab.nochim)))
# If processing a single sample, remove the sapply calls: e.g. replace sapply(dadaFs, getN) with getN(dadaFs)
colnames(track) <- c("input", "filtered", "denoisedF", "denoisedR", "merged", "nonchim")

sample.names <- sub("_S[0-9]+_.*", "", rownames(out))
track$sample <- sample.names

write_tsv(track, file = "read_tracking.tsv")
