<!--
metadata:
  created_at:   2026-11-12T12:40:44-05:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-11-12T12:40:44-05:00
-->

# Story: Faster Test Suite

## Summary

AS a developer working on head_music
I WANT the full test suite to finish in a fraction of its current time
SO THAT `rake validate` is something to run before every commit, not something to wait on

## Acceptance Criteria

- Measure a baseline first: wall-clock time for `bundle exec rake spec` and
  `bundle exec rake validate`, plus the slowest example groups (`--profile`),
  recorded in this story.
- Find where the time goes before choosing a fix, and record it here: slow
  examples, slow files, repeated expensive setup, coverage overhead.
- Cut `rake spec` to an agreed target, measured on the same machine as the
  baseline. Set the target once the profile is in.
- No loss of coverage: the same examples run, line and branch coverage hold
  (99.77% and 95.28% at last count), and the 90% minimum still applies.
- Any change to how the suite runs (parallelism, tags, split tasks) is
  reflected in the CLAUDE.md commands.

## Notes

- On 2026-11-12, `rake validate` ran 18,871 examples in 10 minutes 6 seconds
  before lint, the security audit, and RubyCritic.
  `spec/head_music/midi` alone took about 48 seconds for 1,017 examples, and
  `spec/head_music/notation` with `spec/head_music/instruments` ran past 2
  minutes.
- `.rspec` uses `--format documentation`, which prints a line for every
  example.
- `rake spec` always turns on SimpleCov (`Rakefile`); `bundle exec rspec` does
  not. Comparing the two shows what coverage costs.
- The outside-tool oracle specs are opt-in (`ORACLES=1`, `rake oracles`), so
  they are not the default run's problem.
- Candidates to evaluate after profiling, not to assume: running in parallel
  (`parallel_tests`, with SimpleCov results merged), memoizing catalog and YAML
  loads that specs repeat, `let_it_be`-style shared setup for expensive
  fixtures, a progress formatter, and a fast default task with the slow
  groups behind a tag.
- `rake validate` runs its steps one after another, so RubyCritic and RuboCop
  could also run alongside the specs.

## Implementation Plan

[to be filled in by /stories plan]
