#!/usr/bin/env Rscript

# Load necessary libraries
library(optparse)
library(dada2)
library(ShortRead)
library(Biostrings)
library(R.utils)
library(phyloseq)
library(readr)

# Define command-line options
option_list <- list(
    make_option(c("-i", "--input_dir"), type = "character", default = NULL,
                help = "Path to input folder containing FASTQ files", metavar = "character"),
    make_option(c("-o", "--output_dir"), type = "character", default = NULL,
                help = "Path to output directory", metavar = "character"),
    make_option(c("-f", "--forward_primer"), type = "character", default = NULL,
                help = "Sequence of forward primer", metavar = "character"),
    make_option(c("-r", "--reverse_primer"), type = "character", default = NULL,
                help = "Sequence of reverse primer", metavar = "character"),
    make_option(c("-t", "--threads"), type = "integer", default = 1,
                help = "Number of threads to use", metavar = "integer"),
    make_option(c("-v", "--verbose"), action = "store_true", default = FALSE,
                help = "Print extra output")
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

if (is.null(opt$forward_primer)) {
    stop("Error: Forward primer sequence is required. Use -f or --forward_primer to specify the forward primer sequence.")
}

if (is.null(opt$reverse_primer)) {
    stop("Error: Reverse primer sequence is required. Use -r or --reverse_primer to specify the reverse primer sequence.")
}

# Main script logic
path <- opt$input_dir
if (!dir.exists(path)) {
    stop("Error: Input directory does not exist.")
}   
all_files <- list.files(path, pattern = "\\.fastq(\\.gz)?$", recursive = TRUE)

#Unzip all files
for(i in 1:length(all_files)){
    file_path <- file.path(path, all_files[i])
    if (grepl("\\.gz$", all_files[i])) {
        gunzip(file_path, remove = TRUE)
    }
}

if (grepl("_001\.", all_files[1])) {
    fnFs <- sort(list.files(path, pattern = "_R1_001.fastq", full.names = TRUE, recursive = TRUE))
    fnRs <- sort(list.files(path, pattern = "_R2_001.fastq", full.names = TRUE, recursive = TRUE))
} else if (grepl("_R1\.", all_files[1])) {
    fnFs <- sort(list.files(path, pattern = "_R1.fastq", full.names = TRUE, recursive = TRUE))
    fnRs <- sort(list.files(path, pattern = "_R2.fastq", full.names = TRUE, recursive = TRUE))
} else {
    stop(paste(
        "Error: No valid paired-end FASTQ files found in the input directory.",
        "Ensure files are named with either '_R1_001.fastq' and '_R2_001.fastq',",
        "or '_R1.fastq' and '_R2.fastq'."
    ))
}

#Identify primers
FWD <- opt$forward_primer
REV <- opt$reverse_primer

allOrients <- function(primer) {
    # Create all orientations of the input sequence
    dna <- DNAString(primer)  # The Biostrings works w/ DNAString objects rather than character vectors
    orients <- c(Forward = dna, Complement = Biostrings::complement(dna), Reverse = Biostrings::reverse(dna),
                RevComp = Biostrings::reverseComplement(dna))
    return(sapply(orients, toString))  # Convert back to character vector
}

FWD.orients <- allOrients(FWD)
REV.orients <- allOrients(REV)
FWD.orients
REV.orients

fnFs.filtN <- file.path("filtN", basename(fnFs)) # Put N-filtered files in filtN/ subdirectory
fnRs.filtN <- file.path("filtN", basename(fnRs))
filterAndTrim(fnFs, fnFs.filtN, fnRs, fnRs.filtN, maxN = 0, multithread = opt$threads, verbose = opt$verbose)

primerHits <- function(primer, fn) {
  # Counts number of reads in which the primer is found
  nhits <- vcountPattern(primer, sread(readFastq(fn)), fixed = FALSE)
  return(sum(nhits > 0))
}

# Sanity check: how many reads feature have sections before trimming?
pre_trimming <- as.data.frame(rbind(FWD.ForwardReads = sapply(FWD.orients, primerHits, fn = fnFs.filtN[[1]]),
                                    FWD.ReverseReads = sapply(FWD.orients, primerHits, fn = fnRs.filtN[[1]]),
                                    REV.ForwardReads = sapply(REV.orients, primerHits, fn = fnFs.filtN[[1]]),
                                    REV.ReverseReads = sapply(REV.orients, primerHits, fn = fnRs.filtN[[1]])))
write_tsv(pre_trimming, "stats_pre_trimming.tsv")

#Remove primers
cutadapt <- "/usr/local/bin/cutadapt" # CHANGE ME to the cutadapt path on your machine
system2(cutadapt, args = "--version") # Run shell commands from R

path.cut <- file.path(opt$output_dir)
if(!dir.exists(path.cut)) dir.create(path.cut)
fnFs.cut <- file.path(path.cut, basename(fnFs))
fnRs.cut <- file.path(path.cut, basename(fnRs))

FWD.RC <- dada2:::rc(FWD)
rev_rc <- as.character(Biostrings::reverseComplement(DNAString(REV)))

# Trim FWD and the reverse-complement of REV off of R1 (forward reads)
R1.flags <- paste("-g", FWD, "-a", REV.RC)
# Trim REV and the reverse-complement of FWD off of R2 (reverse reads)
R2.flags <- paste("-G", REV, "-A", FWD.RC)

speed.flags <- c("-j", opt$threads)

# Run Cutadapt
for(i in seq_along(fnFs)) {
    system2(cutadapt, args = c( R1.flags, R2.flags, speed.flags
                                "-n", 2, # -n 2 required to remove FWD and REV from reads
                                "-o", fnFs.cut[i], # output files forward reads
                                "-p", fnRs.cut[i], # output files reverse reads
                                fnFs.filtN[i], fnRs.filtN[i])) # input files
}

#Sanity check
post_trimming <- as.data.frame(rbind(   FWD.ForwardReads = sapply(FWD.orients, primerHits, fn = fnFs.cut[[1]]),
                                        FWD.ReverseReads = sapply(FWD.orients,primerHits, fn = fnRs.cut[[1]]),
                                        REV.ForwardReads = sapply(REV.orients, primerHits, fn = fnFs.cut[[1]]),
                                        REV.ReverseReads = sapply(REV.orients, primerHits, fn = fnRs.cut[[1]])))
write_tsv(post_trimming, "stats_post_trimming.tsv")


# Forward and reverse fastq filenames have the format:
cutFs <- sort(list.files(path.cut, pattern = "_R1_001.fastq", full.names = TRUE))
cutRs <- sort(list.files(path.cut, pattern = "_R2_001.fastq", full.names = TRUE))

#Let's save the plots of the resulting read quality stats
if (length(cutFs) >= 2) {
    forward_qc_plot <- plotQualityProfile(cutFs[1:2])
if (length(cutRs) >= 2) {
    reverse_qc_plot <- plotQualityProfile(cutRs[1:2])
    ggsave("reverse_quality_profile.png", reverse_qc_plot, width = 8, height = 6)
} else if (length(cutRs) == 1) {
    reverse_qc_plot <- plotQualityProfile(cutRs[1])
    ggsave("reverse_quality_profile.png", reverse_qc_plot, width = 8, height = 6)
} else {
    warning("No reverse read files found for quality profile plot.")
}
} else {
    stop("No forward reads found for quality profile plotting.")
}
ggsave("forward_quality_profile.png", forward_qc_plot, width = 8, height = 6)

if (length(cutRs) >= 2) {
    reverse_qc_plot <- plotQualityProfile(cutRs[1:2])
} else if (length(cutRs) == 1) {
    reverse_qc_plot <- plotQualityProfile(cutRs[1])
} else {
    stop("No reverse reads found for quality profile plotting.")
}
ggsave("reverse_quality_profile.png", reverse_qc_plot, width = 8, height = 6)
