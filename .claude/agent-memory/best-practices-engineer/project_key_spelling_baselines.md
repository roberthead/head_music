---
name: project-key-spelling-baselines
description: Prototype baselines (2026-10-15) for whole-piece key finding by profile and line-of-fifths spelling accuracy on the Bach chorales
metadata:
  type: project
---

These come from a prototype measured during the Key and Spelling Inference planning on 2026-10-15. Key finding used duration-weighted Pearson correlation over the whole piece. Agreement with the designation, on the 319 major and minor chorales: Krumhansl-Kessler 80.6% (mostly dominant errors), Temperley 1999/CBMS 76.5% (mostly relative errors; that profile was built for flat input and a dot product), Temperley 2007 Kostka-Payne 88.7%, Bellman-Budge 90.9%, Aarden-Essen 92.5%.

Spelling, with key distance on the line of fifths alone: 99.87% with the key given. The hybrid adds a direction rule gated to chromatic notes (weight 3), chord span (weight 1 per fifth), and a center of gravity (beta 1, over one whole note); it reaches 99.93% given and 99.92-99.94% inferred. An ungated direction rule drops accuracy to 98.98%, because in minor it turns b6 into a raised 5.

**Why:** the story pins floors from these runs. The story's own floor (98%) is far below what was measured.

**How to apply:** use these figures when judging floors or default profiles. Re-measure after the real implementation lands, then update or remove this memory. See [[reference-bach-chorale-corpus]].
