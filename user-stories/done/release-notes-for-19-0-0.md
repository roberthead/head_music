<!--
metadata:
  created_at:   2026-08-16T15:45:22-07:00
  activated_at: 2026-08-19T10:49:58-07:00
  planned_at:   2026-08-19T11:02:14-07:00
  finished_at:  2026-08-19T11:31:12-07:00
  updated_at:   2026-08-19T11:52:30-07:00
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
  9.0.0 onward renders as a compare link rather than plain text. **Met for every
  heading that can be linked** -- 24 of 28. `17.4.0`, `16.0.0`, `15.1.0`, and
  `10.0.0` have no tag on origin, so no reference exists that would resolve; see
  the plan. The criterion was written believing all the tags existed.
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

## Review

Reviewed 2026-08-19 against the working tree on `story/release-notes-for-19-0-0`
(branched from `a2c6726`; the changes below are uncommitted).

### Acceptance criteria

| Criterion | Verdict | Evidence |
| --- | --- | --- |
| `## [19.0.0] - 2026-08-07` heading | ✅ met | `CHANGELOG.md:77`, by the First-Class Guide Items story |
| `## [Unreleased]` above it | ✅ met | `CHANGELOG.md:8`, holding the 20.0 entries |
| `[Unreleased]` compares from `v19.0.0` | ✅ met | `CHANGELOG.md:645` |
| `[19.0.0]` reference exists | ✅ met | `CHANGELOG.md:646` |
| References for `[9.0.0]`–`[18.0.0]` | ⚠️ met as far as it can be | 24 added, all resolving on origin. `17.4.0`, `16.0.0`, `15.1.0`, `10.0.0` have no tag on origin and are left as plain text |
| No entry from 18.0.0 or earlier edited | ✅ met | `git diff CHANGELOG.md` is 24 insertions and 0 deletions, all inside the reference block |

### Findings

**The verification that mattered was the one against origin.** Generating from
`git tag` passed every local check and would have shipped four references naming
`v17.4.0` and `v15.1.0` -- tags that exist on this machine and nowhere else, so
every one would have 404'd for the reader the story is written for. `git
ls-remote --tags origin` is the only list that describes what a link can reach.
Four of the URLs were also fetched through `gh api .../compare/...` and return
`ahead` or `diverged` with a commit count, so the format is confirmed, not
assumed.

**Four ranges silently include the release below them.** `[17.0.0]` spans
16.0.0's commits, `[11.0.0]` spans 10.0.0's, `[15.2.0]` spans 15.1.0's, and
`[17.5.0]` spans 17.4.0's, because the intervening release has no reachable tag.
A reader gets more than the heading promises rather than less, which is the safer
failure, but it is a failure. Pushing `v15.1.0` and `v17.4.0` and tagging 16.0.0
(`aa8dee1`) and 10.0.0 (`6d8f443`) would resolve all four and let the missing
references be added. Recommended as a follow-up ticket; publishing tags was not
this ticket's remit.

**Pre-existing rot below the line, left alone.** `[8.1.0]`, `[8.0.2]`,
`[8.0.0]`, and `[3.0.1]` point at tags that exist nowhere, and `## [8.2.1]` has
no reference. All predate this ticket and sit below its stated floor of 9.0.0.

**No code changed.** `bundle exec rspec` (6602 examples, 0 failures) and `bundle
exec rubocop` (507 files, clean) were run as a guard against an incidental edit,
not because the diff touches Ruby.

### Verified after the fact: the split itself, and the date

The review above accepted items 1-3 as done because the heading exists. That
checks the heading, not what sits under it, and the question worth answering is
whether any 20.0 work got filed under a shipped release. Four checks, none of
which rely on reading the entries:

1. The current `## [19.0.0]` section is **byte-identical** to the `[Unreleased]`
   block at the `v19.0.0` tag -- `diff` reports one differing line, the heading
   itself. Nothing was added, removed, or reworded in the split.
2. The **published gem** was fetched from rubygems and unpacked. Its `lib/` and
   its `CHANGELOG.md` are byte-identical to the `v19.0.0` tag, so the tag is
   what shipped.
3. **Nothing landed in between.** The tag is `ea52df0`, 2026-08-07 18:16 Pacific;
   the gem was pushed 20:51 Pacific; the next commit in the repo is `65eb860` on
   2026-08-08 15:57 Pacific and touches `user-stories/` only.
4. The 20.0 entries now under `[Unreleased]` -- tiers, `GuideItem`,
   `GuideAssessment`, `guide.assess` -- were all written on 2026-08-16, nine days
   after the push.

**On the heading date, 2026-08-07 against rubygems' "August 08, 2026".** The
story's own justification cites 18.0.0, which proves nothing: that push was
17:24 UTC, the same calendar date in both zones. The real evidence is the five
other releases pushed in the window where the zones disagree -- 17.3.0, 17.1.0,
17.0.0, 15.2.0, and 14.0.0. Every one of them is headed with the **Pacific**
date, and none with the UTC date rubygems displays. 19.0.0 at `2026-08-07`
follows the file's actual convention.

