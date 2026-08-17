# Re-tier the Guides — grades before and after

Generated. Do not edit by hand:

```
bundle exec ruby bin/guide_grade_corpus.rb before.json   # at the merge-base
bundle exec ruby bin/guide_grade_corpus.rb after.json    # here
bundle exec ruby bin/guide_grade_table.rb before.json after.json \
  user-stories/current/re-tier-the-guides.grades.md
```

The capture script takes no arguments beyond its output path and asks only 
what both trees can answer, so the two columns are the same measurement made 
twice. **3266 rows** — 142 corpus entries × 23 registry entries. 1944 moved, 1322 unchanged. An asterisk marks an unassessable voice.

| why it moved | rows |
| --- | ---: |
| crash fixed | 126 |
| demoted | 607 |
| gated | 1006 |
| threshold split | 205 |

- **crash fixed** — the harmony guides raised for a voice with no companion.
- **gated** — a precondition now stops the assessment instead of scaling it.
- **gate added** — a guide gained a precondition it did not have; the voice
  clears it, so the grade moves only by the gate's own fitness.
- **threshold split** — a note minimum became a low gate plus a rubric
  prescription. These guides keep flat rubrics; nothing was demoted.
- **demoted** — the species guides weigh what they teach above what they
  inherit.

## Every row that moved

