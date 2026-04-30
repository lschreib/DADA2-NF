#!/usr/bin/env python3
import sys
import argparse
from ete3 import Tree
import pandas as pd
import numpy as np

# Definitions of helper functions
def read_tax_file(tax_file):
    """
    Reads a taxonomy table file and extracts the required columns ('OTU_id' and 'taxonomy').

    Args:
        tax_file (str): Path to the taxonomy table file in TSV format.

    Returns:
        pd.DataFrame: A DataFrame containing the 'OTU_id' and 'taxonomy' columns.

    Raises:
        SystemExit: If the required columns are not present in the file.
    """
    print(f"Reading taxonomy table file: {tax_file}")
    tax_table = pd.read_csv(tax_file, sep = "\t")
    print("Extracting id and taxonomy columns")

    # Check for the presence of required columns
    if 'taxonomy' not in tax_table.columns:
        print("Error: Taxonomy table file does not contain a 'taxonomy' column")
        sys.exit(1)
    if 'OTU_id' not in tax_table.columns:
        print("Error: Taxonomy table file does not contain an 'OTU_id' column")
        sys.exit(1)

    # Extract the required columns
    tax_df = tax_table[['OTU_id', 'taxonomy']]
    return tax_df

def clean_tax_string(tax_string):
    """
    Cleans a taxonomy string by removing invalid levels (3-character strings).

    Args:
        tax_string (str): The taxonomy string to clean.

    Returns:
        str: The cleaned taxonomy string, or NaN if no valid levels remain.
    """
    if pd.isna(tax_string):
        return tax_string  # Return NaN as it is, without processing

    levels = tax_string.split(';')
    cleaned_levels = []
    
    for level in levels:
        # Check if the level is exactly 3 characters long
        if len(level) == 3:
            cleaned_levels.append(np.nan)  # Replace 3-character level with NaN
        else:
            cleaned_levels.append(level)  # Keep the level as it is
    
    # Return the cleaned levels, joining non-NaN values, or NaN if there are no valid levels
    return ';'.join([str(level) for level in cleaned_levels if pd.notna(level)]) if cleaned_levels else np.nan

def create_phylogenetic_tree(taxonomies):
    """
    Creates a phylogenetic tree from a list of taxonomy strings.

    Args:
        taxonomies (list of str): A list of cleaned taxonomy strings.

    Returns:
        ete3.Tree: A phylogenetic tree constructed from the taxonomy strings.
    """
    tree = Tree()  # Initialize an empty tree

    for taxonomy in taxonomies:
        try:
            levels = taxonomy.split(';')
            node = tree  # Start at the root of the tree
        
            for level in levels:
                # If a child with the same name exists, use it; otherwise, create a new child
                if node.search_nodes(name=level):
                    node = node.search_nodes(name=level)[0]  # Move to the existing node
                else:
                    node = node.add_child(name=level)  # Create a new node for this taxonomic level
        except Exception as e:
            print(f"Error creating tree for taxonomy: {taxonomy}")
            print(f"Details: {e}")
            continue
    
    tree.contract_lone_descendant()

    return tree

# Main funtion (workflow)
def main():
    parser = argparse.ArgumentParser(description="Generate bin-specific annotation and fasta files.")
    parser.add_argument("-t", "--tax_table",
                        required=True,
                        help="Taxonomy table or count table in TSV format. Must contain a 'OTU_id' column with sequence ids matching those of the features.fna file, and a 'taxonomy' column containing  taxonomy strings, i.e. k__Fungi;p__Ascomycota;...")
    parser.add_argument("-o", "--outfile",
                        required=False,
                        help="Name of output tree file. Note: Tree will be in Newick format",
                        default="outtree.nwk")
    args = parser.parse_args()

    tax_file = args.tax_table
    out_file = args.outfile

    # Read taxonomy file
    print("Reading taxonomy file...")
    tax_df = read_tax_file(tax_file = tax_file)

    # Clean taxonomy strings
    print("Reformating taxonomy strings...")
    tax_df['cleaned'] = tax_df.taxonomy.apply(clean_tax_string)

    # Add OTU ids to tax strings
    tax_df['cleaned_final'] = tax_df['cleaned'] + ";" + tax_df['OTU_id']

    # Create final tree
    print("Creation of taxonomic tree...")
    taxonomies = sorted(tax_df.cleaned_final.dropna().tolist())
    outtree = create_phylogenetic_tree(taxonomies)

    # Export created tree
    ## Convert tree into Newick format
    print("Tree export...")
    newick_string = outtree.write(format=1)

    ## Save the Newick string to a file
    with open(out_file, "w") as f:
        f.write(newick_string)

if __name__ == "__main__":
    main()