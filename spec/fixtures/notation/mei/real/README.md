# Real MEI files

MEI encodings made outside head_music, copied unchanged for the reader's real-file specs.

## Bach chorales from the MEI sample encodings

| File | Source path |
| --- | --- |
| `Bach-JS_Herzliebster_Jesu_BWV244-46.mei` | `MEI_5.1/Music/Complete_examples/Bach-JS_Herzliebster_Jesu_BWV244-46.mei` |
| `Bach-JS_Ein_feste_Burg.mei` | `MEI_5.1/Music/Complete_examples/Bach-JS_Ein_feste_Burg.mei` |

- **Source:** [music-encoding/sample-encodings](https://github.com/music-encoding/sample-encodings), commit `f3f1baba02e32279b25dad660b82c834bac034b4` (2025-01-22).
- **License:** the repository is released under the Educational Community License 2.0, copyright the Music Encoding Initiative (MEI) Board. `LICENSE` is its license file, with a final newline added.
- **Rights:** both encodings say in `<useRestrict>`: "This encoding is in the public domain. However, the sources used to create it may be under copyright. We believe their use by the MEI project for educational and research purposes is covered by the Fair Use doctrine."

## music21's MEI test files

| File | Source path |
| --- | --- |
| `music21/test_file.mei` | `music21/mei/test/test_file.mei` |
| `music21/notes_in_utf8.mei` | `music21/mei/test/notes_in_utf8.mei` |
| `music21/notes_in_utf16.mei` | `music21/mei/test/notes_in_utf16.mei` |

- **Source:** [cuthbertLab/music21](https://github.com/cuthbertLab/music21), checkout at commit `bd1e14858c755e160afb36ee219c9b20aaa12463`. The files last changed in commit `113eae0e6ca2b354c73b19dcc0c432147ae1f8b0` (2017-12-29).
- **License:** music21 is copyright Michael Scott Cuthbert and cuthbertLab, distributed under the BSD 3-Clause License or the GNU LGPL. `music21/LICENSE` is its `license.txt`, which holds both texts.
- **Format:** all three declare `meiversion="2013"`. `notes_in_utf16.mei` is UTF-16 little-endian with a byte-order mark. `test_file.mei` puts its `<score>` directly in `<music>`, with no `<body>` or `<mdiv>`.
