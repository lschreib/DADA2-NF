#' @title Remove Chimeras from Paired-End FASTQ Files using DADA2
#'
#' @description
#' This script processes paired-end FASTQ files to remove chimeric sequences using the DADA2 pipeline.
#' It merges paired reads, constructs a sequence table, removes chimeras, and outputs results in RDS, TSV, and FASTA formats.
#'
#' @details
#' The script expects input FASTQ files to be named with either '_R1_001.fastq(.gz)' and '_R2_001.fastq(.gz)',
#' or '_R1.fastq(.gz)' and '_R2.fastq(.gz)'. It uses error models (RDS files) for forward and reverse reads,
#' merges paired reads, constructs a sequence table, removes chimeras using the specified method,
#' and outputs various summary statistics and processed data files.
#'
#' @param -i, --input_dir [character] Path to input folder containing FASTQ files. (Required)
#' @param -f, --forward_sample [character] Path to forward error model file in RDS format. (Required)
#' @param -r, --reverse_sample [character] Path to reverse error model file in RDS format. (Required)
#' @param -m, --method [character] Method for chimera removal ('consensus' | 'pooled' | 'per-sample'). Default: 'consensus'
#' @param -t, --threads [integer] Number of threads to use. Default: 1
#' @param -v, --verbose [character] Print extra output ('TRUE' | 'FALSE'). Default: 'FALSE'
#'
#' @return
#' The script generates the following output files in the working directory:
#' \itemize{
#'   \item merged_reads.rds: Merged paired-end reads.
#'   \item seqtab_dimensions.raw.tsv: Sequence table dimensions before chimera removal.
#'   \item seqtab_length_distribution.raw.tsv: Distribution of sequence lengths before chimera removal.
#'   \item seqtab_dimensions.nochim.tsv: Sequence table dimensions after chimera removal.
#'   \item seqtab_length_distribution.nochim.tsv: Distribution of sequence lengths after chimera removal.
#'   \item seqtab.nochim.rds: Sequence table after chimera removal.
#'   \item seqtab.nochim.fasta: Non-chimeric sequences in FASTA format.
#'   \item seqtab.nochim.tsv: Non-chimeric sequence table in TSV format.
#' }
#'
#' @examples
#' # Run the script from the command line:
#' # Rscript remove_chimera.R -i /path/to/fastq_dir -f forward.rds -r reverse.rds -m consensus -t 4 -v TRUE
#'
#' @author
#' Lars Schreiber
# !/usr/bin/env Rscript

# Load necessary libraries
suppressMessages(library(optparse))
suppressMessages(library(dada2))
suppressMessages(library(readr))
suppressMessages(library(ShortRead))

# Define command-line options
option_list <- list(
    make_option(c("-i", "--input_dir"),
        type = "character", default = NULL,
        help = "Path to input folder containing FASTQ files", metavar = "character"
    ),
    make_option(c("-f", "--forward_sample"),
        type = "character", default = NULL,
        help = "Path to forward error model file in RDS format", metavar = "character"
    ),
    make_option(c("-r", "--reverse_sample"),
        type = "character", default = NULL,
        help = "Path to reverse error model file in RDS format", metavar = "character"
    ),
    make_option(c("-m", "--method"),
        type = "character", default = "consensus",
        help = "Method for chimera removal ('consensus'| 'pooled'| 'per-sample')(DEFAULT: consensus)", metavar = "character"
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

dadaFs <- readRDS(opt$forward_sample)
dadaRs <- readRDS(opt$reverse_sample)

mergers <- mergePairs(dadaFs, inFs, dadaRs, inRs, verbose = as.logical(opt$verbose))
saveRDS(mergers, file = "merged_reads.rds")

seqtab <- makeSequenceTable(mergers)
saveRDS(seqtab, file = "seqtab.rds")

# Inspect sequence table dimensions
stats_before <- data.frame("samples" = dim(seqtab)[1], "unique_sequences" = dim(seqtab)[2])
write_tsv(stats_before, "seqtab_dimensions.raw.tsv")

# Inspect distribution of sequence lengths
write_tsv(as.data.frame(table(nchar(getSequences(seqtab)))), "seqtab_length_distribution.raw.tsv")

# Remove chimeras
seqtab.nochim <- removeBimeraDenovo(seqtab, method = opt$method, multithread = opt$threads, verbose = as.logical(opt$verbose))

# Inspect sequence table dimensions
stats_before <- data.frame("samples" = dim(seqtab.nochim)[1], "unique_sequences" = dim(seqtab.nochim)[2])
write_tsv(stats_before, "seqtab_dimensions.nochim.tsv")

# Inspect distribution of sequence lengths
write_tsv(as.data.frame(table(nchar(getSequences(seqtab.nochim)))), "seqtab_length_distribution.nochim.tsv")

# Save the sequence table
saveRDS(seqtab.nochim, file = "seqtab.nochim.rds")

# Save the sequence table in FASTA format
fasta_file <- "seqtab.nochim.fasta"
writeFasta(getSequences(seqtab.nochim), file = fasta_file)

# Save the sequence table in TSV format
tsv_file <- "seqtab.nochim.tsv"
write_tsv(as.data.frame(seqtab.nochim), tsv_file)
