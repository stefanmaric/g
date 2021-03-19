# Contributing Guide

Hi stranger, thanks for your love.

If you're looking to improve `g`, be sure to first:

- Search through Pull-Requests and Issues; someone might have had the same problem already.
- Check the [releases](https://github.com/stefanmaric/g/releases) and [CHANGELOG](./CHANGELOG.md) to make sure you have the latest version (`g --version`).
- Check [what changes are pending for release](https://github.com/stefanmaric/g/compare/master...next), if any.
- Read the [LICENSE](./LICENSE).
- Read the [Code of Conduct](./CODE_OF_CONDUCT.md).

**IMPORTANT**: If you want to add a feature, please open an issue to discuss it first; `g` aims to be simple.

Once you're ready to start coding:

- Fork the repo.
- Clone your fork.
- Checkout the `next` branch.
- Apply your changes.
- Document your changes (README, --help content, etc) where necessary.
- Update the [CHANGELOG](./CHANGELOG.md) describing your contributions.
- Run `make lint` to check the code with `shellcheck` and run `make format` afterwards to style it with `shfmt`.

Once you are done with your changes and cleared by `make lint` and `make format`:

- Commit with a meaningful message. See: [How to Write a Git Commit Message](https://chris.beams.io/posts/git-commit/).
- If your contribution is related to an existing issue, remember to reference the issue number.
- Push your changes to your fork.
- Open a pull request against the `next` branch.
- Wait for the CI to finish. We use Github Actions to lint and test on pull-requests.
- Ask for review.
- Be patient.

Love. ♥
