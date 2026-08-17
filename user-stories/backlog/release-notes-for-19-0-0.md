<!--
metadata:
  created_at:   2026-08-16T15:45:22-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-08-16T19:13:17-07:00
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

## Everything under `[Unreleased]` was 19.0.0, and has been split

Worth recording, because the obvious worry was that the block mixed shipped and
unshipped work. It did not — checked against the push time below — which is what
made the split a rename rather than a judgment call about which bullet belonged
where. The First-Class Guide Items story performed it before adding its own
entries.

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

**Items 1–3 were done by the First-Class Guide Items story**, which had to split
the heading before it could file its own entry: adding 20.0 content under a
heading that describes a shipped release would have misfiled it, and would have
invalidated this ticket's own premise that everything under `[Unreleased]` is
19.0.0. What remains is the backfill in the next section.

1. ~~Rename `## [Unreleased]` to `## [19.0.0] - 2026-08-07`.~~ Done.
2. ~~Add a fresh `## [Unreleased]` section above it.~~ Done — it now holds the
   20.0 entries.
3. ~~Fix the `[Unreleased]` link reference, which read `compare/v8.2.0...HEAD`.~~
   Done; a `[19.0.0]` reference was added alongside it.

### Also broken, and worth deciding on

**The link-reference list stops at 8.x.** There are heading entries for every
release through 18.0.0 but link references only through `[8.2.0]`, so eleven
majors' worth of `## [N]` headings render as plain text rather than compare
links. Either backfill `[9.0.0]` through `[19.0.0]` — all the tags exist, so this
is mechanical — or accept the rot and only add `[19.0.0]`. Backfilling is the
better answer and is a few lines of shell against `git tag`, but it is a bigger
diff than this ticket's title implies, so it is called out rather than assumed.

## Acceptance Criteria

- ~~`CHANGELOG.md` has a `## [19.0.0] - 2026-08-07` heading.~~ Done.
- ~~An `## [Unreleased]` section sits above it.~~ Done; it holds the 20.0 entries.
- ~~The `[Unreleased]` link reference compares from `v19.0.0`.~~ Done.
- ~~A `[19.0.0]` link reference exists.~~ Done.
- Link references exist for `[9.0.0]` through `[18.0.0]`, so every heading from
  9.0.0 onward renders as a compare link rather than plain text.
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
