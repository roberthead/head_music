# Composite Guides — grades before and after

Generated. Do not edit by hand:

```
bundle exec ruby bin/guide_grade_corpus.rb tmp/before.json
bundle exec ruby bin/guide_grade_corpus.rb tmp/after.json
bundle exec ruby bin/guide_grade_table.rb user-stories/current/composite-guides.grades.md \
  "composite guides:tmp/before.json:tmp/after.json"
```

The capture script takes no arguments beyond its output path and asks only what every tree can answer, so each column is the same measurement made again. **3266 rows** in the first capture — 142 corpus entries × 23 registry entries — and **4260** in the last, 142 × 30. An asterisk marks an unassessable voice.

**Two denominators live in the harmony numbers and must not be conflated.** Of the 994 harmony rows, only **266 are assessable** — 38 entries × 7 harmony guides. Of those, **252** come from published fixtures (36 voices) and **14** from 2 synthetic ladder-against-cantus voices. Every assessable harmony row is first-species or ladder material: there are no second, third, fourth, or fifth species fixtures anywhere in `spec/`, so this corpus compares each line against itself rather than against a line of another species.

One section per join, and **each join spans exactly one change**, so its label is its cause rather than a guess made from the numbers. A row is relabelled only when the voice changed assessability, which is a gate moving rather than a weight.

## Composite guides

`before.json` → `after.json`. 0 of 3266 joined rows moved, 3266 unchanged.

994 further rows have no before column: 7 registry entries this change adds. They are new rather than moved, and are excluded from the counts above.

No row moved. This change is a provable no-op across the whole corpus.

## Composites beside their members

Every assessable composite row in `after.json`, with the two grades it was computed from. The last column recomputes the geometric mean from the members, so a composite grading by any other rule would show a gap here.

