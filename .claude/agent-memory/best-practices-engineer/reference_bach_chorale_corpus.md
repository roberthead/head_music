---
name: reference-bach-chorale-corpus
description: Local clone of the Bach chorale kern corpus used by KERN_CORPUS specs, its parse cost, and its key designations by mode
metadata:
  type: reference
---

The KERN_CORPUS clone lives at `~/github.com/craigsapp/bach-370-chorales` (files under `kern/`). 366 of 370 parse; 4 are refused by name in `spec/head_music/notation/kern_corpus_spec.rb`.

Measured 2026-10-15: parsing all 366 with `HeadMusic::Notation::Kern.parse` takes about 46 s, and they hold 83,196 pitched notes. Every chorale has a designation; by mode there are 182 major, 137 minor, 36 dorian, 9 mixolydian, and 2 phrygian. So any key-agreement metric has to say how the 47 modal designations are scored.

**How to apply:** a corpus spec should parse each chorale once and run every measurement from that parse. Prototype scripts for key and spelling inference were written under the session scratchpad (`kasi-plan/bp/`); they are throwaway. See [[project-key-spelling-baselines]].
