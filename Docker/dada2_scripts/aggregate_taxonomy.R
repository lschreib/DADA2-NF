#!/usr/bin/env Rscript

# Load necessary libraries
suppressMessages(library(optparse))
suppressMessages(library(readr))
suppressMessages(library(phyloseq))
suppressMessages(library(qiime2R))

# Define command-line options
option_list <- list(
    make_option(c("-i", "--feature_table"),
        type = "character", default = NULL,
        help = "Path to feature table file in TSV format", metavar = "character"
    ),
    make_option(c("-l", "--level"),
        type = "integer", default = 6,
        help = "Level of taxonomy to aggregate (1-8). 1 = domain, 2 = phylum, 3 = class, 4 = order, 5 = family, 6 = genus (DEFAULT), 7 = species, 8 = strain/species hypothesis", metavar = "integer"
    ),
    make_option(c("-n", "--na_remove"),
        action = "store_true", default = FALSE,
        help = "Add this option to remove NA values during the aggregation (DEFAULT: FALSE)", metavar = "logical"
    ),
    make_option(c("-o", "--output_prefix"),
        type = "character", default = "aggregated_taxonomy",
        help = "Prefix of the generated output files for aggregated taxonomy (DEFAULT: 'aggregated_taxonomy')", metavar = "character"
    )
)

# Parse command-line arguments
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# Check if required arguments are provided
if (is.null(opt$feature_table)) {
    stop("Error: Feature table is required. Use -i or --feature_table to specify the feature table.")
}

# Main script logic
suppressMessages(feature_table <- read_tsv(file = opt$feature_table, col_names = TRUE))

ot <- as.data.frame(feature_table[, !(colnames(feature_table) %in% c("OTU_id", "taxonomy"))])
rownames(ot) <- feature_table$OTU_id
if (is.null(ot) || nrow(ot) == 0) {
    stop("Error: Feature table is empty or not properly formatted.")
}

tt <- as.data.frame(feature_table[, colnames(feature_table) %in% c("OTU_id", "taxonomy")])
colnames(tt) <- c("Feature.ID", "Taxon")
tt_parsed <- as.matrix(parse_taxonomy(tt))
if (is.null(tt_parsed) || nrow(tt_parsed) == 0) {
    stop("Error: Taxonomy table is empty or not properly formatted.")
}

# Load into phyloseq object
ps <- phyloseq(
    otu_table(ot, taxa_are_rows = TRUE),
    tax_table(tt_parsed)
)


levels <- colnames(tt_parsed)

if (opt$level < 1 || opt$level > length(levels)) {
    stop(paste("Error: Invalid level. Please choose a level between 1 and", length(levels)))
}
aggr_level <- levels[opt$level]

# Build output file names
outfile_reads <- paste0(opt$output_prefix, "_", aggr_level, ".reads.tsv")
outfile_abundance <- paste0(opt$output_prefix, "_", aggr_level, ".rel_abund.tsv")

ps_aggr <- tax_glom(ps, aggr_level, NArm = opt$na_remove)

otu <- as.data.frame(t(otu_table(ps_aggr)))

turn_to_legacy_from_clean <- function(ps) {
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

    return(tx_df[, colnames(tx_df) %in% c("taxonomy", "OTU_id")])
}

turn_to_legacy_from_prefixed <- function(ps) {
    tx_df <- as.data.frame(tax_table(ps))

    # Turn all "shaky" classifications into NA
    tx_df[apply(tx_df, c(1, 2), function(x) startsWith(x, "k__unclassified_"))] <- NA
    tx_df[apply(tx_df, c(1, 2), function(x) startsWith(x, "k__Unclassified_"))] <- NA

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

    return(tx_df[, colnames(tx_df) %in% c("taxonomy", "OTU_id")])
}

# Test if taxa are prefixed or not
test_taxa_prefix <- function(taxa) {
    any(grepl("^(k|p|c|o|f|g|s|t)__", taxa))
}

if (test_taxa_prefix(as.matrix(tax_table(ps_aggr)))) {
    tx_df <- turn_to_legacy_from_prefixed(ps_aggr)
} else {
    tx_df <- turn_to_legacy_from_clean(ps_aggr)
}

# Export in legacy OTU table format
otu <- as.data.frame(otu_table(ps_aggr))
colnames(otu) <- make.names(colnames(otu))

# Now the same again but with relative abundances instead of reads
otu_pc <- as.matrix(otu)
otu_pc <- as.data.frame(round(prop.table(otu_pc, margin = 2), digits = 3))

otu_pc$OTU_id <- rownames(otu_pc)
otu$OTU_id <- rownames(otu)

seqtab <- otu[otu$OTU_id %in% tx_df$OTU_id, ]

feature_table_reads <- merge(seqtab, tx_df[, colnames(tx_df) %in% c("taxonomy", "OTU_id")],
    by = "OTU_id", all.x = TRUE
)

write_tsv(feature_table_reads, file = outfile_reads)


seqtab_pc <- otu_pc[otu_pc$OTU_id %in% tx_df$OTU_id, ]

feature_table_pc <- merge(seqtab_pc, tx_df[, colnames(tx_df) %in% c("taxonomy", "OTU_id")],
    by = "OTU_id", all.x = TRUE
)

write_tsv(feature_table_pc, file = outfile_abundance)
