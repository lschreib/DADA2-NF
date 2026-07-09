# Container recipes

Container recipes are maintained separately from workflow logic, while workflow execution refers to immutable image URIs in configuration profiles.

## Location

- DADA2 runtime image: `assets/containers/dada2/Dockerfile`
- FUNGuild image: `assets/containers/funguild/Dockerfile`
- PICRUSt2 image: `assets/containers/picrust2/Dockerfile`

## Runtime contract

The DADA2 image intentionally provides scripts at `/dada2_scripts`. Pipeline modules rely on this contract.

## Profile mapping

`conf/nrc.config` maps process names to site-specific Singularity images (`file:///...sif`) via:

- default DADA2 image (`params.container_dada2`)
- process overrides for MAFFT / IQ-TREE / FastTree / PICRUSt / FUNGuild / FAPROTAX

## Build and release policy

1. Update Dockerfile(s) in `assets/containers/*`.
2. Build and validate image behavior (including `/dada2_scripts` for DADA2).
3. Convert/publish immutable Singularity images for target HPC.
4. Update profile image paths and tag/version metadata.
5. Keep changelog and reference manifest aligned with release versions.

## CI checks

The repository includes container CI checks for Dockerfiles:

- Dockerfile linting (Hadolint)
- Build validation (no push)

See `.github/workflows/container_checks.yml`.

## Vendored tool policy (pipeline-internal patches)

FUNGuild is used as a vendored tool inside this pipeline with local, non-upstream patches.

- Upstream tool/version: FunGuild `1.1`
- Internal patch ID format: `dada2nf.2`
- Effective runtime version string: `<upstream>+<patch>` (example: `1.1+dada2nf.2`)

For internal patches, update all of the following together:

1. Script metadata in `assets/containers/funguild/funguild/Guilds_v1.1.py`
2. Container labels in `assets/containers/funguild/Dockerfile`
3. Workflow call site (module wrapper) and changelog notes

This policy is intentionally scoped to DADA2-NF and is not a standalone public release stream.
