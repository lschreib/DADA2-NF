# Rationale
An extended version of the [FAPROTAX](http://www.loucalab.com/archive/FAPROTAX/lib/php/index.php) database that includes functional categories relevant in a biotechnological context (found under: FAPROTAX1/FAPTROAX.txt)

In addtion we can try to leverage the more comprhensive FAPROTAX2  database. In contrast to version 1, version 2 does not allow the addtion of custom functions anymore. So to get the benefit of custom functions and a bigger dataset, we can backport the version 2 database to version format and then merge it with the customized version 1 dataset. This can be done in R using the "FAPROTAX_DB_conversion.Rmd" script. An up-to-date verison of the database can be found under "FAPROTAX2_BT.txt.gz". Note database needs be decompressed before feeding it into the FAPROTAX1 tool.

# Additions so far
- Clostridial acetone-butanol-ethanol (ABE) fermentation
- Caproic acid production by chain elongation (i.e. non-saccharolytic production of caproic acid)
- Caproic acid production by saccharolytic fermentation
- Homoacetogenesis
- Microbial electrosynthesis (i.e. electrode-facilitated CO2 fixation)
- Syngas fermentation