| corpus | notes | composite | grade | melody | harmony | √(m·h) |
| --- | ---: | --- | ---: | ---: | ---: | ---: |
| against-cantus-4 | 4 | `first_species` | 0.537878 | 0.705214 | 0.410249 | 0.537878 |
| against-cantus-4 | 4 | `second_species` | 0.685477 | 0.540485 | 0.869364 | 0.685477 |
| against-cantus-4 | 4 | `third_species` | 0.685477 | 0.540485 | 0.869364 | 0.685477 |
| against-cantus-4 | 4 | `third_species_triple_meter` | 0.685477 | 0.540485 | 0.869364 | 0.685477 |
| against-cantus-4 | 4 | `fourth_species` | 0.595650 | 0.422451 | 0.839856 | 0.595650 |
| against-cantus-4 | 4 | `fifth_species` | 0.664055 | 0.596214 | 0.739616 | 0.664055 |
| against-cantus-4 | 4 | `first_three_species` | 0.780834 | 0.962743 | 0.633296 | 0.780834 |
| against-cantus-8 | 8 | `first_species` | 0.780252 | 0.952012 | 0.639480 | 0.780252 |
| against-cantus-8 | 8 | `second_species` | 0.680786 | 0.549565 | 0.843339 | 0.680786 |
| against-cantus-8 | 8 | `third_species` | 0.680786 | 0.549565 | 0.843339 | 0.680786 |
| against-cantus-8 | 8 | `third_species_triple_meter` | 0.680786 | 0.549565 | 0.843339 | 0.680786 |
| against-cantus-8 | 8 | `fourth_species` | 0.883620 | 0.959395 | 0.813830 | 0.883620 |
| against-cantus-8 | 8 | `fifth_species` | 0.591126 | 0.542987 | 0.643533 | 0.591126 |
| against-cantus-8 | 8 | `first_three_species` | 0.670175 | 0.973473 | 0.461373 | 0.670175 |
| fux_first_species_examples-0-v0 | 11 | `first_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| fux_first_species_examples-0-v0 | 11 | `second_species` | 0.752191 | 0.565791 | 1.000000 | 0.752191 |
| fux_first_species_examples-0-v0 | 11 | `third_species` | 0.752191 | 0.565791 | 1.000000 | 0.752191 |
| fux_first_species_examples-0-v0 | 11 | `third_species_triple_meter` | 0.752191 | 0.565791 | 1.000000 | 0.752191 |
| fux_first_species_examples-0-v0 | 11 | `fourth_species` | 0.994373 | 0.988777 | 1.000000 | 0.994373 |
| fux_first_species_examples-0-v0 | 11 | `fifth_species` | 0.751158 | 0.564239 | 1.000000 | 0.751158 |
| fux_first_species_examples-0-v0 | 11 | `first_three_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| fux_first_species_examples-0-v1 | 11 | `first_species` | 1.000000 | 1.000000 | 1.000000 | 1.000000 |
| fux_first_species_examples-0-v1 | 11 | `second_species` | 0.747566 | 0.558855 | 1.000000 | 0.747566 |
| fux_first_species_examples-0-v1 | 11 | `third_species` | 0.747566 | 0.558855 | 1.000000 | 0.747566 |
| fux_first_species_examples-0-v1 | 11 | `third_species_triple_meter` | 0.747566 | 0.558855 | 1.000000 | 0.747566 |
| fux_first_species_examples-0-v1 | 11 | `fourth_species` | 0.990879 | 0.981841 | 1.000000 | 0.990879 |
| fux_first_species_examples-0-v1 | 11 | `fifth_species` | 0.746527 | 0.557302 | 1.000000 | 0.746527 |
| fux_first_species_examples-0-v1 | 11 | `first_three_species` | 0.989211 | 0.978539 | 1.000000 | 0.989211 |
| fux_first_species_examples-1-v0 | 11 | `first_species` | 0.965963 | 0.986737 | 0.945627 | 0.965963 |
| fux_first_species_examples-1-v0 | 11 | `second_species` | 0.736694 | 0.565791 | 0.959220 | 0.736694 |
| fux_first_species_examples-1-v0 | 11 | `third_species` | 0.736694 | 0.565791 | 0.959220 | 0.736694 |
| fux_first_species_examples-1-v0 | 11 | `third_species_triple_meter` | 0.736694 | 0.565791 | 0.959220 | 0.736694 |
| fux_first_species_examples-1-v0 | 11 | `fourth_species` | 0.973887 | 0.988777 | 0.959220 | 0.973887 |
| fux_first_species_examples-1-v0 | 11 | `fifth_species` | 0.737418 | 0.564239 | 0.963751 | 0.737418 |
| fux_first_species_examples-1-v0 | 11 | `first_three_species` | 0.972881 | 0.986737 | 0.959220 | 0.972881 |
| fux_first_species_examples-1-v1 | 11 | `first_species` | 0.965963 | 0.986737 | 0.945627 | 0.965963 |
| fux_first_species_examples-1-v1 | 11 | `second_species` | 0.736694 | 0.565791 | 0.959220 | 0.736694 |
| fux_first_species_examples-1-v1 | 11 | `third_species` | 0.736694 | 0.565791 | 0.959220 | 0.736694 |
| fux_first_species_examples-1-v1 | 11 | `third_species_triple_meter` | 0.736694 | 0.565791 | 0.959220 | 0.736694 |
| fux_first_species_examples-1-v1 | 11 | `fourth_species` | 0.973887 | 0.988777 | 0.959220 | 0.973887 |
| fux_first_species_examples-1-v1 | 11 | `fifth_species` | 0.737418 | 0.564239 | 0.963751 | 0.737418 |
| fux_first_species_examples-1-v1 | 11 | `first_three_species` | 0.972881 | 0.986737 | 0.959220 | 0.972881 |
| fux_first_species_examples-2-v0 | 11 | `first_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| fux_first_species_examples-2-v0 | 11 | `second_species` | 0.752191 | 0.565791 | 1.000000 | 0.752191 |
| fux_first_species_examples-2-v0 | 11 | `third_species` | 0.752191 | 0.565791 | 1.000000 | 0.752191 |
| fux_first_species_examples-2-v0 | 11 | `third_species_triple_meter` | 0.752191 | 0.565791 | 1.000000 | 0.752191 |
| fux_first_species_examples-2-v0 | 11 | `fourth_species` | 0.994373 | 0.988777 | 1.000000 | 0.994373 |
| fux_first_species_examples-2-v0 | 11 | `fifth_species` | 0.751158 | 0.564239 | 1.000000 | 0.751158 |
| fux_first_species_examples-2-v0 | 11 | `first_three_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| fux_first_species_examples-2-v1 | 11 | `first_species` | 1.000000 | 1.000000 | 1.000000 | 1.000000 |
| fux_first_species_examples-2-v1 | 11 | `second_species` | 0.752191 | 0.565791 | 1.000000 | 0.752191 |
| fux_first_species_examples-2-v1 | 11 | `third_species` | 0.752191 | 0.565791 | 1.000000 | 0.752191 |
| fux_first_species_examples-2-v1 | 11 | `third_species_triple_meter` | 0.752191 | 0.565791 | 1.000000 | 0.752191 |
| fux_first_species_examples-2-v1 | 11 | `fourth_species` | 0.994373 | 0.988777 | 1.000000 | 0.994373 |
| fux_first_species_examples-2-v1 | 11 | `fifth_species` | 0.751158 | 0.564239 | 1.000000 | 0.751158 |
| fux_first_species_examples-2-v1 | 11 | `first_three_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| fux_first_species_examples-3-v0 | 10 | `first_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| fux_first_species_examples-3-v0 | 10 | `second_species` | 0.753859 | 0.568304 | 1.000000 | 0.753859 |
| fux_first_species_examples-3-v0 | 10 | `third_species` | 0.753859 | 0.568304 | 1.000000 | 0.753859 |
| fux_first_species_examples-3-v0 | 10 | `third_species_triple_meter` | 0.753859 | 0.568304 | 1.000000 | 0.753859 |
| fux_first_species_examples-3-v0 | 10 | `fourth_species` | 0.994373 | 0.988777 | 1.000000 | 0.994373 |
| fux_first_species_examples-3-v0 | 10 | `fifth_species` | 0.752191 | 0.565791 | 1.000000 | 0.752191 |
| fux_first_species_examples-3-v0 | 10 | `first_three_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| fux_first_species_examples-3-v1 | 10 | `first_species` | 1.000000 | 1.000000 | 1.000000 | 1.000000 |
| fux_first_species_examples-3-v1 | 10 | `second_species` | 0.761267 | 0.579527 | 1.000000 | 0.761267 |
| fux_first_species_examples-3-v1 | 10 | `third_species` | 0.761267 | 0.579527 | 1.000000 | 0.761267 |
| fux_first_species_examples-3-v1 | 10 | `third_species_triple_meter` | 0.761267 | 0.579527 | 1.000000 | 0.761267 |
| fux_first_species_examples-3-v1 | 10 | `fourth_species` | 1.000000 | 1.000000 | 1.000000 | 1.000000 |
| fux_first_species_examples-3-v1 | 10 | `fifth_species` | 0.759615 | 0.577014 | 1.000000 | 0.759615 |
| fux_first_species_examples-3-v1 | 10 | `first_three_species` | 1.000000 | 1.000000 | 1.000000 | 1.000000 |
| fux_first_species_examples-4-v0 | 10 | `first_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| fux_first_species_examples-4-v0 | 10 | `second_species` | 0.753859 | 0.568304 | 1.000000 | 0.753859 |
| fux_first_species_examples-4-v0 | 10 | `third_species` | 0.753859 | 0.568304 | 1.000000 | 0.753859 |
| fux_first_species_examples-4-v0 | 10 | `third_species_triple_meter` | 0.753859 | 0.568304 | 1.000000 | 0.753859 |
| fux_first_species_examples-4-v0 | 10 | `fourth_species` | 0.994373 | 0.988777 | 1.000000 | 0.994373 |
| fux_first_species_examples-4-v0 | 10 | `fifth_species` | 0.752191 | 0.565791 | 1.000000 | 0.752191 |
| fux_first_species_examples-4-v0 | 10 | `first_three_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| fux_first_species_examples-4-v1 | 10 | `first_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| fux_first_species_examples-4-v1 | 10 | `second_species` | 0.746379 | 0.557081 | 1.000000 | 0.746379 |
| fux_first_species_examples-4-v1 | 10 | `third_species` | 0.746379 | 0.557081 | 1.000000 | 0.746379 |
| fux_first_species_examples-4-v1 | 10 | `third_species_triple_meter` | 0.746379 | 0.557081 | 1.000000 | 0.746379 |
| fux_first_species_examples-4-v1 | 10 | `fourth_species` | 0.988713 | 0.977554 | 1.000000 | 0.988713 |
| fux_first_species_examples-4-v1 | 10 | `fifth_species` | 0.744694 | 0.554568 | 1.000000 | 0.744694 |
| fux_first_species_examples-4-v1 | 10 | `first_three_species` | 0.986647 | 0.973473 | 1.000000 | 0.986647 |
| fux_first_species_examples-5-v0 | 10 | `first_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| fux_first_species_examples-5-v0 | 10 | `second_species` | 0.753859 | 0.568304 | 1.000000 | 0.753859 |
| fux_first_species_examples-5-v0 | 10 | `third_species` | 0.753859 | 0.568304 | 1.000000 | 0.753859 |
| fux_first_species_examples-5-v0 | 10 | `third_species_triple_meter` | 0.753859 | 0.568304 | 1.000000 | 0.753859 |
| fux_first_species_examples-5-v0 | 10 | `fourth_species` | 0.994373 | 0.988777 | 1.000000 | 0.994373 |
| fux_first_species_examples-5-v0 | 10 | `fifth_species` | 0.752191 | 0.565791 | 1.000000 | 0.752191 |
| fux_first_species_examples-5-v0 | 10 | `first_three_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| fux_first_species_examples-5-v1 | 10 | `first_species` | 1.000000 | 1.000000 | 1.000000 | 1.000000 |
| fux_first_species_examples-5-v1 | 10 | `second_species` | 0.749245 | 0.561368 | 1.000000 | 0.749245 |
| fux_first_species_examples-5-v1 | 10 | `third_species` | 0.749245 | 0.561368 | 1.000000 | 0.749245 |
| fux_first_species_examples-5-v1 | 10 | `third_species_triple_meter` | 0.749245 | 0.561368 | 1.000000 | 0.749245 |
| fux_first_species_examples-5-v1 | 10 | `fourth_species` | 0.990879 | 0.981841 | 1.000000 | 0.990879 |
| fux_first_species_examples-5-v1 | 10 | `fifth_species` | 0.747566 | 0.558855 | 1.000000 | 0.747566 |
| fux_first_species_examples-5-v1 | 10 | `first_three_species` | 0.989211 | 0.978539 | 1.000000 | 0.989211 |
| fux_first_species_examples-6-v0 | 12 | `first_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| fux_first_species_examples-6-v0 | 12 | `second_species` | 0.751158 | 0.564239 | 1.000000 | 0.751158 |
| fux_first_species_examples-6-v0 | 12 | `third_species` | 0.751158 | 0.564239 | 1.000000 | 0.751158 |
| fux_first_species_examples-6-v0 | 12 | `third_species_triple_meter` | 0.751158 | 0.564239 | 1.000000 | 0.751158 |
| fux_first_species_examples-6-v0 | 12 | `fourth_species` | 0.994373 | 0.988777 | 1.000000 | 0.994373 |
| fux_first_species_examples-6-v0 | 12 | `fifth_species` | 0.750519 | 0.563279 | 1.000000 | 0.750519 |
| fux_first_species_examples-6-v0 | 12 | `first_three_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| fux_first_species_examples-6-v1 | 12 | `first_species` | 1.000000 | 1.000000 | 1.000000 | 1.000000 |
| fux_first_species_examples-6-v1 | 12 | `second_species` | 0.751158 | 0.564239 | 1.000000 | 0.751158 |
| fux_first_species_examples-6-v1 | 12 | `third_species` | 0.751158 | 0.564239 | 1.000000 | 0.751158 |
| fux_first_species_examples-6-v1 | 12 | `third_species_triple_meter` | 0.751158 | 0.564239 | 1.000000 | 0.751158 |
| fux_first_species_examples-6-v1 | 12 | `fourth_species` | 0.994373 | 0.988777 | 1.000000 | 0.994373 |
| fux_first_species_examples-6-v1 | 12 | `fifth_species` | 0.750519 | 0.563279 | 1.000000 | 0.750519 |
| fux_first_species_examples-6-v1 | 12 | `first_three_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| fux_first_species_examples-7-v0 | 12 | `first_species` | 0.965963 | 0.986737 | 0.945627 | 0.965963 |
| fux_first_species_examples-7-v0 | 12 | `second_species` | 0.735683 | 0.564239 | 0.959220 | 0.735683 |
| fux_first_species_examples-7-v0 | 12 | `third_species` | 0.735683 | 0.564239 | 0.959220 | 0.735683 |
| fux_first_species_examples-7-v0 | 12 | `third_species_triple_meter` | 0.735683 | 0.564239 | 0.959220 | 0.735683 |
| fux_first_species_examples-7-v0 | 12 | `fourth_species` | 0.973887 | 0.988777 | 0.959220 | 0.973887 |
| fux_first_species_examples-7-v0 | 12 | `fifth_species` | 0.736791 | 0.563279 | 0.963751 | 0.736791 |
| fux_first_species_examples-7-v0 | 12 | `first_three_species` | 0.972881 | 0.986737 | 0.959220 | 0.972881 |
| fux_first_species_examples-7-v1 | 12 | `first_species` | 0.944063 | 1.000000 | 0.891254 | 0.944063 |
| fux_first_species_examples-7-v1 | 12 | `second_species` | 0.726999 | 0.575462 | 0.918441 | 0.726999 |
| fux_first_species_examples-7-v1 | 12 | `third_species` | 0.726999 | 0.575462 | 0.918441 | 0.726999 |
| fux_first_species_examples-7-v1 | 12 | `third_species_triple_meter` | 0.726999 | 0.575462 | 0.918441 | 0.726999 |
| fux_first_species_examples-7-v1 | 12 | `fourth_species` | 0.958353 | 1.000000 | 0.918441 | 0.958353 |
| fux_first_species_examples-7-v1 | 12 | `fifth_species` | 0.729967 | 0.574502 | 0.927503 | 0.729967 |
| fux_first_species_examples-7-v1 | 12 | `first_three_species` | 0.958353 | 1.000000 | 0.918441 | 0.958353 |
| fux_first_species_examples-8-v0 | 14 | `first_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| fux_first_species_examples-8-v0 | 14 | `second_species` | 0.750124 | 0.562686 | 1.000000 | 0.750124 |
| fux_first_species_examples-8-v0 | 14 | `third_species` | 0.750124 | 0.562686 | 1.000000 | 0.750124 |
| fux_first_species_examples-8-v0 | 14 | `third_species_triple_meter` | 0.750124 | 0.562686 | 1.000000 | 0.750124 |
| fux_first_species_examples-8-v0 | 14 | `fourth_species` | 0.994373 | 0.988777 | 1.000000 | 0.994373 |
| fux_first_species_examples-8-v0 | 14 | `fifth_species` | 0.749879 | 0.562319 | 1.000000 | 0.749879 |
| fux_first_species_examples-8-v0 | 14 | `first_three_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| fux_first_species_examples-8-v1 | 14 | `first_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| fux_first_species_examples-8-v1 | 14 | `second_species` | 0.737921 | 0.544527 | 1.000000 | 0.737921 |
| fux_first_species_examples-8-v1 | 14 | `third_species` | 0.737921 | 0.544527 | 1.000000 | 0.737921 |
| fux_first_species_examples-8-v1 | 14 | `third_species_triple_meter` | 0.737921 | 0.544527 | 1.000000 | 0.737921 |
| fux_first_species_examples-8-v1 | 14 | `fourth_species` | 0.985199 | 0.970618 | 1.000000 | 0.985199 |
| fux_first_species_examples-8-v1 | 14 | `fifth_species` | 0.737672 | 0.544160 | 1.000000 | 0.737672 |
| fux_first_species_examples-8-v1 | 14 | `first_three_species` | 0.982485 | 0.965276 | 1.000000 | 0.982485 |
| fux_first_species_examples-9-v0 | 14 | `first_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| fux_first_species_examples-9-v0 | 14 | `second_species` | 0.750124 | 0.562686 | 1.000000 | 0.750124 |
| fux_first_species_examples-9-v0 | 14 | `third_species` | 0.750124 | 0.562686 | 1.000000 | 0.750124 |
| fux_first_species_examples-9-v0 | 14 | `third_species_triple_meter` | 0.750124 | 0.562686 | 1.000000 | 0.750124 |
| fux_first_species_examples-9-v0 | 14 | `fourth_species` | 0.994373 | 0.988777 | 1.000000 | 0.994373 |
| fux_first_species_examples-9-v0 | 14 | `fifth_species` | 0.749879 | 0.562319 | 1.000000 | 0.749879 |
| fux_first_species_examples-9-v0 | 14 | `first_three_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| fux_first_species_examples-9-v1 | 14 | `first_species` | 1.000000 | 1.000000 | 1.000000 | 1.000000 |
| fux_first_species_examples-9-v1 | 14 | `second_species` | 0.745486 | 0.555750 | 1.000000 | 0.745486 |
| fux_first_species_examples-9-v1 | 14 | `third_species` | 0.745486 | 0.555750 | 1.000000 | 0.745486 |
| fux_first_species_examples-9-v1 | 14 | `third_species_triple_meter` | 0.745486 | 0.555750 | 1.000000 | 0.745486 |
| fux_first_species_examples-9-v1 | 14 | `fourth_species` | 0.990879 | 0.981841 | 1.000000 | 0.990879 |
| fux_first_species_examples-9-v1 | 14 | `fifth_species` | 0.745240 | 0.555383 | 1.000000 | 0.745240 |
| fux_first_species_examples-9-v1 | 14 | `first_three_species` | 0.989211 | 0.978539 | 1.000000 | 0.989211 |
| fux_first_species_examples-10-v0 | 14 | `first_species` | 0.986647 | 0.973473 | 1.000000 | 0.986647 |
| fux_first_species_examples-10-v0 | 14 | `second_species` | 0.742605 | 0.551463 | 1.000000 | 0.742605 |
| fux_first_species_examples-10-v0 | 14 | `third_species` | 0.742605 | 0.551463 | 1.000000 | 0.742605 |
| fux_first_species_examples-10-v0 | 14 | `third_species_triple_meter` | 0.742605 | 0.551463 | 1.000000 | 0.742605 |
| fux_first_species_examples-10-v0 | 14 | `fourth_species` | 0.988713 | 0.977554 | 1.000000 | 0.988713 |
| fux_first_species_examples-10-v0 | 14 | `fifth_species` | 0.742359 | 0.551096 | 1.000000 | 0.742359 |
| fux_first_species_examples-10-v0 | 14 | `first_three_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| fux_first_species_examples-10-v1 | 14 | `first_species` | 0.987767 | 1.000000 | 0.975684 | 0.987767 |
| fux_first_species_examples-10-v1 | 14 | `second_species` | 0.743252 | 0.562686 | 0.981763 | 0.743252 |
| fux_first_species_examples-10-v1 | 14 | `third_species` | 0.743252 | 0.562686 | 0.981763 | 0.743252 |
| fux_first_species_examples-10-v1 | 14 | `third_species_triple_meter` | 0.743252 | 0.562686 | 0.981763 | 0.743252 |
| fux_first_species_examples-10-v1 | 14 | `fourth_species` | 0.985264 | 0.988777 | 0.981763 | 0.985264 |
| fux_first_species_examples-10-v1 | 14 | `fifth_species` | 0.743777 | 0.562319 | 0.983789 | 0.743777 |
| fux_first_species_examples-10-v1 | 14 | `first_three_species` | 0.984247 | 0.986737 | 0.981763 | 0.984247 |
| fux_first_species_examples-11-v0 | 12 | `first_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| fux_first_species_examples-11-v0 | 12 | `second_species` | 0.751158 | 0.564239 | 1.000000 | 0.751158 |
| fux_first_species_examples-11-v0 | 12 | `third_species` | 0.751158 | 0.564239 | 1.000000 | 0.751158 |
| fux_first_species_examples-11-v0 | 12 | `third_species_triple_meter` | 0.751158 | 0.564239 | 1.000000 | 0.751158 |
| fux_first_species_examples-11-v0 | 12 | `fourth_species` | 0.994373 | 0.988777 | 1.000000 | 0.994373 |
| fux_first_species_examples-11-v0 | 12 | `fifth_species` | 0.750519 | 0.563279 | 1.000000 | 0.750519 |
| fux_first_species_examples-11-v0 | 12 | `first_three_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| fux_first_species_examples-11-v1 | 12 | `first_species` | 1.000000 | 1.000000 | 1.000000 | 1.000000 |
| fux_first_species_examples-11-v1 | 12 | `second_species` | 0.751158 | 0.564239 | 1.000000 | 0.751158 |
| fux_first_species_examples-11-v1 | 12 | `third_species` | 0.751158 | 0.564239 | 1.000000 | 0.751158 |
| fux_first_species_examples-11-v1 | 12 | `third_species_triple_meter` | 0.751158 | 0.564239 | 1.000000 | 0.751158 |
| fux_first_species_examples-11-v1 | 12 | `fourth_species` | 0.994373 | 0.988777 | 1.000000 | 0.994373 |
| fux_first_species_examples-11-v1 | 12 | `fifth_species` | 0.750519 | 0.563279 | 1.000000 | 0.750519 |
| fux_first_species_examples-11-v1 | 12 | `first_three_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| fux_first_species_examples-12-v0 | 12 | `first_species` | 0.986647 | 0.973473 | 1.000000 | 0.986647 |
| fux_first_species_examples-12-v0 | 12 | `second_species` | 0.743650 | 0.553016 | 1.000000 | 0.743650 |
| fux_first_species_examples-12-v0 | 12 | `third_species` | 0.743650 | 0.553016 | 1.000000 | 0.743650 |
| fux_first_species_examples-12-v0 | 12 | `third_species_triple_meter` | 0.743650 | 0.553016 | 1.000000 | 0.743650 |
| fux_first_species_examples-12-v0 | 12 | `fourth_species` | 0.988713 | 0.977554 | 1.000000 | 0.988713 |
| fux_first_species_examples-12-v0 | 12 | `fifth_species` | 0.743005 | 0.552056 | 1.000000 | 0.743005 |
| fux_first_species_examples-12-v0 | 12 | `first_three_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| fux_first_species_examples-12-v1 | 12 | `first_species` | 1.000000 | 1.000000 | 1.000000 | 1.000000 |
| fux_first_species_examples-12-v1 | 12 | `second_species` | 0.746527 | 0.557302 | 1.000000 | 0.746527 |
| fux_first_species_examples-12-v1 | 12 | `third_species` | 0.746527 | 0.557302 | 1.000000 | 0.746527 |
| fux_first_species_examples-12-v1 | 12 | `third_species_triple_meter` | 0.746527 | 0.557302 | 1.000000 | 0.746527 |
| fux_first_species_examples-12-v1 | 12 | `fourth_species` | 0.990879 | 0.981841 | 1.000000 | 0.990879 |
| fux_first_species_examples-12-v1 | 12 | `fifth_species` | 0.745884 | 0.556343 | 1.000000 | 0.745884 |
| fux_first_species_examples-12-v1 | 12 | `first_three_species` | 0.989211 | 0.978539 | 1.000000 | 0.989211 |
| clendinning_first_species_examples-0-v0 | 12 | `first_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| clendinning_first_species_examples-0-v0 | 12 | `second_species` | 0.751158 | 0.564239 | 1.000000 | 0.751158 |
| clendinning_first_species_examples-0-v0 | 12 | `third_species` | 0.751158 | 0.564239 | 1.000000 | 0.751158 |
| clendinning_first_species_examples-0-v0 | 12 | `third_species_triple_meter` | 0.751158 | 0.564239 | 1.000000 | 0.751158 |
| clendinning_first_species_examples-0-v0 | 12 | `fourth_species` | 0.994373 | 0.988777 | 1.000000 | 0.994373 |
| clendinning_first_species_examples-0-v0 | 12 | `fifth_species` | 0.750519 | 0.563279 | 1.000000 | 0.750519 |
| clendinning_first_species_examples-0-v0 | 12 | `first_three_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| clendinning_first_species_examples-0-v1 | 12 | `first_species` | 1.000000 | 1.000000 | 1.000000 | 1.000000 |
| clendinning_first_species_examples-0-v1 | 12 | `second_species` | 0.758592 | 0.575462 | 1.000000 | 0.758592 |
| clendinning_first_species_examples-0-v1 | 12 | `third_species` | 0.758592 | 0.575462 | 1.000000 | 0.758592 |
| clendinning_first_species_examples-0-v1 | 12 | `third_species_triple_meter` | 0.758592 | 0.575462 | 1.000000 | 0.758592 |
| clendinning_first_species_examples-0-v1 | 12 | `fourth_species` | 1.000000 | 1.000000 | 1.000000 | 1.000000 |
| clendinning_first_species_examples-0-v1 | 12 | `fifth_species` | 0.757959 | 0.574502 | 1.000000 | 0.757959 |
| clendinning_first_species_examples-0-v1 | 12 | `first_three_species` | 1.000000 | 1.000000 | 1.000000 | 1.000000 |
| clendinning_first_species_examples-1-v0 | 9 | `first_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| clendinning_first_species_examples-1-v0 | 9 | `second_species` | 0.756551 | 0.572369 | 1.000000 | 0.756551 |
| clendinning_first_species_examples-1-v0 | 9 | `third_species` | 0.756551 | 0.572369 | 1.000000 | 0.756551 |
| clendinning_first_species_examples-1-v0 | 9 | `third_species_triple_meter` | 0.756551 | 0.572369 | 1.000000 | 0.756551 |
| clendinning_first_species_examples-1-v0 | 9 | `fourth_species` | 0.994373 | 0.988777 | 1.000000 | 0.994373 |
| clendinning_first_species_examples-1-v0 | 9 | `fifth_species` | 0.753859 | 0.568304 | 1.000000 | 0.753859 |
| clendinning_first_species_examples-1-v0 | 9 | `first_three_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| clendinning_first_species_examples-1-v1 | 9 | `first_species` | 1.000000 | 1.000000 | 1.000000 | 1.000000 |
| clendinning_first_species_examples-1-v1 | 9 | `second_species` | 0.763932 | 0.583592 | 1.000000 | 0.763932 |
| clendinning_first_species_examples-1-v1 | 9 | `third_species` | 0.763932 | 0.583592 | 1.000000 | 0.763932 |
| clendinning_first_species_examples-1-v1 | 9 | `third_species_triple_meter` | 0.763932 | 0.583592 | 1.000000 | 0.763932 |
| clendinning_first_species_examples-1-v1 | 9 | `fourth_species` | 1.000000 | 1.000000 | 1.000000 | 1.000000 |
| clendinning_first_species_examples-1-v1 | 9 | `fifth_species` | 0.761267 | 0.579527 | 1.000000 | 0.761267 |
| clendinning_first_species_examples-1-v1 | 9 | `first_three_species` | 1.000000 | 1.000000 | 1.000000 | 1.000000 |
| clendinning_first_species_examples-2-v0 | 11 | `first_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| clendinning_first_species_examples-2-v0 | 11 | `second_species` | 0.752191 | 0.565791 | 1.000000 | 0.752191 |
| clendinning_first_species_examples-2-v0 | 11 | `third_species` | 0.752191 | 0.565791 | 1.000000 | 0.752191 |
| clendinning_first_species_examples-2-v0 | 11 | `third_species_triple_meter` | 0.752191 | 0.565791 | 1.000000 | 0.752191 |
| clendinning_first_species_examples-2-v0 | 11 | `fourth_species` | 0.994373 | 0.988777 | 1.000000 | 0.994373 |
| clendinning_first_species_examples-2-v0 | 11 | `fifth_species` | 0.751158 | 0.564239 | 1.000000 | 0.751158 |
| clendinning_first_species_examples-2-v0 | 11 | `first_three_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| clendinning_first_species_examples-2-v1 | 11 | `first_species` | 1.000000 | 1.000000 | 1.000000 | 1.000000 |
| clendinning_first_species_examples-2-v1 | 11 | `second_species` | 0.752191 | 0.565791 | 1.000000 | 0.752191 |
| clendinning_first_species_examples-2-v1 | 11 | `third_species` | 0.752191 | 0.565791 | 1.000000 | 0.752191 |
| clendinning_first_species_examples-2-v1 | 11 | `third_species_triple_meter` | 0.752191 | 0.565791 | 1.000000 | 0.752191 |
| clendinning_first_species_examples-2-v1 | 11 | `fourth_species` | 0.994373 | 0.988777 | 1.000000 | 0.994373 |
| clendinning_first_species_examples-2-v1 | 11 | `fifth_species` | 0.751158 | 0.564239 | 1.000000 | 0.751158 |
| clendinning_first_species_examples-2-v1 | 11 | `first_three_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| davis_and_lybbert_first_species_examples-0-v0 | 10 | `first_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| davis_and_lybbert_first_species_examples-0-v0 | 10 | `second_species` | 0.753859 | 0.568304 | 1.000000 | 0.753859 |
| davis_and_lybbert_first_species_examples-0-v0 | 10 | `third_species` | 0.753859 | 0.568304 | 1.000000 | 0.753859 |
| davis_and_lybbert_first_species_examples-0-v0 | 10 | `third_species_triple_meter` | 0.753859 | 0.568304 | 1.000000 | 0.753859 |
| davis_and_lybbert_first_species_examples-0-v0 | 10 | `fourth_species` | 0.994373 | 0.988777 | 1.000000 | 0.994373 |
| davis_and_lybbert_first_species_examples-0-v0 | 10 | `fifth_species` | 0.752191 | 0.565791 | 1.000000 | 0.752191 |
| davis_and_lybbert_first_species_examples-0-v0 | 10 | `first_three_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| davis_and_lybbert_first_species_examples-0-v1 | 10 | `first_species` | 1.000000 | 1.000000 | 1.000000 | 1.000000 |
| davis_and_lybbert_first_species_examples-0-v1 | 10 | `second_species` | 0.761267 | 0.579527 | 1.000000 | 0.761267 |
| davis_and_lybbert_first_species_examples-0-v1 | 10 | `third_species` | 0.761267 | 0.579527 | 1.000000 | 0.761267 |
| davis_and_lybbert_first_species_examples-0-v1 | 10 | `third_species_triple_meter` | 0.761267 | 0.579527 | 1.000000 | 0.761267 |
| davis_and_lybbert_first_species_examples-0-v1 | 10 | `fourth_species` | 1.000000 | 1.000000 | 1.000000 | 1.000000 |
| davis_and_lybbert_first_species_examples-0-v1 | 10 | `fifth_species` | 0.759615 | 0.577014 | 1.000000 | 0.759615 |
| davis_and_lybbert_first_species_examples-0-v1 | 10 | `first_three_species` | 1.000000 | 1.000000 | 1.000000 | 1.000000 |
| davis_and_lybbert_first_species_examples-1-v0 | 11 | `first_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| davis_and_lybbert_first_species_examples-1-v0 | 11 | `second_species` | 0.752191 | 0.565791 | 1.000000 | 0.752191 |
| davis_and_lybbert_first_species_examples-1-v0 | 11 | `third_species` | 0.752191 | 0.565791 | 1.000000 | 0.752191 |
| davis_and_lybbert_first_species_examples-1-v0 | 11 | `third_species_triple_meter` | 0.752191 | 0.565791 | 1.000000 | 0.752191 |
| davis_and_lybbert_first_species_examples-1-v0 | 11 | `fourth_species` | 0.994373 | 0.988777 | 1.000000 | 0.994373 |
| davis_and_lybbert_first_species_examples-1-v0 | 11 | `fifth_species` | 0.751158 | 0.564239 | 1.000000 | 0.751158 |
| davis_and_lybbert_first_species_examples-1-v0 | 11 | `first_three_species` | 0.993346 | 0.986737 | 1.000000 | 0.993346 |
| davis_and_lybbert_first_species_examples-1-v1 | 11 | `first_species` | 1.000000 | 1.000000 | 1.000000 | 1.000000 |
| davis_and_lybbert_first_species_examples-1-v1 | 11 | `second_species` | 0.759615 | 0.577014 | 1.000000 | 0.759615 |
| davis_and_lybbert_first_species_examples-1-v1 | 11 | `third_species` | 0.759615 | 0.577014 | 1.000000 | 0.759615 |
| davis_and_lybbert_first_species_examples-1-v1 | 11 | `third_species_triple_meter` | 0.759615 | 0.577014 | 1.000000 | 0.759615 |
| davis_and_lybbert_first_species_examples-1-v1 | 11 | `fourth_species` | 1.000000 | 1.000000 | 1.000000 | 1.000000 |
| davis_and_lybbert_first_species_examples-1-v1 | 11 | `fifth_species` | 0.758592 | 0.575462 | 1.000000 | 0.758592 |
| davis_and_lybbert_first_species_examples-1-v1 | 11 | `first_three_species` | 1.000000 | 1.000000 | 1.000000 | 1.000000 |

The remaining 728 composite rows are unassessable single-voice compositions: the harmony member has no companion to be set against, so the composite grades on its members' gate factors and reads 0.000.

A gate both members declare is assessed by each of them, so it appears twice in the raw capture. Deduplicated here rather than in the model, where the flat concatenation is what lets a consumer walk members and composite alike.

| failed gate | composite rows |
| --- | ---: |
| `MinimumNotes` | 357 |
| `SetAgainstAnotherVoice` | 434 |
