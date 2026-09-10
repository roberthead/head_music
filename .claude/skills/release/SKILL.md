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

## 5. Publish

Stop here. Do not run the release task without the user's explicit go in this
conversation. It pushes a tag and uploads to RubyGems, and neither can be
undone.

```bash
bundle exec rake release
```

This builds the gem, creates the annotated tag `vX.Y.Z`, pushes the tag, and
pushes the gem to RubyGems. RubyGems requires a one-time password for this
gem, so the user will usually run it themselves with the `!` prefix.

## 6. Verify

- `gem search -r head_music` lists the new version.
- `git ls-remote --tags origin` shows `vX.Y.Z`.
- `gh run list --workflow=release.yml --limit 1` shows the tag-triggered
  workflow. As of 2026-09-10 that workflow has failed on every run, most
  recently because it names a version of the RubyGems credentials action that
  does not exist, so no GitHub Release is created and the local push above is
  what publishes the gem. Report the run's status. Do not assume it passed.
