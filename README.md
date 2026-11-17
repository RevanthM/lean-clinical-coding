# Lean Clinical Coding

An executable Lean 4 research prototype for checking narrow ICD-10-CM coding certificates against clinician-reviewed structured notes. The checker supports **two fixture concepts** (`R50.9` and `I10`), **12 named theorems**, and **23 synthetic regression fixtures**. It does not implement the ICD-10-CM classification or extract diagnoses from patient prose.

The model proposal contains a note identifier, policy revision, concept, quotation, and Unicode-scalar offset. Lean checks the quotation, source identity, outpatient setting, valid calendar date, effective window, reviewed certainty, and concept agreement. Missing support produces `none`; an uncertain or negated reviewed condition cannot produce an accepted certificate.

## Run

Install Lean with [the official instructions](https://lean-lang.org/install/). The `lean-toolchain` pins `leanprover/lean4:v4.35.0`; no Mathlib or third-party Lean packages are required.

```sh
lake build
lake exe clinical_demo
python3 scripts/check_proofs.py
```

Expected output ends with `23/23 synthetic clinical fixtures passed.` A compile-time `example` also evaluates every fixture through Lean's proof checker.

## Read the work

- [Whitepaper](docs/whitepaper.md): architecture, theorem inventory, evaluation, and limits.
- [Model](ClinicalCoding/Model.lean): input structures, executable checker, and proofs.
- [Fixtures](Main.lean): accepted cases and rejected mutations.
- [Source manifest](sources.json): authoritative references and explicit synthetic data provenance.

The input's clinician-reviewed semantic annotations are a trust boundary. Exact text matching does not establish that an annotation correctly interprets negation, temporality, clinical causation, or the full medical record. A model-generated annotation must be reviewed before it is treated as a `ReviewedNote`. This repository contains no patient data, trained model, model weights, real-world accuracy estimate, billing integration, or operational clinical workflow.

## Reproduce the central example

The complete synthetic note is `Fever`. Its reviewed concept is affirmed fever in a current outpatient encounter, and its certificate quotes that same text at offset zero. The checker yields `some "R50.9"`. Changing the proposed concept to hypertension, changing the quotation, changing the reviewed certainty, or using a policy date outside the fixture's effective window causes rejection. `Essential hypertension` is the second deliberately restricted phrase and maps to `I10` only with matching reviewed input.

These two mappings are illustrative identifiers, not a complete coding recommendation. Classification conventions, exclusions, sequencing, specificity, and the full record still require a complete reviewed coding system.

Authored software and documentation are MIT licensed; referenced third-party sources retain their own terms. Research by Matha Labs, November 15, 2026.

## Publication

Read the [Matha Labs research article](https://www.mathalabs.com/blog/clinical-coding-in-lean/), [download the whitepaper PDF](docs/whitepaper.pdf), or inspect its [editable source](docs/whitepaper.md). The published evaluation uses synthetic fixtures only.


## Expanded whitepaper edition

The illustrated edition 2.0, revised November 16, 2026, adds methods, primary-source references, exact theorem boundaries, synthetic worked examples and a proposed evaluation protocol. [Read the paper](docs/whitepaper.md), [download the PDF](docs/whitepaper.pdf), or inspect the [structured source](docs/whitepaper.json). The first edition is retained in [the archive](docs/archive/2026-11-15/).

To regenerate the PDF, Markdown and SVG figures from the structured source, install ReportLab and run `python3 tools/render_whitepaper.py`.

The code and experimental counts are unchanged. The expanded paper identifies its exact evaluated implementation revision; new research plans are not reported as completed measurements.
