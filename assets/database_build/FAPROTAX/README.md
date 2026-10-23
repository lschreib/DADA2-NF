# Rationale
An [FAPROTAX](http://www.loucalab.com/archive/FAPROTAX/lib/php/index.php) version 1.x-compatible database that is based on the more comprehensive FAPROTAX2 database and that includes functional categories relevant in a biotechnological context.

The newer FAPROTAX2 database does not allow the addition of new functional group (i.e. customization). To overcome this limitation, we will generate the a FAPROTAX1-compatible database form the FAPROTAX2 database, and add these function to the custom-functions we added to the data.

Database conversion can be carried out using the R-markdown file "FAPROTAX_DB_conversion.Rmd". This directory only contains a very abbreviated version of the FAPROTAX2 database that should be replaced with the most current version (full version) to be found [here](http://www.loucalab.com/archive/FAPROTAX2/lib/php/index.php).

*Note: FAPROTAX2 now also offers information on nesting of functional categories, contained in the accompanying "FAPROTAX2-db_definitions_and_summaries.tsv" file. An updated version of this file containing the custom functions and also additional categories for function clustering (i.e. metabolism functions vs habitat/niche/ecology functions; separate column to indicate photosynthesis-related functions).*


# Additions so far
- Clostridial acetone-butanol-ethanol (ABE) fermentation
- Caproic acid production by chain elongation (i.e. non-saccharolytic production of caproic acid)
- Caproic acid production by saccharolytic fermentation
- Homoacetogenesis
- Electroactive (electrotrophic and anode-respiring) bacteria

# Planned additions
- Syngas fermentation