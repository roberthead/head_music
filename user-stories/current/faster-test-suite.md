<!--
metadata:
  created_at:   2026-11-12T12:40:44-05:00
  activated_at: 2026-11-12T14:25:06-05:00
  planned_at:   2026-11-12T16:44:02-05:00
  finished_at:
  updated_at:   2026-11-12T21:21:42-05:00
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
- Cut `bin/validate`, which runs the specs without coverage, to under 2
  minutes.
- No loss of coverage: the same examples run, and under `rake spec` and CI
  line and branch coverage hold (99.77% and 95.28% at last count) with the
  90% minimum still applied. `rake validate` does not check coverage.
- CI stays serial; parallelizing it is out of scope, since CI already fits
  its timeout and no one waits on it locally.
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
| `bin/validate`, specs without coverage, still serial (after 5ba3c7de) | 3m45s |
| Boot (`require "spec_helper"`) | 0.7s |

The earlier 10m06s and 19m31s runs were under heavier, unrecorded load, so
compare only against runs with a matching load note.

## After

Measured 2026-11-12 with `parallel_rspec` on 10 processes, the game still
running (load average 5 to 7). Every run: 18,871 examples, 0 failures.

| Run | Before | After |
| --- | --- | --- |
| `rake spec` (coverage, files placed by runtime) | 4m59s | 43s |
| `rake spec:without_coverage` (files placed by size, no log yet) | 3m29s | 63s |
| `bin/validate` (files placed by runtime) | 3m45s | 49s (specs 32s) |

Coverage is unchanged: 99.77% line and 95.28% branch, merged from all ten
processes. Raising `minimum_coverage` to 99.9 failed the run (exit 1), so
the merged total is what the minimum checks.

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
5. **Group by runtime.** Leave grouping to parallel_tests, which uses that
   log when it covers enough files and file size otherwise. The log stays in
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

## Review

Reviewed 2026-11-12 at `eb3e439d`, by an independent agent, with each
finding confirmed in the source.

| Criterion | Verdict | Evidence |
| --- | --- | --- |
| Baseline recorded | ⚠️ | `rake spec` and the profile are recorded. `rake validate` appears only as a sum of steps (about 5m20s), and the 3m45s "before" for `bin/validate` in `## After` is the uncovered serial run, which the Baseline section never lists. |
| Where the time goes | ✅ | `## Where the Time Goes` |
| `rake spec` under 90s | ✅ | 43s, and 47.6s on the reviewer's rerun at load 9 |
| `bin/validate` under 2 minutes | ✅ | 49s, and 51.7s on the reviewer's rerun at load 32 |
| No loss of coverage | ✅ | merged from 10 processes: 99.77% / 95.28%; `minimum_coverage 90` at `spec/spec_helper.rb:13`; a raised minimum fails the run |
| CI stays serial | ✅ | `.github/workflows/ci.yml` unchanged; it never reads `.rspec_parallel` |
| CLAUDE.md reflects the change | ⚠️ | `rake spec:without_coverage` is not listed, and two statements are inaccurate (findings 3 and 4) |

### Findings

1. **Stale comment.** `spec/spec_helper.rb:3-4` still says `rake validate`
   sets `COVERAGE`.
2. **`rake spec SPEC=...` is silently ignored.** The tasks are plain `sh`
   calls, and parallel_tests never reads `SPEC`, so the whole suite runs.
   `RSpec::Core::RakeTask` used to honor it.
3. **The `--only-failures` note in CLAUDE.md is wrong.** RSpec keeps statuses
   for files a run did not load. `spec/examples.txt` therefore holds 670
   files: process 1's fresh results plus stale ones from the last serial
   run. A rerun after a parallel run replays old failures and misses new
   ones from processes 2–10.
4. **Doc inaccuracies:**
   - CI checks coverage only on pushes to `main` and on PRs, in one matrix
     leg, not "on every push".
   - Grouping by runtime falls back to file size when the log covers too
     few files (`runtimes.size * 1.5 > tests.size`), which the `Rakefile`
     comment does not say.
   - Plan step 5's `--group-by runtime` flag was not used; auto-detection
     is.
5. **Stale coverage results.** A leftover serial coverage result in
   `coverage/.resultset.json` caused 10 "older than merge_timeout"
   warnings. If that result were newer than 10 minutes, it would be merged
   into the total and could hide a drop. Inferred from SimpleCov's
   behavior, not reproduced.
6. **Minor:**
   - `spec:without_coverage` inherits `COVERAGE` from the shell; the
     `sh({"COVERAGE" => nil}, ...)` pattern already in the `Rakefile` would
     prevent that.
   - `parallel_tests` sits under the `Gemfile` comment about rubocop, which
     reads as if it explains the new line.

None blocks `finish` on the criteria. Findings 1–4 and 6 are small fixes.

### Resolution

Fixed in 72802b82, and verified by running each case:

- `SPEC=path` narrows the run (4 processes for 4 files).
- A planted failure from a parallel run is the one example
  `rspec --only-failures` reruns, and its entry is dropped once the file
  is gone.
- The resultset is cleared before a coverage run, so the merge_timeout
  warnings are gone.
- `COVERAGE` is unset for `spec:without_coverage`.
- The docs and comments are corrected, and the Baseline now lists the
  3m45s run.

Testing showed one more problem: a narrowed run replaced the runtime log
with its own few files, so the next full `rake spec` grouped by file size
and took 90s. A narrowed run now merges its timings into the log, which
keeps all 656 entries. Afterward, `rake spec` took 45s and `bin/validate`
57s (at load 30), with 18,871 examples, 0 failures, and coverage of
99.77% / 95.28%.
