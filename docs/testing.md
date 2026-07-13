# Testing Guide

## Local validation matrix

The repository uses a local PowerShell helper in `tests/run-local-tests.ps1` to validate the main workflow combinations before a real pipeline run.

The current matrix covers:

- `short_read` + `16S` + `FAPROTAX`
- `long_read` + `16S` + `FAPROTAX`
- `short_read` + `ITS` + `FUNGuild`

Each case is defined in `tests/params/*.yml` so the test input, marker gene, and downstream toggles stay explicit and reproducible.
The required minimal reference databases live under `assets/test_databases/`.

## Run a single case locally

```bash
# Make sure the test databases can be seen by Nextflow
export HOST_PROJECT_DIR="$(pwd -P)"
nextflow run main.nf -profile test_short_16S,singularity -params-file tests/params/short_16S_faprotax.yml -bg -resume
```

Swap the parameter file to run any other test case.

For an end-to-end local smoke test, run:

```powershell
bash tests/run-local-tests.sh
```

## Notes

- The test workflow uses repository fixtures in `tests/data/reads/`.
- Functional annotation tests point to bundled test databases in `assets/test_databases/`.
- `-preview` keeps the checks fast and verifies the workflow wiring without running the heavy bioinformatics steps.