# 1)  Download SILVA_138.2_SSURef_tax_silva_trunc.fasta from SILVA website
# 2)  Replace all U's in the file by T's:
#     sed '/^>/! s/U/T/g' SILVA_138.2_SSURef_tax_silva_trunc.fasta > SILVA_138.2_SSURef_tax_silva_trunc.nuc.fasta
# 3)  Run script below to generate DADA2 database file

library("Biostrings"); packageVersion("Biostrings")
library("DECIPHER"); packageVersion("DECIPHER")

#First we generate the general classification DB
#Load SILVA seqs into R
SILVA_db <- readDNAStringSet("SILVA_138.2_SSURef_NR99_tax_silva_trunc.nuc.fasta")

#Remove posisble gaps in the seqs
SILVA_db <- RemoveGaps(SILVA_db)

#Get the sequecne names so that we can extract the taxonomic classification from it
seq_names <- names(SILVA_db)
head(seq_names)
#The sequences are formatted as:
#AY846379.1.1791 Eukaryota;Archaeplastida;Chloroplastida;Chlorophyta;Chlorophyceae;Sphaeropleales;Monoraphidium;Monoraphidium sp. Itas 9/21 14-6w
#They should be like this though:
#Eukaryota;Archaeplastida;Chloroplastida;Chlorophyta;Chlorophyceae;Sphaeropleales;Monoraphidium;Monoraphidium sp. Itas 9/21 14-6w"

#Also we don't need any Eukaryotes in there -> let's rmeove them first before we move on
seqnames_filter <- !grepl("Eukaryota", seq_names)

SILVA_db <- SILVA_db[seqnames_filter]
seq_names <- names(SILVA_db)

#Now lets rename everything so that it fits the DADA2 format
seqs_tax <- sub("^[^ ]+ ", "", seq_names)

#Add a trailing ; to make it dada2 compatible
seqs_tax <- paste0(seqs_tax,";")
head(seqs_tax)

#Remove everything that is past the genus
seqs_tax <- sub(";[^;]+;$", ";", seqs_tax)

#Bring re-formatted names back into the DB
names(SILVA_db) <- seqs_tax

#Export everything so that we are done
writeXStringSet(SILVA_db, filepath = "SILVA_138.2_SSURef_NR99_tax_silva_trunc.nuc.dada2.fasta")


#####################
# Now let's generate the species dataset
#####################

SILVA_db_species <- readDNAStringSet("SILVA_138.2_SSURef_tax_silva_trunc.nuc.fasta")

#Remove posisble gaps in the seqs
SILVA_db_species <- RemoveGaps(SILVA_db_species)

#Get the sequecne names so that we can extract the taxonomic classification from it
seq_names_species <- names(SILVA_db_species)

#Remove all Eukaryotes
seqnames_filter <- !grepl("Eukaryota", seq_names_species)

SILVA_db_species <- SILVA_db_species[seqnames_filter]
seq_names_species <- names(SILVA_db_species)
head(seq_names_species)

#Convert headers into DADA2 format
process_string <- function(x) {
  # Step 1: Split the string into two parts, separating at the first space
  parts <- sub("^(\\S+)\\s(.*)$", "\\1###\\2", x) #Replace the first space with ###
  split_parts <- strsplit(parts, "###")[[1]] #Split on ###

  # Step 2: First part is the accession number
  accession <- split_parts[1]
  
  # Step 3: Second part is the taxonomy, split by semicolon and get the last element
  taxonomy_parts <- strsplit(split_parts[2], ";")[[1]]
  genus_species <- taxonomy_parts[length(taxonomy_parts)]
  
  # Step 4: Combine accession and genus_species
  result <- paste(accession, genus_species)
  
  return(result)
}

seq_names_species <- setNames(sapply(seq_names_species, process_string), seq_along(seq_names_species))
head(seq_names_species)

names(SILVA_db_species) <- seq_names_species

writeXStringSet(SILVA_db_species, filepath = "SILVA_138.2_SSURef_tax_silva_trunc.nuc.dada2.fasta")