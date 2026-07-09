# 1)  Download the QIIME release of the UNITE database
# 2)  Replace all U's in the file by T's:
#     sed '/^>/! s/U/T/g' SILVA_138.2_SSURef_tax_silva_trunc.fasta > SILVA_138.2_SSURef_tax_silva_trunc.nuc.fasta
# 3)  Run script below to generate DECIPHER reference file

#Update to latest DECIPHER version
library("DECIPHER"); packageVersion("DECIPHER")
library("readr"); packageVersion("readr")

#Load UNITE sequences into R
UNITE_db <- readDNAStringSet("sh_qiime_release_04.04.2024/developer/sh_refs_qiime_ver10_dynamic_04.04.2024_dev.fasta")

#Remove possible gaps in the seqs
UNITE_db <- RemoveGaps(UNITE_db)

#Get the sequence names so that we can extract the taxonomic classification from it
seq_names <- names(UNITE_db)
head(seq_names)

#Extract taxonomic information form the sequence header so we can manipulate it to work with DECIPHER
seqs_tax <- as.data.frame(read_tsv(file = "sh_qiime_release_04.04.2024/developer/sh_taxonomy_qiime_ver10_dynamic_04.04.2024_dev.txt"))
#Add Root; to tax string to make it work with DECIPHER
seqs_tax$Taxon <- paste0("Root;",seqs_tax$Taxon)
head(seqs_tax)
#How many unique taxa do we have in the dataset?
tax_counts <- table(seqs_tax$Taxon)
unique_taxa <- names(tax_counts)
length(tax_counts)

# Extract the names from the DNAStringSet
sequence_order <- names(UNITE_db)
# Create an ordering index based on `sequence_order`
ordering_index <- match(sequence_order, seqs_tax$`Feature ID`)
# Reorder the dataframe based on the index
seqs_tax <- seqs_tax[ordering_index, ]

names(UNITE_db) <- seqs_tax$Taxon

#Train the classifier
trainingSet <- LearnTaxa(UNITE_db,names(UNITE_db))

saveRDS(trainingSet, file = "DECIPHER_UNITE_v10.0_20241129.RData")