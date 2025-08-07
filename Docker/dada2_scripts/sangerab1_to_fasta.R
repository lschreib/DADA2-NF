#!/usr/bin/env Rscript

# This script processes Sanger sequencing `.ab1` files to generate trimmed and quality-annotated
# sequence outputs in both FASTQ and FASTA formats. It performs the following steps:
# 1. Reads `.ab1` files from a specified directory.
# 2. Calculates de novo quality scores for each base using a custom scoring function.
# 3. Trims sequences based on quality scores and primer positions using Mott's trimming algorithm.
# 4. Outputs the processed sequences and their quality scores in multi-FASTQ and multi-FASTA formats.

# Load necessary libraries
suppressMessages(library(optparse))
suppressMessages(library(sangerseqR))
suppressMessages(library(ShortRead))
suppressMessages(library(Biostrings))
suppressMessages(library(sangeranalyseR))

option_list <- list(
    make_option(c("-i", "--input_dir"),
        type = "character", default = NULL,
        help = "Path to input folder containing Sanger AB1 files. Files will need to have .ab1 extension.", metavar = "character"
    ),
    make_option(c("-f", "--forward_primer"),
        type = "character", default = NULL,
        help = "Sequence of forward primer", metavar = "character"
    ),
    make_option(c("-r", "--reverse_primer"),
        type = "character", default = NULL,
        help = "Sequence of reverse primer", metavar = "character"
    ),
    make_option(c("-w", "--qual_window"),
        type = "integer", default = 10,
        help = "Window size for quality calculation (DEFAULT: 10)", metavar = "integer"
    ),
    make_option(c("-p", "--pnr_threshold"),
        type = "numeric", default = 0.1,
        help = "Peak-to-noise ratio threshold (DEFAULT: 0.1)", metavar = "numeric"
    ),
    make_option(c("-a", "--weight_ambiguity"),
        type = "numeric", default = 0.4,
        help = "Weight for ambiguity penalty (DEFAULT: 0.4)", metavar = "numeric"
    ),
    make_option(c("-v", "--weight_peak_var"),
        type = "numeric", default = 0.2,
        help = "Weight for peak variability penalty (DEFAULT: 0.2)", metavar = "numeric"
    ),
    make_option(c("-n", "--weight_pnr"),
        type = "numeric", default = 0.4,
        help = "Weight for peak-to-noise ratio penalty (DEFAULT: 0.4)", metavar = "numeric"
    )
)


# Parse command-line arguments
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# Check if required arguments are provided
if (is.null(opt$input_dir)) {
    stop("Error: Input directory is required. Use -i or --input to specify the input directory.")
}
if (!dir.exists(opt$input_dir)) {
    stop("Error: Input directory does not exist.")
}
if (is.null(opt$forward_primer)) {
    stop("Error: Forward primer sequence is required. Use -f or --forward_primer to specify the forward primer sequence.")
}
if (is.null(opt$reverse_primer)) {
    stop("Error: Reverse primer sequence is required. Use -r or --reverse_primer to specify the reverse primer sequence.")
}

# Internal functions

calculate_qualities <- function(base_calls, base_positions, trace_data, win = 10, pnr_threshold = 0.1,
                                w_ambiguity = 0.4, w_peak_var = 0.2, w_pnr = 0.4) {
    n <- nchar(base_calls)

    # Convert the string into a vector of individual characters
    base_calls <- str_split(base_calls, "")[[1]]

    # Initialize penalties
    ambiguity_penalty <- numeric(n)
    peak_var_penalty <- numeric(n)
    pnr_penalty <- numeric(n)
    quality_scores <- numeric(n) # Initialize quality scores

    # Ambiguity penalty
    for (i in seq_len(n)) {
        # If the basecall itself is ambiguous, set quality to NA
        if (!(base_calls[i] %in% c("A", "C", "G", "T"))) {
            quality_scores[i] <- NA
            next
        }

        start <- max(1, i - floor(win / 2))
        end <- min(n, i + floor(win / 2))
        window <- base_calls[start:end]
        ambiguity_penalty[i] <- sum(!(window %in% c("A", "C", "G", "T")) | is.na(window)) # Count non-ACGT bases
    }

    # Mean basecall distance
    mean_dist <- mean(diff(base_positions))

    # Peak distance variability penalty
    for (i in seq_len(n - win)) {
        window_positions <- base_positions[i:(i + win - 1)]
        distances <- diff(window_positions)
        min_dist <- min(distances)
        max_dist <- max(distances)
        peak_var <- abs(max_dist - mean_dist) + abs(min_dist - mean_dist)
        peak_var_penalty[i:(i + win - 1)] <- peak_var_penalty[i:(i + win - 1)] + peak_var
    }

    # Peak-to-noise ratio penalty
    for (i in seq_len(n)) {
        # Skip further calculations if quality is already set to NA
        if (is.na(quality_scores[i])) {
            next
        }

        # Check if there is no signal at all
        signals <- trace_data[i, ]
        if (all(signals == 0)) {
            # No signal at this position, set quality to NA and skip further calculations
            quality_scores[i] <- NA
            next
        }

        # Extract signal intensities for A, C, G, T at the current position
        dominant_peak <- max(signals)
        second_peak <- sort(signals, decreasing = TRUE)[2]

        # Handle cases where peaks are zero
        if (second_peak == 0) {
            # No competing signal, no penalty
            pnr_penalty[i] <- 0
        } else {
            # Calculate PNR
            pnr <- dominant_peak / second_peak

            # Penalize low PNR
            if (pnr < pnr_threshold) {
                pnr_penalty[i] <- (1 - pnr / pnr_threshold) * 10 # Scale penalty
            }
        }
    }

    # Normalize penalties
    if (max(ambiguity_penalty) > 0) {
        ambiguity_penalty <- ambiguity_penalty / max(ambiguity_penalty)
    }
    if (max(peak_var_penalty) > 0) {
        peak_var_penalty <- peak_var_penalty / max(peak_var_penalty)
    }
    if (max(pnr_penalty) > 0) {
        pnr_penalty <- pnr_penalty / max(pnr_penalty)
    }

    # Combine penalties with weights
    final_penalty <- w_ambiguity * ambiguity_penalty +
        w_peak_var * peak_var_penalty +
        w_pnr * pnr_penalty

    # Rescale penalties to 0-60
    for (i in seq_len(n)) {
        if (is.na(quality_scores[i])) {
            # Skip rescaling for positions with no signal or ambiguous basecalls
            quality_scores[i] <- 0
            next
        }
        quality_scores[i] <- 60 * (1 - final_penalty[i])
    }
    quality_scores[quality_scores < 0] <- 0
    quality_scores[quality_scores > 60] <- 60

    # Round all values
    quality_scores <- round(quality_scores, digits = 0)

    return(quality_scores)
}


