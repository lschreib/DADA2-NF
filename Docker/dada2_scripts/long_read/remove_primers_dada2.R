#!/usr/bin/env Rscript

# Load necessary libraries
suppressMessages(library(optparse))
suppressMessages(library(dada2))
suppressMessages(library(ShortRead))
suppressMessages(library(Biostrings))
suppressMessages(library(R.utils))
suppressMessages(library(readr))
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
    make_option(c("-f", "--forward_primer"),
        type = "character", default = NULL,
        help = "Sequence of forward primer", metavar = "character"
    ),
    make_option(c("-r", "--reverse_primer"),
        type = "character", default = NULL,
        help = "Sequence of reverse primer", metavar = "character"
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

if (grepl("\\.gz$", all_files[1])) {
    pattern_reads <- ".fastq.gz"
} else if (grepl("\\.fastq$", all_files[1])) {
    pattern_reads <- ".fastq"
} else {
    stop(paste(
        "Error: No valid FASTQ files found in the input directory.",
        "Ensure files are named with '*.fastq(.gz)'."
    ))
}

fns <- sort(list.files(path, pattern = pattern_reads, full.names = TRUE, recursive = TRUE))

# Sanity check: get length distribution of raw reads
lens.fn <- lapply(fns, function(fn) nchar(getSequences(fn)))
lens <- do.call(c, lens.fn)

png("read_length_distribution.pre.png", width = 800, height = 600) # Open PNG device
hist(lens, 100, main = "Read Length Distribution Before Primer Removal", xlab = "Read Length", ylab = "Frequency")
invisible(dev.off()) # close PNG device

# Identify primers
FWD <- opt$forward_primer
REV <- opt$reverse_primer
# Use Biostrings::reverseComplement for reverse complement function


primerHits <- function(primer, fn) {
    # Counts number of reads in which the primer is found
    nhits <- vcountPattern(primer, sread(readFastq(fn)), fixed = FALSE)
    return(sum(nhits > 0))
}

allOrients <- function(primer) {
    # Create all orientations of the input sequence
    dna <- DNAString(primer) # The Biostrings works w/ DNAString objects rather than character vectors
    orients <- c(
        Forward = dna, Complement = Biostrings::complement(dna), Reverse = Biostrings::reverse(dna),
        RevComp = Biostrings::reverseComplement(dna)
    )
    return(sapply(orients, toString)) # Convert back to character vector
}

FWD.orients <- allOrients(FWD)
REV.orients <- allOrients(REV)

# Sanity check: how many reads feature have sections before trimming?
pre_trimming <- as.data.frame(rbind(
    FWD.Reads = sapply(FWD.orients, primerHits, fn = fns[[1]]),
    REV.Reads = sapply(REV.orients, primerHits, fn = fns[[1]])
))
pre_trimming <- cbind(RowNames = rownames(pre_trimming), pre_trimming) # Add row names as the first column
write_tsv(pre_trimming, "primer_hits.pre.tsv")

path.cut <- file.path(opt$output_dir)
if (!dir.exists(path.cut)) dir.create(path.cut)
fns.no_prime <- file.path(path.cut, ifelse(grepl("\\.gz$", basename(fns)), basename(fns), paste0(basename(fns), ".gz"))) # Put trimmed files in output directory


# Remove primers
prim <- removePrimers(fns, fns.no_prime, primer.fwd = FWD, primer.rev = as.character(Biostrings::reverseComplement(DNAString(REV))), orient = TRUE, verbose = as.logical(opt$verbose))

saveRDS(prim, file = "removed_primers_output.rds")

# Sanity check: are there any primer hits after trimming?
post_trimming <- as.data.frame(rbind(
    FWD.Reads = sapply(FWD.orients, primerHits, fn = fns.no_prime[[1]]),
    REV.Reads = sapply(REV.orients, primerHits, fn = fns.no_prime[[1]])
))
post_trimming <- cbind(RowNames = rownames(post_trimming), post_trimming)
write_tsv(post_trimming, "primer_hits.post.tsv")

# Sanity check: length distribution after removing primers
lens.fn <- lapply(fns.no_prime, function(fn) nchar(getSequences(fn)))
lens <- do.call(c, lens.fn)

png("read_length_distribution.post.png", width = 800, height = 600) # Open PNG device
hist(lens, 100, main = "Read Length Distribution After Primer Removal", xlab = "Read Length", ylab = "Frequency")
invisible(dev.off())

# Forward and reverse fastq filenames have the format:
cuts <- sort(list.files(path.cut, pattern = pattern_reads, full.names = TRUE))

# Let's save some plots of the resulting read quality stats
if (length(cuts) == 0) {
    stop("Error: No trimmed FASTQ files found. Please check the input directory and primer sequences.")
}

if (length(cuts) >= 2) {
    forward_qc_plot <- plotQualityProfile(cuts[1:2])
    ggsave("quality_profile.preTrim.png", forward_qc_plot, width = 8, height = 6)
} else if (length(cuts) == 1) {
    forward_qc_plot <- plotQualityProfile(cuts[1])
    ggsave("quality_profile.preTrim.png", forward_qc_plot, width = 8, height = 6)
} else {
    stop("No reads found for quality profile plotting.")
}
