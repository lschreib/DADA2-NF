#!/usr/bin/env Rscript

# Load necessary libraries
suppressMessages(library(optparse))
suppressMessages(library(dada2))
suppressMessages(library(readr))
suppressMessages(library(ShortRead))

# Define command-line options
option_list <- list(
    make_option(c("-d", "--denoised_output"),
        type = "character", default = "denoised_output.rds",
        help = "Path to denoised output file (dada class object) in RDS format (DEFAULT: denoised_output.rds)", metavar = "character"
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
        type = "character", default = "'FALSE'", metavar = "character",
        help = "Print extra output ('TRUE'| 'FALSE')(DEFAULT: 'FALSE')"
    )
)

# Parse command-line arguments
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# Check if required arguments are provided
if (is.null(opt$denoised_output)) {
    stop("Error: Denoised file is required. Use -d or --denoised_output to specify the denoised output file.")
}

# Main script logic
if (!file.exists(opt$denoised_output)) {
    stop("Error:  Denoised file does not exist.")
}
denoised <- readRDS(opt$denoised_output)

seqtab <- makeSequenceTable(denoised)

bim <- isBimeraDenovo(seqtab, minFoldParentOverAbundance = 3.5, multithread = TRUE, verbose = as.logical(opt$verbose))

# Quantify and export the number of detected chimeras
{
    invisible(sink("chimera_summary.txt"))

    # Output the table of bimera results
    cat("Bimera Table:\n")
    print(table(bim))

    # Output the proportion of chimeric reads
    cat("\nProportion of Chimeric Reads:\n")
    print(sum(seqtab[, bim]) / sum(seqtab))

    # Stop redirecting output
    sink()
}

# Remove chimeras
seqtab.nochim <- removeBimeraDenovo(seqtab, method = opt$method, multithread = opt$threads, verbose = as.logical(opt$verbose))

# Save the sequence table
saveRDS(seqtab.nochim, file = "seqtab.nochim.rds")

# Save the sequence table in FASTA format
fasta_file <- "seqtab.nochim.fasta"
writeFasta(getSequences(seqtab.nochim), file = fasta_file)

# Save the sequence table in TSV format
tsv_file <- "seqtab.nochim.tsv"
write_tsv(as.data.frame(seqtab.nochim), tsv_file)
