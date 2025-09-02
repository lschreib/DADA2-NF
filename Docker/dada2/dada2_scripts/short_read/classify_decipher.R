#!/usr/bin/env Rscript

# Load necessary libraries
suppressMessages(library(optparse))
suppressMessages(library(dada2))
suppressMessages(library(ShortRead))
suppressMessages(library(Biostrings))
suppressMessages(library(R.utils))
suppressMessages(library(readr))
suppressMessages(library(phyloseq))
suppressMessages(library(DECIPHER))

# Define command-line options
option_list <- list(
    make_option(c("-i", "--sequence_table"),
        type = "character", default = NULL,
        help = "Path to sequence table file in RDS format", metavar = "character"
    ),
    make_option(c("-s", "--strand"),
        type = "character", default = "both",
        help = "Strand to use for alignment ('top'|'bottom'|'both')(DEFAULT: 'both')", metavar = "character"
    ),
    make_option(c("-d", "--database"),
        type = "character", default = NULL,
        help = "Path to DECIPHER database file in RDS format", metavar = "character"
    ),
    make_option(c("-t", "--threads"),
        type = "integer", default = 1,
        help = "Number of threads to use (DEFAULT: 1)", metavar = "integer"
    ),
    make_option(c("-v", "--verbose"),
        type = "character", default = "TRUE", metavar = "character",
        help = "Print extra output ('TRUE'| 'FALSE')(DEFAULT: 'TRUE')"
    )
)

# Parse command-line arguments
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# Check if required arguments are provided
if (is.null(opt$sequence_table)) {
    stop("Error: Sequence table is required. Use -i or --sequence_table to specify the sequence table.")
}

if (is.null(opt$database)) {
    stop("Error: DECIPHER database is required. Use -d or --database to specify the DECIPHER database.")
}

# Main script logic
seqtab.nochim <- readRDS(opt$sequence_table) # Load the sequence table
if (is.null(seqtab.nochim)) {
    stop("Error: Could not read the sequence table. Please check the file path and format.")
}

trainingSet <- readRDS(opt$database) # Load the DECIPHER database
if (is.null(trainingSet) || !(inherits(trainingSet, "Taxa") || is.list(trainingSet))) {
    stop("Error: DECIPHER database not loaded correctly. Please check the file path and format.")
}

dna <- DNAStringSet(getSequences(seqtab.nochim)) # Create a DNAStringSet from the ASVs
ids <- IdTaxa(dna, trainingSet, strand = opt$strand, processors = opt$threads, verbose = as.logical(opt$verbose))
saveRDS(object = ids, file = "decipher_ids.rds")

# Convert the output object of class "Taxa" to a matrix analogous to the output from assignTaxonomy
ranks <- c("domain", "phylum", "class", "order", "family", "genus", "species", "strain") # ranks of interest
taxid <- matrix(NA, nrow = length(ids), ncol = length(ranks))
# Loop through each item in 'ids'
for (i in seq_along(ids)) {
    # Extract the current list element
    x <- ids[[i]]
    # Initialize a temporary vector to store taxa for this iteration (we are omitting the Root and hence start at index 2)
    taxa <- x$taxon[2:(length(ranks) + 1)]
    # Put taxonomic classifiction into the final matrix
    taxid[i, ] <- taxa
}

# Turn all "shaky" classifications into NA
taxid[apply(taxid, c(1, 2), function(x) startsWith(x, "unclassified_"))] <- NA
taxid[apply(taxid, c(1, 2), function(x) startsWith(x, "Unclassified_"))] <- NA

colnames(taxid) <- ranks
rownames(taxid) <- getSequences(seqtab.nochim)

# Hand-off to phyloseq
ps <- phyloseq(
    otu_table(seqtab.nochim, taxa_are_rows = FALSE),
    tax_table(taxid)
)

# Rename the OTU's to something shorter
dna <- Biostrings::DNAStringSet(taxa_names(ps))
names(dna) <- taxa_names(ps)
ps <- merge_phyloseq(ps, dna)
taxa_names(ps) <- paste0("ASV", seq(ntaxa(ps)))

