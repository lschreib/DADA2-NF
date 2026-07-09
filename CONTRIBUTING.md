# Contribution guidelines

## Did you find a bug?

- **Ensure the bug was not already reported** by searching on GitHub under [Issues](https://github.com/lschreib/DADA2-NF/issues).
- If you're unable to find an open issue addressing the problem, [open a new one](https://github.com/lschreib/DADA2-NF/issues/new). Be sure to include:
  - A clear and descriptive title
  - A description of exactly what the unexpected behavior is, with as many relevant details as possible
  - A code sample or executable test case demonstrating the expected behavior that is not occurring

## Did you write a patch that fixes a bug?

- Open a new GitHub pull request with the patch
- Ensure the PR description clearly describes the problem and solution
- Include the relevant issue number if applicable

## Do you intend to add a new feature or change an existing one?

- Suggest your change by [opening an issue](https://github.com/lschreib/DADA2-NF/issues/new) and start writing code
- Do not open a pull request until you have collected positive feedback about the change

## Code Style

- Groovy code in modules should follow the [Groovy style guide](http://groovy-lang.org/style-guide.html)
- R code should follow the [tidyverse style guide](https://style.tidyverse.org/)
- Python code should follow [PEP 8](https://pep8.org/)
- Configuration files should use 4 spaces for indentation

## Development Setup

1. Clone the repository
2. Ensure you have Nextflow >=23.10.0 installed
3. For local testing, use the `test` profile: `nextflow run main.nf -profile test`
4. Run `nf-core lint` to check for compliance issues

## Testing

- Add test data to `tests/data/` if adding new functionality
- Update or create relevant test workflows
- Run `nextflow run main.nf -profile test` to validate changes

## Documentation

- Update `README.md` if your changes affect the main interface
- Update relevant files in `docs/` for feature additions
- Add comments to complex Groovy/R/Python code
- Update `CHANGELOG.md` with your changes

## Commit messages

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally after the first line

## License

By contributing to DADA2-NF, you agree that your contributions will be licensed under its MIT License.
