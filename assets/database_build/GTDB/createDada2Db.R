library("ShortRead")

arch_ssu <- readFasta("ar53_ssu_reps_r226.fna.gz")
bac_ssu <- readFasta("bac120_ssu_reps_r226.fna.gz")

test_ids <- as.character(id(arch_ssu))

transform_headers <- function(header_list){
  genome_id <- sapply(strsplit(header_list, split = " "), function(x) x[1])
  taxonomy_string <- sapply(strsplit(header_list, split = " "), function(x) x[2])
  species <- sapply(strsplit(header_list, split = " "), function(x) x[3])
 
  # Remove all the junk from the taxonomy string:
  # Initate the output helper dataframe
  tax_df <- as.data.frame(matrix(nrow = length(taxonomy_string), ncol = 7))
  colnames(tax_df) <- c("Domain", "Phylum", "Class", "Order", "Family", "Genus", "Species")
  
  
  tax_df$Domain <- sapply(strsplit(taxonomy_string, split = ";"), function(x) x[1])
  tax_df$Domain <- substr(tax_df$Domain, start = 4, stop = nchar(tax_df$Domain))
  
  tax_df$Phylum <- sapply(strsplit(taxonomy_string, split = ";"), function(x) x[2])
  tax_df$Phylum <- substr(tax_df$Phylum, start = 4, stop = nchar(tax_df$Phylum))
  
  tax_df$Class <- sapply(strsplit(taxonomy_string, split = ";"), function(x) x[3])
  tax_df$Class <- substr(tax_df$Class, start = 4, stop = nchar(tax_df$Class))
  
  tax_df$Order <- sapply(strsplit(taxonomy_string, split = ";"), function(x) x[4])
  tax_df$Order <- substr(tax_df$Order, start = 4, stop = nchar(tax_df$Order))
  
  tax_df$Family <- sapply(strsplit(taxonomy_string, split = ";"), function(x) x[5])
  tax_df$Family <- substr(tax_df$Family, start = 4, stop = nchar(tax_df$Family))
  
  tax_df$Genus <- sapply(strsplit(taxonomy_string, split = ";"), function(x) x[6])
  tax_df$Genus <- substr(tax_df$Genus, start = 4, stop = nchar(tax_df$Genus))
  
  tax_df$Species <- sapply(strsplit(taxonomy_string, split = ";"), function(x) x[7])
  tax_df$Species <- substr(tax_df$Species, start = 4, stop = nchar(tax_df$Species))
  
  
  # Build the new tax string
  tax_df$new_tax_string <- paste(sep = ";",
                                 tax_df$Domain,
                                 tax_df$Phylum,
                                 tax_df$Class,
                                 tax_df$Order,
                                 tax_df$Family,
                                 tax_df$Genus,
                                 paste0(tax_df$Species," ", species, "_(", genome_id,")"))
}

# Merge both datasets
# Extract sequences and IDs
all_seqs <- c(sread(arch_ssu), sread(bac_ssu))
all_ids  <- c(id(arch_ssu),    id(bac_ssu))

# Create a new ShortRead object with merged sequences and IDs
combined_fasta <- ShortRead(sread = all_seqs, id = all_ids)

# Manipulate the sequence headers
old_ids <- as.character(id(combined_fasta))

new_ids <- BStringSet(transform_headers(old_ids))

# Create object for final fasta file
output_fasta <- ShortRead(sread = all_seqs, id = new_ids)
# Sanity test:
id(output_fasta)
# Looks good

# Write to file
writeFasta(output_fasta, file = "ar53_bac120_ssu_reps_r226.dada2_fmt.fna")