| corpus | notes | guide | before | after | delta | assessable | why |
| --- | ---: | --- | ---: | ---: | ---: | --- | --- |
| solo-ascending-0 | 0 | `first_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| solo-ascending-0 | 0 | `first_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-0 | 0 | `second_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| solo-ascending-0 | 0 | `second_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-0 | 0 | `third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| solo-ascending-0 | 0 | `third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-0 | 0 | `third_species_triple_meter_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| solo-ascending-0 | 0 | `third_species_triple_meter_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-0 | 0 | `fourth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| solo-ascending-0 | 0 | `fourth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-0 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| solo-ascending-0 | 0 | `combined_first_second_third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-0 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| solo-ascending-0 | 0 | `fifth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-1 | 1 | `fux_cantus_firmus` | 0.125 | 0.333* | +0.208 | no | gated |
| solo-ascending-1 | 1 | `salzer_schachter_cantus_firmus` | 0.125 | 0.333* | +0.208 | no | gated |
| solo-ascending-1 | 1 | `diatonic_melody` | 0.200 | 0.333* | +0.133 | no | gated |
| solo-ascending-1 | 1 | `first_species_melody` | 1.000 | 0.333* | -0.667 | no | gated |
| solo-ascending-1 | 1 | `first_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-1 | 1 | `second_species_melody` | 0.978 | 0.333* | -0.644 | no | gated |
| solo-ascending-1 | 1 | `second_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-1 | 1 | `third_species_melody` | 0.978 | 0.333* | -0.644 | no | gated |
| solo-ascending-1 | 1 | `third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-1 | 1 | `third_species_triple_meter_melody` | 0.978 | 0.333* | -0.644 | no | gated |
| solo-ascending-1 | 1 | `third_species_triple_meter_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-1 | 1 | `fourth_species_melody` | 1.000 | 0.333* | -0.667 | no | gated |
| solo-ascending-1 | 1 | `fourth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-1 | 1 | `combined_first_second_third_species_melody` | 1.000 | 0.333* | -0.667 | no | gated |
| solo-ascending-1 | 1 | `combined_first_second_third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-1 | 1 | `fifth_species_melody` | 1.000 | 0.333* | -0.667 | no | gated |
| solo-ascending-1 | 1 | `fifth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-1 | 1 | `static_contour_melody` | 0.200 | 0.333* | +0.133 | no | gated |
| solo-ascending-2 | 2 | `fux_cantus_firmus` | 0.230 | 0.667* | +0.437 | no | gated |
| solo-ascending-2 | 2 | `salzer_schachter_cantus_firmus` | 0.235 | 0.667* | +0.432 | no | gated |
| solo-ascending-2 | 2 | `diatonic_melody` | 0.391 | 0.667* | +0.275 | no | gated |
| solo-ascending-2 | 2 | `first_species_melody` | 0.935 | 0.667* | -0.268 | no | gated |
| solo-ascending-2 | 2 | `first_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-2 | 2 | `second_species_melody` | 0.920 | 0.667* | -0.253 | no | gated |
| solo-ascending-2 | 2 | `second_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-2 | 2 | `third_species_melody` | 0.920 | 0.667* | -0.253 | no | gated |
| solo-ascending-2 | 2 | `third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-2 | 2 | `third_species_triple_meter_melody` | 0.920 | 0.667* | -0.253 | no | gated |
| solo-ascending-2 | 2 | `third_species_triple_meter_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-2 | 2 | `fourth_species_melody` | 0.939 | 0.667* | -0.272 | no | gated |
| solo-ascending-2 | 2 | `fourth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-2 | 2 | `combined_first_second_third_species_melody` | 0.930 | 0.667* | -0.263 | no | gated |
| solo-ascending-2 | 2 | `combined_first_second_third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-2 | 2 | `fifth_species_melody` | 0.898 | 0.667* | -0.231 | no | gated |
| solo-ascending-2 | 2 | `fifth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-2 | 2 | `arch_contour_melody` | 0.122 | 0.333* | +0.211 | no | gated |
| solo-ascending-2 | 2 | `ascending_contour_melody` | 0.397 | 0.667* | +0.270 | no | gated |
| solo-ascending-2 | 2 | `descending_contour_melody` | 0.244 | 0.667* | +0.423 | no | gated |
| solo-ascending-2 | 2 | `static_contour_melody` | 0.244 | 0.667* | +0.423 | no | gated |
| solo-ascending-2 | 2 | `valley_contour_melody` | 0.122 | 0.333* | +0.211 | no | gated |
| solo-ascending-2 | 2 | `wave_contour_melody` | 0.122 | 0.333* | +0.211 | no | gated |
| solo-ascending-3 | 3 | `fux_cantus_firmus` | 0.365 | 0.937 | +0.572 | yes | threshold split |
| solo-ascending-3 | 3 | `salzer_schachter_cantus_firmus` | 0.366 | 0.941 | +0.575 | yes | threshold split |
| solo-ascending-3 | 3 | `diatonic_melody` | 0.600 | 0.964 | +0.364 | yes | threshold split |
| solo-ascending-3 | 3 | `first_species_melody` | 0.949 | 0.978 | +0.028 | yes | demoted |
| solo-ascending-3 | 3 | `first_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-3 | 3 | `second_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| solo-ascending-3 | 3 | `second_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-3 | 3 | `third_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| solo-ascending-3 | 3 | `third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-3 | 3 | `third_species_triple_meter_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| solo-ascending-3 | 3 | `third_species_triple_meter_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-3 | 3 | `fourth_species_melody` | 0.952 | 0.981 | +0.028 | yes | demoted |
| solo-ascending-3 | 3 | `fourth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-3 | 3 | `combined_first_second_third_species_melody` | 0.945 | 0.978 | +0.032 | yes | demoted |
| solo-ascending-3 | 3 | `combined_first_second_third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-3 | 3 | `fifth_species_melody` | 0.896 | 0.672 | -0.225 | yes | demoted |
| solo-ascending-3 | 3 | `fifth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-3 | 3 | `arch_contour_melody` | 0.600 | 0.986 | +0.386 | yes | threshold split |
| solo-ascending-3 | 3 | `ascending_contour_melody` | 0.371 | 0.604 | +0.233 | yes | threshold split |
| solo-ascending-3 | 3 | `descending_contour_melody` | 0.371 | 0.604 | +0.233 | yes | threshold split |
| solo-ascending-3 | 3 | `static_contour_melody` | 0.600 | 0.986 | +0.386 | yes | threshold split |
| solo-ascending-3 | 3 | `valley_contour_melody` | 0.371 | 0.604 | +0.233 | yes | threshold split |
| solo-ascending-3 | 3 | `wave_contour_melody` | 0.371 | 0.604 | +0.233 | yes | threshold split |
| solo-ascending-4 | 4 | `fux_cantus_firmus` | 0.454 | 0.882 | +0.428 | yes | threshold split |
| solo-ascending-4 | 4 | `salzer_schachter_cantus_firmus` | 0.464 | 0.903 | +0.439 | yes | threshold split |
| solo-ascending-4 | 4 | `diatonic_melody` | 0.769 | 0.947 | +0.178 | yes | threshold split |
| solo-ascending-4 | 4 | `first_species_melody` | 0.924 | 0.966 | +0.043 | yes | demoted |
| solo-ascending-4 | 4 | `first_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-4 | 4 | `second_species_melody` | 0.910 | 0.853 | -0.057 | yes | demoted |
| solo-ascending-4 | 4 | `second_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-4 | 4 | `third_species_melody` | 0.910 | 0.853 | -0.057 | yes | demoted |
| solo-ascending-4 | 4 | `third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-4 | 4 | `third_species_triple_meter_melody` | 0.910 | 0.853 | -0.057 | yes | demoted |
| solo-ascending-4 | 4 | `third_species_triple_meter_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-4 | 4 | `fourth_species_melody` | 0.928 | 0.971 | +0.042 | yes | demoted |
| solo-ascending-4 | 4 | `fourth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-4 | 4 | `combined_first_second_third_species_melody` | 0.918 | 0.966 | +0.048 | yes | demoted |
| solo-ascending-4 | 4 | `combined_first_second_third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-4 | 4 | `fifth_species_melody` | 0.865 | 0.617 | -0.248 | yes | demoted |
| solo-ascending-4 | 4 | `fifth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-4 | 4 | `arch_contour_melody` | 0.483 | 0.598 | +0.115 | yes | threshold split |
| solo-ascending-4 | 4 | `ascending_contour_melody` | 0.788 | 0.980 | +0.191 | yes | threshold split |
| solo-ascending-4 | 4 | `descending_contour_melody` | 0.483 | 0.598 | +0.115 | yes | threshold split |
| solo-ascending-4 | 4 | `static_contour_melody` | 0.483 | 0.598 | +0.115 | yes | threshold split |
| solo-ascending-4 | 4 | `valley_contour_melody` | 0.483 | 0.598 | +0.115 | yes | threshold split |
| solo-ascending-4 | 4 | `wave_contour_melody` | 0.483 | 0.598 | +0.115 | yes | threshold split |
| solo-ascending-5 | 5 | `fux_cantus_firmus` | 0.609 | 0.953 | +0.344 | yes | threshold split |
| solo-ascending-5 | 5 | `salzer_schachter_cantus_firmus` | 0.610 | 0.955 | +0.345 | yes | threshold split |
| solo-ascending-5 | 5 | `first_species_melody` | 0.949 | 0.978 | +0.028 | yes | demoted |
| solo-ascending-5 | 5 | `first_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-5 | 5 | `second_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| solo-ascending-5 | 5 | `second_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-5 | 5 | `third_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| solo-ascending-5 | 5 | `third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-5 | 5 | `third_species_triple_meter_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| solo-ascending-5 | 5 | `third_species_triple_meter_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-5 | 5 | `fourth_species_melody` | 0.952 | 0.981 | +0.028 | yes | demoted |
| solo-ascending-5 | 5 | `fourth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-5 | 5 | `combined_first_second_third_species_melody` | 0.945 | 0.978 | +0.032 | yes | demoted |
| solo-ascending-5 | 5 | `combined_first_second_third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-5 | 5 | `fifth_species_melody` | 0.882 | 0.599 | -0.284 | yes | demoted |
| solo-ascending-5 | 5 | `fifth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-6 | 6 | `fux_cantus_firmus` | 0.700 | 0.922 | +0.222 | yes | threshold split |
| solo-ascending-6 | 6 | `salzer_schachter_cantus_firmus` | 0.714 | 0.940 | +0.226 | yes | threshold split |
| solo-ascending-6 | 6 | `first_species_melody` | 0.949 | 0.978 | +0.028 | yes | demoted |
| solo-ascending-6 | 6 | `first_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-6 | 6 | `second_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| solo-ascending-6 | 6 | `second_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-6 | 6 | `third_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| solo-ascending-6 | 6 | `third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-6 | 6 | `third_species_triple_meter_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| solo-ascending-6 | 6 | `third_species_triple_meter_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-6 | 6 | `fourth_species_melody` | 0.952 | 0.981 | +0.028 | yes | demoted |
| solo-ascending-6 | 6 | `fourth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-6 | 6 | `combined_first_second_third_species_melody` | 0.945 | 0.978 | +0.032 | yes | demoted |
| solo-ascending-6 | 6 | `combined_first_second_third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-6 | 6 | `fifth_species_melody` | 0.879 | 0.581 | -0.298 | yes | demoted |
| solo-ascending-6 | 6 | `fifth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-7 | 7 | `fux_cantus_firmus` | 0.853 | 0.968 | +0.116 | yes | threshold split |
| solo-ascending-7 | 7 | `salzer_schachter_cantus_firmus` | 0.854 | 0.970 | +0.116 | yes | threshold split |
| solo-ascending-7 | 7 | `first_species_melody` | 0.949 | 0.978 | +0.028 | yes | demoted |
| solo-ascending-7 | 7 | `first_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-7 | 7 | `second_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| solo-ascending-7 | 7 | `second_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-7 | 7 | `third_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| solo-ascending-7 | 7 | `third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-7 | 7 | `third_species_triple_meter_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| solo-ascending-7 | 7 | `third_species_triple_meter_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-7 | 7 | `fourth_species_melody` | 0.952 | 0.981 | +0.028 | yes | demoted |
| solo-ascending-7 | 7 | `fourth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-7 | 7 | `combined_first_second_third_species_melody` | 0.945 | 0.978 | +0.032 | yes | demoted |
| solo-ascending-7 | 7 | `combined_first_second_third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-7 | 7 | `fifth_species_melody` | 0.877 | 0.571 | -0.306 | yes | demoted |
| solo-ascending-7 | 7 | `fifth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-8 | 8 | `fux_cantus_firmus` | 0.975 | 0.976 | +0.002 | yes | threshold split |
| solo-ascending-8 | 8 | `salzer_schachter_cantus_firmus` | 0.976 | 0.978 | +0.001 | yes | threshold split |
| solo-ascending-8 | 8 | `first_species_melody` | 0.949 | 0.978 | +0.028 | yes | demoted |
| solo-ascending-8 | 8 | `first_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-8 | 8 | `second_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| solo-ascending-8 | 8 | `second_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-8 | 8 | `third_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| solo-ascending-8 | 8 | `third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-8 | 8 | `third_species_triple_meter_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| solo-ascending-8 | 8 | `third_species_triple_meter_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-8 | 8 | `fourth_species_melody` | 0.952 | 0.981 | +0.028 | yes | demoted |
| solo-ascending-8 | 8 | `fourth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-8 | 8 | `combined_first_second_third_species_melody` | 0.945 | 0.978 | +0.032 | yes | demoted |
| solo-ascending-8 | 8 | `combined_first_second_third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-ascending-8 | 8 | `fifth_species_melody` | 0.876 | 0.564 | -0.312 | yes | demoted |
| solo-ascending-8 | 8 | `fifth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-0 | 0 | `first_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| solo-repeated-0 | 0 | `first_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-0 | 0 | `second_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| solo-repeated-0 | 0 | `second_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-0 | 0 | `third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| solo-repeated-0 | 0 | `third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-0 | 0 | `third_species_triple_meter_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| solo-repeated-0 | 0 | `third_species_triple_meter_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-0 | 0 | `fourth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| solo-repeated-0 | 0 | `fourth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-0 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| solo-repeated-0 | 0 | `combined_first_second_third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-0 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| solo-repeated-0 | 0 | `fifth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-1 | 1 | `fux_cantus_firmus` | 0.115 | 0.333* | +0.218 | no | gated |
| solo-repeated-1 | 1 | `salzer_schachter_cantus_firmus` | 0.116 | 0.333* | +0.217 | no | gated |
| solo-repeated-1 | 1 | `diatonic_melody` | 0.192 | 0.333* | +0.141 | no | gated |
| solo-repeated-1 | 1 | `first_species_melody` | 0.924 | 0.333* | -0.590 | no | gated |
| solo-repeated-1 | 1 | `first_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-1 | 1 | `second_species_melody` | 0.910 | 0.333* | -0.577 | no | gated |
| solo-repeated-1 | 1 | `second_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-1 | 1 | `third_species_melody` | 0.910 | 0.333* | -0.577 | no | gated |
| solo-repeated-1 | 1 | `third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-1 | 1 | `third_species_triple_meter_melody` | 0.910 | 0.333* | -0.577 | no | gated |
| solo-repeated-1 | 1 | `third_species_triple_meter_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-1 | 1 | `fourth_species_melody` | 0.928 | 0.333* | -0.595 | no | gated |
| solo-repeated-1 | 1 | `fourth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-1 | 1 | `combined_first_second_third_species_melody` | 0.918 | 0.333* | -0.585 | no | gated |
| solo-repeated-1 | 1 | `combined_first_second_third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-1 | 1 | `fifth_species_melody` | 0.933 | 0.333* | -0.599 | no | gated |
| solo-repeated-1 | 1 | `fifth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-1 | 1 | `static_contour_melody` | 0.197 | 0.333* | +0.136 | no | gated |
| solo-repeated-2 | 2 | `fux_cantus_firmus` | 0.207 | 0.667* | +0.460 | no | gated |
| solo-repeated-2 | 2 | `salzer_schachter_cantus_firmus` | 0.213 | 0.667* | +0.454 | no | gated |
| solo-repeated-2 | 2 | `diatonic_melody` | 0.367 | 0.667* | +0.300 | no | gated |
| solo-repeated-2 | 2 | `first_species_melody` | 0.852 | 0.667* | -0.186 | no | gated |
| solo-repeated-2 | 2 | `first_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-2 | 2 | `second_species_melody` | 0.825 | 0.667* | -0.158 | no | gated |
| solo-repeated-2 | 2 | `second_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-2 | 2 | `third_species_melody` | 0.825 | 0.667* | -0.158 | no | gated |
| solo-repeated-2 | 2 | `third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-2 | 2 | `third_species_triple_meter_melody` | 0.825 | 0.667* | -0.158 | no | gated |
| solo-repeated-2 | 2 | `third_species_triple_meter_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-2 | 2 | `fourth_species_melody` | 0.838 | 0.667* | -0.171 | no | gated |
| solo-repeated-2 | 2 | `fourth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-2 | 2 | `combined_first_second_third_species_melody` | 0.815 | 0.667* | -0.148 | no | gated |
| solo-repeated-2 | 2 | `combined_first_second_third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-2 | 2 | `fifth_species_melody` | 0.802 | 0.667* | -0.136 | no | gated |
| solo-repeated-2 | 2 | `fifth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-2 | 2 | `static_contour_melody` | 0.387 | 0.667* | +0.279 | no | gated |
| solo-repeated-3 | 3 | `fux_cantus_firmus` | 0.296 | 0.764 | +0.468 | yes | threshold split |
| solo-repeated-3 | 3 | `salzer_schachter_cantus_firmus` | 0.307 | 0.792 | +0.485 | yes | threshold split |
| solo-repeated-3 | 3 | `diatonic_melody` | 0.531 | 0.859 | +0.328 | yes | threshold split |
| solo-repeated-3 | 3 | `first_species_melody` | 0.831 | 0.926 | +0.094 | yes | demoted |
| solo-repeated-3 | 3 | `first_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-3 | 3 | `second_species_melody` | 0.792 | 0.802 | +0.009 | yes | demoted |
| solo-repeated-3 | 3 | `second_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-3 | 3 | `third_species_melody` | 0.792 | 0.802 | +0.009 | yes | demoted |
| solo-repeated-3 | 3 | `third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-3 | 3 | `third_species_triple_meter_melody` | 0.792 | 0.802 | +0.009 | yes | demoted |
| solo-repeated-3 | 3 | `third_species_triple_meter_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-3 | 3 | `fourth_species_melody` | 0.803 | 0.920 | +0.117 | yes | demoted |
| solo-repeated-3 | 3 | `fourth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-3 | 3 | `combined_first_second_third_species_melody` | 0.775 | 0.908 | +0.132 | yes | demoted |
| solo-repeated-3 | 3 | `combined_first_second_third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-3 | 3 | `fifth_species_melody` | 0.756 | 0.611 | -0.145 | yes | demoted |
| solo-repeated-3 | 3 | `fifth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-3 | 3 | `static_contour_melody` | 0.574 | 0.946 | +0.373 | yes | threshold split |
| solo-repeated-4 | 4 | `fux_cantus_firmus` | 0.370 | 0.725 | +0.355 | yes | threshold split |
| solo-repeated-4 | 4 | `salzer_schachter_cantus_firmus` | 0.398 | 0.778 | +0.380 | yes | threshold split |
| solo-repeated-4 | 4 | `diatonic_melody` | 0.691 | 0.857 | +0.167 | yes | threshold split |
| solo-repeated-4 | 4 | `first_species_melody` | 0.791 | 0.908 | +0.117 | yes | demoted |
| solo-repeated-4 | 4 | `first_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-4 | 4 | `second_species_melody` | 0.748 | 0.783 | +0.034 | yes | demoted |
| solo-repeated-4 | 4 | `second_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-4 | 4 | `third_species_melody` | 0.748 | 0.783 | +0.034 | yes | demoted |
| solo-repeated-4 | 4 | `third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-4 | 4 | `third_species_triple_meter_melody` | 0.748 | 0.783 | +0.034 | yes | demoted |
| solo-repeated-4 | 4 | `third_species_triple_meter_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-4 | 4 | `fourth_species_melody` | 0.756 | 0.901 | +0.144 | yes | demoted |
| solo-repeated-4 | 4 | `fourth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-4 | 4 | `combined_first_second_third_species_melody` | 0.722 | 0.886 | +0.164 | yes | demoted |
| solo-repeated-4 | 4 | `combined_first_second_third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-4 | 4 | `fifth_species_melody` | 0.703 | 0.547 | -0.157 | yes | demoted |
| solo-repeated-4 | 4 | `fifth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-4 | 4 | `static_contour_melody` | 0.758 | 0.946 | +0.187 | yes | threshold split |
| solo-repeated-5 | 5 | `fux_cantus_firmus` | 0.448 | 0.710 | +0.263 | yes | threshold split |
| solo-repeated-5 | 5 | `salzer_schachter_cantus_firmus` | 0.487 | 0.770 | +0.283 | yes | threshold split |
| solo-repeated-5 | 5 | `diatonic_melody` | 0.847 | 0.861 | +0.014 | yes | threshold split |
| solo-repeated-5 | 5 | `first_species_melody` | 0.773 | 0.900 | +0.127 | yes | demoted |
| solo-repeated-5 | 5 | `first_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-5 | 5 | `second_species_melody` | 0.727 | 0.774 | +0.046 | yes | demoted |
| solo-repeated-5 | 5 | `second_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-5 | 5 | `third_species_melody` | 0.727 | 0.774 | +0.046 | yes | demoted |
| solo-repeated-5 | 5 | `third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-5 | 5 | `third_species_triple_meter_melody` | 0.727 | 0.774 | +0.046 | yes | demoted |
| solo-repeated-5 | 5 | `third_species_triple_meter_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-5 | 5 | `fourth_species_melody` | 0.734 | 0.892 | +0.158 | yes | demoted |
| solo-repeated-5 | 5 | `fourth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-5 | 5 | `combined_first_second_third_species_melody` | 0.696 | 0.875 | +0.179 | yes | demoted |
| solo-repeated-5 | 5 | `combined_first_second_third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-5 | 5 | `fifth_species_melody` | 0.677 | 0.510 | -0.167 | yes | demoted |
| solo-repeated-5 | 5 | `fifth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-5 | 5 | `static_contour_melody` | 0.942 | 0.947 | +0.005 | yes | threshold split |
| solo-repeated-6 | 6 | `fux_cantus_firmus` | 0.525 | 0.703 | +0.178 | yes | threshold split |
| solo-repeated-6 | 6 | `salzer_schachter_cantus_firmus` | 0.559 | 0.745 | +0.187 | yes | threshold split |
| solo-repeated-6 | 6 | `diatonic_melody` | 0.797 | 0.816 | +0.018 | yes | threshold split |
| solo-repeated-6 | 6 | `first_species_melody` | 0.761 | 0.894 | +0.134 | yes | demoted |
| solo-repeated-6 | 6 | `first_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-6 | 6 | `second_species_melody` | 0.713 | 0.767 | +0.055 | yes | demoted |
| solo-repeated-6 | 6 | `second_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-6 | 6 | `third_species_melody` | 0.713 | 0.767 | +0.055 | yes | demoted |
| solo-repeated-6 | 6 | `third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-6 | 6 | `third_species_triple_meter_melody` | 0.713 | 0.767 | +0.055 | yes | demoted |
| solo-repeated-6 | 6 | `third_species_triple_meter_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-6 | 6 | `fourth_species_melody` | 0.719 | 0.885 | +0.167 | yes | demoted |
| solo-repeated-6 | 6 | `fourth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-6 | 6 | `combined_first_second_third_species_melody` | 0.678 | 0.868 | +0.189 | yes | demoted |
| solo-repeated-6 | 6 | `combined_first_second_third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-6 | 6 | `fifth_species_melody` | 0.659 | 0.486 | -0.173 | yes | demoted |
| solo-repeated-6 | 6 | `fifth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-6 | 6 | `static_contour_melody` | 0.923 | 0.930 | +0.007 | yes | threshold split |
| solo-repeated-7 | 7 | `fux_cantus_firmus` | 0.602 | 0.700 | +0.098 | yes | threshold split |
| solo-repeated-7 | 7 | `salzer_schachter_cantus_firmus` | 0.639 | 0.739 | +0.100 | yes | threshold split |
| solo-repeated-7 | 7 | `diatonic_melody` | 0.778 | 0.798 | +0.020 | yes | threshold split |
| solo-repeated-7 | 7 | `first_species_melody` | 0.751 | 0.890 | +0.139 | yes | demoted |
| solo-repeated-7 | 7 | `first_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-7 | 7 | `second_species_melody` | 0.703 | 0.763 | +0.060 | yes | demoted |
| solo-repeated-7 | 7 | `second_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-7 | 7 | `third_species_melody` | 0.703 | 0.763 | +0.060 | yes | demoted |
| solo-repeated-7 | 7 | `third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-7 | 7 | `third_species_triple_meter_melody` | 0.703 | 0.763 | +0.060 | yes | demoted |
| solo-repeated-7 | 7 | `third_species_triple_meter_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-7 | 7 | `fourth_species_melody` | 0.708 | 0.881 | +0.173 | yes | demoted |
| solo-repeated-7 | 7 | `fourth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-7 | 7 | `combined_first_second_third_species_melody` | 0.666 | 0.863 | +0.197 | yes | demoted |
| solo-repeated-7 | 7 | `combined_first_second_third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-7 | 7 | `fifth_species_melody` | 0.647 | 0.471 | -0.176 | yes | demoted |
| solo-repeated-7 | 7 | `fifth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-7 | 7 | `static_contour_melody` | 0.915 | 0.923 | +0.008 | yes | threshold split |
| solo-repeated-8 | 8 | `fux_cantus_firmus` | 0.680 | 0.700 | +0.020 | yes | threshold split |
| solo-repeated-8 | 8 | `salzer_schachter_cantus_firmus` | 0.721 | 0.737 | +0.016 | yes | threshold split |
| solo-repeated-8 | 8 | `diatonic_melody` | 0.764 | 0.786 | +0.021 | yes | threshold split |
| solo-repeated-8 | 8 | `first_species_melody` | 0.744 | 0.887 | +0.143 | yes | demoted |
| solo-repeated-8 | 8 | `first_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-8 | 8 | `second_species_melody` | 0.695 | 0.760 | +0.065 | yes | demoted |
| solo-repeated-8 | 8 | `second_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-8 | 8 | `third_species_melody` | 0.695 | 0.760 | +0.065 | yes | demoted |
| solo-repeated-8 | 8 | `third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-8 | 8 | `third_species_triple_meter_melody` | 0.695 | 0.760 | +0.065 | yes | demoted |
| solo-repeated-8 | 8 | `third_species_triple_meter_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-8 | 8 | `fourth_species_melody` | 0.700 | 0.878 | +0.178 | yes | demoted |
| solo-repeated-8 | 8 | `fourth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-8 | 8 | `combined_first_second_third_species_melody` | 0.657 | 0.859 | +0.202 | yes | demoted |
| solo-repeated-8 | 8 | `combined_first_second_third_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-8 | 8 | `fifth_species_melody` | 0.638 | 0.461 | -0.177 | yes | demoted |
| solo-repeated-8 | 8 | `fifth_species_harmony` | raised | 0.000* | — | no | crash fixed |
| solo-repeated-8 | 8 | `static_contour_melody` | 0.910 | 0.918 | +0.008 | yes | threshold split |
| against-empty-0 | 0 | `first_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-0 | 0 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-0 | 0 | `second_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-0 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-0 | 0 | `third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-0 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-0 | 0 | `third_species_triple_meter_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-0 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-0 | 0 | `fourth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-0 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-0 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-0 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-0 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-0 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-1 | 1 | `fux_cantus_firmus` | 0.125 | 0.333* | +0.208 | no | gated |
| against-empty-1 | 1 | `salzer_schachter_cantus_firmus` | 0.125 | 0.333* | +0.208 | no | gated |
| against-empty-1 | 1 | `diatonic_melody` | 0.200 | 0.333* | +0.133 | no | gated |
| against-empty-1 | 1 | `first_species_melody` | 1.000 | 0.333* | -0.667 | no | gated |
| against-empty-1 | 1 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-1 | 1 | `second_species_melody` | 0.978 | 0.333* | -0.644 | no | gated |
| against-empty-1 | 1 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-1 | 1 | `third_species_melody` | 0.978 | 0.333* | -0.644 | no | gated |
| against-empty-1 | 1 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-1 | 1 | `third_species_triple_meter_melody` | 0.978 | 0.333* | -0.644 | no | gated |
| against-empty-1 | 1 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-1 | 1 | `fourth_species_melody` | 1.000 | 0.333* | -0.667 | no | gated |
| against-empty-1 | 1 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-1 | 1 | `combined_first_second_third_species_melody` | 1.000 | 0.333* | -0.667 | no | gated |
| against-empty-1 | 1 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-1 | 1 | `fifth_species_melody` | 1.000 | 0.333* | -0.667 | no | gated |
| against-empty-1 | 1 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-1 | 1 | `static_contour_melody` | 0.200 | 0.333* | +0.133 | no | gated |
| against-empty-2 | 2 | `fux_cantus_firmus` | 0.230 | 0.667* | +0.437 | no | gated |
| against-empty-2 | 2 | `salzer_schachter_cantus_firmus` | 0.235 | 0.667* | +0.432 | no | gated |
| against-empty-2 | 2 | `diatonic_melody` | 0.391 | 0.667* | +0.275 | no | gated |
| against-empty-2 | 2 | `first_species_melody` | 0.935 | 0.667* | -0.268 | no | gated |
| against-empty-2 | 2 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-2 | 2 | `second_species_melody` | 0.920 | 0.667* | -0.253 | no | gated |
| against-empty-2 | 2 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-2 | 2 | `third_species_melody` | 0.920 | 0.667* | -0.253 | no | gated |
| against-empty-2 | 2 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-2 | 2 | `third_species_triple_meter_melody` | 0.920 | 0.667* | -0.253 | no | gated |
| against-empty-2 | 2 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-2 | 2 | `fourth_species_melody` | 0.939 | 0.667* | -0.272 | no | gated |
| against-empty-2 | 2 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-2 | 2 | `combined_first_second_third_species_melody` | 0.930 | 0.667* | -0.263 | no | gated |
| against-empty-2 | 2 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-2 | 2 | `fifth_species_melody` | 0.898 | 0.667* | -0.231 | no | gated |
| against-empty-2 | 2 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-2 | 2 | `arch_contour_melody` | 0.122 | 0.333* | +0.211 | no | gated |
| against-empty-2 | 2 | `ascending_contour_melody` | 0.397 | 0.667* | +0.270 | no | gated |
| against-empty-2 | 2 | `descending_contour_melody` | 0.244 | 0.667* | +0.423 | no | gated |
| against-empty-2 | 2 | `static_contour_melody` | 0.244 | 0.667* | +0.423 | no | gated |
| against-empty-2 | 2 | `valley_contour_melody` | 0.122 | 0.333* | +0.211 | no | gated |
| against-empty-2 | 2 | `wave_contour_melody` | 0.122 | 0.333* | +0.211 | no | gated |
| against-empty-4 | 4 | `fux_cantus_firmus` | 0.454 | 0.882 | +0.428 | yes | threshold split |
| against-empty-4 | 4 | `salzer_schachter_cantus_firmus` | 0.464 | 0.903 | +0.439 | yes | threshold split |
| against-empty-4 | 4 | `diatonic_melody` | 0.769 | 0.947 | +0.178 | yes | threshold split |
| against-empty-4 | 4 | `first_species_melody` | 0.924 | 0.966 | +0.043 | yes | demoted |
| against-empty-4 | 4 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-4 | 4 | `second_species_melody` | 0.910 | 0.853 | -0.057 | yes | demoted |
| against-empty-4 | 4 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-4 | 4 | `third_species_melody` | 0.910 | 0.853 | -0.057 | yes | demoted |
| against-empty-4 | 4 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-4 | 4 | `third_species_triple_meter_melody` | 0.910 | 0.853 | -0.057 | yes | demoted |
| against-empty-4 | 4 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-4 | 4 | `fourth_species_melody` | 0.928 | 0.971 | +0.042 | yes | demoted |
| against-empty-4 | 4 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-4 | 4 | `combined_first_second_third_species_melody` | 0.918 | 0.966 | +0.048 | yes | demoted |
| against-empty-4 | 4 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-4 | 4 | `fifth_species_melody` | 0.865 | 0.617 | -0.248 | yes | demoted |
| against-empty-4 | 4 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-4 | 4 | `arch_contour_melody` | 0.483 | 0.598 | +0.115 | yes | threshold split |
| against-empty-4 | 4 | `ascending_contour_melody` | 0.788 | 0.980 | +0.191 | yes | threshold split |
| against-empty-4 | 4 | `descending_contour_melody` | 0.483 | 0.598 | +0.115 | yes | threshold split |
| against-empty-4 | 4 | `static_contour_melody` | 0.483 | 0.598 | +0.115 | yes | threshold split |
| against-empty-4 | 4 | `valley_contour_melody` | 0.483 | 0.598 | +0.115 | yes | threshold split |
| against-empty-4 | 4 | `wave_contour_melody` | 0.483 | 0.598 | +0.115 | yes | threshold split |
| against-empty-8 | 8 | `fux_cantus_firmus` | 0.975 | 0.976 | +0.002 | yes | threshold split |
| against-empty-8 | 8 | `salzer_schachter_cantus_firmus` | 0.976 | 0.978 | +0.001 | yes | threshold split |
| against-empty-8 | 8 | `first_species_melody` | 0.949 | 0.978 | +0.028 | yes | demoted |
| against-empty-8 | 8 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-8 | 8 | `second_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| against-empty-8 | 8 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-8 | 8 | `third_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| against-empty-8 | 8 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-8 | 8 | `third_species_triple_meter_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| against-empty-8 | 8 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-8 | 8 | `fourth_species_melody` | 0.952 | 0.981 | +0.028 | yes | demoted |
| against-empty-8 | 8 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-8 | 8 | `combined_first_second_third_species_melody` | 0.945 | 0.978 | +0.032 | yes | demoted |
| against-empty-8 | 8 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-empty-8 | 8 | `fifth_species_melody` | 0.876 | 0.564 | -0.312 | yes | demoted |
| against-empty-8 | 8 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-cantus-0 | 0 | `first_species_melody` | 0.937 | 0.000* | -0.937 | no | gated |
| against-cantus-0 | 0 | `first_species_harmony` | 0.891 | 0.000* | -0.891 | no | gated |
| against-cantus-0 | 0 | `second_species_melody` | 0.944 | 0.000* | -0.944 | no | gated |
| against-cantus-0 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-cantus-0 | 0 | `third_species_melody` | 0.944 | 0.000* | -0.944 | no | gated |
| against-cantus-0 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-cantus-0 | 0 | `third_species_triple_meter_melody` | 0.944 | 0.000* | -0.944 | no | gated |
| against-cantus-0 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-cantus-0 | 0 | `fourth_species_melody` | 0.939 | 0.000* | -0.939 | no | gated |
| against-cantus-0 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-cantus-0 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| against-cantus-0 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-cantus-0 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| against-cantus-0 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| against-cantus-1 | 1 | `fux_cantus_firmus` | 0.125 | 0.333* | +0.208 | no | gated |
| against-cantus-1 | 1 | `salzer_schachter_cantus_firmus` | 0.125 | 0.333* | +0.208 | no | gated |
| against-cantus-1 | 1 | `diatonic_melody` | 0.200 | 0.333* | +0.133 | no | gated |
| against-cantus-1 | 1 | `first_species_melody` | 0.937 | 0.333* | -0.604 | no | gated |
| against-cantus-1 | 1 | `first_species_harmony` | 0.893 | 0.333* | -0.559 | no | gated |
| against-cantus-1 | 1 | `second_species_melody` | 0.922 | 0.333* | -0.589 | no | gated |
| against-cantus-1 | 1 | `second_species_harmony` | 1.000 | 0.333* | -0.667 | no | gated |
| against-cantus-1 | 1 | `third_species_melody` | 0.922 | 0.333* | -0.589 | no | gated |
| against-cantus-1 | 1 | `third_species_harmony` | 1.000 | 0.333* | -0.667 | no | gated |
| against-cantus-1 | 1 | `third_species_triple_meter_melody` | 0.922 | 0.333* | -0.589 | no | gated |
| against-cantus-1 | 1 | `third_species_triple_meter_harmony` | 1.000 | 0.333* | -0.667 | no | gated |
| against-cantus-1 | 1 | `fourth_species_melody` | 0.940 | 0.333* | -0.606 | no | gated |
| against-cantus-1 | 1 | `fourth_species_harmony` | 1.000 | 0.333* | -0.667 | no | gated |
| against-cantus-1 | 1 | `combined_first_second_third_species_melody` | 1.000 | 0.333* | -0.667 | no | gated |
| against-cantus-1 | 1 | `combined_first_second_third_species_harmony` | 1.000 | 0.333* | -0.667 | no | gated |
| against-cantus-1 | 1 | `fifth_species_melody` | 1.000 | 0.333* | -0.667 | no | gated |
| against-cantus-1 | 1 | `fifth_species_harmony` | 1.000 | 0.333* | -0.667 | no | gated |
| against-cantus-1 | 1 | `static_contour_melody` | 0.200 | 0.333* | +0.133 | no | gated |
| against-cantus-2 | 2 | `fux_cantus_firmus` | 0.230 | 0.667* | +0.437 | no | gated |
| against-cantus-2 | 2 | `salzer_schachter_cantus_firmus` | 0.235 | 0.667* | +0.432 | no | gated |
| against-cantus-2 | 2 | `diatonic_melody` | 0.391 | 0.667* | +0.275 | no | gated |
| against-cantus-2 | 2 | `first_species_melody` | 0.849 | 0.667* | -0.182 | no | gated |
| against-cantus-2 | 2 | `first_species_harmony` | 0.725 | 0.667* | -0.059 | no | gated |
| against-cantus-2 | 2 | `second_species_melody` | 0.842 | 0.667* | -0.175 | no | gated |
| against-cantus-2 | 2 | `second_species_harmony` | 0.847 | 0.667* | -0.181 | no | gated |
| against-cantus-2 | 2 | `third_species_melody` | 0.842 | 0.667* | -0.175 | no | gated |
| against-cantus-2 | 2 | `third_species_harmony` | 0.847 | 0.667* | -0.181 | no | gated |
| against-cantus-2 | 2 | `third_species_triple_meter_melody` | 0.842 | 0.667* | -0.175 | no | gated |
| against-cantus-2 | 2 | `third_species_triple_meter_harmony` | 0.847 | 0.667* | -0.181 | no | gated |
| against-cantus-2 | 2 | `fourth_species_melody` | 0.856 | 0.667* | -0.189 | no | gated |
| against-cantus-2 | 2 | `fourth_species_harmony` | 0.826 | 0.667* | -0.160 | no | gated |
| against-cantus-2 | 2 | `combined_first_second_third_species_melody` | 0.930 | 0.667* | -0.263 | no | gated |
| against-cantus-2 | 2 | `combined_first_second_third_species_harmony` | 0.809 | 0.667* | -0.142 | no | gated |
| against-cantus-2 | 2 | `fifth_species_melody` | 0.875 | 0.667* | -0.208 | no | gated |
| against-cantus-2 | 2 | `fifth_species_harmony` | 0.841 | 0.667* | -0.174 | no | gated |
| against-cantus-2 | 2 | `arch_contour_melody` | 0.122 | 0.333* | +0.211 | no | gated |
| against-cantus-2 | 2 | `ascending_contour_melody` | 0.397 | 0.667* | +0.270 | no | gated |
| against-cantus-2 | 2 | `descending_contour_melody` | 0.244 | 0.667* | +0.423 | no | gated |
| against-cantus-2 | 2 | `static_contour_melody` | 0.244 | 0.667* | +0.423 | no | gated |
| against-cantus-2 | 2 | `valley_contour_melody` | 0.122 | 0.333* | +0.211 | no | gated |
| against-cantus-2 | 2 | `wave_contour_melody` | 0.122 | 0.333* | +0.211 | no | gated |
| against-cantus-4 | 4 | `fux_cantus_firmus` | 0.454 | 0.882 | +0.428 | yes | threshold split |
| against-cantus-4 | 4 | `salzer_schachter_cantus_firmus` | 0.464 | 0.903 | +0.439 | yes | threshold split |
| against-cantus-4 | 4 | `diatonic_melody` | 0.769 | 0.947 | +0.178 | yes | threshold split |
| against-cantus-4 | 4 | `first_species_melody` | 0.831 | 0.712 | -0.119 | yes | demoted |
| against-cantus-4 | 4 | `second_species_melody` | 0.818 | 0.545 | -0.273 | yes | demoted |
| against-cantus-4 | 4 | `third_species_melody` | 0.818 | 0.545 | -0.273 | yes | demoted |
| against-cantus-4 | 4 | `third_species_triple_meter_melody` | 0.818 | 0.545 | -0.273 | yes | demoted |
| against-cantus-4 | 4 | `fourth_species_melody` | 0.836 | 0.427 | -0.409 | yes | demoted |
| against-cantus-4 | 4 | `combined_first_second_third_species_melody` | 0.918 | 0.966 | +0.048 | yes | demoted |
| against-cantus-4 | 4 | `fifth_species_melody` | 0.829 | 0.601 | -0.228 | yes | demoted |
| against-cantus-4 | 4 | `arch_contour_melody` | 0.483 | 0.598 | +0.115 | yes | threshold split |
| against-cantus-4 | 4 | `ascending_contour_melody` | 0.788 | 0.980 | +0.191 | yes | threshold split |
| against-cantus-4 | 4 | `descending_contour_melody` | 0.483 | 0.598 | +0.115 | yes | threshold split |
| against-cantus-4 | 4 | `static_contour_melody` | 0.483 | 0.598 | +0.115 | yes | threshold split |
| against-cantus-4 | 4 | `valley_contour_melody` | 0.483 | 0.598 | +0.115 | yes | threshold split |
| against-cantus-4 | 4 | `wave_contour_melody` | 0.483 | 0.598 | +0.115 | yes | threshold split |
| against-cantus-8 | 8 | `fux_cantus_firmus` | 0.975 | 0.976 | +0.002 | yes | threshold split |
| against-cantus-8 | 8 | `salzer_schachter_cantus_firmus` | 0.976 | 0.978 | +0.001 | yes | threshold split |
| against-cantus-8 | 8 | `first_species_melody` | 0.908 | 0.959 | +0.052 | yes | demoted |
| against-cantus-8 | 8 | `second_species_melody` | 0.841 | 0.555 | -0.286 | yes | demoted |
| against-cantus-8 | 8 | `third_species_melody` | 0.841 | 0.555 | -0.286 | yes | demoted |
| against-cantus-8 | 8 | `third_species_triple_meter_melody` | 0.841 | 0.555 | -0.286 | yes | demoted |
| against-cantus-8 | 8 | `fourth_species_melody` | 0.914 | 0.965 | +0.051 | yes | demoted |
| against-cantus-8 | 8 | `combined_first_second_third_species_melody` | 0.945 | 0.978 | +0.032 | yes | demoted |
| against-cantus-8 | 8 | `fifth_species_melody` | 0.839 | 0.548 | -0.291 | yes | demoted |
| fux_cantus_firmus_examples-0-v0 | 11 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_cantus_firmus_examples-0-v0 | 11 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-0-v0 | 11 | `second_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples-0-v0 | 11 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-0-v0 | 11 | `third_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples-0-v0 | 11 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-0-v0 | 11 | `third_species_triple_meter_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples-0-v0 | 11 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-0-v0 | 11 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_cantus_firmus_examples-0-v0 | 11 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-0-v0 | 11 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_cantus_firmus_examples-0-v0 | 11 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-0-v0 | 11 | `fifth_species_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| fux_cantus_firmus_examples-0-v0 | 11 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-0-v1 | 0 | `first_species_melody` | 0.934 | 0.000* | -0.934 | no | gated |
| fux_cantus_firmus_examples-0-v1 | 0 | `first_species_harmony` | 0.889 | 0.000* | -0.889 | no | gated |
| fux_cantus_firmus_examples-0-v1 | 0 | `second_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples-0-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-0-v1 | 0 | `third_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples-0-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-0-v1 | 0 | `third_species_triple_meter_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples-0-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-0-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| fux_cantus_firmus_examples-0-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-0-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-0-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-0-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-0-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-1-v0 | 10 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_cantus_firmus_examples-1-v0 | 10 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-1-v0 | 10 | `second_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples-1-v0 | 10 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-1-v0 | 10 | `third_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples-1-v0 | 10 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-1-v0 | 10 | `third_species_triple_meter_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples-1-v0 | 10 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-1-v0 | 10 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_cantus_firmus_examples-1-v0 | 10 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-1-v0 | 10 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_cantus_firmus_examples-1-v0 | 10 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-1-v0 | 10 | `fifth_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| fux_cantus_firmus_examples-1-v0 | 10 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-1-v1 | 0 | `first_species_melody` | 0.935 | 0.000* | -0.935 | no | gated |
| fux_cantus_firmus_examples-1-v1 | 0 | `first_species_harmony` | 0.890 | 0.000* | -0.890 | no | gated |
| fux_cantus_firmus_examples-1-v1 | 0 | `second_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples-1-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-1-v1 | 0 | `third_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples-1-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-1-v1 | 0 | `third_species_triple_meter_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples-1-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-1-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| fux_cantus_firmus_examples-1-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-1-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-1-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-1-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-1-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-2-v0 | 12 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_cantus_firmus_examples-2-v0 | 12 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-2-v0 | 12 | `second_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples-2-v0 | 12 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-2-v0 | 12 | `third_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples-2-v0 | 12 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-2-v0 | 12 | `third_species_triple_meter_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples-2-v0 | 12 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-2-v0 | 12 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_cantus_firmus_examples-2-v0 | 12 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-2-v0 | 12 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_cantus_firmus_examples-2-v0 | 12 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-2-v0 | 12 | `fifth_species_melody` | 0.897 | 0.565 | -0.332 | yes | demoted |
| fux_cantus_firmus_examples-2-v0 | 12 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-2-v1 | 0 | `first_species_melody` | 0.934 | 0.000* | -0.934 | no | gated |
| fux_cantus_firmus_examples-2-v1 | 0 | `first_species_harmony` | 0.889 | 0.000* | -0.889 | no | gated |
| fux_cantus_firmus_examples-2-v1 | 0 | `second_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples-2-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-2-v1 | 0 | `third_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples-2-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-2-v1 | 0 | `third_species_triple_meter_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples-2-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-2-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| fux_cantus_firmus_examples-2-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-2-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-2-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-2-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-2-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-3-v0 | 14 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_cantus_firmus_examples-3-v0 | 14 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-3-v0 | 14 | `second_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples-3-v0 | 14 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-3-v0 | 14 | `third_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples-3-v0 | 14 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-3-v0 | 14 | `third_species_triple_meter_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples-3-v0 | 14 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-3-v0 | 14 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_cantus_firmus_examples-3-v0 | 14 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-3-v0 | 14 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_cantus_firmus_examples-3-v0 | 14 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-3-v0 | 14 | `fifth_species_melody` | 0.896 | 0.564 | -0.333 | yes | demoted |
| fux_cantus_firmus_examples-3-v0 | 14 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-3-v1 | 0 | `first_species_melody` | 0.934 | 0.000* | -0.934 | no | gated |
| fux_cantus_firmus_examples-3-v1 | 0 | `first_species_harmony` | 0.889 | 0.000* | -0.889 | no | gated |
| fux_cantus_firmus_examples-3-v1 | 0 | `second_species_melody` | 0.941 | 0.000* | -0.941 | no | gated |
| fux_cantus_firmus_examples-3-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-3-v1 | 0 | `third_species_melody` | 0.941 | 0.000* | -0.941 | no | gated |
| fux_cantus_firmus_examples-3-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-3-v1 | 0 | `third_species_triple_meter_melody` | 0.941 | 0.000* | -0.941 | no | gated |
| fux_cantus_firmus_examples-3-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-3-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| fux_cantus_firmus_examples-3-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-3-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-3-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-3-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-3-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-4-v0 | 12 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_cantus_firmus_examples-4-v0 | 12 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-4-v0 | 12 | `second_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples-4-v0 | 12 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-4-v0 | 12 | `third_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples-4-v0 | 12 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-4-v0 | 12 | `third_species_triple_meter_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples-4-v0 | 12 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-4-v0 | 12 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_cantus_firmus_examples-4-v0 | 12 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-4-v0 | 12 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_cantus_firmus_examples-4-v0 | 12 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-4-v0 | 12 | `fifth_species_melody` | 0.897 | 0.565 | -0.332 | yes | demoted |
| fux_cantus_firmus_examples-4-v0 | 12 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-4-v1 | 0 | `first_species_melody` | 0.934 | 0.000* | -0.934 | no | gated |
| fux_cantus_firmus_examples-4-v1 | 0 | `first_species_harmony` | 0.889 | 0.000* | -0.889 | no | gated |
| fux_cantus_firmus_examples-4-v1 | 0 | `second_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples-4-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-4-v1 | 0 | `third_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples-4-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-4-v1 | 0 | `third_species_triple_meter_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples-4-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-4-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| fux_cantus_firmus_examples-4-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-4-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-4-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-4-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-4-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-5-v0 | 12 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_cantus_firmus_examples-5-v0 | 12 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-5-v0 | 12 | `second_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples-5-v0 | 12 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-5-v0 | 12 | `third_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples-5-v0 | 12 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-5-v0 | 12 | `third_species_triple_meter_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples-5-v0 | 12 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-5-v0 | 12 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_cantus_firmus_examples-5-v0 | 12 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-5-v0 | 12 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_cantus_firmus_examples-5-v0 | 12 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-5-v0 | 12 | `fifth_species_melody` | 0.897 | 0.565 | -0.332 | yes | demoted |
| fux_cantus_firmus_examples-5-v0 | 12 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-5-v1 | 0 | `first_species_melody` | 0.934 | 0.000* | -0.934 | no | gated |
| fux_cantus_firmus_examples-5-v1 | 0 | `first_species_harmony` | 0.889 | 0.000* | -0.889 | no | gated |
| fux_cantus_firmus_examples-5-v1 | 0 | `second_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples-5-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-5-v1 | 0 | `third_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples-5-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-5-v1 | 0 | `third_species_triple_meter_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples-5-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-5-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| fux_cantus_firmus_examples-5-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-5-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-5-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-5-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-5-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-6-v0 | 9 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_cantus_firmus_examples-6-v0 | 9 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-6-v0 | 9 | `second_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples-6-v0 | 9 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-6-v0 | 9 | `third_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples-6-v0 | 9 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-6-v0 | 9 | `third_species_triple_meter_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples-6-v0 | 9 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-6-v0 | 9 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_cantus_firmus_examples-6-v0 | 9 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-6-v0 | 9 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_cantus_firmus_examples-6-v0 | 9 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-6-v0 | 9 | `fifth_species_melody` | 0.897 | 0.570 | -0.328 | yes | demoted |
| fux_cantus_firmus_examples-6-v0 | 9 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-6-v1 | 0 | `first_species_melody` | 0.936 | 0.000* | -0.936 | no | gated |
| fux_cantus_firmus_examples-6-v1 | 0 | `first_species_harmony` | 0.890 | 0.000* | -0.890 | no | gated |
| fux_cantus_firmus_examples-6-v1 | 0 | `second_species_melody` | 0.943 | 0.000* | -0.943 | no | gated |
| fux_cantus_firmus_examples-6-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-6-v1 | 0 | `third_species_melody` | 0.943 | 0.000* | -0.943 | no | gated |
| fux_cantus_firmus_examples-6-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-6-v1 | 0 | `third_species_triple_meter_melody` | 0.943 | 0.000* | -0.943 | no | gated |
| fux_cantus_firmus_examples-6-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-6-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| fux_cantus_firmus_examples-6-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-6-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-6-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-6-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples-6-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-0-v0 | 12 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| clendinning_cantus_firmus_examples-0-v0 | 12 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-0-v0 | 12 | `second_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| clendinning_cantus_firmus_examples-0-v0 | 12 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-0-v0 | 12 | `third_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| clendinning_cantus_firmus_examples-0-v0 | 12 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-0-v0 | 12 | `third_species_triple_meter_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| clendinning_cantus_firmus_examples-0-v0 | 12 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-0-v0 | 12 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| clendinning_cantus_firmus_examples-0-v0 | 12 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-0-v0 | 12 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| clendinning_cantus_firmus_examples-0-v0 | 12 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-0-v0 | 12 | `fifth_species_melody` | 0.897 | 0.565 | -0.332 | yes | demoted |
| clendinning_cantus_firmus_examples-0-v0 | 12 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-0-v1 | 0 | `first_species_melody` | 0.934 | 0.000* | -0.934 | no | gated |
| clendinning_cantus_firmus_examples-0-v1 | 0 | `first_species_harmony` | 0.889 | 0.000* | -0.889 | no | gated |
| clendinning_cantus_firmus_examples-0-v1 | 0 | `second_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| clendinning_cantus_firmus_examples-0-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-0-v1 | 0 | `third_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| clendinning_cantus_firmus_examples-0-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-0-v1 | 0 | `third_species_triple_meter_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| clendinning_cantus_firmus_examples-0-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-0-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| clendinning_cantus_firmus_examples-0-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-0-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-0-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-0-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-0-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-1-v0 | 9 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| clendinning_cantus_firmus_examples-1-v0 | 9 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-1-v0 | 9 | `second_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| clendinning_cantus_firmus_examples-1-v0 | 9 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-1-v0 | 9 | `third_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| clendinning_cantus_firmus_examples-1-v0 | 9 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-1-v0 | 9 | `third_species_triple_meter_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| clendinning_cantus_firmus_examples-1-v0 | 9 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-1-v0 | 9 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| clendinning_cantus_firmus_examples-1-v0 | 9 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-1-v0 | 9 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| clendinning_cantus_firmus_examples-1-v0 | 9 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-1-v0 | 9 | `fifth_species_melody` | 0.897 | 0.570 | -0.328 | yes | demoted |
| clendinning_cantus_firmus_examples-1-v0 | 9 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-1-v1 | 0 | `first_species_melody` | 0.936 | 0.000* | -0.936 | no | gated |
| clendinning_cantus_firmus_examples-1-v1 | 0 | `first_species_harmony` | 0.890 | 0.000* | -0.890 | no | gated |
| clendinning_cantus_firmus_examples-1-v1 | 0 | `second_species_melody` | 0.943 | 0.000* | -0.943 | no | gated |
| clendinning_cantus_firmus_examples-1-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-1-v1 | 0 | `third_species_melody` | 0.943 | 0.000* | -0.943 | no | gated |
| clendinning_cantus_firmus_examples-1-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-1-v1 | 0 | `third_species_triple_meter_melody` | 0.943 | 0.000* | -0.943 | no | gated |
| clendinning_cantus_firmus_examples-1-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-1-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| clendinning_cantus_firmus_examples-1-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-1-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-1-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-1-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-1-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-2-v0 | 11 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| clendinning_cantus_firmus_examples-2-v0 | 11 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-2-v0 | 11 | `second_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| clendinning_cantus_firmus_examples-2-v0 | 11 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-2-v0 | 11 | `third_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| clendinning_cantus_firmus_examples-2-v0 | 11 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-2-v0 | 11 | `third_species_triple_meter_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| clendinning_cantus_firmus_examples-2-v0 | 11 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-2-v0 | 11 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| clendinning_cantus_firmus_examples-2-v0 | 11 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-2-v0 | 11 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| clendinning_cantus_firmus_examples-2-v0 | 11 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-2-v0 | 11 | `fifth_species_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| clendinning_cantus_firmus_examples-2-v0 | 11 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-2-v1 | 0 | `first_species_melody` | 0.934 | 0.000* | -0.934 | no | gated |
| clendinning_cantus_firmus_examples-2-v1 | 0 | `first_species_harmony` | 0.889 | 0.000* | -0.889 | no | gated |
| clendinning_cantus_firmus_examples-2-v1 | 0 | `second_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| clendinning_cantus_firmus_examples-2-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-2-v1 | 0 | `third_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| clendinning_cantus_firmus_examples-2-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-2-v1 | 0 | `third_species_triple_meter_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| clendinning_cantus_firmus_examples-2-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-2-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| clendinning_cantus_firmus_examples-2-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-2-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-2-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-2-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-2-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-3-v0 | 12 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| clendinning_cantus_firmus_examples-3-v0 | 12 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-3-v0 | 12 | `second_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| clendinning_cantus_firmus_examples-3-v0 | 12 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-3-v0 | 12 | `third_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| clendinning_cantus_firmus_examples-3-v0 | 12 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-3-v0 | 12 | `third_species_triple_meter_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| clendinning_cantus_firmus_examples-3-v0 | 12 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-3-v0 | 12 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| clendinning_cantus_firmus_examples-3-v0 | 12 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-3-v0 | 12 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| clendinning_cantus_firmus_examples-3-v0 | 12 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-3-v0 | 12 | `fifth_species_melody` | 0.897 | 0.565 | -0.332 | yes | demoted |
| clendinning_cantus_firmus_examples-3-v0 | 12 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-3-v1 | 0 | `first_species_melody` | 0.934 | 0.000* | -0.934 | no | gated |
| clendinning_cantus_firmus_examples-3-v1 | 0 | `first_species_harmony` | 0.889 | 0.000* | -0.889 | no | gated |
| clendinning_cantus_firmus_examples-3-v1 | 0 | `second_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| clendinning_cantus_firmus_examples-3-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-3-v1 | 0 | `third_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| clendinning_cantus_firmus_examples-3-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-3-v1 | 0 | `third_species_triple_meter_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| clendinning_cantus_firmus_examples-3-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-3-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| clendinning_cantus_firmus_examples-3-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-3-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-3-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-3-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| clendinning_cantus_firmus_examples-3-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-0-v0 | 8 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| schoenberg_cantus_firmus_examples-0-v0 | 8 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-0-v0 | 8 | `second_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| schoenberg_cantus_firmus_examples-0-v0 | 8 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-0-v0 | 8 | `third_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| schoenberg_cantus_firmus_examples-0-v0 | 8 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-0-v0 | 8 | `third_species_triple_meter_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| schoenberg_cantus_firmus_examples-0-v0 | 8 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-0-v0 | 8 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| schoenberg_cantus_firmus_examples-0-v0 | 8 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-0-v0 | 8 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| schoenberg_cantus_firmus_examples-0-v0 | 8 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-0-v0 | 8 | `fifth_species_melody` | 0.898 | 0.574 | -0.324 | yes | demoted |
| schoenberg_cantus_firmus_examples-0-v0 | 8 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-0-v1 | 0 | `first_species_melody` | 0.937 | 0.000* | -0.937 | no | gated |
| schoenberg_cantus_firmus_examples-0-v1 | 0 | `first_species_harmony` | 0.891 | 0.000* | -0.891 | no | gated |
| schoenberg_cantus_firmus_examples-0-v1 | 0 | `second_species_melody` | 0.944 | 0.000* | -0.944 | no | gated |
| schoenberg_cantus_firmus_examples-0-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-0-v1 | 0 | `third_species_melody` | 0.944 | 0.000* | -0.944 | no | gated |
| schoenberg_cantus_firmus_examples-0-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-0-v1 | 0 | `third_species_triple_meter_melody` | 0.944 | 0.000* | -0.944 | no | gated |
| schoenberg_cantus_firmus_examples-0-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-0-v1 | 0 | `fourth_species_melody` | 0.939 | 0.000* | -0.939 | no | gated |
| schoenberg_cantus_firmus_examples-0-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-0-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-0-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-0-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-0-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-1-v0 | 8 | `fux_cantus_firmus` | 0.949 | 0.952 | +0.003 | yes | threshold split |
| schoenberg_cantus_firmus_examples-1-v0 | 8 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-1-v0 | 8 | `second_species_melody` | 0.978 | 0.882 | -0.096 | yes | demoted |
| schoenberg_cantus_firmus_examples-1-v0 | 8 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-1-v0 | 8 | `third_species_melody` | 0.978 | 0.882 | -0.096 | yes | demoted |
| schoenberg_cantus_firmus_examples-1-v0 | 8 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-1-v0 | 8 | `third_species_triple_meter_melody` | 0.978 | 0.882 | -0.096 | yes | demoted |
| schoenberg_cantus_firmus_examples-1-v0 | 8 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-1-v0 | 8 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-1-v0 | 8 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-1-v0 | 8 | `fifth_species_melody` | 0.921 | 0.584 | -0.337 | yes | demoted |
| schoenberg_cantus_firmus_examples-1-v0 | 8 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-1-v1 | 0 | `first_species_melody` | 0.937 | 0.000* | -0.937 | no | gated |
| schoenberg_cantus_firmus_examples-1-v1 | 0 | `first_species_harmony` | 0.891 | 0.000* | -0.891 | no | gated |
| schoenberg_cantus_firmus_examples-1-v1 | 0 | `second_species_melody` | 0.944 | 0.000* | -0.944 | no | gated |
| schoenberg_cantus_firmus_examples-1-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-1-v1 | 0 | `third_species_melody` | 0.944 | 0.000* | -0.944 | no | gated |
| schoenberg_cantus_firmus_examples-1-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-1-v1 | 0 | `third_species_triple_meter_melody` | 0.944 | 0.000* | -0.944 | no | gated |
| schoenberg_cantus_firmus_examples-1-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-1-v1 | 0 | `fourth_species_melody` | 0.939 | 0.000* | -0.939 | no | gated |
| schoenberg_cantus_firmus_examples-1-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-1-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-1-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-1-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| schoenberg_cantus_firmus_examples-1-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-0-v0 | 10 | `fux_cantus_firmus` | 0.975 | 0.976 | +0.002 | yes | threshold split |
| davis_and_lybbert_cantus_firmus_examples-0-v0 | 10 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-0-v0 | 10 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-0-v0 | 10 | `second_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-0-v0 | 10 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-0-v0 | 10 | `third_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-0-v0 | 10 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-0-v0 | 10 | `third_species_triple_meter_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-0-v0 | 10 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-0-v0 | 10 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-0-v0 | 10 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-0-v0 | 10 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-0-v0 | 10 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-0-v0 | 10 | `fifth_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-0-v0 | 10 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-0-v1 | 0 | `first_species_melody` | 0.935 | 0.000* | -0.935 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-0-v1 | 0 | `first_species_harmony` | 0.890 | 0.000* | -0.890 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-0-v1 | 0 | `second_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-0-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-0-v1 | 0 | `third_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-0-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-0-v1 | 0 | `third_species_triple_meter_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-0-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-0-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-0-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-0-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-0-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-0-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-0-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-1-v0 | 9 | `fux_cantus_firmus` | 0.970 | 0.972 | +0.002 | yes | threshold split |
| davis_and_lybbert_cantus_firmus_examples-1-v0 | 9 | `first_species_melody` | 0.945 | 0.976 | +0.031 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-1-v0 | 9 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-1-v0 | 9 | `second_species_melody` | 0.929 | 0.861 | -0.068 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-1-v0 | 9 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-1-v0 | 9 | `third_species_melody` | 0.929 | 0.861 | -0.068 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-1-v0 | 9 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-1-v0 | 9 | `third_species_triple_meter_melody` | 0.929 | 0.861 | -0.068 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-1-v0 | 9 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-1-v0 | 9 | `fourth_species_melody` | 0.948 | 0.979 | +0.031 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-1-v0 | 9 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-1-v0 | 9 | `combined_first_second_third_species_melody` | 0.941 | 0.976 | +0.035 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-1-v0 | 9 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-1-v0 | 9 | `fifth_species_melody` | 0.871 | 0.558 | -0.313 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-1-v0 | 9 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-1-v1 | 0 | `first_species_melody` | 0.936 | 0.000* | -0.936 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-1-v1 | 0 | `first_species_harmony` | 0.890 | 0.000* | -0.890 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-1-v1 | 0 | `second_species_melody` | 0.943 | 0.000* | -0.943 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-1-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-1-v1 | 0 | `third_species_melody` | 0.943 | 0.000* | -0.943 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-1-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-1-v1 | 0 | `third_species_triple_meter_melody` | 0.943 | 0.000* | -0.943 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-1-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-1-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-1-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-1-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-1-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-1-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-1-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-2-v0 | 11 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-2-v0 | 11 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-2-v0 | 11 | `second_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-2-v0 | 11 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-2-v0 | 11 | `third_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-2-v0 | 11 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-2-v0 | 11 | `third_species_triple_meter_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-2-v0 | 11 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-2-v0 | 11 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-2-v0 | 11 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-2-v0 | 11 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-2-v0 | 11 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-2-v0 | 11 | `fifth_species_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-2-v0 | 11 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-2-v1 | 0 | `first_species_melody` | 0.934 | 0.000* | -0.934 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-2-v1 | 0 | `first_species_harmony` | 0.889 | 0.000* | -0.889 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-2-v1 | 0 | `second_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-2-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-2-v1 | 0 | `third_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-2-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-2-v1 | 0 | `third_species_triple_meter_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-2-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-2-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-2-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-2-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-2-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-2-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-2-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-3-v0 | 10 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-3-v0 | 10 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-3-v0 | 10 | `second_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-3-v0 | 10 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-3-v0 | 10 | `third_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-3-v0 | 10 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-3-v0 | 10 | `third_species_triple_meter_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-3-v0 | 10 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-3-v0 | 10 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-3-v0 | 10 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-3-v0 | 10 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-3-v0 | 10 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-3-v0 | 10 | `fifth_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-3-v0 | 10 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-3-v1 | 0 | `first_species_melody` | 0.935 | 0.000* | -0.935 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-3-v1 | 0 | `first_species_harmony` | 0.890 | 0.000* | -0.890 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-3-v1 | 0 | `second_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-3-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-3-v1 | 0 | `third_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-3-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-3-v1 | 0 | `third_species_triple_meter_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-3-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-3-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-3-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-3-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-3-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-3-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-3-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-4-v0 | 10 | `fux_cantus_firmus` | 0.959 | 0.961 | +0.003 | yes | threshold split |
| davis_and_lybbert_cantus_firmus_examples-4-v0 | 10 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-4-v0 | 10 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-4-v0 | 10 | `second_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-4-v0 | 10 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-4-v0 | 10 | `third_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-4-v0 | 10 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-4-v0 | 10 | `third_species_triple_meter_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-4-v0 | 10 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-4-v0 | 10 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-4-v0 | 10 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-4-v0 | 10 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-4-v0 | 10 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-4-v0 | 10 | `fifth_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-4-v0 | 10 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-4-v1 | 0 | `first_species_melody` | 0.935 | 0.000* | -0.935 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-4-v1 | 0 | `first_species_harmony` | 0.890 | 0.000* | -0.890 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-4-v1 | 0 | `second_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-4-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-4-v1 | 0 | `third_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-4-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-4-v1 | 0 | `third_species_triple_meter_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-4-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-4-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-4-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-4-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-4-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-4-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-4-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-5-v0 | 10 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-5-v0 | 10 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-5-v0 | 10 | `second_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-5-v0 | 10 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-5-v0 | 10 | `third_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-5-v0 | 10 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-5-v0 | 10 | `third_species_triple_meter_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-5-v0 | 10 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-5-v0 | 10 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-5-v0 | 10 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-5-v0 | 10 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-5-v0 | 10 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-5-v0 | 10 | `fifth_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-5-v0 | 10 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-5-v1 | 0 | `first_species_melody` | 0.935 | 0.000* | -0.935 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-5-v1 | 0 | `first_species_harmony` | 0.890 | 0.000* | -0.890 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-5-v1 | 0 | `second_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-5-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-5-v1 | 0 | `third_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-5-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-5-v1 | 0 | `third_species_triple_meter_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-5-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-5-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-5-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-5-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-5-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-5-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-5-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-6-v0 | 10 | `fux_cantus_firmus` | 0.967 | 0.969 | +0.002 | yes | threshold split |
| davis_and_lybbert_cantus_firmus_examples-6-v0 | 10 | `first_species_melody` | 0.942 | 0.974 | +0.033 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-6-v0 | 10 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-6-v0 | 10 | `second_species_melody` | 0.926 | 0.860 | -0.066 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-6-v0 | 10 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-6-v0 | 10 | `third_species_melody` | 0.926 | 0.860 | -0.066 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-6-v0 | 10 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-6-v0 | 10 | `third_species_triple_meter_melody` | 0.926 | 0.860 | -0.066 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-6-v0 | 10 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-6-v0 | 10 | `fourth_species_melody` | 0.945 | 0.978 | +0.032 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-6-v0 | 10 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-6-v0 | 10 | `combined_first_second_third_species_melody` | 0.937 | 0.974 | +0.037 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-6-v0 | 10 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-6-v0 | 10 | `fifth_species_melody` | 0.868 | 0.555 | -0.313 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-6-v0 | 10 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-6-v1 | 0 | `first_species_melody` | 0.935 | 0.000* | -0.935 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-6-v1 | 0 | `first_species_harmony` | 0.890 | 0.000* | -0.890 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-6-v1 | 0 | `second_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-6-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-6-v1 | 0 | `third_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-6-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-6-v1 | 0 | `third_species_triple_meter_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-6-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-6-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-6-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-6-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-6-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-6-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-6-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-7-v0 | 10 | `fux_cantus_firmus` | 0.959 | 0.961 | +0.003 | yes | threshold split |
| davis_and_lybbert_cantus_firmus_examples-7-v0 | 10 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-7-v0 | 10 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-7-v0 | 10 | `second_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-7-v0 | 10 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-7-v0 | 10 | `third_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-7-v0 | 10 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-7-v0 | 10 | `third_species_triple_meter_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-7-v0 | 10 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-7-v0 | 10 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-7-v0 | 10 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-7-v0 | 10 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-7-v0 | 10 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-7-v0 | 10 | `fifth_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-7-v0 | 10 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-7-v1 | 0 | `first_species_melody` | 0.935 | 0.000* | -0.935 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-7-v1 | 0 | `first_species_harmony` | 0.890 | 0.000* | -0.890 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-7-v1 | 0 | `second_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-7-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-7-v1 | 0 | `third_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-7-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-7-v1 | 0 | `third_species_triple_meter_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-7-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-7-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-7-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-7-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-7-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-7-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-7-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-8-v0 | 11 | `fux_cantus_firmus` | 0.978 | 0.980 | +0.001 | yes | threshold split |
| davis_and_lybbert_cantus_firmus_examples-8-v0 | 11 | `first_species_melody` | 0.953 | 0.979 | +0.026 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-8-v0 | 11 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-8-v0 | 11 | `second_species_melody` | 0.936 | 0.864 | -0.072 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-8-v0 | 11 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-8-v0 | 11 | `third_species_melody` | 0.936 | 0.864 | -0.072 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-8-v0 | 11 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-8-v0 | 11 | `third_species_triple_meter_melody` | 0.936 | 0.864 | -0.072 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-8-v0 | 11 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-8-v0 | 11 | `fourth_species_melody` | 0.956 | 0.982 | +0.026 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-8-v0 | 11 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-8-v0 | 11 | `combined_first_second_third_species_melody` | 0.950 | 0.979 | +0.030 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-8-v0 | 11 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-8-v0 | 11 | `fifth_species_melody` | 0.878 | 0.557 | -0.320 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-8-v0 | 11 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-8-v1 | 0 | `first_species_melody` | 0.934 | 0.000* | -0.934 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-8-v1 | 0 | `first_species_harmony` | 0.889 | 0.000* | -0.889 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-8-v1 | 0 | `second_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-8-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-8-v1 | 0 | `third_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-8-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-8-v1 | 0 | `third_species_triple_meter_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-8-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-8-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-8-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-8-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-8-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-8-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-8-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-9-v0 | 11 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-9-v0 | 11 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-9-v0 | 11 | `second_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-9-v0 | 11 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-9-v0 | 11 | `third_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-9-v0 | 11 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-9-v0 | 11 | `third_species_triple_meter_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-9-v0 | 11 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-9-v0 | 11 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-9-v0 | 11 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-9-v0 | 11 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-9-v0 | 11 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-9-v0 | 11 | `fifth_species_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| davis_and_lybbert_cantus_firmus_examples-9-v0 | 11 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-9-v1 | 0 | `first_species_melody` | 0.934 | 0.000* | -0.934 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-9-v1 | 0 | `first_species_harmony` | 0.889 | 0.000* | -0.889 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-9-v1 | 0 | `second_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-9-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-9-v1 | 0 | `third_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-9-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-9-v1 | 0 | `third_species_triple_meter_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-9-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-9-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-9-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-9-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-9-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-9-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| davis_and_lybbert_cantus_firmus_examples-9-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-0-v0 | 12 | `fux_cantus_firmus` | 0.975 | 0.976 | +0.002 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-0-v0 | 12 | `salzer_schachter_cantus_firmus` | 0.976 | 0.978 | +0.001 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-0-v0 | 12 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-0-v0 | 12 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-0-v0 | 12 | `second_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-0-v0 | 12 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-0-v0 | 12 | `third_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-0-v0 | 12 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-0-v0 | 12 | `third_species_triple_meter_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-0-v0 | 12 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-0-v0 | 12 | `fourth_species_melody` | 0.952 | 0.981 | +0.028 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-0-v0 | 12 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-0-v0 | 12 | `combined_first_second_third_species_melody` | 0.945 | 0.978 | +0.032 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-0-v0 | 12 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-0-v0 | 12 | `fifth_species_melody` | 0.874 | 0.555 | -0.319 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-0-v0 | 12 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-0-v1 | 0 | `first_species_melody` | 0.934 | 0.000* | -0.934 | no | gated |
| fux_cantus_firmus_examples_with_errors-0-v1 | 0 | `first_species_harmony` | 0.889 | 0.000* | -0.889 | no | gated |
| fux_cantus_firmus_examples_with_errors-0-v1 | 0 | `second_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples_with_errors-0-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-0-v1 | 0 | `third_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples_with_errors-0-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-0-v1 | 0 | `third_species_triple_meter_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples_with_errors-0-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-0-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| fux_cantus_firmus_examples_with_errors-0-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-0-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-0-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-0-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-0-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-1-v0 | 7 | `fux_cantus_firmus` | 0.858 | 0.974 | +0.116 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-1-v0 | 7 | `salzer_schachter_cantus_firmus` | 0.875 | 0.993 | +0.118 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-1-v0 | 7 | `first_species_melody` | 0.955 | 0.980 | +0.025 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-1-v0 | 7 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-1-v0 | 7 | `second_species_melody` | 0.938 | 0.865 | -0.073 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-1-v0 | 7 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-1-v0 | 7 | `third_species_melody` | 0.938 | 0.865 | -0.073 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-1-v0 | 7 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-1-v0 | 7 | `third_species_triple_meter_melody` | 0.938 | 0.865 | -0.073 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-1-v0 | 7 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-1-v0 | 7 | `fourth_species_melody` | 0.958 | 0.983 | +0.025 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-1-v0 | 7 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-1-v0 | 7 | `combined_first_second_third_species_melody` | 0.952 | 0.980 | +0.028 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-1-v0 | 7 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-1-v0 | 7 | `fifth_species_melody` | 0.883 | 0.573 | -0.309 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-1-v0 | 7 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-1-v1 | 0 | `first_species_melody` | 0.939 | 0.000* | -0.939 | no | gated |
| fux_cantus_firmus_examples_with_errors-1-v1 | 0 | `first_species_harmony` | 0.893 | 0.000* | -0.893 | no | gated |
| fux_cantus_firmus_examples_with_errors-1-v1 | 0 | `second_species_melody` | 0.946 | 0.000* | -0.946 | no | gated |
| fux_cantus_firmus_examples_with_errors-1-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-1-v1 | 0 | `third_species_melody` | 0.946 | 0.000* | -0.946 | no | gated |
| fux_cantus_firmus_examples_with_errors-1-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-1-v1 | 0 | `third_species_triple_meter_melody` | 0.946 | 0.000* | -0.946 | no | gated |
| fux_cantus_firmus_examples_with_errors-1-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-1-v1 | 0 | `fourth_species_melody` | 0.940 | 0.000* | -0.940 | no | gated |
| fux_cantus_firmus_examples_with_errors-1-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-1-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-1-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-1-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-1-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `fux_cantus_firmus` | 0.975 | 0.976 | +0.002 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `salzer_schachter_cantus_firmus` | 0.976 | 0.978 | +0.001 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `diatonic_melody` | 0.962 | 0.965 | +0.003 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `first_species_melody` | 0.949 | 0.978 | +0.028 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `second_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `third_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `third_species_triple_meter_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `fourth_species_melody` | 0.952 | 0.981 | +0.028 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `combined_first_second_third_species_melody` | 0.945 | 0.978 | +0.032 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `fifth_species_melody` | 0.874 | 0.556 | -0.318 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `arch_contour_melody` | 0.985 | 0.987 | +0.001 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `ascending_contour_melody` | 0.603 | 0.605 | +0.001 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `descending_contour_melody` | 0.603 | 0.605 | +0.001 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `static_contour_melody` | 0.603 | 0.605 | +0.001 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `valley_contour_melody` | 0.603 | 0.605 | +0.001 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `wave_contour_melody` | 0.603 | 0.605 | +0.001 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-2-v1 | 0 | `first_species_melody` | 0.934 | 0.000* | -0.934 | no | gated |
| fux_cantus_firmus_examples_with_errors-2-v1 | 0 | `first_species_harmony` | 0.889 | 0.000* | -0.889 | no | gated |
| fux_cantus_firmus_examples_with_errors-2-v1 | 0 | `second_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples_with_errors-2-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-2-v1 | 0 | `third_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples_with_errors-2-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-2-v1 | 0 | `third_species_triple_meter_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples_with_errors-2-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-2-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| fux_cantus_firmus_examples_with_errors-2-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-2-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-2-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-2-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-2-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `fux_cantus_firmus` | 0.992 | 0.992 | +0.001 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `salzer_schachter_cantus_firmus` | 0.992 | 0.993 | +0.000 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `diatonic_melody` | 0.988 | 0.989 | +0.001 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `first_species_melody` | 0.966 | 0.985 | +0.019 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `second_species_melody` | 0.948 | 0.869 | -0.079 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `third_species_melody` | 0.948 | 0.869 | -0.079 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `third_species_triple_meter_melody` | 0.948 | 0.869 | -0.079 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `fourth_species_melody` | 0.968 | 0.987 | +0.019 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `combined_first_second_third_species_melody` | 0.964 | 0.985 | +0.021 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `fifth_species_melody` | 0.889 | 0.563 | -0.327 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `arch_contour_melody` | 0.995 | 0.996 | +0.000 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `ascending_contour_melody` | 0.613 | 0.614 | +0.000 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `descending_contour_melody` | 0.613 | 0.614 | +0.000 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `static_contour_melody` | 0.613 | 0.614 | +0.000 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `valley_contour_melody` | 0.613 | 0.614 | +0.000 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `wave_contour_melody` | 0.995 | 0.996 | +0.000 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-3-v1 | 0 | `first_species_melody` | 0.934 | 0.000* | -0.934 | no | gated |
| fux_cantus_firmus_examples_with_errors-3-v1 | 0 | `first_species_harmony` | 0.889 | 0.000* | -0.889 | no | gated |
| fux_cantus_firmus_examples_with_errors-3-v1 | 0 | `second_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples_with_errors-3-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-3-v1 | 0 | `third_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples_with_errors-3-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-3-v1 | 0 | `third_species_triple_meter_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples_with_errors-3-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-3-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| fux_cantus_firmus_examples_with_errors-3-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-3-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-3-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-3-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-3-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-4-v0 | 9 | `fux_cantus_firmus` | 0.975 | 0.976 | +0.002 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-4-v0 | 9 | `salzer_schachter_cantus_firmus` | 0.976 | 0.978 | +0.001 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-4-v0 | 9 | `first_species_melody` | 0.949 | 0.978 | +0.028 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-4-v0 | 9 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-4-v0 | 9 | `second_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-4-v0 | 9 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-4-v0 | 9 | `third_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-4-v0 | 9 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-4-v0 | 9 | `third_species_triple_meter_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-4-v0 | 9 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-4-v0 | 9 | `fourth_species_melody` | 0.952 | 0.981 | +0.028 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-4-v0 | 9 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-4-v0 | 9 | `combined_first_second_third_species_melody` | 0.945 | 0.978 | +0.032 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-4-v0 | 9 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-4-v0 | 9 | `fifth_species_melody` | 0.875 | 0.560 | -0.315 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-4-v0 | 9 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-4-v1 | 0 | `first_species_melody` | 0.936 | 0.000* | -0.936 | no | gated |
| fux_cantus_firmus_examples_with_errors-4-v1 | 0 | `first_species_harmony` | 0.890 | 0.000* | -0.890 | no | gated |
| fux_cantus_firmus_examples_with_errors-4-v1 | 0 | `second_species_melody` | 0.943 | 0.000* | -0.943 | no | gated |
| fux_cantus_firmus_examples_with_errors-4-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-4-v1 | 0 | `third_species_melody` | 0.943 | 0.000* | -0.943 | no | gated |
| fux_cantus_firmus_examples_with_errors-4-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-4-v1 | 0 | `third_species_triple_meter_melody` | 0.943 | 0.000* | -0.943 | no | gated |
| fux_cantus_firmus_examples_with_errors-4-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-4-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| fux_cantus_firmus_examples_with_errors-4-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-4-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-4-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-4-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-4-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-5-v0 | 8 | `fux_cantus_firmus` | 0.975 | 0.976 | +0.002 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-5-v0 | 8 | `first_species_melody` | 0.949 | 0.978 | +0.028 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-5-v0 | 8 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-5-v0 | 8 | `second_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-5-v0 | 8 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-5-v0 | 8 | `third_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-5-v0 | 8 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-5-v0 | 8 | `third_species_triple_meter_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-5-v0 | 8 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-5-v0 | 8 | `fourth_species_melody` | 0.952 | 0.981 | +0.028 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-5-v0 | 8 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-5-v0 | 8 | `combined_first_second_third_species_melody` | 0.945 | 0.978 | +0.032 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-5-v0 | 8 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-5-v0 | 8 | `fifth_species_melody` | 0.876 | 0.564 | -0.312 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-5-v0 | 8 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-5-v1 | 0 | `first_species_melody` | 0.937 | 0.000* | -0.937 | no | gated |
| fux_cantus_firmus_examples_with_errors-5-v1 | 0 | `first_species_harmony` | 0.891 | 0.000* | -0.891 | no | gated |
| fux_cantus_firmus_examples_with_errors-5-v1 | 0 | `second_species_melody` | 0.944 | 0.000* | -0.944 | no | gated |
| fux_cantus_firmus_examples_with_errors-5-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-5-v1 | 0 | `third_species_melody` | 0.944 | 0.000* | -0.944 | no | gated |
| fux_cantus_firmus_examples_with_errors-5-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-5-v1 | 0 | `third_species_triple_meter_melody` | 0.944 | 0.000* | -0.944 | no | gated |
| fux_cantus_firmus_examples_with_errors-5-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-5-v1 | 0 | `fourth_species_melody` | 0.939 | 0.000* | -0.939 | no | gated |
| fux_cantus_firmus_examples_with_errors-5-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-5-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-5-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-5-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-5-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `fux_cantus_firmus` | 0.933 | 0.938 | +0.004 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `salzer_schachter_cantus_firmus` | 0.923 | 0.927 | +0.005 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `diatonic_melody` | 0.876 | 0.888 | +0.011 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `first_species_melody` | 0.892 | 0.952 | +0.060 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `second_species_melody` | 0.882 | 0.841 | -0.042 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `third_species_melody` | 0.882 | 0.841 | -0.042 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `third_species_triple_meter_melody` | 0.882 | 0.841 | -0.042 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `fourth_species_melody` | 0.899 | 0.959 | +0.060 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `combined_first_second_third_species_melody` | 0.884 | 0.952 | +0.068 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `fifth_species_melody` | 0.824 | 0.532 | -0.291 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `arch_contour_melody` | 0.953 | 0.957 | +0.004 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `ascending_contour_melody` | 0.571 | 0.575 | +0.004 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `descending_contour_melody` | 0.571 | 0.575 | +0.004 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `static_contour_melody` | 0.571 | 0.575 | +0.004 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `valley_contour_melody` | 0.571 | 0.575 | +0.004 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `wave_contour_melody` | 0.953 | 0.957 | +0.004 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-6-v1 | 0 | `first_species_melody` | 0.934 | 0.000* | -0.934 | no | gated |
| fux_cantus_firmus_examples_with_errors-6-v1 | 0 | `first_species_harmony` | 0.889 | 0.000* | -0.889 | no | gated |
| fux_cantus_firmus_examples_with_errors-6-v1 | 0 | `second_species_melody` | 0.941 | 0.000* | -0.941 | no | gated |
| fux_cantus_firmus_examples_with_errors-6-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-6-v1 | 0 | `third_species_melody` | 0.941 | 0.000* | -0.941 | no | gated |
| fux_cantus_firmus_examples_with_errors-6-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-6-v1 | 0 | `third_species_triple_meter_melody` | 0.941 | 0.000* | -0.941 | no | gated |
| fux_cantus_firmus_examples_with_errors-6-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-6-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| fux_cantus_firmus_examples_with_errors-6-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-6-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-6-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-6-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-6-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `fux_cantus_firmus` | 0.943 | 0.947 | +0.004 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `salzer_schachter_cantus_firmus` | 0.947 | 0.950 | +0.003 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `diatonic_melody` | 0.915 | 0.922 | +0.008 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `first_species_melody` | 0.918 | 0.964 | +0.046 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `second_species_melody` | 0.905 | 0.850 | -0.054 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `third_species_melody` | 0.905 | 0.850 | -0.054 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `third_species_triple_meter_melody` | 0.905 | 0.850 | -0.054 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `fourth_species_melody` | 0.923 | 0.969 | +0.046 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `combined_first_second_third_species_melody` | 0.912 | 0.964 | +0.052 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `fifth_species_melody` | 0.846 | 0.542 | -0.304 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `arch_contour_melody` | 0.967 | 0.970 | +0.003 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `ascending_contour_melody` | 0.585 | 0.588 | +0.003 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `descending_contour_melody` | 0.585 | 0.588 | +0.003 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `static_contour_melody` | 0.585 | 0.588 | +0.003 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `valley_contour_melody` | 0.585 | 0.588 | +0.003 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `wave_contour_melody` | 0.967 | 0.970 | +0.003 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-7-v1 | 0 | `first_species_melody` | 0.934 | 0.000* | -0.934 | no | gated |
| fux_cantus_firmus_examples_with_errors-7-v1 | 0 | `first_species_harmony` | 0.889 | 0.000* | -0.889 | no | gated |
| fux_cantus_firmus_examples_with_errors-7-v1 | 0 | `second_species_melody` | 0.941 | 0.000* | -0.941 | no | gated |
| fux_cantus_firmus_examples_with_errors-7-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-7-v1 | 0 | `third_species_melody` | 0.941 | 0.000* | -0.941 | no | gated |
| fux_cantus_firmus_examples_with_errors-7-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-7-v1 | 0 | `third_species_triple_meter_melody` | 0.941 | 0.000* | -0.941 | no | gated |
| fux_cantus_firmus_examples_with_errors-7-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-7-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| fux_cantus_firmus_examples_with_errors-7-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-7-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-7-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-7-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-7-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-8-v0 | 11 | `fux_cantus_firmus` | 0.975 | 0.976 | +0.002 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-8-v0 | 11 | `salzer_schachter_cantus_firmus` | 0.976 | 0.978 | +0.001 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-8-v0 | 11 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-8-v0 | 11 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-8-v0 | 11 | `second_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-8-v0 | 11 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-8-v0 | 11 | `third_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-8-v0 | 11 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-8-v0 | 11 | `third_species_triple_meter_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-8-v0 | 11 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-8-v0 | 11 | `fourth_species_melody` | 0.952 | 0.981 | +0.028 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-8-v0 | 11 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-8-v0 | 11 | `combined_first_second_third_species_melody` | 0.945 | 0.978 | +0.032 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-8-v0 | 11 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-8-v0 | 11 | `fifth_species_melody` | 0.874 | 0.556 | -0.318 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-8-v0 | 11 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-8-v1 | 0 | `first_species_melody` | 0.934 | 0.000* | -0.934 | no | gated |
| fux_cantus_firmus_examples_with_errors-8-v1 | 0 | `first_species_harmony` | 0.889 | 0.000* | -0.889 | no | gated |
| fux_cantus_firmus_examples_with_errors-8-v1 | 0 | `second_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples_with_errors-8-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-8-v1 | 0 | `third_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples_with_errors-8-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-8-v1 | 0 | `third_species_triple_meter_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples_with_errors-8-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-8-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| fux_cantus_firmus_examples_with_errors-8-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-8-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-8-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-8-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-8-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-9-v0 | 11 | `fux_cantus_firmus` | 0.959 | 0.961 | +0.003 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-9-v0 | 11 | `salzer_schachter_cantus_firmus` | 0.961 | 0.964 | +0.002 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-9-v0 | 11 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-9-v0 | 11 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-9-v0 | 11 | `second_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-9-v0 | 11 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-9-v0 | 11 | `third_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-9-v0 | 11 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-9-v0 | 11 | `third_species_triple_meter_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-9-v0 | 11 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-9-v0 | 11 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-9-v0 | 11 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-9-v0 | 11 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-9-v0 | 11 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-9-v0 | 11 | `fifth_species_melody` | 0.897 | 0.570 | -0.328 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-9-v0 | 11 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-9-v1 | 0 | `first_species_melody` | 0.934 | 0.000* | -0.934 | no | gated |
| fux_cantus_firmus_examples_with_errors-9-v1 | 0 | `first_species_harmony` | 0.889 | 0.000* | -0.889 | no | gated |
| fux_cantus_firmus_examples_with_errors-9-v1 | 0 | `second_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples_with_errors-9-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-9-v1 | 0 | `third_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples_with_errors-9-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-9-v1 | 0 | `third_species_triple_meter_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples_with_errors-9-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-9-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| fux_cantus_firmus_examples_with_errors-9-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-9-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-9-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-9-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-9-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-10-v0 | 10 | `fux_cantus_firmus` | 0.975 | 0.976 | +0.002 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-10-v0 | 10 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-10-v0 | 10 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-10-v0 | 10 | `second_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-10-v0 | 10 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-10-v0 | 10 | `third_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-10-v0 | 10 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-10-v0 | 10 | `third_species_triple_meter_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-10-v0 | 10 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-10-v0 | 10 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-10-v0 | 10 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-10-v0 | 10 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-10-v0 | 10 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-10-v0 | 10 | `fifth_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-10-v0 | 10 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-10-v1 | 0 | `first_species_melody` | 0.935 | 0.000* | -0.935 | no | gated |
| fux_cantus_firmus_examples_with_errors-10-v1 | 0 | `first_species_harmony` | 0.890 | 0.000* | -0.890 | no | gated |
| fux_cantus_firmus_examples_with_errors-10-v1 | 0 | `second_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples_with_errors-10-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-10-v1 | 0 | `third_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples_with_errors-10-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-10-v1 | 0 | `third_species_triple_meter_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples_with_errors-10-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-10-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| fux_cantus_firmus_examples_with_errors-10-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-10-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-10-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-10-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-10-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `fux_cantus_firmus` | 0.975 | 0.976 | +0.002 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `salzer_schachter_cantus_firmus` | 0.976 | 0.978 | +0.001 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `diatonic_melody` | 0.962 | 0.965 | +0.003 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `first_species_melody` | 0.949 | 0.978 | +0.028 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `second_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `third_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `third_species_triple_meter_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `fourth_species_melody` | 0.952 | 0.981 | +0.028 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `combined_first_second_third_species_melody` | 0.945 | 0.978 | +0.032 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `fifth_species_melody` | 0.875 | 0.560 | -0.315 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `arch_contour_melody` | 0.985 | 0.987 | +0.001 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `ascending_contour_melody` | 0.603 | 0.605 | +0.001 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `descending_contour_melody` | 0.603 | 0.605 | +0.001 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `static_contour_melody` | 0.603 | 0.605 | +0.001 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `valley_contour_melody` | 0.603 | 0.605 | +0.001 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `wave_contour_melody` | 0.603 | 0.605 | +0.001 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-11-v1 | 0 | `first_species_melody` | 0.936 | 0.000* | -0.936 | no | gated |
| fux_cantus_firmus_examples_with_errors-11-v1 | 0 | `first_species_harmony` | 0.890 | 0.000* | -0.890 | no | gated |
| fux_cantus_firmus_examples_with_errors-11-v1 | 0 | `second_species_melody` | 0.943 | 0.000* | -0.943 | no | gated |
| fux_cantus_firmus_examples_with_errors-11-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-11-v1 | 0 | `third_species_melody` | 0.943 | 0.000* | -0.943 | no | gated |
| fux_cantus_firmus_examples_with_errors-11-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-11-v1 | 0 | `third_species_triple_meter_melody` | 0.943 | 0.000* | -0.943 | no | gated |
| fux_cantus_firmus_examples_with_errors-11-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-11-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| fux_cantus_firmus_examples_with_errors-11-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-11-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-11-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-11-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-11-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `fux_cantus_firmus` | 0.907 | 0.913 | +0.006 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `salzer_schachter_cantus_firmus` | 0.913 | 0.918 | +0.005 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `diatonic_melody` | 0.902 | 0.911 | +0.009 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `first_species_melody` | 0.884 | 0.949 | +0.065 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `second_species_melody` | 0.875 | 0.838 | -0.037 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `third_species_melody` | 0.875 | 0.838 | -0.037 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `third_species_triple_meter_melody` | 0.875 | 0.838 | -0.037 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `fourth_species_melody` | 0.891 | 0.956 | +0.065 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `combined_first_second_third_species_melody` | 0.876 | 0.949 | +0.073 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `fifth_species_melody` | 0.816 | 0.529 | -0.287 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `arch_contour_melody` | 0.963 | 0.966 | +0.003 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `ascending_contour_melody` | 0.581 | 0.584 | +0.003 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `descending_contour_melody` | 0.581 | 0.584 | +0.003 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `static_contour_melody` | 0.581 | 0.584 | +0.003 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `valley_contour_melody` | 0.581 | 0.584 | +0.003 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `wave_contour_melody` | 0.963 | 0.966 | +0.003 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-12-v1 | 0 | `first_species_melody` | 0.933 | 0.000* | -0.933 | no | gated |
| fux_cantus_firmus_examples_with_errors-12-v1 | 0 | `first_species_harmony` | 0.889 | 0.000* | -0.889 | no | gated |
| fux_cantus_firmus_examples_with_errors-12-v1 | 0 | `second_species_melody` | 0.941 | 0.000* | -0.941 | no | gated |
| fux_cantus_firmus_examples_with_errors-12-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-12-v1 | 0 | `third_species_melody` | 0.941 | 0.000* | -0.941 | no | gated |
| fux_cantus_firmus_examples_with_errors-12-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-12-v1 | 0 | `third_species_triple_meter_melody` | 0.941 | 0.000* | -0.941 | no | gated |
| fux_cantus_firmus_examples_with_errors-12-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-12-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| fux_cantus_firmus_examples_with_errors-12-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-12-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-12-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-12-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-12-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-13-v0 | 12 | `fux_cantus_firmus` | 0.975 | 0.976 | +0.002 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-13-v0 | 12 | `salzer_schachter_cantus_firmus` | 0.976 | 0.978 | +0.001 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-13-v0 | 12 | `first_species_melody` | 0.949 | 0.978 | +0.028 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-13-v0 | 12 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-13-v0 | 12 | `second_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-13-v0 | 12 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-13-v0 | 12 | `third_species_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-13-v0 | 12 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-13-v0 | 12 | `third_species_triple_meter_melody` | 0.933 | 0.863 | -0.070 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-13-v0 | 12 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-13-v0 | 12 | `fourth_species_melody` | 0.952 | 0.981 | +0.028 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-13-v0 | 12 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-13-v0 | 12 | `combined_first_second_third_species_melody` | 0.945 | 0.978 | +0.032 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-13-v0 | 12 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-13-v0 | 12 | `fifth_species_melody` | 0.874 | 0.555 | -0.319 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-13-v0 | 12 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-13-v1 | 0 | `first_species_melody` | 0.934 | 0.000* | -0.934 | no | gated |
| fux_cantus_firmus_examples_with_errors-13-v1 | 0 | `first_species_harmony` | 0.889 | 0.000* | -0.889 | no | gated |
| fux_cantus_firmus_examples_with_errors-13-v1 | 0 | `second_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples_with_errors-13-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-13-v1 | 0 | `third_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples_with_errors-13-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-13-v1 | 0 | `third_species_triple_meter_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples_with_errors-13-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-13-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| fux_cantus_firmus_examples_with_errors-13-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-13-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-13-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-13-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-13-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-14-v0 | 10 | `fux_cantus_firmus` | 0.975 | 0.976 | +0.002 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-14-v0 | 10 | `salzer_schachter_cantus_firmus` | 0.976 | 0.978 | +0.001 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-14-v0 | 10 | `first_species_melody` | 0.959 | 0.982 | +0.023 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-14-v0 | 10 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-14-v0 | 10 | `second_species_melody` | 0.941 | 0.866 | -0.075 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-14-v0 | 10 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-14-v0 | 10 | `third_species_melody` | 0.941 | 0.866 | -0.075 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-14-v0 | 10 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-14-v0 | 10 | `third_species_triple_meter_melody` | 0.941 | 0.866 | -0.075 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-14-v0 | 10 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-14-v0 | 10 | `fourth_species_melody` | 0.961 | 0.984 | +0.023 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-14-v0 | 10 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-14-v0 | 10 | `combined_first_second_third_species_melody` | 0.956 | 0.982 | +0.026 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-14-v0 | 10 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-14-v0 | 10 | `fifth_species_melody` | 0.883 | 0.561 | -0.322 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-14-v0 | 10 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-14-v1 | 0 | `first_species_melody` | 0.935 | 0.000* | -0.935 | no | gated |
| fux_cantus_firmus_examples_with_errors-14-v1 | 0 | `first_species_harmony` | 0.890 | 0.000* | -0.890 | no | gated |
| fux_cantus_firmus_examples_with_errors-14-v1 | 0 | `second_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples_with_errors-14-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-14-v1 | 0 | `third_species_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples_with_errors-14-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-14-v1 | 0 | `third_species_triple_meter_melody` | 0.942 | 0.000* | -0.942 | no | gated |
| fux_cantus_firmus_examples_with_errors-14-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-14-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| fux_cantus_firmus_examples_with_errors-14-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-14-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-14-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-14-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-14-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-15-v0 | 15 | `fux_cantus_firmus` | 0.998 | 0.998 | +0.000 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-15-v0 | 15 | `salzer_schachter_cantus_firmus` | 0.998 | 0.998 | +0.000 | yes | threshold split |
| fux_cantus_firmus_examples_with_errors-15-v0 | 15 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-15-v0 | 15 | `first_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-15-v0 | 15 | `second_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-15-v0 | 15 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-15-v0 | 15 | `third_species_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-15-v0 | 15 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-15-v0 | 15 | `third_species_triple_meter_melody` | 0.955 | 0.872 | -0.083 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-15-v0 | 15 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-15-v0 | 15 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-15-v0 | 15 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-15-v0 | 15 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-15-v0 | 15 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-15-v0 | 15 | `fifth_species_melody` | 0.896 | 0.564 | -0.333 | yes | demoted |
| fux_cantus_firmus_examples_with_errors-15-v0 | 15 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-15-v1 | 0 | `first_species_melody` | 0.933 | 0.000* | -0.933 | no | gated |
| fux_cantus_firmus_examples_with_errors-15-v1 | 0 | `first_species_harmony` | 0.889 | 0.000* | -0.889 | no | gated |
| fux_cantus_firmus_examples_with_errors-15-v1 | 0 | `second_species_melody` | 0.941 | 0.000* | -0.941 | no | gated |
| fux_cantus_firmus_examples_with_errors-15-v1 | 0 | `second_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-15-v1 | 0 | `third_species_melody` | 0.941 | 0.000* | -0.941 | no | gated |
| fux_cantus_firmus_examples_with_errors-15-v1 | 0 | `third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-15-v1 | 0 | `third_species_triple_meter_melody` | 0.941 | 0.000* | -0.941 | no | gated |
| fux_cantus_firmus_examples_with_errors-15-v1 | 0 | `third_species_triple_meter_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-15-v1 | 0 | `fourth_species_melody` | 0.938 | 0.000* | -0.938 | no | gated |
| fux_cantus_firmus_examples_with_errors-15-v1 | 0 | `fourth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-15-v1 | 0 | `combined_first_second_third_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-15-v1 | 0 | `combined_first_second_third_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-15-v1 | 0 | `fifth_species_melody` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_cantus_firmus_examples_with_errors-15-v1 | 0 | `fifth_species_harmony` | 1.000 | 0.000* | -1.000 | no | gated |
| fux_first_species_examples-0-v0 | 11 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_first_species_examples-0-v0 | 11 | `second_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| fux_first_species_examples-0-v0 | 11 | `third_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| fux_first_species_examples-0-v0 | 11 | `third_species_triple_meter_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| fux_first_species_examples-0-v0 | 11 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_first_species_examples-0-v0 | 11 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_first_species_examples-0-v0 | 11 | `fifth_species_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| fux_first_species_examples-0-v1 | 11 | `fux_cantus_firmus` | 0.908 | 0.914 | +0.006 | yes | threshold split |
| fux_first_species_examples-0-v1 | 11 | `salzer_schachter_cantus_firmus` | 0.938 | 0.941 | +0.004 | yes | threshold split |
| fux_first_species_examples-0-v1 | 11 | `second_species_melody` | 0.883 | 0.561 | -0.322 | yes | demoted |
| fux_first_species_examples-0-v1 | 11 | `third_species_melody` | 0.883 | 0.561 | -0.322 | yes | demoted |
| fux_first_species_examples-0-v1 | 11 | `third_species_triple_meter_melody` | 0.883 | 0.561 | -0.322 | yes | demoted |
| fux_first_species_examples-0-v1 | 11 | `fourth_species_melody` | 0.961 | 0.984 | +0.023 | yes | demoted |
| fux_first_species_examples-0-v1 | 11 | `combined_first_second_third_species_melody` | 0.956 | 0.982 | +0.026 | yes | demoted |
| fux_first_species_examples-0-v1 | 11 | `fifth_species_melody` | 0.883 | 0.560 | -0.323 | yes | demoted |
| fux_first_species_examples-1-v0 | 11 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_first_species_examples-1-v0 | 11 | `second_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| fux_first_species_examples-1-v0 | 11 | `third_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| fux_first_species_examples-1-v0 | 11 | `third_species_triple_meter_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| fux_first_species_examples-1-v0 | 11 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_first_species_examples-1-v0 | 11 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_first_species_examples-1-v0 | 11 | `fifth_species_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| fux_first_species_examples-1-v1 | 11 | `fux_cantus_firmus` | 0.924 | 0.928 | +0.005 | yes | threshold split |
| fux_first_species_examples-1-v1 | 11 | `salzer_schachter_cantus_firmus` | 0.976 | 0.978 | +0.001 | yes | threshold split |
| fux_first_species_examples-1-v1 | 11 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_first_species_examples-1-v1 | 11 | `second_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| fux_first_species_examples-1-v1 | 11 | `third_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| fux_first_species_examples-1-v1 | 11 | `third_species_triple_meter_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| fux_first_species_examples-1-v1 | 11 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_first_species_examples-1-v1 | 11 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_first_species_examples-1-v1 | 11 | `fifth_species_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| fux_first_species_examples-2-v0 | 11 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_first_species_examples-2-v0 | 11 | `second_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| fux_first_species_examples-2-v0 | 11 | `third_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| fux_first_species_examples-2-v0 | 11 | `third_species_triple_meter_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| fux_first_species_examples-2-v0 | 11 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_first_species_examples-2-v0 | 11 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_first_species_examples-2-v0 | 11 | `fifth_species_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| fux_first_species_examples-2-v1 | 11 | `fux_cantus_firmus` | 0.924 | 0.928 | +0.005 | yes | threshold split |
| fux_first_species_examples-2-v1 | 11 | `salzer_schachter_cantus_firmus` | 0.976 | 0.978 | +0.001 | yes | threshold split |
| fux_first_species_examples-2-v1 | 11 | `second_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| fux_first_species_examples-2-v1 | 11 | `third_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| fux_first_species_examples-2-v1 | 11 | `third_species_triple_meter_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| fux_first_species_examples-2-v1 | 11 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_first_species_examples-2-v1 | 11 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_first_species_examples-2-v1 | 11 | `fifth_species_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| fux_first_species_examples-3-v0 | 10 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_first_species_examples-3-v0 | 10 | `second_species_melody` | 0.897 | 0.570 | -0.328 | yes | demoted |
| fux_first_species_examples-3-v0 | 10 | `third_species_melody` | 0.897 | 0.570 | -0.328 | yes | demoted |
| fux_first_species_examples-3-v0 | 10 | `third_species_triple_meter_melody` | 0.897 | 0.570 | -0.328 | yes | demoted |
| fux_first_species_examples-3-v0 | 10 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_first_species_examples-3-v0 | 10 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_first_species_examples-3-v0 | 10 | `fifth_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| fux_first_species_examples-3-v1 | 10 | `fux_cantus_firmus` | 0.949 | 0.952 | +0.003 | yes | threshold split |
| fux_first_species_examples-3-v1 | 10 | `salzer_schachter_cantus_firmus` | 0.976 | 0.978 | +0.001 | yes | threshold split |
| fux_first_species_examples-3-v1 | 10 | `second_species_melody` | 0.920 | 0.580 | -0.340 | yes | demoted |
| fux_first_species_examples-3-v1 | 10 | `third_species_melody` | 0.920 | 0.580 | -0.340 | yes | demoted |
| fux_first_species_examples-3-v1 | 10 | `third_species_triple_meter_melody` | 0.920 | 0.580 | -0.340 | yes | demoted |
| fux_first_species_examples-3-v1 | 10 | `fifth_species_melody` | 0.919 | 0.577 | -0.342 | yes | demoted |
| fux_first_species_examples-4-v0 | 10 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_first_species_examples-4-v0 | 10 | `second_species_melody` | 0.897 | 0.570 | -0.328 | yes | demoted |
| fux_first_species_examples-4-v0 | 10 | `third_species_melody` | 0.897 | 0.570 | -0.328 | yes | demoted |
| fux_first_species_examples-4-v0 | 10 | `third_species_triple_meter_melody` | 0.897 | 0.570 | -0.328 | yes | demoted |
| fux_first_species_examples-4-v0 | 10 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_first_species_examples-4-v0 | 10 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_first_species_examples-4-v0 | 10 | `fifth_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| fux_first_species_examples-4-v1 | 10 | `fux_cantus_firmus` | 0.882 | 0.890 | +0.007 | yes | threshold split |
| fux_first_species_examples-4-v1 | 10 | `salzer_schachter_cantus_firmus` | 0.928 | 0.933 | +0.004 | yes | threshold split |
| fux_first_species_examples-4-v1 | 10 | `diatonic_melody` | 0.924 | 0.931 | +0.007 | yes | threshold split |
| fux_first_species_examples-4-v1 | 10 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_first_species_examples-4-v1 | 10 | `second_species_melody` | 0.875 | 0.560 | -0.315 | yes | demoted |
| fux_first_species_examples-4-v1 | 10 | `third_species_melody` | 0.875 | 0.560 | -0.315 | yes | demoted |
| fux_first_species_examples-4-v1 | 10 | `third_species_triple_meter_melody` | 0.875 | 0.560 | -0.315 | yes | demoted |
| fux_first_species_examples-4-v1 | 10 | `fourth_species_melody` | 0.952 | 0.981 | +0.028 | yes | demoted |
| fux_first_species_examples-4-v1 | 10 | `combined_first_second_third_species_melody` | 0.945 | 0.978 | +0.032 | yes | demoted |
| fux_first_species_examples-4-v1 | 10 | `fifth_species_melody` | 0.875 | 0.558 | -0.317 | yes | demoted |
| fux_first_species_examples-4-v1 | 10 | `arch_contour_melody` | 0.589 | 0.592 | +0.003 | yes | threshold split |
| fux_first_species_examples-4-v1 | 10 | `ascending_contour_melody` | 0.589 | 0.592 | +0.003 | yes | threshold split |
| fux_first_species_examples-4-v1 | 10 | `descending_contour_melody` | 0.589 | 0.592 | +0.003 | yes | threshold split |
| fux_first_species_examples-4-v1 | 10 | `static_contour_melody` | 0.589 | 0.592 | +0.003 | yes | threshold split |
| fux_first_species_examples-4-v1 | 10 | `valley_contour_melody` | 0.971 | 0.973 | +0.003 | yes | threshold split |
| fux_first_species_examples-4-v1 | 10 | `wave_contour_melody` | 0.971 | 0.973 | +0.003 | yes | threshold split |
| fux_first_species_examples-5-v0 | 10 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_first_species_examples-5-v0 | 10 | `second_species_melody` | 0.897 | 0.570 | -0.328 | yes | demoted |
| fux_first_species_examples-5-v0 | 10 | `third_species_melody` | 0.897 | 0.570 | -0.328 | yes | demoted |
| fux_first_species_examples-5-v0 | 10 | `third_species_triple_meter_melody` | 0.897 | 0.570 | -0.328 | yes | demoted |
| fux_first_species_examples-5-v0 | 10 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_first_species_examples-5-v0 | 10 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_first_species_examples-5-v0 | 10 | `fifth_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| fux_first_species_examples-5-v1 | 10 | `fux_cantus_firmus` | 0.892 | 0.899 | +0.007 | yes | threshold split |
| fux_first_species_examples-5-v1 | 10 | `salzer_schachter_cantus_firmus` | 0.938 | 0.941 | +0.004 | yes | threshold split |
| fux_first_species_examples-5-v1 | 10 | `diatonic_melody` | 0.962 | 0.965 | +0.003 | yes | threshold split |
| fux_first_species_examples-5-v1 | 10 | `second_species_melody` | 0.884 | 0.564 | -0.320 | yes | demoted |
| fux_first_species_examples-5-v1 | 10 | `third_species_melody` | 0.884 | 0.564 | -0.320 | yes | demoted |
| fux_first_species_examples-5-v1 | 10 | `third_species_triple_meter_melody` | 0.884 | 0.564 | -0.320 | yes | demoted |
| fux_first_species_examples-5-v1 | 10 | `fourth_species_melody` | 0.961 | 0.984 | +0.023 | yes | demoted |
| fux_first_species_examples-5-v1 | 10 | `combined_first_second_third_species_melody` | 0.956 | 0.982 | +0.026 | yes | demoted |
| fux_first_species_examples-5-v1 | 10 | `fifth_species_melody` | 0.883 | 0.561 | -0.322 | yes | demoted |
| fux_first_species_examples-5-v1 | 10 | `arch_contour_melody` | 0.603 | 0.605 | +0.001 | yes | threshold split |
| fux_first_species_examples-5-v1 | 10 | `ascending_contour_melody` | 0.603 | 0.605 | +0.001 | yes | threshold split |
| fux_first_species_examples-5-v1 | 10 | `descending_contour_melody` | 0.603 | 0.605 | +0.001 | yes | threshold split |
| fux_first_species_examples-5-v1 | 10 | `static_contour_melody` | 0.603 | 0.605 | +0.001 | yes | threshold split |
| fux_first_species_examples-5-v1 | 10 | `valley_contour_melody` | 0.985 | 0.987 | +0.001 | yes | threshold split |
| fux_first_species_examples-5-v1 | 10 | `wave_contour_melody` | 0.985 | 0.987 | +0.001 | yes | threshold split |
| fux_first_species_examples-6-v0 | 12 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_first_species_examples-6-v0 | 12 | `second_species_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| fux_first_species_examples-6-v0 | 12 | `third_species_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| fux_first_species_examples-6-v0 | 12 | `third_species_triple_meter_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| fux_first_species_examples-6-v0 | 12 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_first_species_examples-6-v0 | 12 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_first_species_examples-6-v0 | 12 | `fifth_species_melody` | 0.897 | 0.565 | -0.332 | yes | demoted |
| fux_first_species_examples-6-v1 | 12 | `fux_cantus_firmus` | 0.908 | 0.914 | +0.006 | yes | threshold split |
| fux_first_species_examples-6-v1 | 12 | `salzer_schachter_cantus_firmus` | 0.976 | 0.978 | +0.001 | yes | threshold split |
| fux_first_species_examples-6-v1 | 12 | `second_species_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| fux_first_species_examples-6-v1 | 12 | `third_species_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| fux_first_species_examples-6-v1 | 12 | `third_species_triple_meter_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| fux_first_species_examples-6-v1 | 12 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_first_species_examples-6-v1 | 12 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_first_species_examples-6-v1 | 12 | `fifth_species_melody` | 0.897 | 0.565 | -0.332 | yes | demoted |
| fux_first_species_examples-7-v0 | 12 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_first_species_examples-7-v0 | 12 | `second_species_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| fux_first_species_examples-7-v0 | 12 | `third_species_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| fux_first_species_examples-7-v0 | 12 | `third_species_triple_meter_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| fux_first_species_examples-7-v0 | 12 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_first_species_examples-7-v0 | 12 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_first_species_examples-7-v0 | 12 | `fifth_species_melody` | 0.897 | 0.565 | -0.332 | yes | demoted |
| fux_first_species_examples-7-v1 | 12 | `fux_cantus_firmus` | 0.975 | 0.976 | +0.002 | yes | threshold split |
| fux_first_species_examples-7-v1 | 12 | `second_species_melody` | 0.919 | 0.575 | -0.344 | yes | demoted |
| fux_first_species_examples-7-v1 | 12 | `third_species_melody` | 0.919 | 0.575 | -0.344 | yes | demoted |
| fux_first_species_examples-7-v1 | 12 | `third_species_triple_meter_melody` | 0.919 | 0.575 | -0.344 | yes | demoted |
| fux_first_species_examples-7-v1 | 12 | `fifth_species_melody` | 0.919 | 0.575 | -0.345 | yes | demoted |
| fux_first_species_examples-8-v0 | 14 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_first_species_examples-8-v0 | 14 | `second_species_melody` | 0.896 | 0.564 | -0.332 | yes | demoted |
| fux_first_species_examples-8-v0 | 14 | `third_species_melody` | 0.896 | 0.564 | -0.332 | yes | demoted |
| fux_first_species_examples-8-v0 | 14 | `third_species_triple_meter_melody` | 0.896 | 0.564 | -0.332 | yes | demoted |
| fux_first_species_examples-8-v0 | 14 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_first_species_examples-8-v0 | 14 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_first_species_examples-8-v0 | 14 | `fifth_species_melody` | 0.896 | 0.564 | -0.333 | yes | demoted |
| fux_first_species_examples-8-v1 | 14 | `fux_cantus_firmus` | 0.867 | 0.875 | +0.008 | yes | threshold split |
| fux_first_species_examples-8-v1 | 14 | `salzer_schachter_cantus_firmus` | 0.938 | 0.941 | +0.004 | yes | threshold split |
| fux_first_species_examples-8-v1 | 14 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_first_species_examples-8-v1 | 14 | `second_species_melody` | 0.860 | 0.548 | -0.312 | yes | demoted |
| fux_first_species_examples-8-v1 | 14 | `third_species_melody` | 0.860 | 0.548 | -0.312 | yes | demoted |
| fux_first_species_examples-8-v1 | 14 | `third_species_triple_meter_melody` | 0.860 | 0.548 | -0.312 | yes | demoted |
| fux_first_species_examples-8-v1 | 14 | `fourth_species_melody` | 0.938 | 0.975 | +0.037 | yes | demoted |
| fux_first_species_examples-8-v1 | 14 | `combined_first_second_third_species_melody` | 0.929 | 0.971 | +0.042 | yes | demoted |
| fux_first_species_examples-8-v1 | 14 | `fifth_species_melody` | 0.860 | 0.548 | -0.312 | yes | demoted |
| fux_first_species_examples-9-v0 | 14 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_first_species_examples-9-v0 | 14 | `second_species_melody` | 0.896 | 0.564 | -0.332 | yes | demoted |
| fux_first_species_examples-9-v0 | 14 | `third_species_melody` | 0.896 | 0.564 | -0.332 | yes | demoted |
| fux_first_species_examples-9-v0 | 14 | `third_species_triple_meter_melody` | 0.896 | 0.564 | -0.332 | yes | demoted |
| fux_first_species_examples-9-v0 | 14 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_first_species_examples-9-v0 | 14 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_first_species_examples-9-v0 | 14 | `fifth_species_melody` | 0.896 | 0.564 | -0.333 | yes | demoted |
| fux_first_species_examples-9-v1 | 14 | `fux_cantus_firmus` | 0.892 | 0.899 | +0.007 | yes | threshold split |
| fux_first_species_examples-9-v1 | 14 | `salzer_schachter_cantus_firmus` | 0.961 | 0.964 | +0.002 | yes | threshold split |
| fux_first_species_examples-9-v1 | 14 | `second_species_melody` | 0.883 | 0.558 | -0.324 | yes | demoted |
| fux_first_species_examples-9-v1 | 14 | `third_species_melody` | 0.883 | 0.558 | -0.324 | yes | demoted |
| fux_first_species_examples-9-v1 | 14 | `third_species_triple_meter_melody` | 0.883 | 0.558 | -0.324 | yes | demoted |
| fux_first_species_examples-9-v1 | 14 | `fourth_species_melody` | 0.961 | 0.984 | +0.023 | yes | demoted |
| fux_first_species_examples-9-v1 | 14 | `combined_first_second_third_species_melody` | 0.956 | 0.982 | +0.026 | yes | demoted |
| fux_first_species_examples-9-v1 | 14 | `fifth_species_melody` | 0.882 | 0.558 | -0.325 | yes | demoted |
| fux_first_species_examples-10-v0 | 14 | `first_species_melody` | 0.949 | 0.978 | +0.028 | yes | demoted |
| fux_first_species_examples-10-v0 | 14 | `second_species_melody` | 0.874 | 0.554 | -0.319 | yes | demoted |
| fux_first_species_examples-10-v0 | 14 | `third_species_melody` | 0.874 | 0.554 | -0.319 | yes | demoted |
| fux_first_species_examples-10-v0 | 14 | `third_species_triple_meter_melody` | 0.874 | 0.554 | -0.319 | yes | demoted |
| fux_first_species_examples-10-v0 | 14 | `fourth_species_melody` | 0.952 | 0.981 | +0.028 | yes | demoted |
| fux_first_species_examples-10-v0 | 14 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_first_species_examples-10-v0 | 14 | `fifth_species_melody` | 0.874 | 0.554 | -0.320 | yes | demoted |
| fux_first_species_examples-10-v1 | 14 | `fux_cantus_firmus` | 0.924 | 0.928 | +0.005 | yes | threshold split |
| fux_first_species_examples-10-v1 | 14 | `salzer_schachter_cantus_firmus` | 0.952 | 0.955 | +0.003 | yes | threshold split |
| fux_first_species_examples-10-v1 | 14 | `diatonic_melody` | 0.962 | 0.965 | +0.003 | yes | threshold split |
| fux_first_species_examples-10-v1 | 14 | `second_species_melody` | 0.896 | 0.564 | -0.332 | yes | demoted |
| fux_first_species_examples-10-v1 | 14 | `third_species_melody` | 0.896 | 0.564 | -0.332 | yes | demoted |
| fux_first_species_examples-10-v1 | 14 | `third_species_triple_meter_melody` | 0.896 | 0.564 | -0.332 | yes | demoted |
| fux_first_species_examples-10-v1 | 14 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_first_species_examples-10-v1 | 14 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_first_species_examples-10-v1 | 14 | `fifth_species_melody` | 0.896 | 0.564 | -0.333 | yes | demoted |
| fux_first_species_examples-10-v1 | 14 | `arch_contour_melody` | 0.985 | 0.987 | +0.001 | yes | threshold split |
| fux_first_species_examples-10-v1 | 14 | `ascending_contour_melody` | 0.603 | 0.605 | +0.001 | yes | threshold split |
| fux_first_species_examples-10-v1 | 14 | `descending_contour_melody` | 0.603 | 0.605 | +0.001 | yes | threshold split |
| fux_first_species_examples-10-v1 | 14 | `static_contour_melody` | 0.603 | 0.605 | +0.001 | yes | threshold split |
| fux_first_species_examples-10-v1 | 14 | `valley_contour_melody` | 0.985 | 0.987 | +0.001 | yes | threshold split |
| fux_first_species_examples-10-v1 | 14 | `wave_contour_melody` | 0.985 | 0.987 | +0.001 | yes | threshold split |
| fux_first_species_examples-11-v0 | 12 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| fux_first_species_examples-11-v0 | 12 | `second_species_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| fux_first_species_examples-11-v0 | 12 | `third_species_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| fux_first_species_examples-11-v0 | 12 | `third_species_triple_meter_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| fux_first_species_examples-11-v0 | 12 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_first_species_examples-11-v0 | 12 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_first_species_examples-11-v0 | 12 | `fifth_species_melody` | 0.897 | 0.565 | -0.332 | yes | demoted |
| fux_first_species_examples-11-v1 | 12 | `fux_cantus_firmus` | 0.924 | 0.928 | +0.005 | yes | threshold split |
| fux_first_species_examples-11-v1 | 12 | `salzer_schachter_cantus_firmus` | 0.976 | 0.978 | +0.001 | yes | threshold split |
| fux_first_species_examples-11-v1 | 12 | `second_species_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| fux_first_species_examples-11-v1 | 12 | `third_species_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| fux_first_species_examples-11-v1 | 12 | `third_species_triple_meter_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| fux_first_species_examples-11-v1 | 12 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| fux_first_species_examples-11-v1 | 12 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_first_species_examples-11-v1 | 12 | `fifth_species_melody` | 0.897 | 0.565 | -0.332 | yes | demoted |
| fux_first_species_examples-12-v0 | 12 | `first_species_melody` | 0.949 | 0.978 | +0.028 | yes | demoted |
| fux_first_species_examples-12-v0 | 12 | `second_species_melody` | 0.874 | 0.556 | -0.318 | yes | demoted |
| fux_first_species_examples-12-v0 | 12 | `third_species_melody` | 0.874 | 0.556 | -0.318 | yes | demoted |
| fux_first_species_examples-12-v0 | 12 | `third_species_triple_meter_melody` | 0.874 | 0.556 | -0.318 | yes | demoted |
| fux_first_species_examples-12-v0 | 12 | `fourth_species_melody` | 0.952 | 0.981 | +0.028 | yes | demoted |
| fux_first_species_examples-12-v0 | 12 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| fux_first_species_examples-12-v0 | 12 | `fifth_species_melody` | 0.874 | 0.555 | -0.319 | yes | demoted |
| fux_first_species_examples-12-v1 | 12 | `fux_cantus_firmus` | 0.908 | 0.914 | +0.006 | yes | threshold split |
| fux_first_species_examples-12-v1 | 12 | `salzer_schachter_cantus_firmus` | 0.961 | 0.964 | +0.002 | yes | threshold split |
| fux_first_species_examples-12-v1 | 12 | `second_species_melody` | 0.883 | 0.560 | -0.323 | yes | demoted |
| fux_first_species_examples-12-v1 | 12 | `third_species_melody` | 0.883 | 0.560 | -0.323 | yes | demoted |
| fux_first_species_examples-12-v1 | 12 | `third_species_triple_meter_melody` | 0.883 | 0.560 | -0.323 | yes | demoted |
| fux_first_species_examples-12-v1 | 12 | `fourth_species_melody` | 0.961 | 0.984 | +0.023 | yes | demoted |
| fux_first_species_examples-12-v1 | 12 | `combined_first_second_third_species_melody` | 0.956 | 0.982 | +0.026 | yes | demoted |
| fux_first_species_examples-12-v1 | 12 | `fifth_species_melody` | 0.883 | 0.559 | -0.324 | yes | demoted |
| clendinning_first_species_examples-0-v0 | 12 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| clendinning_first_species_examples-0-v0 | 12 | `second_species_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| clendinning_first_species_examples-0-v0 | 12 | `third_species_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| clendinning_first_species_examples-0-v0 | 12 | `third_species_triple_meter_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| clendinning_first_species_examples-0-v0 | 12 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| clendinning_first_species_examples-0-v0 | 12 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| clendinning_first_species_examples-0-v0 | 12 | `fifth_species_melody` | 0.897 | 0.565 | -0.332 | yes | demoted |
| clendinning_first_species_examples-0-v1 | 12 | `fux_cantus_firmus` | 0.975 | 0.976 | +0.002 | yes | threshold split |
| clendinning_first_species_examples-0-v1 | 12 | `second_species_melody` | 0.919 | 0.575 | -0.344 | yes | demoted |
| clendinning_first_species_examples-0-v1 | 12 | `third_species_melody` | 0.919 | 0.575 | -0.344 | yes | demoted |
| clendinning_first_species_examples-0-v1 | 12 | `third_species_triple_meter_melody` | 0.919 | 0.575 | -0.344 | yes | demoted |
| clendinning_first_species_examples-0-v1 | 12 | `fifth_species_melody` | 0.919 | 0.575 | -0.345 | yes | demoted |
| clendinning_first_species_examples-1-v0 | 9 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| clendinning_first_species_examples-1-v0 | 9 | `second_species_melody` | 0.898 | 0.574 | -0.324 | yes | demoted |
| clendinning_first_species_examples-1-v0 | 9 | `third_species_melody` | 0.898 | 0.574 | -0.324 | yes | demoted |
| clendinning_first_species_examples-1-v0 | 9 | `third_species_triple_meter_melody` | 0.898 | 0.574 | -0.324 | yes | demoted |
| clendinning_first_species_examples-1-v0 | 9 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| clendinning_first_species_examples-1-v0 | 9 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| clendinning_first_species_examples-1-v0 | 9 | `fifth_species_melody` | 0.897 | 0.570 | -0.328 | yes | demoted |
| clendinning_first_species_examples-1-v1 | 9 | `fux_cantus_firmus` | 0.975 | 0.976 | +0.002 | yes | threshold split |
| clendinning_first_species_examples-1-v1 | 9 | `second_species_melody` | 0.921 | 0.584 | -0.337 | yes | demoted |
| clendinning_first_species_examples-1-v1 | 9 | `third_species_melody` | 0.921 | 0.584 | -0.337 | yes | demoted |
| clendinning_first_species_examples-1-v1 | 9 | `third_species_triple_meter_melody` | 0.921 | 0.584 | -0.337 | yes | demoted |
| clendinning_first_species_examples-1-v1 | 9 | `fifth_species_melody` | 0.920 | 0.580 | -0.340 | yes | demoted |
| clendinning_first_species_examples-2-v0 | 11 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| clendinning_first_species_examples-2-v0 | 11 | `second_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| clendinning_first_species_examples-2-v0 | 11 | `third_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| clendinning_first_species_examples-2-v0 | 11 | `third_species_triple_meter_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| clendinning_first_species_examples-2-v0 | 11 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| clendinning_first_species_examples-2-v0 | 11 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| clendinning_first_species_examples-2-v0 | 11 | `fifth_species_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| clendinning_first_species_examples-2-v1 | 11 | `fux_cantus_firmus` | 0.949 | 0.952 | +0.003 | yes | threshold split |
| clendinning_first_species_examples-2-v1 | 11 | `salzer_schachter_cantus_firmus` | 0.976 | 0.978 | +0.001 | yes | threshold split |
| clendinning_first_species_examples-2-v1 | 11 | `second_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| clendinning_first_species_examples-2-v1 | 11 | `third_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| clendinning_first_species_examples-2-v1 | 11 | `third_species_triple_meter_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| clendinning_first_species_examples-2-v1 | 11 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| clendinning_first_species_examples-2-v1 | 11 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| clendinning_first_species_examples-2-v1 | 11 | `fifth_species_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| davis_and_lybbert_first_species_examples-0-v0 | 10 | `fux_cantus_firmus` | 0.975 | 0.976 | +0.002 | yes | threshold split |
| davis_and_lybbert_first_species_examples-0-v0 | 10 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| davis_and_lybbert_first_species_examples-0-v0 | 10 | `second_species_melody` | 0.897 | 0.570 | -0.328 | yes | demoted |
| davis_and_lybbert_first_species_examples-0-v0 | 10 | `third_species_melody` | 0.897 | 0.570 | -0.328 | yes | demoted |
| davis_and_lybbert_first_species_examples-0-v0 | 10 | `third_species_triple_meter_melody` | 0.897 | 0.570 | -0.328 | yes | demoted |
| davis_and_lybbert_first_species_examples-0-v0 | 10 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| davis_and_lybbert_first_species_examples-0-v0 | 10 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| davis_and_lybbert_first_species_examples-0-v0 | 10 | `fifth_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| davis_and_lybbert_first_species_examples-0-v1 | 10 | `fux_cantus_firmus` | 0.924 | 0.928 | +0.005 | yes | threshold split |
| davis_and_lybbert_first_species_examples-0-v1 | 10 | `salzer_schachter_cantus_firmus` | 0.976 | 0.978 | +0.001 | yes | threshold split |
| davis_and_lybbert_first_species_examples-0-v1 | 10 | `second_species_melody` | 0.920 | 0.580 | -0.340 | yes | demoted |
| davis_and_lybbert_first_species_examples-0-v1 | 10 | `third_species_melody` | 0.920 | 0.580 | -0.340 | yes | demoted |
| davis_and_lybbert_first_species_examples-0-v1 | 10 | `third_species_triple_meter_melody` | 0.920 | 0.580 | -0.340 | yes | demoted |
| davis_and_lybbert_first_species_examples-0-v1 | 10 | `fifth_species_melody` | 0.919 | 0.577 | -0.342 | yes | demoted |
| davis_and_lybbert_first_species_examples-1-v0 | 11 | `first_species_melody` | 0.975 | 0.989 | +0.014 | yes | demoted |
| davis_and_lybbert_first_species_examples-1-v0 | 11 | `second_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| davis_and_lybbert_first_species_examples-1-v0 | 11 | `third_species_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| davis_and_lybbert_first_species_examples-1-v0 | 11 | `third_species_triple_meter_melody` | 0.897 | 0.567 | -0.330 | yes | demoted |
| davis_and_lybbert_first_species_examples-1-v0 | 11 | `fourth_species_melody` | 0.976 | 0.990 | +0.014 | yes | demoted |
| davis_and_lybbert_first_species_examples-1-v0 | 11 | `combined_first_second_third_species_melody` | 0.973 | 0.989 | +0.016 | yes | demoted |
| davis_and_lybbert_first_species_examples-1-v0 | 11 | `fifth_species_melody` | 0.897 | 0.566 | -0.331 | yes | demoted |
| davis_and_lybbert_first_species_examples-1-v1 | 11 | `fux_cantus_firmus` | 0.975 | 0.976 | +0.002 | yes | threshold split |
| davis_and_lybbert_first_species_examples-1-v1 | 11 | `second_species_melody` | 0.919 | 0.577 | -0.342 | yes | demoted |
| davis_and_lybbert_first_species_examples-1-v1 | 11 | `third_species_melody` | 0.919 | 0.577 | -0.342 | yes | demoted |
| davis_and_lybbert_first_species_examples-1-v1 | 11 | `third_species_triple_meter_melody` | 0.919 | 0.577 | -0.342 | yes | demoted |
| davis_and_lybbert_first_species_examples-1-v1 | 11 | `fifth_species_melody` | 0.919 | 0.575 | -0.344 | yes | demoted |
