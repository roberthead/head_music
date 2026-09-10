---
name: release
description: Prepare and publish a head_music release. Verifies the previous version actually shipped, settles the bump with the user, moves Unreleased into a dated CHANGELOG section, bumps version.rb and Gemfile.lock, runs the suite, writes the release commit, and stops before tagging and publishing. Use when the user asks to release, cut a version, bump the version, or publish the gem.
---

# Release

The version bump and the release are one transaction. The bump commit is the
release commit, and a version that is bumped but never tagged and pushed is a
defect, not an intermediate state. This skill prepares everything, then stops
before the irreversible step.

## 1. Preflight

Run these before touching anything. Stop and report if any fails.

- On `main`, clean working tree, up to date with `origin/main`.
- The previous version shipped. Compare `lib/head_music/version.rb` with
  `gem search -r -a head_music`. If the version file is already ahead of
  RubyGems and its CHANGELOG section carries a date, a bump was committed but
  never published. Say so. The fix is usually to fold the new entries into
  that section and release it, not to bump again.
- The `## [Unreleased]` section of `CHANGELOG.md` has entries. If it is
  empty, there is nothing to release.
- `bundle exec rake` passes with coverage and `bundle exec rubocop` is clean.

## 2. Choose the bump

Read the Unreleased subsections and put the choice to the user. Do not decide
alone when a Changed or Removed subsection is present. The project's
convention so far:

- Additive only (Added, and Fixed): minor.
- Behavior changes with no signature change, such as a grading rule that
  regrades existing melodies: minor, called out in the release intro.
- A removed class or method, a serialization schema bump, or a document that
  needs migration: major. 21.0.0 is the model.
- Fixes only: patch.

## 3. Prepare

- In `CHANGELOG.md`, rename `## [Unreleased]` to `## [X.Y.Z] - YYYY-MM-DD`
  with today's date, and insert a fresh empty `## [Unreleased]` above it with
  blank lines around both headings. Subsections stay in Keep a Changelog
  order: Added, Changed, Deprecated, Removed, Fixed, Security.
- For a minor or major release, open the section with a short intro
  paragraph the way 21.0.0 and 21.1.0 do: what the release is for, and a bold
  sentence naming the bump and what a consumer must do to upgrade.
- Set `VERSION` in `lib/head_music/version.rb`.
- Run `bundle install` so `Gemfile.lock` records the new version.
- Run `bundle exec rake` and `bundle exec rubocop` again.
- Show the user the diff: CHANGELOG, version file, lockfile, nothing else.

## 4. Commit and push

Only when the user asks. Subject is `Release X.Y.Z`. Add a body only when the
number needs explaining, such as why a release is major or which behavior
changed. Push `main`.

## 5. Tag

Stop here. Do not tag without the user's explicit go in this conversation.
Pushing the tag starts the publish, and a published version cannot be
withdrawn.

```bash
bundle exec rake release:source_control_push
```

This creates the annotated tag `vX.Y.Z` and pushes it. It does not push the
gem. The tag push triggers `.github/workflows/release.yml`, which runs the
suite and linter, builds the gem, creates the GitHub Release, and publishes to
RubyGems through trusted publishing. Do not run plain `rake release`: its gem
push would race the workflow's, and one of them would be rejected as a
re-push.

Prerequisite, once: the workflow must be registered as a trusted publisher at
rubygems.org/gems/head_music/trusted_publishers, with repository
`roberthead/head_music` and workflow file `release.yml`.

## 6. Verify

- `gh run watch` on the run that the tag started, or
  `gh run list --workflow=release.yml --limit 1`. Report its status. Do not
  assume it passed. The workflow failed on every run before 2026-09-10, first
  on a denied API key and then on an action version that did not exist.
- `gem search -r head_music` lists the new version.
- `gh release view vX.Y.Z` shows the GitHub Release with the gem attached.

If the workflow fails after the tag is pushed, the fallback is
`bundle exec rake release:rubygem_push`, which needs a RubyGems one-time
password and so is the user's to run with the `!` prefix.
