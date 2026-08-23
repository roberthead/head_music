# Extract the Harmonic Cores — grades before and after

Generated. Do not edit by hand:

```
bundle exec ruby bin/guide_grade_corpus.rb tmp/c0.json
bundle exec ruby bin/guide_grade_corpus.rb tmp/c1.json
bundle exec ruby bin/guide_grade_corpus.rb tmp/c2.json
bundle exec ruby bin/guide_grade_corpus.rb tmp/c3.json
bundle exec ruby bin/guide_grade_corpus.rb tmp/c4.json
bundle exec ruby bin/guide_grade_table.rb user-stories/current/extract-the-harmonic-cores.grades.md \
  "the strength axis:tmp/c0.json:tmp/c1.json" \
  "mark softened:tmp/c1.json:tmp/c2.json" \
  "reweighted:tmp/c2.json:tmp/c3.json" \
  "demoted:tmp/c3.json:tmp/c4.json"
```

The capture script takes no arguments beyond its output path and asks only what every tree can answer, so each column is the same measurement made again. **3266 rows** per capture — 142 corpus entries × 23 registry entries. An asterisk marks an unassessable voice.

**Two denominators live in the harmony numbers and must not be conflated.** Of the 994 harmony rows, only **266 are assessable** — 38 entries × 7 harmony guides. Of those, **252** come from published fixtures (36 voices) and **14** from 2 synthetic ladder-against-cantus voices. Every assessable harmony row is first-species or ladder material: there are no second, third, fourth, or fifth species fixtures anywhere in `spec/`, so this corpus compares each line against itself rather than against a line of another species.

One section per join, and **each join spans exactly one change**, so its label is its cause rather than a guess made from the numbers. A row is relabelled only when the voice changed assessability, which is a gate moving rather than a weight.

## The strength axis

`c0.json` → `c1.json`. 0 of 3266 rows moved, 3266 unchanged.

No row moved. This change is a provable no-op across the whole corpus.

## Mark softened

`c1.json` → `c2.json`. 130 of 3266 rows moved, 3136 unchanged.

| why it moved | rows |
| --- | ---: |
| mark softened | 130 |

| corpus | notes | guide | before | after | delta | assessable | why |
| --- | ---: | --- | ---: | ---: | ---: | --- | --- |
| solo-ascending-4 | 4 | `fux_cantus_firmus` | 0.882 | 0.868 | -0.015 | yes | mark softened |
| solo-ascending-4 | 4 | `salzer_schachter_cantus_firmus` | 0.903 | 0.889 | -0.014 | yes | mark softened |
| solo-ascending-4 | 4 | `diatonic_melody` | 0.947 | 0.926 | -0.021 | yes | mark softened |
| solo-ascending-4 | 4 | `first_species_melody` | 0.966 | 0.959 | -0.007 | yes | mark softened |
| solo-ascending-4 | 4 | `second_species_melody` | 0.853 | 0.847 | -0.006 | yes | mark softened |
| solo-ascending-4 | 4 | `third_species_melody` | 0.853 | 0.847 | -0.006 | yes | mark softened |
| solo-ascending-4 | 4 | `third_species_triple_meter_melody` | 0.853 | 0.847 | -0.006 | yes | mark softened |
| solo-ascending-4 | 4 | `fourth_species_melody` | 0.971 | 0.965 | -0.006 | yes | mark softened |
| solo-ascending-4 | 4 | `combined_first_second_third_species_melody` | 0.966 | 0.959 | -0.007 | yes | mark softened |
| solo-ascending-4 | 4 | `fifth_species_melody` | 0.617 | 0.611 | -0.006 | yes | mark softened |
| solo-ascending-4 | 4 | `arch_contour_melody` | 0.598 | 0.590 | -0.008 | yes | mark softened |
| solo-ascending-4 | 4 | `ascending_contour_melody` | 0.980 | 0.972 | -0.008 | yes | mark softened |
| solo-ascending-4 | 4 | `descending_contour_melody` | 0.598 | 0.590 | -0.008 | yes | mark softened |
| solo-ascending-4 | 4 | `static_contour_melody` | 0.598 | 0.590 | -0.008 | yes | mark softened |
| solo-ascending-4 | 4 | `valley_contour_melody` | 0.598 | 0.590 | -0.008 | yes | mark softened |
| solo-ascending-4 | 4 | `wave_contour_melody` | 0.598 | 0.590 | -0.008 | yes | mark softened |
| solo-repeated-3 | 3 | `fux_cantus_firmus` | 0.764 | 0.750 | -0.015 | yes | mark softened |
| solo-repeated-3 | 3 | `salzer_schachter_cantus_firmus` | 0.792 | 0.778 | -0.014 | yes | mark softened |
| solo-repeated-3 | 3 | `diatonic_melody` | 0.859 | 0.838 | -0.021 | yes | mark softened |
| solo-repeated-3 | 3 | `first_species_melody` | 0.926 | 0.919 | -0.007 | yes | mark softened |
| solo-repeated-3 | 3 | `second_species_melody` | 0.802 | 0.796 | -0.006 | yes | mark softened |
| solo-repeated-3 | 3 | `third_species_melody` | 0.802 | 0.796 | -0.006 | yes | mark softened |
| solo-repeated-3 | 3 | `third_species_triple_meter_melody` | 0.802 | 0.796 | -0.006 | yes | mark softened |
| solo-repeated-3 | 3 | `fourth_species_melody` | 0.920 | 0.914 | -0.006 | yes | mark softened |
| solo-repeated-3 | 3 | `combined_first_second_third_species_melody` | 0.908 | 0.901 | -0.007 | yes | mark softened |
| solo-repeated-3 | 3 | `fifth_species_melody` | 0.611 | 0.605 | -0.006 | yes | mark softened |
| solo-repeated-3 | 3 | `static_contour_melody` | 0.946 | 0.938 | -0.008 | yes | mark softened |
| solo-repeated-4 | 4 | `fux_cantus_firmus` | 0.725 | 0.710 | -0.016 | yes | mark softened |
| solo-repeated-4 | 4 | `salzer_schachter_cantus_firmus` | 0.778 | 0.763 | -0.015 | yes | mark softened |
| solo-repeated-4 | 4 | `diatonic_melody` | 0.857 | 0.835 | -0.023 | yes | mark softened |
| solo-repeated-4 | 4 | `first_species_melody` | 0.908 | 0.901 | -0.007 | yes | mark softened |
| solo-repeated-4 | 4 | `second_species_melody` | 0.783 | 0.776 | -0.006 | yes | mark softened |
| solo-repeated-4 | 4 | `third_species_melody` | 0.783 | 0.776 | -0.006 | yes | mark softened |
| solo-repeated-4 | 4 | `third_species_triple_meter_melody` | 0.783 | 0.776 | -0.006 | yes | mark softened |
| solo-repeated-4 | 4 | `fourth_species_melody` | 0.901 | 0.894 | -0.006 | yes | mark softened |
| solo-repeated-4 | 4 | `combined_first_second_third_species_melody` | 0.886 | 0.878 | -0.007 | yes | mark softened |
| solo-repeated-4 | 4 | `fifth_species_melody` | 0.547 | 0.540 | -0.006 | yes | mark softened |
| solo-repeated-4 | 4 | `static_contour_melody` | 0.946 | 0.937 | -0.009 | yes | mark softened |
| solo-repeated-5 | 5 | `fux_cantus_firmus` | 0.710 | 0.696 | -0.015 | yes | mark softened |
| solo-repeated-5 | 5 | `salzer_schachter_cantus_firmus` | 0.770 | 0.757 | -0.014 | yes | mark softened |
| solo-repeated-5 | 5 | `diatonic_melody` | 0.861 | 0.840 | -0.021 | yes | mark softened |
| solo-repeated-5 | 5 | `first_species_melody` | 0.900 | 0.893 | -0.007 | yes | mark softened |
| solo-repeated-5 | 5 | `second_species_melody` | 0.774 | 0.768 | -0.006 | yes | mark softened |
| solo-repeated-5 | 5 | `third_species_melody` | 0.774 | 0.768 | -0.006 | yes | mark softened |
| solo-repeated-5 | 5 | `third_species_triple_meter_melody` | 0.774 | 0.768 | -0.006 | yes | mark softened |
| solo-repeated-5 | 5 | `fourth_species_melody` | 0.892 | 0.886 | -0.006 | yes | mark softened |
| solo-repeated-5 | 5 | `combined_first_second_third_species_melody` | 0.875 | 0.868 | -0.007 | yes | mark softened |
| solo-repeated-5 | 5 | `fifth_species_melody` | 0.510 | 0.504 | -0.006 | yes | mark softened |
| solo-repeated-5 | 5 | `static_contour_melody` | 0.947 | 0.939 | -0.008 | yes | mark softened |
| solo-repeated-6 | 6 | `fux_cantus_firmus` | 0.703 | 0.690 | -0.013 | yes | mark softened |
| solo-repeated-6 | 6 | `salzer_schachter_cantus_firmus` | 0.745 | 0.733 | -0.012 | yes | mark softened |
| solo-repeated-6 | 6 | `diatonic_melody` | 0.816 | 0.797 | -0.019 | yes | mark softened |
| solo-repeated-6 | 6 | `first_species_melody` | 0.894 | 0.888 | -0.006 | yes | mark softened |
| solo-repeated-6 | 6 | `second_species_melody` | 0.767 | 0.762 | -0.005 | yes | mark softened |
| solo-repeated-6 | 6 | `third_species_melody` | 0.767 | 0.762 | -0.005 | yes | mark softened |
| solo-repeated-6 | 6 | `third_species_triple_meter_melody` | 0.767 | 0.762 | -0.005 | yes | mark softened |
| solo-repeated-6 | 6 | `fourth_species_melody` | 0.885 | 0.880 | -0.005 | yes | mark softened |
| solo-repeated-6 | 6 | `combined_first_second_third_species_melody` | 0.868 | 0.862 | -0.006 | yes | mark softened |
| solo-repeated-6 | 6 | `fifth_species_melody` | 0.486 | 0.481 | -0.005 | yes | mark softened |
| solo-repeated-6 | 6 | `static_contour_melody` | 0.930 | 0.922 | -0.007 | yes | mark softened |
| solo-repeated-7 | 7 | `fux_cantus_firmus` | 0.700 | 0.689 | -0.011 | yes | mark softened |
| solo-repeated-7 | 7 | `salzer_schachter_cantus_firmus` | 0.739 | 0.728 | -0.011 | yes | mark softened |
| solo-repeated-7 | 7 | `diatonic_melody` | 0.798 | 0.782 | -0.016 | yes | mark softened |
| solo-repeated-7 | 7 | `first_species_melody` | 0.890 | 0.885 | -0.005 | yes | mark softened |
| solo-repeated-7 | 7 | `second_species_melody` | 0.763 | 0.758 | -0.005 | yes | mark softened |
| solo-repeated-7 | 7 | `third_species_melody` | 0.763 | 0.758 | -0.005 | yes | mark softened |
| solo-repeated-7 | 7 | `third_species_triple_meter_melody` | 0.763 | 0.758 | -0.005 | yes | mark softened |
| solo-repeated-7 | 7 | `fourth_species_melody` | 0.881 | 0.876 | -0.005 | yes | mark softened |
| solo-repeated-7 | 7 | `combined_first_second_third_species_melody` | 0.863 | 0.857 | -0.005 | yes | mark softened |
| solo-repeated-7 | 7 | `fifth_species_melody` | 0.471 | 0.467 | -0.005 | yes | mark softened |
| solo-repeated-7 | 7 | `static_contour_melody` | 0.923 | 0.917 | -0.006 | yes | mark softened |
| solo-repeated-8 | 8 | `fux_cantus_firmus` | 0.700 | 0.691 | -0.009 | yes | mark softened |
| solo-repeated-8 | 8 | `salzer_schachter_cantus_firmus` | 0.737 | 0.728 | -0.009 | yes | mark softened |
| solo-repeated-8 | 8 | `diatonic_melody` | 0.786 | 0.772 | -0.014 | yes | mark softened |
| solo-repeated-8 | 8 | `first_species_melody` | 0.887 | 0.883 | -0.004 | yes | mark softened |
| solo-repeated-8 | 8 | `second_species_melody` | 0.760 | 0.756 | -0.004 | yes | mark softened |
| solo-repeated-8 | 8 | `third_species_melody` | 0.760 | 0.756 | -0.004 | yes | mark softened |
| solo-repeated-8 | 8 | `third_species_triple_meter_melody` | 0.760 | 0.756 | -0.004 | yes | mark softened |
| solo-repeated-8 | 8 | `fourth_species_melody` | 0.878 | 0.874 | -0.004 | yes | mark softened |
| solo-repeated-8 | 8 | `combined_first_second_third_species_melody` | 0.859 | 0.855 | -0.004 | yes | mark softened |
| solo-repeated-8 | 8 | `fifth_species_melody` | 0.461 | 0.458 | -0.004 | yes | mark softened |
| solo-repeated-8 | 8 | `static_contour_melody` | 0.918 | 0.913 | -0.005 | yes | mark softened |
| against-empty-4 | 4 | `fux_cantus_firmus` | 0.882 | 0.868 | -0.015 | yes | mark softened |
| against-empty-4 | 4 | `salzer_schachter_cantus_firmus` | 0.903 | 0.889 | -0.014 | yes | mark softened |
| against-empty-4 | 4 | `diatonic_melody` | 0.947 | 0.926 | -0.021 | yes | mark softened |
| against-empty-4 | 4 | `first_species_melody` | 0.966 | 0.959 | -0.007 | yes | mark softened |
| against-empty-4 | 4 | `second_species_melody` | 0.853 | 0.847 | -0.006 | yes | mark softened |
| against-empty-4 | 4 | `third_species_melody` | 0.853 | 0.847 | -0.006 | yes | mark softened |
| against-empty-4 | 4 | `third_species_triple_meter_melody` | 0.853 | 0.847 | -0.006 | yes | mark softened |
| against-empty-4 | 4 | `fourth_species_melody` | 0.971 | 0.965 | -0.006 | yes | mark softened |
| against-empty-4 | 4 | `combined_first_second_third_species_melody` | 0.966 | 0.959 | -0.007 | yes | mark softened |
| against-empty-4 | 4 | `fifth_species_melody` | 0.617 | 0.611 | -0.006 | yes | mark softened |
| against-empty-4 | 4 | `arch_contour_melody` | 0.598 | 0.590 | -0.008 | yes | mark softened |
| against-empty-4 | 4 | `ascending_contour_melody` | 0.980 | 0.972 | -0.008 | yes | mark softened |
| against-empty-4 | 4 | `descending_contour_melody` | 0.598 | 0.590 | -0.008 | yes | mark softened |
| against-empty-4 | 4 | `static_contour_melody` | 0.598 | 0.590 | -0.008 | yes | mark softened |
| against-empty-4 | 4 | `valley_contour_melody` | 0.598 | 0.590 | -0.008 | yes | mark softened |
| against-empty-4 | 4 | `wave_contour_melody` | 0.598 | 0.590 | -0.008 | yes | mark softened |
| against-cantus-4 | 4 | `fux_cantus_firmus` | 0.882 | 0.868 | -0.015 | yes | mark softened |
| against-cantus-4 | 4 | `salzer_schachter_cantus_firmus` | 0.903 | 0.889 | -0.014 | yes | mark softened |
| against-cantus-4 | 4 | `diatonic_melody` | 0.947 | 0.926 | -0.021 | yes | mark softened |
| against-cantus-4 | 4 | `first_species_melody` | 0.712 | 0.705 | -0.007 | yes | mark softened |
| against-cantus-4 | 4 | `second_species_melody` | 0.545 | 0.539 | -0.006 | yes | mark softened |
| against-cantus-4 | 4 | `third_species_melody` | 0.545 | 0.539 | -0.006 | yes | mark softened |
| against-cantus-4 | 4 | `third_species_triple_meter_melody` | 0.545 | 0.539 | -0.006 | yes | mark softened |
| against-cantus-4 | 4 | `fourth_species_melody` | 0.427 | 0.421 | -0.006 | yes | mark softened |
| against-cantus-4 | 4 | `combined_first_second_third_species_melody` | 0.966 | 0.959 | -0.007 | yes | mark softened |
| against-cantus-4 | 4 | `fifth_species_melody` | 0.601 | 0.595 | -0.006 | yes | mark softened |
| against-cantus-4 | 4 | `arch_contour_melody` | 0.598 | 0.590 | -0.008 | yes | mark softened |
| against-cantus-4 | 4 | `ascending_contour_melody` | 0.980 | 0.972 | -0.008 | yes | mark softened |
| against-cantus-4 | 4 | `descending_contour_melody` | 0.598 | 0.590 | -0.008 | yes | mark softened |
| against-cantus-4 | 4 | `static_contour_melody` | 0.598 | 0.590 | -0.008 | yes | mark softened |
| against-cantus-4 | 4 | `valley_contour_melody` | 0.598 | 0.590 | -0.008 | yes | mark softened |
| against-cantus-4 | 4 | `wave_contour_melody` | 0.598 | 0.590 | -0.008 | yes | mark softened |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `fux_cantus_firmus` | 0.947 | 0.939 | -0.008 | yes | mark softened |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `salzer_schachter_cantus_firmus` | 0.950 | 0.942 | -0.007 | yes | mark softened |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `diatonic_melody` | 0.922 | 0.911 | -0.011 | yes | mark softened |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `first_species_melody` | 0.964 | 0.960 | -0.004 | yes | mark softened |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `second_species_melody` | 0.850 | 0.847 | -0.003 | yes | mark softened |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `third_species_melody` | 0.850 | 0.847 | -0.003 | yes | mark softened |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `third_species_triple_meter_melody` | 0.850 | 0.847 | -0.003 | yes | mark softened |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `fourth_species_melody` | 0.969 | 0.965 | -0.003 | yes | mark softened |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `combined_first_second_third_species_melody` | 0.964 | 0.960 | -0.004 | yes | mark softened |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `fifth_species_melody` | 0.542 | 0.539 | -0.003 | yes | mark softened |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `arch_contour_melody` | 0.970 | 0.966 | -0.004 | yes | mark softened |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `ascending_contour_melody` | 0.588 | 0.584 | -0.004 | yes | mark softened |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `descending_contour_melody` | 0.588 | 0.584 | -0.004 | yes | mark softened |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `static_contour_melody` | 0.588 | 0.584 | -0.004 | yes | mark softened |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `valley_contour_melody` | 0.588 | 0.584 | -0.004 | yes | mark softened |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `wave_contour_melody` | 0.970 | 0.966 | -0.004 | yes | mark softened |

