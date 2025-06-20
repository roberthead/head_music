# Contributing to HeadMusic

Thank you for considering contributing to HeadMusic!

Following these guidelines helps to communicate that you respect the team managing and developing this open source project. In return, we should reciprocate that respect in addressing your issue, assessing changes, and facilitating your pull requests.

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to [robert.head@gmail.com](mailto:robert.head@gmail.com).

## What we are looking for

HeadMusic is an open source project and we love to receive contributions from our community. There are many ways to contribute, from writing tutorials or blog posts, improving the documentation, submitting bug reports and feature requests or writing code which can be incorporated into HeadMusic itself.

## How to contribute

### Reporting Bugs

Before creating bug reports, please check the existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible. Fill out [the required template](.github/ISSUE_TEMPLATE/bug_report.md), the information it asks for helps us resolve issues faster.

**Great Bug Reports** tend to have:

- A quick summary and/or background
- Steps to reproduce
  - Be specific!
  - Give sample code if you can
- What you expected would happen
- What actually happens
- Notes (possibly including why you think this might be happening, or stuff you tried that didn't work)

### Suggesting Enhancements

Before creating enhancement suggestions, please check the existing issues as you might find out that you don't need to create one. When you are creating an enhancement suggestion, please include as many details as possible. Fill in [the template](.github/ISSUE_TEMPLATE/feature_request.md), including the steps that you imagine you would take if the feature you're requesting existed.

### Pull Requests

The process described here has several goals:

- Maintain HeadMusic's quality
- Fix problems that are important to users
- Engage the community in working toward the best possible HeadMusic
- Enable a sustainable system for HeadMusic's maintainers to review contributions

Please follow these steps to have your contribution considered by the maintainers:

1. Fork the repo and create your branch from `main`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes (`bundle exec rspec`).
5. Make sure your code lints (`bundle exec rubocop`).
6. Follow the [pull request template](.github/pull_request_template.md) when creating your PR.

## Development Process

Here's how to get started with development:

1. Fork and clone the repository
2. Run `bin/setup` to install dependencies
3. Run `bundle exec rspec` to run the tests
4. Run `bundle exec rubocop` to check code style
5. Create a new branch for your feature or bug fix
6. Make your changes and add tests
7. Run the tests and linter to ensure everything passes
8. Commit your changes with a clear commit message
9. Push to your fork and submit a pull request

### Setting up your development environment

```bash
git clone https://github.com/your-username/head_music.git
cd head_music
bin/setup
```

### Running tests

```bash
# Run all tests
bundle exec rspec

# Run a specific test file
bundle exec rspec spec/head_music/rudiment/pitch_spec.rb

# Run tests matching a pattern
bundle exec rspec -e "Pitch"
```

### Code style

We use RuboCop with the Standard Ruby style guide. Before submitting a PR, please run:

```bash
bundle exec rubocop
```

To automatically fix many issues:

```bash
bundle exec rubocop --autocorrect
```

## Styleguides

### Git Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally after the first line
- Consider starting the commit message with an applicable emoji:
    - 🎨 `:art:` when improving the format/structure of the code
    - 🐎 `:racehorse:` when improving performance
    - 📝 `:memo:` when writing docs
    - 🐛 `:bug:` when fixing a bug
    - 🔥 `:fire:` when removing code or files
    - ✅ `:white_check_mark:` when adding tests
    - 🔒 `:lock:` when dealing with security
    - ⬆️ `:arrow_up:` when upgrading dependencies
    - ⬇️ `:arrow_down:` when downgrading dependencies

### Ruby Styleguide

All Ruby code must adhere to [Standard Ruby](https://github.com/testdouble/standard).

### Documentation Styleguide

- Use [YARD](https://yardoc.org/) for API documentation.
- Include examples in your documentation when possible.

## Community

- Join our discussions in [GitHub Discussions](https://github.com/roberthead/head_music/discussions)
- Ask questions in the [Issues](https://github.com/roberthead/head_music/issues)

## Recognition

Contributors who submit a pull request that gets merged will be added to our [Contributors list](https://github.com/roberthead/head_music/graphs/contributors).

## Questions?

Feel free to contact the project maintainer at [robert.head@gmail.com](mailto:robert.head@gmail.com) if you have any questions or concerns.

Thank you for contributing to HeadMusic! 🎵
