# Database building

This repository keeps database build scripts separate from the runtime pipeline.

## Location

- `assets/database_build/GTDB`
- `assets/database_build/SILVA`
- `assets/database_build/UNITE`
- `assets/database_build/FAPROTAX`

## Build scripts

- GTDB
  - `assets/database_build/GTDB/createDada2Db.R`
- SILVA
  - `assets/database_build/SILVA/createDada2Db_20240917.R`
  - `assets/database_build/SILVA/createDecipherDb_20240910.R`
- UNITE
  - `assets/database_build/UNITE/createDecipherDb_20240910.R`

## Produced artifact types

- DADA2 classifier FASTA files (`*.fa.gz` / `*.fna.gz`)
- DECIPHER classifier databases (`*.rds`)
- FAPROTAX classifier database (`*.txt`)

## Provenance policy

Track every release in `assets/reference_manifest.tsv` with:

- source URL and version
- script used to build
- output artifact path
- build date
- checksum

## Runtime selection

The pipeline does not build references during normal runs. Database paths are selected per environment/profile, for example in `conf/nrc.config`.

## Recommended release workflow

1. Build or update reference artifacts with scripts in `assets/database_build/*`.
2. Compute checksums and update `assets/reference_manifest.tsv`.
3. Publish artifacts to your shared database location.
4. Update profile paths (for example `conf/nrc.config`) to the new versioned artifacts.
5. Re-run CI and a smoke pipeline run before release.