## Reweighted

`c2.json` → `c3.json`. 833 of 3266 rows moved, 2433 unchanged.

| why it moved | rows |
| --- | ---: |
| reweighted | 833 |

| corpus | notes | guide | before | after | delta | assessable | why |
| --- | ---: | --- | ---: | ---: | ---: | --- | --- |
| solo-ascending-3 | 3 | `fux_cantus_firmus` | 0.937 | 0.928 | -0.009 | yes | reweighted |
| solo-ascending-3 | 3 | `salzer_schachter_cantus_firmus` | 0.941 | 0.931 | -0.010 | yes | reweighted |
| solo-ascending-3 | 3 | `diatonic_melody` | 0.964 | 0.953 | -0.011 | yes | reweighted |
| solo-ascending-3 | 3 | `first_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| solo-ascending-3 | 3 | `second_species_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| solo-ascending-3 | 3 | `third_species_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| solo-ascending-3 | 3 | `third_species_triple_meter_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| solo-ascending-3 | 3 | `fourth_species_melody` | 0.981 | 0.978 | -0.003 | yes | reweighted |
| solo-ascending-3 | 3 | `combined_first_second_third_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| solo-ascending-3 | 3 | `fifth_species_melody` | 0.672 | 0.669 | -0.003 | yes | reweighted |
| solo-ascending-3 | 3 | `arch_contour_melody` | 0.986 | 0.982 | -0.004 | yes | reweighted |
| solo-ascending-3 | 3 | `ascending_contour_melody` | 0.604 | 0.600 | -0.004 | yes | reweighted |
| solo-ascending-3 | 3 | `descending_contour_melody` | 0.604 | 0.600 | -0.004 | yes | reweighted |
| solo-ascending-3 | 3 | `static_contour_melody` | 0.986 | 0.982 | -0.004 | yes | reweighted |
| solo-ascending-3 | 3 | `valley_contour_melody` | 0.604 | 0.600 | -0.004 | yes | reweighted |
| solo-ascending-3 | 3 | `wave_contour_melody` | 0.604 | 0.600 | -0.004 | yes | reweighted |
| solo-ascending-4 | 4 | `fux_cantus_firmus` | 0.868 | 0.871 | +0.003 | yes | reweighted |
| solo-ascending-4 | 4 | `salzer_schachter_cantus_firmus` | 0.889 | 0.892 | +0.002 | yes | reweighted |
| solo-ascending-4 | 4 | `diatonic_melody` | 0.926 | 0.940 | +0.014 | yes | reweighted |
| solo-ascending-4 | 4 | `first_species_melody` | 0.959 | 0.963 | +0.003 | yes | reweighted |
| solo-ascending-4 | 4 | `second_species_melody` | 0.847 | 0.850 | +0.004 | yes | reweighted |
| solo-ascending-4 | 4 | `third_species_melody` | 0.847 | 0.850 | +0.004 | yes | reweighted |
| solo-ascending-4 | 4 | `third_species_triple_meter_melody` | 0.847 | 0.850 | +0.004 | yes | reweighted |
| solo-ascending-4 | 4 | `fourth_species_melody` | 0.965 | 0.968 | +0.004 | yes | reweighted |
| solo-ascending-4 | 4 | `combined_first_second_third_species_melody` | 0.959 | 0.963 | +0.003 | yes | reweighted |
| solo-ascending-4 | 4 | `fifth_species_melody` | 0.611 | 0.614 | +0.004 | yes | reweighted |
| solo-ascending-4 | 4 | `arch_contour_melody` | 0.590 | 0.595 | +0.006 | yes | reweighted |
| solo-ascending-4 | 4 | `ascending_contour_melody` | 0.972 | 0.977 | +0.006 | yes | reweighted |
| solo-ascending-4 | 4 | `descending_contour_melody` | 0.590 | 0.595 | +0.006 | yes | reweighted |
| solo-ascending-4 | 4 | `static_contour_melody` | 0.590 | 0.595 | +0.006 | yes | reweighted |
| solo-ascending-4 | 4 | `valley_contour_melody` | 0.590 | 0.595 | +0.006 | yes | reweighted |
| solo-ascending-4 | 4 | `wave_contour_melody` | 0.590 | 0.595 | +0.006 | yes | reweighted |
| solo-ascending-5 | 5 | `fux_cantus_firmus` | 0.953 | 0.946 | -0.007 | yes | reweighted |
| solo-ascending-5 | 5 | `salzer_schachter_cantus_firmus` | 0.955 | 0.948 | -0.008 | yes | reweighted |
| solo-ascending-5 | 5 | `first_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| solo-ascending-5 | 5 | `second_species_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| solo-ascending-5 | 5 | `third_species_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| solo-ascending-5 | 5 | `third_species_triple_meter_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| solo-ascending-5 | 5 | `fourth_species_melody` | 0.981 | 0.978 | -0.003 | yes | reweighted |
| solo-ascending-5 | 5 | `combined_first_second_third_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| solo-ascending-5 | 5 | `fifth_species_melody` | 0.599 | 0.596 | -0.003 | yes | reweighted |
| solo-ascending-6 | 6 | `fux_cantus_firmus` | 0.922 | 0.911 | -0.011 | yes | reweighted |
| solo-ascending-6 | 6 | `salzer_schachter_cantus_firmus` | 0.940 | 0.930 | -0.010 | yes | reweighted |
| solo-ascending-6 | 6 | `first_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| solo-ascending-6 | 6 | `second_species_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| solo-ascending-6 | 6 | `third_species_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| solo-ascending-6 | 6 | `third_species_triple_meter_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| solo-ascending-6 | 6 | `fourth_species_melody` | 0.981 | 0.978 | -0.003 | yes | reweighted |
| solo-ascending-6 | 6 | `combined_first_second_third_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| solo-ascending-6 | 6 | `fifth_species_melody` | 0.581 | 0.578 | -0.003 | yes | reweighted |
| solo-ascending-7 | 7 | `fux_cantus_firmus` | 0.968 | 0.964 | -0.005 | yes | reweighted |
| solo-ascending-7 | 7 | `salzer_schachter_cantus_firmus` | 0.970 | 0.965 | -0.005 | yes | reweighted |
| solo-ascending-7 | 7 | `first_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| solo-ascending-7 | 7 | `second_species_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| solo-ascending-7 | 7 | `third_species_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| solo-ascending-7 | 7 | `third_species_triple_meter_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| solo-ascending-7 | 7 | `fourth_species_melody` | 0.981 | 0.978 | -0.003 | yes | reweighted |
| solo-ascending-7 | 7 | `combined_first_second_third_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| solo-ascending-7 | 7 | `fifth_species_melody` | 0.571 | 0.568 | -0.003 | yes | reweighted |
| solo-ascending-8 | 8 | `fux_cantus_firmus` | 0.976 | 0.973 | -0.003 | yes | reweighted |
| solo-ascending-8 | 8 | `salzer_schachter_cantus_firmus` | 0.978 | 0.974 | -0.004 | yes | reweighted |
| solo-ascending-8 | 8 | `first_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| solo-ascending-8 | 8 | `second_species_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| solo-ascending-8 | 8 | `third_species_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| solo-ascending-8 | 8 | `third_species_triple_meter_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| solo-ascending-8 | 8 | `fourth_species_melody` | 0.981 | 0.978 | -0.003 | yes | reweighted |
| solo-ascending-8 | 8 | `combined_first_second_third_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| solo-ascending-8 | 8 | `fifth_species_melody` | 0.564 | 0.561 | -0.003 | yes | reweighted |
| solo-repeated-3 | 3 | `fux_cantus_firmus` | 0.750 | 0.736 | -0.014 | yes | reweighted |
| solo-repeated-3 | 3 | `salzer_schachter_cantus_firmus` | 0.778 | 0.761 | -0.017 | yes | reweighted |
| solo-repeated-3 | 3 | `diatonic_melody` | 0.838 | 0.827 | -0.011 | yes | reweighted |
| solo-repeated-3 | 3 | `first_species_melody` | 0.919 | 0.915 | -0.004 | yes | reweighted |
| solo-repeated-3 | 3 | `second_species_melody` | 0.796 | 0.792 | -0.004 | yes | reweighted |
| solo-repeated-3 | 3 | `third_species_melody` | 0.796 | 0.792 | -0.004 | yes | reweighted |
| solo-repeated-3 | 3 | `third_species_triple_meter_melody` | 0.796 | 0.792 | -0.004 | yes | reweighted |
| solo-repeated-3 | 3 | `fourth_species_melody` | 0.914 | 0.910 | -0.004 | yes | reweighted |
| solo-repeated-3 | 3 | `combined_first_second_third_species_melody` | 0.901 | 0.893 | -0.007 | yes | reweighted |
| solo-repeated-3 | 3 | `fifth_species_melody` | 0.605 | 0.601 | -0.004 | yes | reweighted |
| solo-repeated-3 | 3 | `static_contour_melody` | 0.938 | 0.934 | -0.004 | yes | reweighted |
| solo-repeated-4 | 4 | `fux_cantus_firmus` | 0.710 | 0.709 | -0.001 | yes | reweighted |
| solo-repeated-4 | 4 | `salzer_schachter_cantus_firmus` | 0.763 | 0.749 | -0.015 | yes | reweighted |
| solo-repeated-4 | 4 | `diatonic_melody` | 0.835 | 0.831 | -0.004 | yes | reweighted |
| solo-repeated-4 | 4 | `first_species_melody` | 0.901 | 0.902 | +0.002 | yes | reweighted |
| solo-repeated-4 | 4 | `second_species_melody` | 0.776 | 0.777 | +0.001 | yes | reweighted |
| solo-repeated-4 | 4 | `third_species_melody` | 0.776 | 0.777 | +0.001 | yes | reweighted |
| solo-repeated-4 | 4 | `third_species_triple_meter_melody` | 0.776 | 0.777 | +0.001 | yes | reweighted |
| solo-repeated-4 | 4 | `fourth_species_melody` | 0.894 | 0.895 | +0.001 | yes | reweighted |
| solo-repeated-4 | 4 | `combined_first_second_third_species_melody` | 0.878 | 0.876 | -0.002 | yes | reweighted |
| solo-repeated-4 | 4 | `fifth_species_melody` | 0.540 | 0.541 | +0.001 | yes | reweighted |
| solo-repeated-4 | 4 | `static_contour_melody` | 0.937 | 0.935 | -0.001 | yes | reweighted |
| solo-repeated-5 | 5 | `fux_cantus_firmus` | 0.696 | 0.700 | +0.005 | yes | reweighted |
| solo-repeated-5 | 5 | `salzer_schachter_cantus_firmus` | 0.757 | 0.744 | -0.013 | yes | reweighted |
| solo-repeated-5 | 5 | `diatonic_melody` | 0.840 | 0.843 | +0.003 | yes | reweighted |
| solo-repeated-5 | 5 | `first_species_melody` | 0.893 | 0.897 | +0.004 | yes | reweighted |
| solo-repeated-5 | 5 | `second_species_melody` | 0.768 | 0.770 | +0.002 | yes | reweighted |
| solo-repeated-5 | 5 | `third_species_melody` | 0.768 | 0.770 | +0.002 | yes | reweighted |
| solo-repeated-5 | 5 | `third_species_triple_meter_melody` | 0.768 | 0.770 | +0.002 | yes | reweighted |
| solo-repeated-5 | 5 | `fourth_species_melody` | 0.886 | 0.888 | +0.002 | yes | reweighted |
| solo-repeated-5 | 5 | `combined_first_second_third_species_melody` | 0.868 | 0.867 | -0.001 | yes | reweighted |
| solo-repeated-5 | 5 | `fifth_species_melody` | 0.504 | 0.506 | +0.002 | yes | reweighted |
| solo-repeated-5 | 5 | `static_contour_melody` | 0.939 | 0.940 | +0.001 | yes | reweighted |
| solo-repeated-6 | 6 | `fux_cantus_firmus` | 0.690 | 0.698 | +0.008 | yes | reweighted |
| solo-repeated-6 | 6 | `salzer_schachter_cantus_firmus` | 0.733 | 0.731 | -0.002 | yes | reweighted |
| solo-repeated-6 | 6 | `diatonic_melody` | 0.797 | 0.813 | +0.016 | yes | reweighted |
| solo-repeated-6 | 6 | `first_species_melody` | 0.888 | 0.894 | +0.005 | yes | reweighted |
| solo-repeated-6 | 6 | `second_species_melody` | 0.762 | 0.765 | +0.003 | yes | reweighted |
| solo-repeated-6 | 6 | `third_species_melody` | 0.762 | 0.765 | +0.003 | yes | reweighted |
| solo-repeated-6 | 6 | `third_species_triple_meter_melody` | 0.762 | 0.765 | +0.003 | yes | reweighted |
| solo-repeated-6 | 6 | `fourth_species_melody` | 0.880 | 0.883 | +0.003 | yes | reweighted |
| solo-repeated-6 | 6 | `combined_first_second_third_species_melody` | 0.862 | 0.862 | +0.000 | yes | reweighted |
| solo-repeated-6 | 6 | `fifth_species_melody` | 0.481 | 0.484 | +0.003 | yes | reweighted |
| solo-repeated-6 | 6 | `static_contour_melody` | 0.922 | 0.929 | +0.006 | yes | reweighted |
| solo-repeated-7 | 7 | `fux_cantus_firmus` | 0.689 | 0.700 | +0.011 | yes | reweighted |
| solo-repeated-7 | 7 | `salzer_schachter_cantus_firmus` | 0.728 | 0.731 | +0.003 | yes | reweighted |
| solo-repeated-7 | 7 | `diatonic_melody` | 0.782 | 0.802 | +0.020 | yes | reweighted |
| solo-repeated-7 | 7 | `first_species_melody` | 0.885 | 0.891 | +0.006 | yes | reweighted |
| solo-repeated-7 | 7 | `second_species_melody` | 0.758 | 0.762 | +0.004 | yes | reweighted |
| solo-repeated-7 | 7 | `third_species_melody` | 0.758 | 0.762 | +0.004 | yes | reweighted |
| solo-repeated-7 | 7 | `third_species_triple_meter_melody` | 0.758 | 0.762 | +0.004 | yes | reweighted |
| solo-repeated-7 | 7 | `fourth_species_melody` | 0.876 | 0.880 | +0.004 | yes | reweighted |
| solo-repeated-7 | 7 | `combined_first_second_third_species_melody` | 0.857 | 0.859 | +0.001 | yes | reweighted |
| solo-repeated-7 | 7 | `fifth_species_melody` | 0.467 | 0.470 | +0.004 | yes | reweighted |
| solo-repeated-7 | 7 | `static_contour_melody` | 0.917 | 0.924 | +0.008 | yes | reweighted |
| solo-repeated-8 | 8 | `fux_cantus_firmus` | 0.691 | 0.704 | +0.014 | yes | reweighted |
| solo-repeated-8 | 8 | `salzer_schachter_cantus_firmus` | 0.728 | 0.734 | +0.006 | yes | reweighted |
| solo-repeated-8 | 8 | `diatonic_melody` | 0.772 | 0.795 | +0.023 | yes | reweighted |
| solo-repeated-8 | 8 | `first_species_melody` | 0.883 | 0.890 | +0.007 | yes | reweighted |
| solo-repeated-8 | 8 | `second_species_melody` | 0.756 | 0.760 | +0.004 | yes | reweighted |
| solo-repeated-8 | 8 | `third_species_melody` | 0.756 | 0.760 | +0.004 | yes | reweighted |
| solo-repeated-8 | 8 | `third_species_triple_meter_melody` | 0.756 | 0.760 | +0.004 | yes | reweighted |
| solo-repeated-8 | 8 | `fourth_species_melody` | 0.874 | 0.878 | +0.004 | yes | reweighted |
| solo-repeated-8 | 8 | `combined_first_second_third_species_melody` | 0.855 | 0.856 | +0.002 | yes | reweighted |
| solo-repeated-8 | 8 | `fifth_species_melody` | 0.458 | 0.462 | +0.004 | yes | reweighted |
| solo-repeated-8 | 8 | `static_contour_melody` | 0.913 | 0.922 | +0.009 | yes | reweighted |
| against-empty-4 | 4 | `fux_cantus_firmus` | 0.868 | 0.871 | +0.003 | yes | reweighted |
| against-empty-4 | 4 | `salzer_schachter_cantus_firmus` | 0.889 | 0.892 | +0.002 | yes | reweighted |
| against-empty-4 | 4 | `diatonic_melody` | 0.926 | 0.940 | +0.014 | yes | reweighted |
| against-empty-4 | 4 | `first_species_melody` | 0.959 | 0.963 | +0.003 | yes | reweighted |
| against-empty-4 | 4 | `second_species_melody` | 0.847 | 0.850 | +0.004 | yes | reweighted |
| against-empty-4 | 4 | `third_species_melody` | 0.847 | 0.850 | +0.004 | yes | reweighted |
| against-empty-4 | 4 | `third_species_triple_meter_melody` | 0.847 | 0.850 | +0.004 | yes | reweighted |
| against-empty-4 | 4 | `fourth_species_melody` | 0.965 | 0.968 | +0.004 | yes | reweighted |
| against-empty-4 | 4 | `combined_first_second_third_species_melody` | 0.959 | 0.963 | +0.003 | yes | reweighted |
| against-empty-4 | 4 | `fifth_species_melody` | 0.611 | 0.614 | +0.004 | yes | reweighted |
| against-empty-4 | 4 | `arch_contour_melody` | 0.590 | 0.595 | +0.006 | yes | reweighted |
| against-empty-4 | 4 | `ascending_contour_melody` | 0.972 | 0.977 | +0.006 | yes | reweighted |
| against-empty-4 | 4 | `descending_contour_melody` | 0.590 | 0.595 | +0.006 | yes | reweighted |
| against-empty-4 | 4 | `static_contour_melody` | 0.590 | 0.595 | +0.006 | yes | reweighted |
| against-empty-4 | 4 | `valley_contour_melody` | 0.590 | 0.595 | +0.006 | yes | reweighted |
| against-empty-4 | 4 | `wave_contour_melody` | 0.590 | 0.595 | +0.006 | yes | reweighted |
| against-empty-8 | 8 | `fux_cantus_firmus` | 0.976 | 0.973 | -0.003 | yes | reweighted |
| against-empty-8 | 8 | `salzer_schachter_cantus_firmus` | 0.978 | 0.974 | -0.004 | yes | reweighted |
| against-empty-8 | 8 | `first_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| against-empty-8 | 8 | `second_species_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| against-empty-8 | 8 | `third_species_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| against-empty-8 | 8 | `third_species_triple_meter_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| against-empty-8 | 8 | `fourth_species_melody` | 0.981 | 0.978 | -0.003 | yes | reweighted |
| against-empty-8 | 8 | `combined_first_second_third_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| against-empty-8 | 8 | `fifth_species_melody` | 0.564 | 0.561 | -0.003 | yes | reweighted |
| against-cantus-4 | 4 | `fux_cantus_firmus` | 0.868 | 0.871 | +0.003 | yes | reweighted |
| against-cantus-4 | 4 | `salzer_schachter_cantus_firmus` | 0.889 | 0.892 | +0.002 | yes | reweighted |
| against-cantus-4 | 4 | `diatonic_melody` | 0.926 | 0.940 | +0.014 | yes | reweighted |
| against-cantus-4 | 4 | `first_species_melody` | 0.705 | 0.705 | +0.000 | yes | reweighted |
| against-cantus-4 | 4 | `first_species_harmony` | 0.546 | 0.551 | +0.006 | yes | reweighted |
| against-cantus-4 | 4 | `second_species_melody` | 0.539 | 0.540 | +0.001 | yes | reweighted |
| against-cantus-4 | 4 | `second_species_harmony` | 0.676 | 0.696 | +0.020 | yes | reweighted |
| against-cantus-4 | 4 | `third_species_melody` | 0.539 | 0.540 | +0.001 | yes | reweighted |
| against-cantus-4 | 4 | `third_species_harmony` | 0.676 | 0.696 | +0.020 | yes | reweighted |
| against-cantus-4 | 4 | `third_species_triple_meter_melody` | 0.539 | 0.540 | +0.001 | yes | reweighted |
| against-cantus-4 | 4 | `third_species_triple_meter_harmony` | 0.676 | 0.696 | +0.020 | yes | reweighted |
| against-cantus-4 | 4 | `fourth_species_melody` | 0.421 | 0.422 | +0.001 | yes | reweighted |
| against-cantus-4 | 4 | `fourth_species_harmony` | 0.650 | 0.665 | +0.015 | yes | reweighted |
| against-cantus-4 | 4 | `combined_first_second_third_species_melody` | 0.959 | 0.963 | +0.003 | yes | reweighted |
| against-cantus-4 | 4 | `combined_first_second_third_species_harmony` | 0.625 | 0.643 | +0.018 | yes | reweighted |
| against-cantus-4 | 4 | `fifth_species_melody` | 0.595 | 0.596 | +0.001 | yes | reweighted |
| against-cantus-4 | 4 | `fifth_species_harmony` | 0.647 | 0.660 | +0.013 | yes | reweighted |
| against-cantus-4 | 4 | `arch_contour_melody` | 0.590 | 0.595 | +0.006 | yes | reweighted |
| against-cantus-4 | 4 | `ascending_contour_melody` | 0.972 | 0.977 | +0.006 | yes | reweighted |
| against-cantus-4 | 4 | `descending_contour_melody` | 0.590 | 0.595 | +0.006 | yes | reweighted |
| against-cantus-4 | 4 | `static_contour_melody` | 0.590 | 0.595 | +0.006 | yes | reweighted |
| against-cantus-4 | 4 | `valley_contour_melody` | 0.590 | 0.595 | +0.006 | yes | reweighted |
| against-cantus-4 | 4 | `wave_contour_melody` | 0.590 | 0.595 | +0.006 | yes | reweighted |
| against-cantus-8 | 8 | `fux_cantus_firmus` | 0.976 | 0.973 | -0.003 | yes | reweighted |
| against-cantus-8 | 8 | `salzer_schachter_cantus_firmus` | 0.978 | 0.974 | -0.004 | yes | reweighted |
| against-cantus-8 | 8 | `first_species_melody` | 0.959 | 0.952 | -0.007 | yes | reweighted |
| against-cantus-8 | 8 | `first_species_harmony` | 0.588 | 0.590 | +0.002 | yes | reweighted |
| against-cantus-8 | 8 | `second_species_melody` | 0.555 | 0.550 | -0.005 | yes | reweighted |
| against-cantus-8 | 8 | `second_species_harmony` | 0.629 | 0.635 | +0.006 | yes | reweighted |
| against-cantus-8 | 8 | `third_species_melody` | 0.555 | 0.550 | -0.005 | yes | reweighted |
| against-cantus-8 | 8 | `third_species_harmony` | 0.629 | 0.635 | +0.006 | yes | reweighted |
| against-cantus-8 | 8 | `third_species_triple_meter_melody` | 0.555 | 0.550 | -0.005 | yes | reweighted |
| against-cantus-8 | 8 | `third_species_triple_meter_harmony` | 0.629 | 0.635 | +0.006 | yes | reweighted |
| against-cantus-8 | 8 | `fourth_species_melody` | 0.965 | 0.959 | -0.005 | yes | reweighted |
| against-cantus-8 | 8 | `fourth_species_harmony` | 0.607 | 0.610 | +0.003 | yes | reweighted |
| against-cantus-8 | 8 | `combined_first_second_third_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| against-cantus-8 | 8 | `combined_first_second_third_species_harmony` | 0.536 | 0.531 | -0.005 | yes | reweighted |
| against-cantus-8 | 8 | `fifth_species_melody` | 0.548 | 0.543 | -0.005 | yes | reweighted |
| against-cantus-8 | 8 | `fifth_species_harmony` | 0.588 | 0.589 | +0.001 | yes | reweighted |
| fux_cantus_firmus_examples-0-v0 | 11 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples-0-v0 | 11 | `second_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-0-v0 | 11 | `third_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-0-v0 | 11 | `third_species_triple_meter_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-0-v0 | 11 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-0-v0 | 11 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples-0-v0 | 11 | `fifth_species_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-1-v0 | 10 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples-1-v0 | 10 | `second_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-1-v0 | 10 | `third_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-1-v0 | 10 | `third_species_triple_meter_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-1-v0 | 10 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-1-v0 | 10 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples-1-v0 | 10 | `fifth_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-2-v0 | 12 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples-2-v0 | 12 | `second_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-2-v0 | 12 | `third_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-2-v0 | 12 | `third_species_triple_meter_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-2-v0 | 12 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-2-v0 | 12 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples-2-v0 | 12 | `fifth_species_melody` | 0.565 | 0.563 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-3-v0 | 14 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples-3-v0 | 14 | `second_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-3-v0 | 14 | `third_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-3-v0 | 14 | `third_species_triple_meter_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-3-v0 | 14 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-3-v0 | 14 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples-3-v0 | 14 | `fifth_species_melody` | 0.564 | 0.562 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-4-v0 | 12 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples-4-v0 | 12 | `second_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-4-v0 | 12 | `third_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-4-v0 | 12 | `third_species_triple_meter_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-4-v0 | 12 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-4-v0 | 12 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples-4-v0 | 12 | `fifth_species_melody` | 0.565 | 0.563 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-5-v0 | 12 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples-5-v0 | 12 | `second_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-5-v0 | 12 | `third_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-5-v0 | 12 | `third_species_triple_meter_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-5-v0 | 12 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-5-v0 | 12 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples-5-v0 | 12 | `fifth_species_melody` | 0.565 | 0.563 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-6-v0 | 9 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples-6-v0 | 9 | `second_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-6-v0 | 9 | `third_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-6-v0 | 9 | `third_species_triple_meter_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-6-v0 | 9 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples-6-v0 | 9 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples-6-v0 | 9 | `fifth_species_melody` | 0.570 | 0.568 | -0.001 | yes | reweighted |
| clendinning_cantus_firmus_examples-0-v0 | 12 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| clendinning_cantus_firmus_examples-0-v0 | 12 | `second_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| clendinning_cantus_firmus_examples-0-v0 | 12 | `third_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| clendinning_cantus_firmus_examples-0-v0 | 12 | `third_species_triple_meter_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| clendinning_cantus_firmus_examples-0-v0 | 12 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| clendinning_cantus_firmus_examples-0-v0 | 12 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| clendinning_cantus_firmus_examples-0-v0 | 12 | `fifth_species_melody` | 0.565 | 0.563 | -0.001 | yes | reweighted |
| clendinning_cantus_firmus_examples-1-v0 | 9 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| clendinning_cantus_firmus_examples-1-v0 | 9 | `second_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| clendinning_cantus_firmus_examples-1-v0 | 9 | `third_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| clendinning_cantus_firmus_examples-1-v0 | 9 | `third_species_triple_meter_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| clendinning_cantus_firmus_examples-1-v0 | 9 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| clendinning_cantus_firmus_examples-1-v0 | 9 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| clendinning_cantus_firmus_examples-1-v0 | 9 | `fifth_species_melody` | 0.570 | 0.568 | -0.001 | yes | reweighted |
| clendinning_cantus_firmus_examples-2-v0 | 11 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| clendinning_cantus_firmus_examples-2-v0 | 11 | `second_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| clendinning_cantus_firmus_examples-2-v0 | 11 | `third_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| clendinning_cantus_firmus_examples-2-v0 | 11 | `third_species_triple_meter_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| clendinning_cantus_firmus_examples-2-v0 | 11 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| clendinning_cantus_firmus_examples-2-v0 | 11 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| clendinning_cantus_firmus_examples-2-v0 | 11 | `fifth_species_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| clendinning_cantus_firmus_examples-3-v0 | 12 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| clendinning_cantus_firmus_examples-3-v0 | 12 | `second_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| clendinning_cantus_firmus_examples-3-v0 | 12 | `third_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| clendinning_cantus_firmus_examples-3-v0 | 12 | `third_species_triple_meter_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| clendinning_cantus_firmus_examples-3-v0 | 12 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| clendinning_cantus_firmus_examples-3-v0 | 12 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| clendinning_cantus_firmus_examples-3-v0 | 12 | `fifth_species_melody` | 0.565 | 0.563 | -0.001 | yes | reweighted |
| schoenberg_cantus_firmus_examples-0-v0 | 8 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| schoenberg_cantus_firmus_examples-0-v0 | 8 | `second_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| schoenberg_cantus_firmus_examples-0-v0 | 8 | `third_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| schoenberg_cantus_firmus_examples-0-v0 | 8 | `third_species_triple_meter_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| schoenberg_cantus_firmus_examples-0-v0 | 8 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| schoenberg_cantus_firmus_examples-0-v0 | 8 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| schoenberg_cantus_firmus_examples-0-v0 | 8 | `fifth_species_melody` | 0.574 | 0.572 | -0.001 | yes | reweighted |
| schoenberg_cantus_firmus_examples-1-v0 | 8 | `fux_cantus_firmus` | 0.952 | 0.959 | +0.007 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-0-v0 | 10 | `fux_cantus_firmus` | 0.976 | 0.986 | +0.010 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-0-v0 | 10 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-0-v0 | 10 | `second_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-0-v0 | 10 | `third_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-0-v0 | 10 | `third_species_triple_meter_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-0-v0 | 10 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-0-v0 | 10 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-0-v0 | 10 | `fifth_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-1-v0 | 9 | `fux_cantus_firmus` | 0.972 | 0.984 | +0.012 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-1-v0 | 9 | `first_species_melody` | 0.976 | 0.979 | +0.003 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-1-v0 | 9 | `second_species_melody` | 0.861 | 0.864 | +0.003 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-1-v0 | 9 | `third_species_melody` | 0.861 | 0.864 | +0.003 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-1-v0 | 9 | `third_species_triple_meter_melody` | 0.861 | 0.864 | +0.003 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-1-v0 | 9 | `fourth_species_melody` | 0.979 | 0.982 | +0.003 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-1-v0 | 9 | `combined_first_second_third_species_melody` | 0.976 | 0.979 | +0.003 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-1-v0 | 9 | `fifth_species_melody` | 0.558 | 0.562 | +0.003 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-2-v0 | 11 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-2-v0 | 11 | `second_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-2-v0 | 11 | `third_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-2-v0 | 11 | `third_species_triple_meter_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-2-v0 | 11 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-2-v0 | 11 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-2-v0 | 11 | `fifth_species_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-3-v0 | 10 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-3-v0 | 10 | `second_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-3-v0 | 10 | `third_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-3-v0 | 10 | `third_species_triple_meter_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-3-v0 | 10 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-3-v0 | 10 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-3-v0 | 10 | `fifth_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-4-v0 | 10 | `fux_cantus_firmus` | 0.961 | 0.978 | +0.017 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-4-v0 | 10 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-4-v0 | 10 | `second_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-4-v0 | 10 | `third_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-4-v0 | 10 | `third_species_triple_meter_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-4-v0 | 10 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-4-v0 | 10 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-4-v0 | 10 | `fifth_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-5-v0 | 10 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-5-v0 | 10 | `second_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-5-v0 | 10 | `third_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-5-v0 | 10 | `third_species_triple_meter_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-5-v0 | 10 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-5-v0 | 10 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-5-v0 | 10 | `fifth_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-6-v0 | 10 | `fux_cantus_firmus` | 0.969 | 0.982 | +0.013 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-6-v0 | 10 | `first_species_melody` | 0.974 | 0.978 | +0.004 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-6-v0 | 10 | `second_species_melody` | 0.860 | 0.863 | +0.004 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-6-v0 | 10 | `third_species_melody` | 0.860 | 0.863 | +0.004 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-6-v0 | 10 | `third_species_triple_meter_melody` | 0.860 | 0.863 | +0.004 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-6-v0 | 10 | `fourth_species_melody` | 0.978 | 0.982 | +0.004 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-6-v0 | 10 | `combined_first_second_third_species_melody` | 0.974 | 0.978 | +0.004 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-6-v0 | 10 | `fifth_species_melody` | 0.555 | 0.559 | +0.004 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-7-v0 | 10 | `fux_cantus_firmus` | 0.961 | 0.978 | +0.017 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-7-v0 | 10 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-7-v0 | 10 | `second_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-7-v0 | 10 | `third_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-7-v0 | 10 | `third_species_triple_meter_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-7-v0 | 10 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-7-v0 | 10 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-7-v0 | 10 | `fifth_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-8-v0 | 11 | `fux_cantus_firmus` | 0.980 | 0.988 | +0.009 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-8-v0 | 11 | `first_species_melody` | 0.979 | 0.981 | +0.002 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-8-v0 | 11 | `second_species_melody` | 0.864 | 0.866 | +0.002 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-8-v0 | 11 | `third_species_melody` | 0.864 | 0.866 | +0.002 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-8-v0 | 11 | `third_species_triple_meter_melody` | 0.864 | 0.866 | +0.002 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-8-v0 | 11 | `fourth_species_melody` | 0.982 | 0.984 | +0.002 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-8-v0 | 11 | `combined_first_second_third_species_melody` | 0.979 | 0.981 | +0.002 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-8-v0 | 11 | `fifth_species_melody` | 0.557 | 0.559 | +0.002 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-9-v0 | 11 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-9-v0 | 11 | `second_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-9-v0 | 11 | `third_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-9-v0 | 11 | `third_species_triple_meter_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-9-v0 | 11 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-9-v0 | 11 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| davis_and_lybbert_cantus_firmus_examples-9-v0 | 11 | `fifth_species_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-0-v0 | 12 | `fux_cantus_firmus` | 0.976 | 0.973 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-0-v0 | 12 | `salzer_schachter_cantus_firmus` | 0.978 | 0.974 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-0-v0 | 12 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-0-v0 | 12 | `second_species_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-0-v0 | 12 | `third_species_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-0-v0 | 12 | `third_species_triple_meter_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-0-v0 | 12 | `fourth_species_melody` | 0.981 | 0.978 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-0-v0 | 12 | `combined_first_second_third_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-0-v0 | 12 | `fifth_species_melody` | 0.555 | 0.552 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-1-v0 | 7 | `fux_cantus_firmus` | 0.974 | 0.981 | +0.007 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-1-v0 | 7 | `salzer_schachter_cantus_firmus` | 0.993 | 0.991 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-1-v0 | 7 | `first_species_melody` | 0.980 | 0.982 | +0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-1-v0 | 7 | `second_species_melody` | 0.865 | 0.867 | +0.002 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-1-v0 | 7 | `third_species_melody` | 0.865 | 0.867 | +0.002 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-1-v0 | 7 | `third_species_triple_meter_melody` | 0.865 | 0.867 | +0.002 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-1-v0 | 7 | `fourth_species_melody` | 0.983 | 0.985 | +0.002 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-1-v0 | 7 | `combined_first_second_third_species_melody` | 0.980 | 0.982 | +0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-1-v0 | 7 | `fifth_species_melody` | 0.573 | 0.575 | +0.002 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `fux_cantus_firmus` | 0.976 | 0.973 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `salzer_schachter_cantus_firmus` | 0.978 | 0.974 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `diatonic_melody` | 0.965 | 0.955 | -0.010 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `first_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `second_species_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `third_species_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `third_species_triple_meter_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `fourth_species_melody` | 0.981 | 0.978 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `combined_first_second_third_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `fifth_species_melody` | 0.556 | 0.553 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `arch_contour_melody` | 0.987 | 0.983 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `ascending_contour_melody` | 0.605 | 0.601 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `descending_contour_melody` | 0.605 | 0.601 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `static_contour_melody` | 0.605 | 0.601 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `valley_contour_melody` | 0.605 | 0.601 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-2-v0 | 11 | `wave_contour_melody` | 0.605 | 0.601 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `fux_cantus_firmus` | 0.992 | 0.991 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `salzer_schachter_cantus_firmus` | 0.993 | 0.992 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `diatonic_melody` | 0.989 | 0.986 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `first_species_melody` | 0.985 | 0.982 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `second_species_melody` | 0.869 | 0.867 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `third_species_melody` | 0.869 | 0.867 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `third_species_triple_meter_melody` | 0.869 | 0.867 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `fourth_species_melody` | 0.987 | 0.985 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `combined_first_second_third_species_melody` | 0.985 | 0.982 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `fifth_species_melody` | 0.563 | 0.561 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `arch_contour_melody` | 0.996 | 0.994 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `ascending_contour_melody` | 0.614 | 0.613 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `descending_contour_melody` | 0.614 | 0.613 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `static_contour_melody` | 0.614 | 0.613 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `valley_contour_melody` | 0.614 | 0.613 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-3-v0 | 11 | `wave_contour_melody` | 0.996 | 0.994 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-4-v0 | 9 | `fux_cantus_firmus` | 0.976 | 0.973 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-4-v0 | 9 | `salzer_schachter_cantus_firmus` | 0.978 | 0.974 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-4-v0 | 9 | `first_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-4-v0 | 9 | `second_species_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-4-v0 | 9 | `third_species_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-4-v0 | 9 | `third_species_triple_meter_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-4-v0 | 9 | `fourth_species_melody` | 0.981 | 0.978 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-4-v0 | 9 | `combined_first_second_third_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-4-v0 | 9 | `fifth_species_melody` | 0.560 | 0.557 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-5-v0 | 8 | `fux_cantus_firmus` | 0.976 | 0.986 | +0.010 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-5-v0 | 8 | `first_species_melody` | 0.978 | 0.980 | +0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-5-v0 | 8 | `second_species_melody` | 0.863 | 0.865 | +0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-5-v0 | 8 | `third_species_melody` | 0.863 | 0.865 | +0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-5-v0 | 8 | `third_species_triple_meter_melody` | 0.863 | 0.865 | +0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-5-v0 | 8 | `fourth_species_melody` | 0.981 | 0.983 | +0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-5-v0 | 8 | `combined_first_second_third_species_melody` | 0.978 | 0.980 | +0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-5-v0 | 8 | `fifth_species_melody` | 0.564 | 0.567 | +0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `fux_cantus_firmus` | 0.938 | 0.964 | +0.027 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `salzer_schachter_cantus_firmus` | 0.927 | 0.957 | +0.030 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `diatonic_melody` | 0.888 | 0.927 | +0.040 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `first_species_melody` | 0.952 | 0.965 | +0.013 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `second_species_melody` | 0.841 | 0.853 | +0.012 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `third_species_melody` | 0.841 | 0.853 | +0.012 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `third_species_triple_meter_melody` | 0.841 | 0.853 | +0.012 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `fourth_species_melody` | 0.959 | 0.971 | +0.012 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `combined_first_second_third_species_melody` | 0.952 | 0.965 | +0.013 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `fifth_species_melody` | 0.532 | 0.544 | +0.012 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `arch_contour_melody` | 0.957 | 0.972 | +0.015 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `ascending_contour_melody` | 0.575 | 0.590 | +0.015 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `descending_contour_melody` | 0.575 | 0.590 | +0.015 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `static_contour_melody` | 0.575 | 0.590 | +0.015 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `valley_contour_melody` | 0.575 | 0.590 | +0.015 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-6-v0 | 14 | `wave_contour_melody` | 0.957 | 0.972 | +0.015 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `fux_cantus_firmus` | 0.939 | 0.965 | +0.026 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `salzer_schachter_cantus_firmus` | 0.942 | 0.966 | +0.024 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `diatonic_melody` | 0.911 | 0.942 | +0.031 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `first_species_melody` | 0.960 | 0.970 | +0.010 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `second_species_melody` | 0.847 | 0.856 | +0.009 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `third_species_melody` | 0.847 | 0.856 | +0.009 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `third_species_triple_meter_melody` | 0.847 | 0.856 | +0.009 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `fourth_species_melody` | 0.965 | 0.974 | +0.009 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `combined_first_second_third_species_melody` | 0.960 | 0.970 | +0.010 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `fifth_species_melody` | 0.539 | 0.548 | +0.009 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `arch_contour_melody` | 0.966 | 0.978 | +0.012 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `ascending_contour_melody` | 0.584 | 0.596 | +0.012 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `descending_contour_melody` | 0.584 | 0.596 | +0.012 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `static_contour_melody` | 0.584 | 0.596 | +0.012 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `valley_contour_melody` | 0.584 | 0.596 | +0.012 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-7-v0 | 13 | `wave_contour_melody` | 0.966 | 0.978 | +0.012 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-8-v0 | 11 | `fux_cantus_firmus` | 0.976 | 0.973 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-8-v0 | 11 | `salzer_schachter_cantus_firmus` | 0.978 | 0.974 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-8-v0 | 11 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-8-v0 | 11 | `second_species_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-8-v0 | 11 | `third_species_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-8-v0 | 11 | `third_species_triple_meter_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-8-v0 | 11 | `fourth_species_melody` | 0.981 | 0.978 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-8-v0 | 11 | `combined_first_second_third_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-8-v0 | 11 | `fifth_species_melody` | 0.556 | 0.553 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-9-v0 | 11 | `fux_cantus_firmus` | 0.961 | 0.956 | -0.006 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-9-v0 | 11 | `salzer_schachter_cantus_firmus` | 0.964 | 0.957 | -0.006 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-9-v0 | 11 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-9-v0 | 11 | `second_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-9-v0 | 11 | `third_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-9-v0 | 11 | `third_species_triple_meter_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-9-v0 | 11 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-9-v0 | 11 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-9-v0 | 11 | `fifth_species_melody` | 0.570 | 0.568 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-10-v0 | 10 | `fux_cantus_firmus` | 0.976 | 0.986 | +0.010 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-10-v0 | 10 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-10-v0 | 10 | `second_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-10-v0 | 10 | `third_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-10-v0 | 10 | `third_species_triple_meter_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-10-v0 | 10 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-10-v0 | 10 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-10-v0 | 10 | `fifth_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `fux_cantus_firmus` | 0.976 | 0.973 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `salzer_schachter_cantus_firmus` | 0.978 | 0.974 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `diatonic_melody` | 0.965 | 0.955 | -0.010 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `first_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `second_species_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `third_species_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `third_species_triple_meter_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `fourth_species_melody` | 0.981 | 0.978 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `combined_first_second_third_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `fifth_species_melody` | 0.560 | 0.557 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `arch_contour_melody` | 0.987 | 0.983 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `ascending_contour_melody` | 0.605 | 0.601 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `descending_contour_melody` | 0.605 | 0.601 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `static_contour_melody` | 0.605 | 0.601 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `valley_contour_melody` | 0.605 | 0.601 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-11-v0 | 9 | `wave_contour_melody` | 0.605 | 0.601 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `fux_cantus_firmus` | 0.913 | 0.901 | -0.012 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `salzer_schachter_cantus_firmus` | 0.918 | 0.904 | -0.014 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `diatonic_melody` | 0.911 | 0.885 | -0.026 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `first_species_melody` | 0.949 | 0.939 | -0.009 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `second_species_melody` | 0.838 | 0.831 | -0.007 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `third_species_melody` | 0.838 | 0.831 | -0.007 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `third_species_triple_meter_melody` | 0.838 | 0.831 | -0.007 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `fourth_species_melody` | 0.956 | 0.949 | -0.007 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `combined_first_second_third_species_melody` | 0.949 | 0.939 | -0.009 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `fifth_species_melody` | 0.529 | 0.522 | -0.007 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `arch_contour_melody` | 0.966 | 0.956 | -0.010 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `ascending_contour_melody` | 0.584 | 0.574 | -0.010 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `descending_contour_melody` | 0.584 | 0.574 | -0.010 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `static_contour_melody` | 0.584 | 0.574 | -0.010 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `valley_contour_melody` | 0.584 | 0.574 | -0.010 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-12-v0 | 15 | `wave_contour_melody` | 0.966 | 0.956 | -0.010 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-13-v0 | 12 | `fux_cantus_firmus` | 0.976 | 0.973 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-13-v0 | 12 | `salzer_schachter_cantus_firmus` | 0.978 | 0.974 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-13-v0 | 12 | `first_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-13-v0 | 12 | `second_species_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-13-v0 | 12 | `third_species_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-13-v0 | 12 | `third_species_triple_meter_melody` | 0.863 | 0.860 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-13-v0 | 12 | `fourth_species_melody` | 0.981 | 0.978 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-13-v0 | 12 | `combined_first_second_third_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-13-v0 | 12 | `fifth_species_melody` | 0.555 | 0.552 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-14-v0 | 10 | `fux_cantus_firmus` | 0.976 | 0.973 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-14-v0 | 10 | `salzer_schachter_cantus_firmus` | 0.978 | 0.974 | -0.004 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-14-v0 | 10 | `first_species_melody` | 0.982 | 0.979 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-14-v0 | 10 | `second_species_melody` | 0.866 | 0.864 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-14-v0 | 10 | `third_species_melody` | 0.866 | 0.864 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-14-v0 | 10 | `third_species_triple_meter_melody` | 0.866 | 0.864 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-14-v0 | 10 | `fourth_species_melody` | 0.984 | 0.982 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-14-v0 | 10 | `combined_first_second_third_species_melody` | 0.982 | 0.979 | -0.003 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-14-v0 | 10 | `fifth_species_melody` | 0.561 | 0.559 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-15-v0 | 15 | `fux_cantus_firmus` | 0.998 | 0.998 | -0.000 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-15-v0 | 15 | `salzer_schachter_cantus_firmus` | 0.998 | 0.998 | -0.000 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-15-v0 | 15 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-15-v0 | 15 | `second_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-15-v0 | 15 | `third_species_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-15-v0 | 15 | `third_species_triple_meter_melody` | 0.872 | 0.871 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-15-v0 | 15 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-15-v0 | 15 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_cantus_firmus_examples_with_errors-15-v0 | 15 | `fifth_species_melody` | 0.564 | 0.562 | -0.001 | yes | reweighted |
| fux_first_species_examples-0-v0 | 11 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-0-v0 | 11 | `second_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| fux_first_species_examples-0-v0 | 11 | `third_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| fux_first_species_examples-0-v0 | 11 | `third_species_triple_meter_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| fux_first_species_examples-0-v0 | 11 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_first_species_examples-0-v0 | 11 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-0-v0 | 11 | `fifth_species_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| fux_first_species_examples-0-v1 | 11 | `fux_cantus_firmus` | 0.914 | 0.901 | -0.012 | yes | reweighted |
| fux_first_species_examples-0-v1 | 11 | `salzer_schachter_cantus_firmus` | 0.941 | 0.931 | -0.010 | yes | reweighted |
| fux_first_species_examples-0-v1 | 11 | `second_species_melody` | 0.561 | 0.559 | -0.002 | yes | reweighted |
| fux_first_species_examples-0-v1 | 11 | `third_species_melody` | 0.561 | 0.559 | -0.002 | yes | reweighted |
| fux_first_species_examples-0-v1 | 11 | `third_species_triple_meter_melody` | 0.561 | 0.559 | -0.002 | yes | reweighted |
| fux_first_species_examples-0-v1 | 11 | `fourth_species_melody` | 0.984 | 0.982 | -0.002 | yes | reweighted |
| fux_first_species_examples-0-v1 | 11 | `combined_first_second_third_species_melody` | 0.982 | 0.979 | -0.003 | yes | reweighted |
| fux_first_species_examples-0-v1 | 11 | `fifth_species_melody` | 0.560 | 0.557 | -0.002 | yes | reweighted |
| fux_first_species_examples-1-v0 | 11 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-1-v0 | 11 | `first_species_harmony` | 0.853 | 0.893 | +0.041 | yes | reweighted |
| fux_first_species_examples-1-v0 | 11 | `second_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| fux_first_species_examples-1-v0 | 11 | `second_species_harmony` | 0.867 | 0.905 | +0.038 | yes | reweighted |
| fux_first_species_examples-1-v0 | 11 | `third_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| fux_first_species_examples-1-v0 | 11 | `third_species_harmony` | 0.867 | 0.905 | +0.038 | yes | reweighted |
| fux_first_species_examples-1-v0 | 11 | `third_species_triple_meter_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| fux_first_species_examples-1-v0 | 11 | `third_species_triple_meter_harmony` | 0.867 | 0.905 | +0.038 | yes | reweighted |
| fux_first_species_examples-1-v0 | 11 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_first_species_examples-1-v0 | 11 | `fourth_species_harmony` | 0.879 | 0.915 | +0.035 | yes | reweighted |
| fux_first_species_examples-1-v0 | 11 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-1-v0 | 11 | `combined_first_second_third_species_harmony` | 0.834 | 0.878 | +0.044 | yes | reweighted |
| fux_first_species_examples-1-v0 | 11 | `fifth_species_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| fux_first_species_examples-1-v0 | 11 | `fifth_species_harmony` | 0.889 | 0.922 | +0.033 | yes | reweighted |
| fux_first_species_examples-1-v1 | 11 | `fux_cantus_firmus` | 0.928 | 0.932 | +0.003 | yes | reweighted |
| fux_first_species_examples-1-v1 | 11 | `salzer_schachter_cantus_firmus` | 0.978 | 0.974 | -0.004 | yes | reweighted |
| fux_first_species_examples-1-v1 | 11 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-1-v1 | 11 | `first_species_harmony` | 0.853 | 0.893 | +0.041 | yes | reweighted |
| fux_first_species_examples-1-v1 | 11 | `second_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| fux_first_species_examples-1-v1 | 11 | `second_species_harmony` | 0.867 | 0.905 | +0.038 | yes | reweighted |
| fux_first_species_examples-1-v1 | 11 | `third_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| fux_first_species_examples-1-v1 | 11 | `third_species_harmony` | 0.867 | 0.905 | +0.038 | yes | reweighted |
| fux_first_species_examples-1-v1 | 11 | `third_species_triple_meter_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| fux_first_species_examples-1-v1 | 11 | `third_species_triple_meter_harmony` | 0.867 | 0.905 | +0.038 | yes | reweighted |
| fux_first_species_examples-1-v1 | 11 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_first_species_examples-1-v1 | 11 | `fourth_species_harmony` | 0.879 | 0.915 | +0.035 | yes | reweighted |
| fux_first_species_examples-1-v1 | 11 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-1-v1 | 11 | `combined_first_second_third_species_harmony` | 0.834 | 0.878 | +0.044 | yes | reweighted |
| fux_first_species_examples-1-v1 | 11 | `fifth_species_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| fux_first_species_examples-1-v1 | 11 | `fifth_species_harmony` | 0.889 | 0.922 | +0.033 | yes | reweighted |
| fux_first_species_examples-2-v0 | 11 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-2-v0 | 11 | `second_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| fux_first_species_examples-2-v0 | 11 | `third_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| fux_first_species_examples-2-v0 | 11 | `third_species_triple_meter_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| fux_first_species_examples-2-v0 | 11 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_first_species_examples-2-v0 | 11 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-2-v0 | 11 | `fifth_species_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| fux_first_species_examples-2-v1 | 11 | `fux_cantus_firmus` | 0.928 | 0.932 | +0.003 | yes | reweighted |
| fux_first_species_examples-2-v1 | 11 | `salzer_schachter_cantus_firmus` | 0.978 | 0.974 | -0.004 | yes | reweighted |
| fux_first_species_examples-2-v1 | 11 | `second_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| fux_first_species_examples-2-v1 | 11 | `third_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| fux_first_species_examples-2-v1 | 11 | `third_species_triple_meter_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| fux_first_species_examples-2-v1 | 11 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_first_species_examples-2-v1 | 11 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-2-v1 | 11 | `fifth_species_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| fux_first_species_examples-3-v0 | 10 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-3-v0 | 10 | `second_species_melody` | 0.570 | 0.568 | -0.001 | yes | reweighted |
| fux_first_species_examples-3-v0 | 10 | `third_species_melody` | 0.570 | 0.568 | -0.001 | yes | reweighted |
| fux_first_species_examples-3-v0 | 10 | `third_species_triple_meter_melody` | 0.570 | 0.568 | -0.001 | yes | reweighted |
| fux_first_species_examples-3-v0 | 10 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_first_species_examples-3-v0 | 10 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-3-v0 | 10 | `fifth_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| fux_first_species_examples-3-v1 | 10 | `fux_cantus_firmus` | 0.952 | 0.945 | -0.007 | yes | reweighted |
| fux_first_species_examples-3-v1 | 10 | `salzer_schachter_cantus_firmus` | 0.978 | 0.974 | -0.004 | yes | reweighted |
| fux_first_species_examples-4-v0 | 10 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-4-v0 | 10 | `second_species_melody` | 0.570 | 0.568 | -0.001 | yes | reweighted |
| fux_first_species_examples-4-v0 | 10 | `third_species_melody` | 0.570 | 0.568 | -0.001 | yes | reweighted |
| fux_first_species_examples-4-v0 | 10 | `third_species_triple_meter_melody` | 0.570 | 0.568 | -0.001 | yes | reweighted |
| fux_first_species_examples-4-v0 | 10 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_first_species_examples-4-v0 | 10 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-4-v0 | 10 | `fifth_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| fux_first_species_examples-4-v1 | 10 | `fux_cantus_firmus` | 0.890 | 0.896 | +0.006 | yes | reweighted |
| fux_first_species_examples-4-v1 | 10 | `salzer_schachter_cantus_firmus` | 0.933 | 0.934 | +0.002 | yes | reweighted |
| fux_first_species_examples-4-v1 | 10 | `diatonic_melody` | 0.931 | 0.933 | +0.002 | yes | reweighted |
| fux_first_species_examples-4-v1 | 10 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-4-v1 | 10 | `second_species_melody` | 0.560 | 0.557 | -0.003 | yes | reweighted |
| fux_first_species_examples-4-v1 | 10 | `third_species_melody` | 0.560 | 0.557 | -0.003 | yes | reweighted |
| fux_first_species_examples-4-v1 | 10 | `third_species_triple_meter_melody` | 0.560 | 0.557 | -0.003 | yes | reweighted |
| fux_first_species_examples-4-v1 | 10 | `fourth_species_melody` | 0.981 | 0.978 | -0.003 | yes | reweighted |
| fux_first_species_examples-4-v1 | 10 | `combined_first_second_third_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| fux_first_species_examples-4-v1 | 10 | `fifth_species_melody` | 0.558 | 0.555 | -0.003 | yes | reweighted |
| fux_first_species_examples-4-v1 | 10 | `arch_contour_melody` | 0.592 | 0.592 | +0.001 | yes | reweighted |
| fux_first_species_examples-4-v1 | 10 | `ascending_contour_melody` | 0.592 | 0.592 | +0.001 | yes | reweighted |
| fux_first_species_examples-4-v1 | 10 | `descending_contour_melody` | 0.592 | 0.592 | +0.001 | yes | reweighted |
| fux_first_species_examples-4-v1 | 10 | `static_contour_melody` | 0.592 | 0.592 | +0.001 | yes | reweighted |
| fux_first_species_examples-4-v1 | 10 | `valley_contour_melody` | 0.973 | 0.974 | +0.001 | yes | reweighted |
| fux_first_species_examples-4-v1 | 10 | `wave_contour_melody` | 0.973 | 0.974 | +0.001 | yes | reweighted |
| fux_first_species_examples-5-v0 | 10 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-5-v0 | 10 | `second_species_melody` | 0.570 | 0.568 | -0.001 | yes | reweighted |
| fux_first_species_examples-5-v0 | 10 | `third_species_melody` | 0.570 | 0.568 | -0.001 | yes | reweighted |
| fux_first_species_examples-5-v0 | 10 | `third_species_triple_meter_melody` | 0.570 | 0.568 | -0.001 | yes | reweighted |
| fux_first_species_examples-5-v0 | 10 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_first_species_examples-5-v0 | 10 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-5-v0 | 10 | `fifth_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| fux_first_species_examples-5-v1 | 10 | `fux_cantus_firmus` | 0.899 | 0.906 | +0.008 | yes | reweighted |
| fux_first_species_examples-5-v1 | 10 | `salzer_schachter_cantus_firmus` | 0.941 | 0.944 | +0.003 | yes | reweighted |
| fux_first_species_examples-5-v1 | 10 | `diatonic_melody` | 0.965 | 0.978 | +0.012 | yes | reweighted |
| fux_first_species_examples-5-v1 | 10 | `second_species_melody` | 0.564 | 0.561 | -0.002 | yes | reweighted |
| fux_first_species_examples-5-v1 | 10 | `third_species_melody` | 0.564 | 0.561 | -0.002 | yes | reweighted |
| fux_first_species_examples-5-v1 | 10 | `third_species_triple_meter_melody` | 0.564 | 0.561 | -0.002 | yes | reweighted |
| fux_first_species_examples-5-v1 | 10 | `fourth_species_melody` | 0.984 | 0.982 | -0.002 | yes | reweighted |
| fux_first_species_examples-5-v1 | 10 | `combined_first_second_third_species_melody` | 0.982 | 0.979 | -0.003 | yes | reweighted |
| fux_first_species_examples-5-v1 | 10 | `fifth_species_melody` | 0.561 | 0.559 | -0.002 | yes | reweighted |
| fux_first_species_examples-5-v1 | 10 | `arch_contour_melody` | 0.605 | 0.609 | +0.005 | yes | reweighted |
| fux_first_species_examples-5-v1 | 10 | `ascending_contour_melody` | 0.605 | 0.609 | +0.005 | yes | reweighted |
| fux_first_species_examples-5-v1 | 10 | `descending_contour_melody` | 0.605 | 0.609 | +0.005 | yes | reweighted |
| fux_first_species_examples-5-v1 | 10 | `static_contour_melody` | 0.605 | 0.609 | +0.005 | yes | reweighted |
| fux_first_species_examples-5-v1 | 10 | `valley_contour_melody` | 0.987 | 0.991 | +0.005 | yes | reweighted |
| fux_first_species_examples-5-v1 | 10 | `wave_contour_melody` | 0.987 | 0.991 | +0.005 | yes | reweighted |
| fux_first_species_examples-6-v0 | 12 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-6-v0 | 12 | `second_species_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| fux_first_species_examples-6-v0 | 12 | `third_species_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| fux_first_species_examples-6-v0 | 12 | `third_species_triple_meter_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| fux_first_species_examples-6-v0 | 12 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_first_species_examples-6-v0 | 12 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-6-v0 | 12 | `fifth_species_melody` | 0.565 | 0.563 | -0.001 | yes | reweighted |
| fux_first_species_examples-6-v1 | 12 | `fux_cantus_firmus` | 0.914 | 0.923 | +0.010 | yes | reweighted |
| fux_first_species_examples-6-v1 | 12 | `salzer_schachter_cantus_firmus` | 0.978 | 0.974 | -0.004 | yes | reweighted |
| fux_first_species_examples-6-v1 | 12 | `second_species_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| fux_first_species_examples-6-v1 | 12 | `third_species_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| fux_first_species_examples-6-v1 | 12 | `third_species_triple_meter_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| fux_first_species_examples-6-v1 | 12 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_first_species_examples-6-v1 | 12 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-6-v1 | 12 | `fifth_species_melody` | 0.565 | 0.563 | -0.001 | yes | reweighted |
| fux_first_species_examples-7-v0 | 12 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-7-v0 | 12 | `first_species_harmony` | 0.905 | 0.893 | -0.012 | yes | reweighted |
| fux_first_species_examples-7-v0 | 12 | `second_species_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| fux_first_species_examples-7-v0 | 12 | `second_species_harmony` | 0.915 | 0.905 | -0.009 | yes | reweighted |
| fux_first_species_examples-7-v0 | 12 | `third_species_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| fux_first_species_examples-7-v0 | 12 | `third_species_harmony` | 0.915 | 0.905 | -0.009 | yes | reweighted |
| fux_first_species_examples-7-v0 | 12 | `third_species_triple_meter_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| fux_first_species_examples-7-v0 | 12 | `third_species_triple_meter_harmony` | 0.915 | 0.905 | -0.009 | yes | reweighted |
| fux_first_species_examples-7-v0 | 12 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_first_species_examples-7-v0 | 12 | `fourth_species_harmony` | 0.922 | 0.915 | -0.008 | yes | reweighted |
| fux_first_species_examples-7-v0 | 12 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-7-v0 | 12 | `combined_first_second_third_species_harmony` | 0.893 | 0.878 | -0.015 | yes | reweighted |
| fux_first_species_examples-7-v0 | 12 | `fifth_species_melody` | 0.565 | 0.563 | -0.001 | yes | reweighted |
| fux_first_species_examples-7-v0 | 12 | `fifth_species_harmony` | 0.929 | 0.922 | -0.006 | yes | reweighted |
| fux_first_species_examples-7-v1 | 12 | `fux_cantus_firmus` | 0.976 | 0.973 | -0.003 | yes | reweighted |
| fux_first_species_examples-7-v1 | 12 | `first_species_harmony` | 0.810 | 0.786 | -0.024 | yes | reweighted |
| fux_first_species_examples-7-v1 | 12 | `second_species_harmony` | 0.829 | 0.810 | -0.019 | yes | reweighted |
| fux_first_species_examples-7-v1 | 12 | `third_species_harmony` | 0.829 | 0.810 | -0.019 | yes | reweighted |
| fux_first_species_examples-7-v1 | 12 | `third_species_triple_meter_harmony` | 0.829 | 0.810 | -0.019 | yes | reweighted |
| fux_first_species_examples-7-v1 | 12 | `fourth_species_harmony` | 0.845 | 0.829 | -0.016 | yes | reweighted |
| fux_first_species_examples-7-v1 | 12 | `combined_first_second_third_species_harmony` | 0.786 | 0.756 | -0.031 | yes | reweighted |
| fux_first_species_examples-7-v1 | 12 | `fifth_species_harmony` | 0.858 | 0.845 | -0.013 | yes | reweighted |
| fux_first_species_examples-8-v0 | 14 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-8-v0 | 14 | `second_species_melody` | 0.564 | 0.563 | -0.001 | yes | reweighted |
| fux_first_species_examples-8-v0 | 14 | `third_species_melody` | 0.564 | 0.563 | -0.001 | yes | reweighted |
| fux_first_species_examples-8-v0 | 14 | `third_species_triple_meter_melody` | 0.564 | 0.563 | -0.001 | yes | reweighted |
| fux_first_species_examples-8-v0 | 14 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_first_species_examples-8-v0 | 14 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-8-v0 | 14 | `fifth_species_melody` | 0.564 | 0.562 | -0.001 | yes | reweighted |
| fux_first_species_examples-8-v1 | 14 | `fux_cantus_firmus` | 0.875 | 0.879 | +0.004 | yes | reweighted |
| fux_first_species_examples-8-v1 | 14 | `salzer_schachter_cantus_firmus` | 0.941 | 0.931 | -0.010 | yes | reweighted |
| fux_first_species_examples-8-v1 | 14 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-8-v1 | 14 | `second_species_melody` | 0.548 | 0.545 | -0.004 | yes | reweighted |
| fux_first_species_examples-8-v1 | 14 | `third_species_melody` | 0.548 | 0.545 | -0.004 | yes | reweighted |
| fux_first_species_examples-8-v1 | 14 | `third_species_triple_meter_melody` | 0.548 | 0.545 | -0.004 | yes | reweighted |
| fux_first_species_examples-8-v1 | 14 | `fourth_species_melody` | 0.975 | 0.971 | -0.004 | yes | reweighted |
| fux_first_species_examples-8-v1 | 14 | `combined_first_second_third_species_melody` | 0.971 | 0.965 | -0.005 | yes | reweighted |
| fux_first_species_examples-8-v1 | 14 | `fifth_species_melody` | 0.548 | 0.544 | -0.004 | yes | reweighted |
| fux_first_species_examples-9-v0 | 14 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-9-v0 | 14 | `second_species_melody` | 0.564 | 0.563 | -0.001 | yes | reweighted |
| fux_first_species_examples-9-v0 | 14 | `third_species_melody` | 0.564 | 0.563 | -0.001 | yes | reweighted |
| fux_first_species_examples-9-v0 | 14 | `third_species_triple_meter_melody` | 0.564 | 0.563 | -0.001 | yes | reweighted |
| fux_first_species_examples-9-v0 | 14 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_first_species_examples-9-v0 | 14 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-9-v0 | 14 | `fifth_species_melody` | 0.564 | 0.562 | -0.001 | yes | reweighted |
| fux_first_species_examples-9-v1 | 14 | `fux_cantus_firmus` | 0.899 | 0.906 | +0.008 | yes | reweighted |
| fux_first_species_examples-9-v1 | 14 | `salzer_schachter_cantus_firmus` | 0.964 | 0.957 | -0.006 | yes | reweighted |
| fux_first_species_examples-9-v1 | 14 | `second_species_melody` | 0.558 | 0.556 | -0.002 | yes | reweighted |
| fux_first_species_examples-9-v1 | 14 | `third_species_melody` | 0.558 | 0.556 | -0.002 | yes | reweighted |
| fux_first_species_examples-9-v1 | 14 | `third_species_triple_meter_melody` | 0.558 | 0.556 | -0.002 | yes | reweighted |
| fux_first_species_examples-9-v1 | 14 | `fourth_species_melody` | 0.984 | 0.982 | -0.002 | yes | reweighted |
| fux_first_species_examples-9-v1 | 14 | `combined_first_second_third_species_melody` | 0.982 | 0.979 | -0.003 | yes | reweighted |
| fux_first_species_examples-9-v1 | 14 | `fifth_species_melody` | 0.558 | 0.555 | -0.002 | yes | reweighted |
| fux_first_species_examples-10-v0 | 14 | `first_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| fux_first_species_examples-10-v0 | 14 | `second_species_melody` | 0.554 | 0.551 | -0.003 | yes | reweighted |
| fux_first_species_examples-10-v0 | 14 | `third_species_melody` | 0.554 | 0.551 | -0.003 | yes | reweighted |
| fux_first_species_examples-10-v0 | 14 | `third_species_triple_meter_melody` | 0.554 | 0.551 | -0.003 | yes | reweighted |
| fux_first_species_examples-10-v0 | 14 | `fourth_species_melody` | 0.981 | 0.978 | -0.003 | yes | reweighted |
| fux_first_species_examples-10-v0 | 14 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-10-v0 | 14 | `fifth_species_melody` | 0.554 | 0.551 | -0.003 | yes | reweighted |
| fux_first_species_examples-10-v1 | 14 | `fux_cantus_firmus` | 0.928 | 0.932 | +0.003 | yes | reweighted |
| fux_first_species_examples-10-v1 | 14 | `salzer_schachter_cantus_firmus` | 0.955 | 0.960 | +0.005 | yes | reweighted |
| fux_first_species_examples-10-v1 | 14 | `diatonic_melody` | 0.965 | 0.978 | +0.012 | yes | reweighted |
| fux_first_species_examples-10-v1 | 14 | `first_species_harmony` | 0.958 | 0.952 | -0.005 | yes | reweighted |
| fux_first_species_examples-10-v1 | 14 | `second_species_melody` | 0.564 | 0.563 | -0.001 | yes | reweighted |
| fux_first_species_examples-10-v1 | 14 | `second_species_harmony` | 0.962 | 0.958 | -0.004 | yes | reweighted |
| fux_first_species_examples-10-v1 | 14 | `third_species_melody` | 0.564 | 0.563 | -0.001 | yes | reweighted |
| fux_first_species_examples-10-v1 | 14 | `third_species_harmony` | 0.962 | 0.958 | -0.004 | yes | reweighted |
| fux_first_species_examples-10-v1 | 14 | `third_species_triple_meter_melody` | 0.564 | 0.563 | -0.001 | yes | reweighted |
| fux_first_species_examples-10-v1 | 14 | `third_species_triple_meter_harmony` | 0.962 | 0.958 | -0.004 | yes | reweighted |
| fux_first_species_examples-10-v1 | 14 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_first_species_examples-10-v1 | 14 | `fourth_species_harmony` | 0.965 | 0.962 | -0.003 | yes | reweighted |
| fux_first_species_examples-10-v1 | 14 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-10-v1 | 14 | `combined_first_second_third_species_harmony` | 0.952 | 0.945 | -0.007 | yes | reweighted |
| fux_first_species_examples-10-v1 | 14 | `fifth_species_melody` | 0.564 | 0.562 | -0.001 | yes | reweighted |
| fux_first_species_examples-10-v1 | 14 | `fifth_species_harmony` | 0.968 | 0.965 | -0.003 | yes | reweighted |
| fux_first_species_examples-10-v1 | 14 | `arch_contour_melody` | 0.987 | 0.991 | +0.005 | yes | reweighted |
| fux_first_species_examples-10-v1 | 14 | `ascending_contour_melody` | 0.605 | 0.609 | +0.005 | yes | reweighted |
| fux_first_species_examples-10-v1 | 14 | `descending_contour_melody` | 0.605 | 0.609 | +0.005 | yes | reweighted |
| fux_first_species_examples-10-v1 | 14 | `static_contour_melody` | 0.605 | 0.609 | +0.005 | yes | reweighted |
| fux_first_species_examples-10-v1 | 14 | `valley_contour_melody` | 0.987 | 0.991 | +0.005 | yes | reweighted |
| fux_first_species_examples-10-v1 | 14 | `wave_contour_melody` | 0.987 | 0.991 | +0.005 | yes | reweighted |
| fux_first_species_examples-11-v0 | 12 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-11-v0 | 12 | `second_species_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| fux_first_species_examples-11-v0 | 12 | `third_species_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| fux_first_species_examples-11-v0 | 12 | `third_species_triple_meter_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| fux_first_species_examples-11-v0 | 12 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_first_species_examples-11-v0 | 12 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-11-v0 | 12 | `fifth_species_melody` | 0.565 | 0.563 | -0.001 | yes | reweighted |
| fux_first_species_examples-11-v1 | 12 | `fux_cantus_firmus` | 0.928 | 0.932 | +0.003 | yes | reweighted |
| fux_first_species_examples-11-v1 | 12 | `salzer_schachter_cantus_firmus` | 0.978 | 0.974 | -0.004 | yes | reweighted |
| fux_first_species_examples-11-v1 | 12 | `second_species_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| fux_first_species_examples-11-v1 | 12 | `third_species_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| fux_first_species_examples-11-v1 | 12 | `third_species_triple_meter_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| fux_first_species_examples-11-v1 | 12 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| fux_first_species_examples-11-v1 | 12 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-11-v1 | 12 | `fifth_species_melody` | 0.565 | 0.563 | -0.001 | yes | reweighted |
| fux_first_species_examples-12-v0 | 12 | `first_species_melody` | 0.978 | 0.973 | -0.004 | yes | reweighted |
| fux_first_species_examples-12-v0 | 12 | `second_species_melody` | 0.556 | 0.553 | -0.003 | yes | reweighted |
| fux_first_species_examples-12-v0 | 12 | `third_species_melody` | 0.556 | 0.553 | -0.003 | yes | reweighted |
| fux_first_species_examples-12-v0 | 12 | `third_species_triple_meter_melody` | 0.556 | 0.553 | -0.003 | yes | reweighted |
| fux_first_species_examples-12-v0 | 12 | `fourth_species_melody` | 0.981 | 0.978 | -0.003 | yes | reweighted |
| fux_first_species_examples-12-v0 | 12 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| fux_first_species_examples-12-v0 | 12 | `fifth_species_melody` | 0.555 | 0.552 | -0.003 | yes | reweighted |
| fux_first_species_examples-12-v1 | 12 | `fux_cantus_firmus` | 0.914 | 0.915 | +0.001 | yes | reweighted |
| fux_first_species_examples-12-v1 | 12 | `salzer_schachter_cantus_firmus` | 0.964 | 0.957 | -0.006 | yes | reweighted |
| fux_first_species_examples-12-v1 | 12 | `second_species_melody` | 0.560 | 0.557 | -0.002 | yes | reweighted |
| fux_first_species_examples-12-v1 | 12 | `third_species_melody` | 0.560 | 0.557 | -0.002 | yes | reweighted |
| fux_first_species_examples-12-v1 | 12 | `third_species_triple_meter_melody` | 0.560 | 0.557 | -0.002 | yes | reweighted |
| fux_first_species_examples-12-v1 | 12 | `fourth_species_melody` | 0.984 | 0.982 | -0.002 | yes | reweighted |
| fux_first_species_examples-12-v1 | 12 | `combined_first_second_third_species_melody` | 0.982 | 0.979 | -0.003 | yes | reweighted |
| fux_first_species_examples-12-v1 | 12 | `fifth_species_melody` | 0.559 | 0.556 | -0.002 | yes | reweighted |
| clendinning_first_species_examples-0-v0 | 12 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| clendinning_first_species_examples-0-v0 | 12 | `second_species_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| clendinning_first_species_examples-0-v0 | 12 | `third_species_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| clendinning_first_species_examples-0-v0 | 12 | `third_species_triple_meter_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| clendinning_first_species_examples-0-v0 | 12 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| clendinning_first_species_examples-0-v0 | 12 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| clendinning_first_species_examples-0-v0 | 12 | `fifth_species_melody` | 0.565 | 0.563 | -0.001 | yes | reweighted |
| clendinning_first_species_examples-0-v1 | 12 | `fux_cantus_firmus` | 0.976 | 0.973 | -0.003 | yes | reweighted |
| clendinning_first_species_examples-1-v0 | 9 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| clendinning_first_species_examples-1-v0 | 9 | `second_species_melody` | 0.574 | 0.572 | -0.001 | yes | reweighted |
| clendinning_first_species_examples-1-v0 | 9 | `third_species_melody` | 0.574 | 0.572 | -0.001 | yes | reweighted |
| clendinning_first_species_examples-1-v0 | 9 | `third_species_triple_meter_melody` | 0.574 | 0.572 | -0.001 | yes | reweighted |
| clendinning_first_species_examples-1-v0 | 9 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| clendinning_first_species_examples-1-v0 | 9 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| clendinning_first_species_examples-1-v0 | 9 | `fifth_species_melody` | 0.570 | 0.568 | -0.001 | yes | reweighted |
| clendinning_first_species_examples-1-v1 | 9 | `fux_cantus_firmus` | 0.976 | 0.973 | -0.003 | yes | reweighted |
| clendinning_first_species_examples-2-v0 | 11 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| clendinning_first_species_examples-2-v0 | 11 | `second_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| clendinning_first_species_examples-2-v0 | 11 | `third_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| clendinning_first_species_examples-2-v0 | 11 | `third_species_triple_meter_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| clendinning_first_species_examples-2-v0 | 11 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| clendinning_first_species_examples-2-v0 | 11 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| clendinning_first_species_examples-2-v0 | 11 | `fifth_species_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| clendinning_first_species_examples-2-v1 | 11 | `fux_cantus_firmus` | 0.952 | 0.945 | -0.007 | yes | reweighted |
| clendinning_first_species_examples-2-v1 | 11 | `salzer_schachter_cantus_firmus` | 0.978 | 0.974 | -0.004 | yes | reweighted |
| clendinning_first_species_examples-2-v1 | 11 | `second_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| clendinning_first_species_examples-2-v1 | 11 | `third_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| clendinning_first_species_examples-2-v1 | 11 | `third_species_triple_meter_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| clendinning_first_species_examples-2-v1 | 11 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| clendinning_first_species_examples-2-v1 | 11 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| clendinning_first_species_examples-2-v1 | 11 | `fifth_species_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| davis_and_lybbert_first_species_examples-0-v0 | 10 | `fux_cantus_firmus` | 0.976 | 0.986 | +0.010 | yes | reweighted |
| davis_and_lybbert_first_species_examples-0-v0 | 10 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| davis_and_lybbert_first_species_examples-0-v0 | 10 | `second_species_melody` | 0.570 | 0.568 | -0.001 | yes | reweighted |
| davis_and_lybbert_first_species_examples-0-v0 | 10 | `third_species_melody` | 0.570 | 0.568 | -0.001 | yes | reweighted |
| davis_and_lybbert_first_species_examples-0-v0 | 10 | `third_species_triple_meter_melody` | 0.570 | 0.568 | -0.001 | yes | reweighted |
| davis_and_lybbert_first_species_examples-0-v0 | 10 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| davis_and_lybbert_first_species_examples-0-v0 | 10 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| davis_and_lybbert_first_species_examples-0-v0 | 10 | `fifth_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| davis_and_lybbert_first_species_examples-0-v1 | 10 | `fux_cantus_firmus` | 0.928 | 0.932 | +0.003 | yes | reweighted |
| davis_and_lybbert_first_species_examples-0-v1 | 10 | `salzer_schachter_cantus_firmus` | 0.978 | 0.974 | -0.004 | yes | reweighted |
| davis_and_lybbert_first_species_examples-1-v0 | 11 | `first_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| davis_and_lybbert_first_species_examples-1-v0 | 11 | `second_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| davis_and_lybbert_first_species_examples-1-v0 | 11 | `third_species_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| davis_and_lybbert_first_species_examples-1-v0 | 11 | `third_species_triple_meter_melody` | 0.567 | 0.566 | -0.001 | yes | reweighted |
| davis_and_lybbert_first_species_examples-1-v0 | 11 | `fourth_species_melody` | 0.990 | 0.989 | -0.001 | yes | reweighted |
| davis_and_lybbert_first_species_examples-1-v0 | 11 | `combined_first_second_third_species_melody` | 0.989 | 0.987 | -0.002 | yes | reweighted |
| davis_and_lybbert_first_species_examples-1-v0 | 11 | `fifth_species_melody` | 0.566 | 0.564 | -0.001 | yes | reweighted |
| davis_and_lybbert_first_species_examples-1-v1 | 11 | `fux_cantus_firmus` | 0.976 | 0.973 | -0.003 | yes | reweighted |

## Demoted

`c3.json` → `c4.json`. 49 of 3266 rows moved, 3217 unchanged.

| why it moved | rows |
| --- | ---: |
| demoted | 49 |

| corpus | notes | guide | before | after | delta | assessable | why |
| --- | ---: | --- | ---: | ---: | ---: | --- | --- |
| against-cantus-4 | 4 | `first_species_harmony` | 0.551 | 0.410 | -0.141 | yes | demoted |
| against-cantus-4 | 4 | `second_species_harmony` | 0.696 | 0.869 | +0.173 | yes | demoted |
| against-cantus-4 | 4 | `third_species_harmony` | 0.696 | 0.869 | +0.173 | yes | demoted |
| against-cantus-4 | 4 | `third_species_triple_meter_harmony` | 0.696 | 0.869 | +0.173 | yes | demoted |
| against-cantus-4 | 4 | `fourth_species_harmony` | 0.665 | 0.840 | +0.175 | yes | demoted |
| against-cantus-4 | 4 | `combined_first_second_third_species_harmony` | 0.643 | 0.633 | -0.010 | yes | demoted |
| against-cantus-4 | 4 | `fifth_species_harmony` | 0.660 | 0.740 | +0.079 | yes | demoted |
| against-cantus-8 | 8 | `first_species_harmony` | 0.590 | 0.639 | +0.050 | yes | demoted |
| against-cantus-8 | 8 | `second_species_harmony` | 0.635 | 0.843 | +0.208 | yes | demoted |
| against-cantus-8 | 8 | `third_species_harmony` | 0.635 | 0.843 | +0.208 | yes | demoted |
| against-cantus-8 | 8 | `third_species_triple_meter_harmony` | 0.635 | 0.843 | +0.208 | yes | demoted |
| against-cantus-8 | 8 | `fourth_species_harmony` | 0.610 | 0.814 | +0.204 | yes | demoted |
| against-cantus-8 | 8 | `combined_first_second_third_species_harmony` | 0.531 | 0.461 | -0.070 | yes | demoted |
| against-cantus-8 | 8 | `fifth_species_harmony` | 0.589 | 0.644 | +0.054 | yes | demoted |
| fux_first_species_examples-1-v0 | 11 | `first_species_harmony` | 0.893 | 0.946 | +0.052 | yes | demoted |
| fux_first_species_examples-1-v0 | 11 | `second_species_harmony` | 0.905 | 0.959 | +0.054 | yes | demoted |
| fux_first_species_examples-1-v0 | 11 | `third_species_harmony` | 0.905 | 0.959 | +0.054 | yes | demoted |
| fux_first_species_examples-1-v0 | 11 | `third_species_triple_meter_harmony` | 0.905 | 0.959 | +0.054 | yes | demoted |
| fux_first_species_examples-1-v0 | 11 | `fourth_species_harmony` | 0.915 | 0.959 | +0.045 | yes | demoted |
| fux_first_species_examples-1-v0 | 11 | `combined_first_second_third_species_harmony` | 0.878 | 0.959 | +0.081 | yes | demoted |
| fux_first_species_examples-1-v0 | 11 | `fifth_species_harmony` | 0.922 | 0.964 | +0.041 | yes | demoted |
| fux_first_species_examples-1-v1 | 11 | `first_species_harmony` | 0.893 | 0.946 | +0.052 | yes | demoted |
| fux_first_species_examples-1-v1 | 11 | `second_species_harmony` | 0.905 | 0.959 | +0.054 | yes | demoted |
| fux_first_species_examples-1-v1 | 11 | `third_species_harmony` | 0.905 | 0.959 | +0.054 | yes | demoted |
| fux_first_species_examples-1-v1 | 11 | `third_species_triple_meter_harmony` | 0.905 | 0.959 | +0.054 | yes | demoted |
| fux_first_species_examples-1-v1 | 11 | `fourth_species_harmony` | 0.915 | 0.959 | +0.045 | yes | demoted |
| fux_first_species_examples-1-v1 | 11 | `combined_first_second_third_species_harmony` | 0.878 | 0.959 | +0.081 | yes | demoted |
| fux_first_species_examples-1-v1 | 11 | `fifth_species_harmony` | 0.922 | 0.964 | +0.041 | yes | demoted |
| fux_first_species_examples-7-v0 | 12 | `first_species_harmony` | 0.893 | 0.946 | +0.052 | yes | demoted |
| fux_first_species_examples-7-v0 | 12 | `second_species_harmony` | 0.905 | 0.959 | +0.054 | yes | demoted |
| fux_first_species_examples-7-v0 | 12 | `third_species_harmony` | 0.905 | 0.959 | +0.054 | yes | demoted |
| fux_first_species_examples-7-v0 | 12 | `third_species_triple_meter_harmony` | 0.905 | 0.959 | +0.054 | yes | demoted |
| fux_first_species_examples-7-v0 | 12 | `fourth_species_harmony` | 0.915 | 0.959 | +0.045 | yes | demoted |
| fux_first_species_examples-7-v0 | 12 | `combined_first_second_third_species_harmony` | 0.878 | 0.959 | +0.081 | yes | demoted |
| fux_first_species_examples-7-v0 | 12 | `fifth_species_harmony` | 0.922 | 0.964 | +0.041 | yes | demoted |
| fux_first_species_examples-7-v1 | 12 | `first_species_harmony` | 0.786 | 0.891 | +0.105 | yes | demoted |
| fux_first_species_examples-7-v1 | 12 | `second_species_harmony` | 0.810 | 0.918 | +0.108 | yes | demoted |
| fux_first_species_examples-7-v1 | 12 | `third_species_harmony` | 0.810 | 0.918 | +0.108 | yes | demoted |
| fux_first_species_examples-7-v1 | 12 | `third_species_triple_meter_harmony` | 0.810 | 0.918 | +0.108 | yes | demoted |
| fux_first_species_examples-7-v1 | 12 | `fourth_species_harmony` | 0.829 | 0.918 | +0.089 | yes | demoted |
| fux_first_species_examples-7-v1 | 12 | `combined_first_second_third_species_harmony` | 0.756 | 0.918 | +0.162 | yes | demoted |
| fux_first_species_examples-7-v1 | 12 | `fifth_species_harmony` | 0.845 | 0.928 | +0.083 | yes | demoted |
| fux_first_species_examples-10-v1 | 14 | `first_species_harmony` | 0.952 | 0.976 | +0.023 | yes | demoted |
| fux_first_species_examples-10-v1 | 14 | `second_species_harmony` | 0.958 | 0.982 | +0.024 | yes | demoted |
| fux_first_species_examples-10-v1 | 14 | `third_species_harmony` | 0.958 | 0.982 | +0.024 | yes | demoted |
| fux_first_species_examples-10-v1 | 14 | `third_species_triple_meter_harmony` | 0.958 | 0.982 | +0.024 | yes | demoted |
| fux_first_species_examples-10-v1 | 14 | `fourth_species_harmony` | 0.962 | 0.982 | +0.020 | yes | demoted |
| fux_first_species_examples-10-v1 | 14 | `combined_first_second_third_species_harmony` | 0.945 | 0.982 | +0.036 | yes | demoted |
| fux_first_species_examples-10-v1 | 14 | `fifth_species_harmony` | 0.965 | 0.984 | +0.019 | yes | demoted |
