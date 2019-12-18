# Contributing Guide

Hi stranger, thanks for your love.

If you're looking to improve `g`, be sure to first:

* Search through Pull-Requests and Issues; someone might have had the same problem already.
* Read the [LICENSE](./LICENSE).
* Read the [Code of Conduct](./CODE_OF_CONDUCT.md).
* Check the [`next` branch](https://github.com/stefanmaric/g/tree/next) and [what changes are pending for release](https://github.com/stefanmaric/g/compare/master...next), if any.

**IMPORTANT**: If you want to add a feature, please open an issue to discuss it first; `g` aims to be simple.

Once you're ready to start coding:

* Fork the repo.
* Clone your fork.
* Checkout the `next` branch.
* Apply your changes.
* Document your changes (README, CHANGELOG, --help, etc) where necessary.
* Run `make lint` to check the code with `shellcheck` and run `make format` afterwards to style it with `shfmt`.

Once you are done with your changes and cleared by `make lint` and `make format`:

* Commit with a meaningful message. See: [How to Write a Git Commit Message](https://chris.beams.io/posts/git-commit/).
* If your contribution is related to an existing issue, remember to reference the issue number.
* Push.
* Open a pull request against the `next` branch.
* Ask for review.
* Be patient.

Love. ♥
