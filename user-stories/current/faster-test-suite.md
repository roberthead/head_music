<!--
metadata:
  created_at:   2026-11-12T12:40:44-05:00
  activated_at: 2026-11-12T14:25:06-05:00
  planned_at:   2026-11-12T16:44:02-05:00
  finished_at:
  updated_at:   2026-11-12T16:44:02-05:00
-->

# Story: Faster Test Suite

## Summary

AS a developer working on head_music
I WANT the full test suite to finish in a fraction of its current time
SO THAT `rake validate` can be run more frequently

## Acceptance Criteria

- Measure a baseline first: wall-clock time for `bundle exec rake spec` and
  `bundle exec rake validate`, plus the slowest example groups (`--profile`),
  recorded in this story.
- Find where the time goes before choosing a fix, and record it here: slow
  examples, slow files, repeated expensive setup, coverage overhead.
- Cut `rake spec`, with coverage, from 4m59s to under 90 seconds on the same
  machine as the baseline; under 150 seconds is acceptable as a first step.
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

## Baseline

Measured 2026-11-12 at 9b66acb2 on Rob's 10-core Mac, with a game holding
about 220% CPU throughout (load average near 5). Examples: 18,871.

| Run | Wall clock |
| --- | --- |
| `rake spec` (SimpleCov, documentation formatter) | 4m59s (rspec reports 293s) |
| `rspec --format progress` (no coverage) | 3m29s |
| `rake rubocop` | 2s |
| `rake bundle:audit:check` | 0.6s |
| `rake rubycritic` | 17s |
| `rake validate` (sum of the above steps) | about 5m20s |
| Boot (`require "spec_helper"`) | 0.7s |

The earlier 10m06s and 19m31s runs were under heavier, unrecorded load, so
compare only against runs with a matching load note.

## Where the Time Goes

- Coverage and the documentation formatter together cost about 90 seconds,
  roughly 43% on top of an uncovered progress run; the two are not yet
  measured apart.
- `spec/head_music/notation` takes 224 of the 293 example seconds (77%);
  `style` 30s, `midi` 16s, everything else under 10s combined.
- The 16,092 examples under 10ms take 20s in all. The 679 examples between
  0.1s and 1s take 162s, and 17 examples over 1s take 49s.
- Slowest files: `music_xml_round_trip_spec.rb` 34s (372 examples),
  `mei_round_trip_spec.rb` 31s (421), `lily_pond_round_trip_spec.rb` 26s
  (369), `music_xml/writer_tuplet_summaries_spec.rb` 23s (118),
  `style/guide_corpus_fitness_spec.rb` 17s (178), `lily_pond/writer_spec.rb`
  16s, the shared examples in `support/lily_pond_helpers.rb` 14s,
  `music_xml/beam_reader_spec.rb` 14s, `mei/flow_builder_size_spec.rb` 12s
  (4 examples).
- Slowest examples: the MEI beam round trip of every tuplet flow (7.1s), the
  MEI and MusicXML linear-time size checks (5.9s, 5.2s, 4.1s), the LilyPond
  tuplets-and-grace-notes generator (5.4s), the MEI slur tuplet round trip
  (4.0s), and the MIDI budget over `MAX_NOTES` (3.1s).
- The round-trip examples each render, parse, render again, and parse again,
  so their cost is the work under test rather than repeated setup. Catalog
  YAML is already loaded once into constants.
- RSpec runs on one core of ten.

## Implementation Plan

Run the specs in ten processes with `parallel_tests`, grouped by each file's
recorded runtime, and let SimpleCov merge the processes' results before it
checks the minimum. `rake validate` already runs without coverage (done
ahead of the plan, at Rob's request), so both it and `rake spec` gain from
the same change. `bundle exec rspec` stays serial for running a single file.

### Steps

1. **Add the gem.** Add `parallel_tests` to the `:test` group in `Gemfile`,
   `bundle install`, and run `rake bundle:audit:check`.
2. **Separate per-process state.** In `spec/spec_helper.rb`, name the status
   file `spec/examples#{ENV["TEST_ENV_NUMBER"]}.txt` so ten processes do not
   overwrite one `spec/examples.txt`, and widen `.gitignore` to
   `/spec/examples*.txt`. Temp files already go through `Dir.mktmpdir`, and
   the scaling specs count calls rather than time, so nothing else is
   shared.
3. **Merge coverage.** SimpleCov detects `parallel_tests` itself: each
   process writes its result, and the last to finish merges them and
   applies `minimum_coverage` and `maximum_coverage_drop`. Confirm that
   simplecov 1.0.3 still does this. If it does not, give each process a
   `command_name` and merge with `SimpleCov.collate` in the Rake task.
4. **Choose the output.** Add `.rspec_parallel` with `--format progress` and
   `--format ParallelTests::RSpec::RuntimeLogger --out
   tmp/parallel_runtime_rspec.log`, because ten interleaved documentation
   streams are unreadable. Check whether `.rspec`'s `--format documentation`
   still applies under `parallel_rspec`; if it does, override it there
   rather than changing `.rspec`, which serves single-file runs.
5. **Group by runtime.** Pass `--group-by runtime` with that log once it
   exists, falling back to file size on the first run. The log stays in
   `tmp/` (ignored); a stale or missing log only makes the split less even.
6. **Point the tasks at it.** In `Rakefile`, make `spec` run
   `parallel_rspec spec` with `COVERAGE=true`, and make
   `spec:without_coverage` run it without. Keep `rake oracles` serial,
   since its specs drive outside tools.
7. **Measure.** Run `rake spec` and `bin/validate` under a load note like
   the baseline's. Confirm 18,871 examples, 0 failures, and line and branch
   coverage of 99.77% and 95.28%. Record the times beside the baseline.
8. **Only if still over target:** run RuboCop, the audit, and RubyCritic
   alongside the specs in `validate` (about 20s), then look at the largest
   files. `music_xml_round_trip_spec.rb` at 34s sets the floor for a split
   that keeps whole files together.
9. **Docs.** Update the CLAUDE.md commands and the `rake -T` descriptions to
   say the suite runs in parallel and how to run one file serially.

### Data model changes

None.

### Tests

No new specs: the change is to how the suite runs, not what it checks.
Proof is the example count, zero failures, and unchanged coverage from the
merged report, compared with the baseline.

### Risks and open questions

- Files that pass only after another file has set up state will fail when
  grouped apart. The suite has no random ordering today, so this has not
  been tested. Fix any such file instead of pinning the grouping.
- If the game is still running, ten processes compete with it for cores, so
  measure under the same load note as the baseline.
- `--only-failures` reads one status file. With one file per process, it
  misses a parallel run's failures unless the files are read together.
