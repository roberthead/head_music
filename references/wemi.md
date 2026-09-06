# WEMI: Work, Expression, Manifestation, Item

Four levels of "the same thing." A model from library cataloging for saying which sameness you mean when two objects are both, somehow, Beethoven's Fifth. Intended as background for the `Work`, `Score`, and `Layout` entities proposed in the Identity and Presentation story, and for placing `Project` and `Flow` correctly relative to them.

---

## 1. Where It Comes From

WEMI is the core of the **Functional Requirements for Bibliographic Records** (FRBR), an entity-relationship model published by the International Federation of Library Associations (IFLA) in 1998. The study group's problem was that a library catalog entry conflates several different things: the idea of a book, a particular translation of it, a particular printing, and the copy on the shelf with a barcode. FRBR pulled those apart into four entities that stack one inside the next.

In 2017 IFLA consolidated FRBR with its two sibling models for authority data into the **IFLA Library Reference Model** (LRM). The four WEMI entities survive intact in LRM, joined by a handful of new ones such as Agent, Nomen, Place, and Time-span. RDA, the cataloging standard most English-language libraries use, is built on LRM, so the model is in daily use rather than only in theory.

The insight that spread beyond libraries is the relationship between the levels. Each is one-to-many with the next: one work has many expressions, each expression has many manifestations, each manifestation has many items. A question about "the same piece" is really a question about which level you are asking at.

---

## 2. The Four Levels

| Level | FRBR definition | What it is | Identified by |
|---|---|---|---|
| **Work** | "a distinct intellectual or artistic creation" | The abstract creation. No physical form, no fixed text. Beethoven's Symphony No. 5 in C minor; *Hamlet*; a folk tune with no known author. | Recognized only through its expressions. |
| **Expression** | "the intellectual or artistic realization of a work" | A specific realization in some form: a text, a notated score, a performance, a choreography. A translation, a revised edition, an arrangement for piano four hands, and a live performance are each distinct expressions of one work. | The content itself. |
| **Manifestation** | "the physical embodiment of an expression of a work" | The embodiment as a product: a specific published printing of a score, a specific label's release of a recording, a specific PDF as distributed. Reset the type or reissue the disc and you have a new manifestation of the same expression. | Publisher catalog numbers, ISBN, ISMN. |
| **Item** | "a single exemplar of a manifestation" | One copy. The score on your shelf with its pencil markings; the one disc in a library's collection with its barcode. Two items of one manifestation differ only in condition, location, and ownership. | Accession numbers. |

Expression is the level most often dropped when the initialism is recalled from memory, and it is the level head_music lives at.

---

## 3. One Work, Traced Down

The same piece at all four levels, nested the way a catalog might hold it. Every branch is one-to-many, so the shape is a tree, not a chain.

```
W  Beethoven, Symphonies, no. 5, op. 67, C minor
   E  Urtext score, ed. Jonathan Del Mar
      M  Bärenreiter, full score, printed
         I  the copy on the conductor's stand (pencil cuts in the finale)
         I  the copy in the university library (barcode, due-date slip)
      M  Bärenreiter, study score, printed
   E  Liszt's transcription for solo piano, S. 464/5
      M  a scanned public-domain PDF on IMSLP
   E  Berlin Philharmonic, cond. Karajan, recorded 1962
      M  Deutsche Grammophon LP
      M  Deutsche Grammophon CD reissue
      M  streaming release
```

This is an illustrative example, not a transcription of any library's catalog.

Two things to notice. A performance is an *expression*, not a manifestation; the recording of it, pressed or streamed, is the manifestation. And a transcription is a new expression of the *same work*, not a new work, because the intellectual content being realized is still Beethoven's symphony.

---

## 4. Where the Lines Fall

FRBR's rule of thumb: a change to intellectual or artistic content makes a new expression; a change only to physical form makes a new manifestation.