create_multifastq <- function(sequences, quality_scores_list, output_file, sequence_ids) {
    # Ensure sequences and quality_scores_list are lists of the same length
    if (length(sequences) != length(quality_scores_list) || length(sequences) != length(sequence_ids)) {
        stop("The number of sequences, quality scores, and sequence IDs must be the same.")
    }

    # Convert sequences and quality scores to ShortReadQ components
    sread <- DNAStringSet(sequences) # Sequences as DNAStringSet

    quality <- BStringSet(sapply(quality_scores_list, function(q) {
        paste(sapply(q, function(score) {
            if (is.na(score)) score <- 0 # Handle NA values by setting them to 0
            rawToChar(as.raw(score + 33)) # Convert to Phred+33 ASCII
        }), collapse = "")
    }))

    id <- BStringSet(sequence_ids) # Sequence identifiers

    # Create a ShortReadQ object
    fq <- ShortReadQ(sread = sread, quality = quality, id = id)

    # Write to FASTQ file
    writeFastq(fq, file = output_file, compress = FALSE)

    cat("Multi-FASTQ file written to:", output_file, "\n")
}

create_multifasta <- function(sequences, output_file, sequence_ids) {
    # Ensure sequences and sequence_ids are lists of the same length
    if (length(sequences) != length(sequence_ids)) {
        stop("The number of sequences and sequence IDs must be the same.")
    }

    # Convert sequences and quality scores to ShortReadQ components
    sread <- DNAStringSet(sequences) # Sequences as DNAStringSet

    id <- BStringSet(sequence_ids) # Sequence identifiers

    # Create a ShortReadQ object
    fa <- ShortRead(sread = sread, id = id)

    # Write to FASTQ file
    writeFasta(fa, file = output_file, compress = FALSE)

    cat("Multi-FASTA file written to:", output_file, "\n")
}


# Main script logic

# Used primer set
primer_fwd <- opt$forward_primer
primer_rev <- opt$reverse_primer

path <- opt$input_dir
all_files <- list.files(path, recursive = TRUE, pattern = "\\.ab1$")

all_seqs <- vector("list", length = length(all_files))
all_ids <- vector("list", length = length(all_files))
all_qual <- vector("list", length = length(all_files))


# Process all ab1 files
for (i in 1:length(all_files)) {
    read_seq <- readsangerseq(paste0(path, "/", all_files[i]))
    read_name <- gsub(".ab1", "", all_files[i], fixed = TRUE)

    base_calls <- as.character(read_seq@primarySeq)
    base_positions <- read_seq@peakPosMatrix[, 1]
    trace_data <- read_seq@traceMatrix
    trace_data_relevant <- trace_data[base_positions, ]

    # De novo estimate quality values
    quality_data <- calculate_qualities(
        base_calls = base_calls,
        base_positions = base_positions,
        trace_data = trace_data_relevant
    )

    # Get 5' primer length
    primer_length <- max(c(
        nchar(primer_fwd),
        nchar(primer_rev)
    ))

    # Mott's sequence trimming
    # 1) Create ABIF object for trimmer
    read_abif <- read.abif(paste0(path, "/", all_files[i]))

    # 2) Add estimated quality values
    read_abif@data$PCON.2 <- quality_data

    # 3) Get trimming positions
    trimming_pos <- trim.mott(read_abif, cutoff = 0.0001)


    # Adjust 5' trimming so that 5' primer will definitely be cut
    trimming_pos$start <- max(c(
        trimming_pos$start,
        (primer_length + 1)
    ))

    all_seqs[i] <- substr(base_calls[1], start = trimming_pos$start, stop = trimming_pos$finish)
    all_ids[i] <- read_name[1]
    all_qual[i] <- list(quality_data[trimming_pos$start:trimming_pos$finish])
}

all_seqs <- unlist(all_seqs)
all_ids <- unlist(all_ids)

# Create trimmed output files
# (i) FASTQ
# Output file
output_file <- paste0("output.fastq")

# Create the multi-FASTQ file
create_multifastq(all_seqs, all_qual, output_file, all_ids)


# (ii) FASTA
# Output file
output_file <- paste0("output.fasta")

# Create the multi-FASTA file
create_multifasta(all_seqs, output_file, all_ids)
