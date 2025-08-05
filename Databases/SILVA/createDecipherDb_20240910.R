# 1)  Download SILVA_138.2_SSURef_tax_silva_trunc.fasta from SILVA website
# 2)  Replace all U's in the file by T's:
#     sed '/^>/! s/U/T/g' SILVA_138.2_SSURef_tax_silva_trunc.fasta > SILVA_138.2_SSURef_tax_silva_trunc.nuc.fasta
# 3)  Run script below to generate DECIPHER reference file

#Update to latest DECIPHER version
library("DECIPHER"); packageVersion("DECIPHER")

#Load SILVA sequences into R
SILVA_db <- readDNAStringSet("SILVA_138.2_SSURef_NR99_tax_silva_trunc.nuc.fasta")
#This could also be done with the with full 'Ref" dataset, however, when using the full dataset each iteration of the 
#LearnTaxa command then takes ~1 week
#SILVA_db <- readDNAStringSet("SILVA_138.2_SSURef_tax_silva_trunc.nuc.fasta")

#Remove possible gaps in the seqs
SILVA_db <- RemoveGaps(SILVA_db)

#Get the sequence names so that we can extract the taxonomic classification from it
seq_names <- names(SILVA_db)
head(seq_names)

#We are only interested in classifying Prokaryotes, so remove all Eukaryotes
seqnames_filter <- !grepl("Eukaryota", seq_names)
SILVA_db <- SILVA_db[seqnames_filter]
seq_names <- names(SILVA_db)
head(seq_names)

#Extract taxonomic information form the sequence header so we can manipulate it to work with DECIPHER
seqs_tax <- sub("^[^ ]* ", "", seq_names)
#Add Root; to tax string to make it work with DECIPHER
seqs_tax <- paste0("Root;",seqs_tax)
head(seqs_tax)
#How many unique taxa do we have in the dataset?
tax_counts <- table(seqs_tax)
unique_taxa <- names(tax_counts)
length(tax_counts)

#Limit the maximum number of representatives for each taxa to make the database slimmer without really losing a lot of information
maxGroupSize <- 10 # max sequences per label (>= 1)
remove <- logical(length(SILVA_db))
for (i in which(tax_counts > maxGroupSize)) {
  index <- which(seqs_tax==unique_taxa[i])
  keep <- sample(length(index),
                 maxGroupSize)
  remove[index[-keep]] <- TRUE
}
sum(remove) # number of sequences eliminated

#Subset everything to not have to only work with the slim dataset from here on
names(SILVA_db) <- seqs_tax
SILVA_db_reps <- SILVA_db[!remove]

#Train the classifier
#Simple training without removal of problematic sequences
#(only do this if working with a gigantic dataset that does not allow multiple iterations of 'LearnTaxa'
#trainingSet <- LearnTaxa(SILVA_db_reps,names(SILVA_db_reps))
#saveRDS(trainingSet, file = "DECIPHER_SILVA_SSU_R138.2_NR99_20240910.RData")

#If you have a relatively small data set (e.g. the NR99 dataset) and if removal of"problematic" 
#sequences is desired do this:
{
  maxIterations <- 5 # must be >= 1; make it >= 2 if removal of "problematic" sequences is desired
  allowGroupRemoval <- FALSE #Don't allow removal of whole taxonomic groups
  remove <- logical(length(SILVA_db_reps)) #initialize new removal vector
  probSeqsPrev <- integer() # suspected problem sequences from prior iteration
  for (i in seq_len(maxIterations)) {
    cat("Training iteration: ", i, "\n", sep="")
    # train the classifier
    trainingSet <- LearnTaxa(SILVA_db_reps[!remove],
                             names(SILVA_db_reps)[!remove],
                             taxid) #Here is where we actually remove the sequences from the dataset
    # look for problem sequences
    probSeqs <- trainingSet$problemSequences$Index
    if (length(probSeqs)==0) {
      cat("No problem sequences remaining.\n")
      break
    } else if (length(probSeqs)==length(probSeqsPrev) &&
               all(probSeqsPrev==probSeqs)) {
      cat("Iterations converged.\n")
      break
    }
    if (i==maxIterations)
      break
    probSeqsPrev <- probSeqs
    # remove any problem sequences
    index <- which(!remove)[probSeqs]
    remove[index] <- TRUE # remove all problem sequences
    if (!allowGroupRemoval) {
      # In case procedure removes all reps of a taxon, put it back in
      missing <- !(unique_taxa %in% seqs_tax[!remove])
      missing <-unique_taxa[missing]
      if (length(missing) > 0) {
        index <- index[seqs_tax[index] %in% missing]
        remove[index] <- FALSE # don't remove
      }
    }
  }
  sum(remove) # total number of sequences eliminated
  length(probSeqs) # number of remaining problem sequencess
}

saveRDS(trainingSet, file = "DECIPHER_SILVA_SSU_R138.2_NR99_20240918.RData")