| Change | Result |
|---|---|
| Transposing a song into a singer's key | new expression |
| Arranging an orchestral work for wind band | new expression |
| A different performer's recording | new expression |
| Correcting engraving errors in a second printing | new manifestation |
| Reissuing an LP recording on CD | new manifestation |
| Exporting one engraving as both PDF and PNG | new manifestation |
| Two library copies of one printing | two items |
| A parody with new lyrics and a new tune | arguably a new work |

Catalogers argue about the last row, and about where a heavily revised edition stops being an expression and becomes a new work. The model does not settle these; it gives the argument a vocabulary.

---

## 5. What It Means for head_music

The gem's content model, Project → Flow → Part → Voice, sits almost entirely at one WEMI level. A `Flow` is notated content: specific pitches at specific positions, in a specific key and meter. That is an expression. Transpose it or rearrange it for other instruments and you have a different flow, which is the right behavior, because you have a different expression.

| Level | In head_music | Status |
|---|---|---|
| **Work** | The proposed `Work` entity, with `Person` and `Credit`. A title and its people, independent of any one notated version. Today `Flow#composer` and `#origin` are plain strings standing in for it. | Identity and Presentation story |
| **Expression** | `Project` and `Flow`, down through parts, voices, placements, and the timeline. Two arrangements are two projects, both expressions of one work. | Shipped in 21.0.0 |
| **Manifestation** | The proposed `Score` and `Layout`: which parts appear, in what order, with what page and staff layout. The LilyPond, MusicXML, and ABC writers each produce a manifestation of a flow. | Identity and Presentation story |
| **Item** | A particular file on disk, a particular printed copy. The gem produces the bytes and stops. | Out of scope |

Two consequences worth holding onto:

- **`Project` is not `Work`.** A project holds one set of players and one set of flows; a work can have many such projects. The multi-movement grouping that motivated `Project` is an expression-level fact (this realization has four movements), not a work-level one.
- **The rendering methods on `Flow` cross a level boundary**, an expression producing its own manifestation. That is fine as long as layout decisions live on the manifestation side when `Score` arrives, so that one flow can render to many scores.

This mapping is a proposal, not settled doctrine. If the Identity and Presentation story lands differently, revise this section to match.

---

## 6. Sources

- **IFLA, primary source.** [Functional Requirements for Bibliographic Records: Final Report](https://repository.ifla.org/handle/123456789/811) (1998, amended 2009). The original study group report. Section 3 defines the four Group 1 entities and their attributes.
- **IFLA, current model.** [IFLA Library Reference Model (LRM)](https://repository.ifla.org/handle/123456789/40) (2017). Consolidates FRBR, FRAD, and FRSAD. WEMI persists as LRM-E2 through LRM-E5, alongside Res, Agent, Nomen, Place, and Time-span.
- **Library of Congress, introduction.** Barbara Tillett, [*What is FRBR? A Conceptual Model for the Bibliographic Universe*](https://www.loc.gov/cds/downloads/FRBR.PDF) (2004). The standard eight-page primer, with the classic diagrams of the one-to-many relationships.
- **Wikipedia, overview.** [Functional Requirements for Bibliographic Records](https://en.wikipedia.org/wiki/Functional_Requirements_for_Bibliographic_Records). Summary of the model, its Group 1/2/3 entities, and its criticisms.
- **RDA Steering Committee, implementation.** [RDA: Resource Description and Access](https://www.rdatoolkit.org/). The cataloging standard built on LRM. Shows how WEMI is applied to real records, including music.
- **CIDOC CRM, formal ontology.** [LRMoo (formerly FRBRoo)](https://www.cidoc-crm.org/lrmoo). An object-oriented harmonization of LRM with the museum-world CIDOC CRM. Useful where the library model meets performance and event data.
- **MusicBrainz, music analogue.** [MusicBrainz entities: Work, Recording, Release, Medium](https://musicbrainz.org/doc/MusicBrainz_Entity). A working music database whose Work, Recording, and Release entities map closely to work, expression, and manifestation.