outseqs <- refseq(ps)
writeXStringSet(outseqs,
    filepath = "features.fna", append = FALSE,
    compress = FALSE, compression_level = NA, format = "fasta"
)


otu <- as.data.frame(t(otu_table(ps)))

turn_to_legacy_from_clean <- function(ps) {
    otu <- as.data.frame(t(otu_table(ps)))
    colnames(otu) <- make.names(colnames(otu))
    otu$OTU_id <- rownames(otu)

    tx_df <- as.data.frame(tax_table(ps))

    # Turn all "shaky" classifications into NA
    tx_df[apply(tx_df, c(1, 2), function(x) startsWith(x, "unclassified_"))] <- NA
    tx_df[apply(tx_df, c(1, 2), function(x) startsWith(x, "Unclassified_"))] <- NA

    tax_string <- paste0("k__", tx_df[[1]], ";") # Start with the first column (domain)
    tax_string[is.na(tx_df[[1]])] <- "k__Unclassified"

    prefix_list <- c("p__", "c__", "o__", "f__", "g__", "s__", "t__")

    # Iterate over the remaining columns dynamically
    for (i in 2:length(colnames(tx_df))) { # Skip the first column (domain)
        col_name <- colnames(tx_df)[i]
        tax_string[!(is.na(tx_df[[col_name]]))] <- paste0(
            tax_string[!(is.na(tx_df[[col_name]]))],
            prefix_list[i - 1], # Use the corresponding prefix from the list
            tx_df[[col_name]][!(is.na(tx_df[[col_name]]))],
            ";"
        )
    }
    tx_df$taxonomy <- tax_string
    tx_df$OTU_id <- rownames(tx_df)
    # Remove all ASVs that are classified as "Unclassified"
    tx_df <- tx_df[!is.na(tx_df[[1]]), ]

    seqtab <- otu[otu$OTU_id %in% tx_df$OTU_id, ]

    feature_table <- merge(seqtab, tx_df[, colnames(tx_df) %in% c("taxonomy", "OTU_id")],
        by = "OTU_id", all.x = TRUE
    )
    return(feature_table)
}

turn_to_legacy_from_prefixed <- function(ps) {
    otu <- as.data.frame(t(otu_table(ps)))
    colnames(otu) <- make.names(colnames(otu))
    otu$OTU_id <- rownames(otu)

    tx_df <- as.data.frame(tax_table(ps))

    # Turn all "shaky" classifications into NA
    tx_df[apply(tx_df, c(1, 2), function(x) startsWith(x, "unclassified_"))] <- NA
    tx_df[apply(tx_df, c(1, 2), function(x) startsWith(x, "Unclassified_"))] <- NA

    tax_string <- paste0(tx_df[[1]], ";")
    tax_string[is.na(tx_df[[1]])] <- "k__Unclassified"

    # Iterate over the remaining columns dynamically
    for (i in 2:length(colnames(tx_df))) { # Skip the first column (domain)
        col_name <- colnames(tx_df)[i]
        tax_string[!(is.na(tx_df[[col_name]]))] <- paste0(
            tax_string[!(is.na(tx_df[[col_name]]))],
            tx_df[[col_name]][!(is.na(tx_df[[col_name]]))],
            ";"
        )
    }
    tx_df$taxonomy <- tax_string
    tx_df$OTU_id <- rownames(tx_df)
    # Remove all ASVs that are classified as "Unclassified"
    tx_df <- tx_df[!is.na(tx_df[[1]]), ]


    seqtab <- otu[otu$OTU_id %in% tx_df$OTU_id, ]

    feature_table <- merge(seqtab, tx_df[, colnames(tx_df) %in% c("taxonomy", "OTU_id")],
        by = "OTU_id", all.x = TRUE
    )
    return(feature_table)
}

# Test if taxa are prefixed or not
test_taxa_prefix <- function(taxa) {
    any(grepl("^(k|p|c|o|f|g|s|t)__", taxa))
}

if (test_taxa_prefix(taxid)) {
    feature_table <- turn_to_legacy_from_prefixed(ps)
} else {
    feature_table <- turn_to_legacy_from_clean(ps)
}

write_tsv(feature_table, file = "feature_table.tsv")
