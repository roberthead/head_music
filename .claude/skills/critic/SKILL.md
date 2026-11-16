---
name: critic
description: Raise head_music's RubyCritic score and file grades through genuine reductions in flog complexity and flay duplication, never by gaming the metric. Measures a baseline, ranks the costliest files and duplication clusters, refactors the best candidates one commit at a time with the specs as the safety net, and reports the change. Use when the user asks to improve code quality, the RubyCritic score, file grades, complexity, or duplication, or when `rake rubycritic` or `rake validate` fails on a D or F file.
---

# Critic

The score is a proxy for code that is easier to read and change. Every move
in this skill has to make the code better on its own terms; a higher score
that the code did not earn is a regression.

## How the score works

- Score = `100 - 6.25 × average file cost`, each file's cost capped at 32.
- A file's cost = its flog complexity / 25, plus `mass / 25` (integer
  division) for each flay duplicate it takes part in.
- Grades: A ≤ 2, B ≤ 4, C ≤ 8, D ≤ 16, F above. With no duplication,
  C ends near 200 flog.
- Flog's `#none` bucket, the class body, is not counted: delegates,
  includes, constants, and `define_method` loops are free.
- Reek smells and churn cost nothing. Ignore them here.
- A duplicate is charged to every file it appears in, so DRYing a block
  shared by N files reclaims it from N - 1 of them.

`rake rubycritic` fails below `minimum_score` in `.rubycritic.yml` or on any
D or F file, and `rake validate` runs it.

## 1. Measure

```bash
bundle exec rubycritic
ruby .claude/skills/critic/scripts/report.rb --target 85 --save <scratchpad>/critic-base.json
```

The report prints the score, rating counts, the costliest files, and
duplication clusters ranked by reclaimable cost. `--target` says how many
cost units a score needs at the current file count. Check the report's
timestamp: a stale `report.json` quotes figures that no longer exist.

For a quick per-file check between full runs: `bundle exec flog -a FILE`,
total minus the `#none` line, over 25.

## 2. Choose

Work in this order:

1. **D and F files.** They fail `rake validate`.
2. **Duplication clusters that are real.** They are the cheapest points.
   Flay matches on AST shape, so first read every location in a cluster.
   Two unrelated letter tables, data tables (tuning ratios, key profiles,
   duration names), or two-line guide shells are false positives. Leave
   them, and say so.
3. **Files with the highest complexity.** Look for misplaced work first.

Present the shortlist with costs and the planned move for each before
editing, unless the user asked for a fix to a named file.

## 3. Refactor

Moves that lower total flog:

- Move work to the collaborator that owns it. Find a precedent in the
  codebase (a reader base class, a collection object, a value object) and
  follow it.
- Replace case or if chains with data lookups.
- Extract a shared module or base class for a true duplicate, such as the
  MEI and MusicXML readers that grew up in parallel.
- Remove operations that are actually repeated.

Moves that are gaming and must not be made:

- Splitting a file only to grow the denominator.
- Moving methods into `define_method` tables or class-body code to hide
  them in the untaxed `#none` bucket.
- Extracting a method that only relocates its operations. Flog's nesting
  multiplier is gentle, so this rarely lowers the file total.
- Removing features or behavior.

Judge a change by the total cost of every file it touches, including new
ones, not only the file it targets. Watch for a neighbor tipping over, and
for parallel extractions creating new cross-file duplicates.

New files need an explicit `require` in `lib/head_music.rb` before their
users. There is no autoloader, though the format entry files glob their
directories.

## 4. Verify each change

- Run the specs for the touched directories, then `bundle exec rubocop -a`.
- Compare the `Finished in` time for those specs with the baseline. A
  simpler rewrite can be much slower; `Position#normalize` once made a
  7000-event spec 2.5 times slower.
- If a refactor exposes a latent bug, write a failing spec for it and fix
  it in its own commit.
- Commit each coherent move on its own, describing the design change, not
  the score.

## 5. Report

```bash
bundle exec rubycritic
ruby .claude/skills/critic/scripts/report.rb --compare <scratchpad>/critic-base.json
```

Report the score and total cost before and after, the file count change,
grades that moved, and the clusters left alone as false positives. If the
score rose mostly through new files, not lower total cost, say so.
Finish with `bundle exec rake validate`, and check its exit status rather
than grepping its output.

## Scaling up

For a large pass, fan out worktree agents, one per subsystem. Give each the
base commit, its owned files, the gaming list above, and the rule that it is
judged on its group's total cost. Integrate their commits one at a time and
rerun the report after each, since a file nobody owned can tip over.