**What can look like a mix-up and is not.** The 19.0.0 entries describe
`Style::Analysis` and `Annotation::Configured`, names that no longer exist
because 20.0 renamed them. That is shipped history describing the API as it
shipped; the Rename Annotation to Guideline story decided deliberately to leave
those words alone.

## Implementation Plan

### What the ticket assumed, and what is actually there

The ticket calls the backfill "a few lines of shell against `git tag`" because
"all the tags exist". Four of them do not, in two different ways:

| Heading | Local tag | On origin | Version bumped by |
| --- | --- | --- | --- |
| `## [17.4.0] - 2026-07-20` | yes | **no** | — |
| `## [16.0.0] - 2026-07-17` | **no** | no | `aa8dee1`, `2a33c9f` |
| `## [15.1.0] - 2026-07-07` | yes | **no** | — |
| `## [10.0.0] - 2025-12-01` | **no** | no | `6d8f443`, `3d736b7` |

All four were released -- `lib/head_music/version.rb` carried each number -- but
none can be the endpoint of a link that resolves for a reader. Two were never
tagged at all; two were tagged locally and the tag was never pushed, which is
indistinguishable from the first case in a browser. `v11.4.0` is a third
unpushed tag, harmless here because no heading or link range names it.

The tags disagree with the headings in the other direction too: `v8.3.0`,
`v8.4.0`, `v9.0.1`, `v9.1.0`, and `v11.1.0` through `v11.5.1` are released tags
with no changelog heading.

### The rule for the "from" side

Existing references compare from the preceding *heading*, which works only while
headings and tags agree. They stop agreeing above 8.x, so each backfilled
reference compares from **the tag immediately preceding it in version order,
among tags that exist on origin** -- the range a reader actually wants, and the
only one that resolves.

The check that matters is against `git ls-remote --tags origin`, not `git tag`.
Generating from the local list produced four references naming `v17.4.0` and
`v15.1.0`, every one of which would have rendered as a 404 while passing any
local verification.

Four ranges therefore swallow the release below them: `[11.0.0]` includes
10.0.0's commits, `[17.0.0]` includes 16.0.0's, `[15.2.0]` includes 15.1.0's,
and `[17.5.0]` includes 17.4.0's.

Pushing `v15.1.0` and `v17.4.0`, and tagging 16.0.0 and 10.0.0, would let all
four be linked directly. That is the recommended follow-up and is not done here:
publishing tags to a public repository is not something this ticket asked for.

### Steps

1. Generate one reference per heading from 9.0.0 through 18.0.0 whose tag exists
   on origin, each comparing from the previous such tag. 24 lines; four headings
   are skipped for want of a reachable tag.
2. Insert them into the reference block between `[19.0.0]` and `[8.2.0]`, in
   descending version order, matching the block's existing style.
3. Verify: every reference names two tags present on origin, no duplicates, the
   block stays in descending order, and the diff is insertions only -- so no
   released entry is edited.
4. Record the four unlinkable headings, and the pre-existing 8.x rot found on the
   way past: `[8.1.0]`, `[8.0.2]`, `[8.0.0]`, and `[3.0.1]` already point at tags
   that exist nowhere, and `## [8.2.1]` has no reference at all. All below this
   ticket's line, so all left alone.

## Learnings

**The ticket's own premise was the thing to check first.** "All the tags exist,
so this is mechanical" was written from the headings, not from `git tag`. Four
of the twenty-eight headings in range have no tag a reader can reach. Ten
minutes of checking turned the estimate from wrong-and-fast into right-and-still
-fast; the check belonged in planning, not in review.

**`git tag` is not the list that matters.** A link in a published changelog is
reached from a browser, so the only authority is `git ls-remote --tags origin`.
The first generated version of this backfill passed every local check and
contained four references to `v17.4.0` and `v15.1.0` -- tags that exist on this
machine alone. Local-only tags are invisible to every verification that does not
ask the remote, which is exactly the shape of bug a changelog ships without
anyone noticing for a year.

**Verify the artifact the way its reader will use it.** Four of the generated
URLs went through `gh api .../compare/...` and came back with commit counts. That
is a different claim from "the string looks right", and it is the claim the
story is about.

**A criterion written on a false premise cannot be met, only annotated.** The
honest close is "24 of 28, and here is why the other four cannot exist" rather
than quietly narrowing the criterion or padding it with links that 404. The
story already used strikethrough to record what another story had done to it;
the same convention carried the exception.

**Reading the current file state before planning saved redoing three items.**
Items 1-3 of the scope were already done by the First-Class Guide Items story,
which had to split the heading before it could file its own entries. The story
file said so; the plan only had to confirm it against `CHANGELOG.md`.

### Follow-up worth filing

Push `v15.1.0` and `v17.4.0`, and tag 16.0.0 (`aa8dee1`) and 10.0.0
(`6d8f443`). That would let the four missing references be added and would stop
`[11.0.0]`, `[15.2.0]`, `[17.0.0]`, and `[17.5.0]` from spanning a release each.
