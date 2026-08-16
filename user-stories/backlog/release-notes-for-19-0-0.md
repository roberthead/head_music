<!--
metadata:
  created_at:   2026-08-16T15:45:22-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-08-16T15:45:22-07:00
-->

# Release Notes for 19.0.0

AS someone deciding whether to upgrade

I WANT `CHANGELOG.md` to have a `19.0.0` heading with its release date

SO THAT I can tell what shipped in the version I am installing, rather than reading notes filed under "Unreleased" for a release that went out nine days ago

## Background

19.0.0 shipped and its notes never got a heading.

| | |
| --- | --- |
| Published to rubygems | `19.0.0` on 2026-08-08T03:51:52Z (2026-08-07, 20:51 Pacific) |
| Git tag | `v19.0.0` exists |
| `lib/head_music/version.rb` | `VERSION = "19.0.0"` |
| `CHANGELOG.md` | No `## [19.0.0]` heading. Its notes sit under `## [Unreleased]` (lines 8–49), directly above `## [18.0.0] - 2026-07-27` |

So the changelog claims the guide registry, the collapsed contour guides, the
`Instrument.get` signature change, and the ABC/MusicXML constant moves are all
unreleased, when every one of them is installable today.

## Everything under `[Unreleased]` is 19.0.0

Worth stating, because the obvious worry is that the block mixes shipped and
unshipped work and needs splitting. It does not. Checked against the push time:

| Commit | Committed | vs. rubygems push |
| --- | --- | --- |
| `b1cef76` Split the notation writers and lexer | 2026-08-06 18:44 | before |
| `7e2ce56` Add a guide registry, bump to 19.0.0 | 2026-08-07 15:31 | before |
| `4157040` Close the inherited ruleset hole | 2026-08-07 15:55 | before |
| `6e7f4b8` Pin the guide keys and warm-up | 2026-08-07 16:04 | before |
| `ea52df0` Close two gaps before the 19.0.0 release | 2026-08-07 18:16 | before |
| — rubygems push — | 2026-08-07 20:51 | — |
| `65eb860`, `06f85e2` | 2026-08-08 onward | after, **`user-stories/` only** |

`ea52df0` is the last commit to touch `CHANGELOG.md`, and it landed before the
push. Nothing but story documentation has been committed since. So this is a
rename, not a split — no judgment call about which bullet belongs where.

## Scope

1. Rename `## [Unreleased]` (line 8) to `## [19.0.0] - 2026-08-07`.
2. Add a fresh, empty `## [Unreleased]` section above it.
3. Fix the `[Unreleased]` link reference at line 576, which currently reads
   `compare/v8.2.0...HEAD` — eleven major versions stale. It should compare from
   `v19.0.0`.

### Also broken, and worth deciding on

**The link-reference list stops at 8.x.** There are heading entries for every
release through 18.0.0 but link references only through `[8.2.0]`, so eleven
majors' worth of `## [N]` headings render as plain text rather than compare
links. Either backfill `[9.0.0]` through `[19.0.0]` — all the tags exist, so this
is mechanical — or accept the rot and only add `[19.0.0]`. Backfilling is the
better answer and is a few lines of shell against `git tag`, but it is a bigger
diff than this ticket's title implies, so it is called out rather than assumed.

## Acceptance Criteria

- `CHANGELOG.md` has a `## [19.0.0] - 2026-08-07` heading holding what is
  currently under `## [Unreleased]`, with no bullet added, removed, or reworded.
- An empty `## [Unreleased]` section sits above it, ready for the next change.
- The `[Unreleased]` link reference compares from `v19.0.0`, not `v8.2.0`.
- A `[19.0.0]` link reference exists, comparing `v18.0.0...v19.0.0`.
- No released entry from 18.0.0 or earlier is edited.

## Notes

**The date is 2026-08-07, not 2026-08-08.** The rubygems timestamp is UTC; the
existing headings follow local dates — 18.0.0's rubygems push was
2026-07-27T17:24Z and its heading reads `2026-07-27`, which is the Pacific date.
Same convention here, and Pacific is a day earlier than UTC for an evening push.

This surfaced while planning [Rename Annotation to Guideline](../done/rename-annotation-to-guideline.md),
which decided to leave `CHANGELOG.md:20` alone because it describes
`Guides::Configured` as "the guide-layer twin of `Annotation::Configured`" and is
shipped history. That decision stands whichever order these two land in: this
ticket only moves a heading, and never rewords a bullet.

## Implementation Plan

[to be filled in by /stories plan]
