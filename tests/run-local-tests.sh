#!/usr/bin/env bash
set -euo pipefail

preview_only=false

if [[ "${1:-}" == "--preview-only" || "${1:-}" == "-p" ]]; then
  preview_only=true
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(dirname "$script_dir")"

test_params=(
  "tests/params/short_16S_faprotax.yml"
  "tests/params/short_16S_picrust2.yml"
  "tests/params/long_16S_faprotax.yml"
  "tests/params/long_16S_picrust2.yml"
  "tests/params/its_funguild.yml"
)

for params_file in "${test_params[@]}"; do
  echo "Running $params_file"

  arguments=(
    run
    main.nf
    -profile
    nrc,singularity
    -params-file
    "$params_file"
  )

  if [[ "$preview_only" == true ]]; then
    arguments+=("-preview")
  fi

  nextflow "${arguments[@]}"
done
