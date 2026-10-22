---
name: claim-check
description: Recheck a disputed claim from independent evidence instead of defending or folding. Use when the user rejects an earlier answer ("I don't believe that", "that's wrong", "show me the log"), says it came from stale knowledge or a contaminated test, or when an answer rested on a model or tool vouching for itself. Isolates one falsifiable claim, labels the old evidence, runs one discriminating check, and reports Confirmed, Corrected, or Blocked.
license: MIT
---

# Claim Check

When a user pushes back on a claim, agents fail in one of two ways. They defend it: restate the same reasoning with more confidence. Or they fold: agree the user is right without checking anything. Both skip the only useful move, which is a cleaner test.

This skill treats doubt as a trigger to verify, not as evidence either way. Suspend the old conclusion, isolate the claim, look at what actually supported it, and run one check that could have come out differently.

## When to Use

- "I don't believe that." "That claim is wrong." "Show me the exact log or tool call."
- "You are answering from stale knowledge."
- "That test used the component it was supposed to test."
- The user separates "done" from "done well", or says the reported completion is overstated.
- An earlier answer relied on a model or tool describing itself: its identity, routing, memory, or whether it finished.

Not for an unrelated new question, and not as ceremony before every ordinary claim.

## How to Run

Open the strongest available source for the disputed claim: the file, the log, the live command or endpoint, the current docs, or the original session history. Prefer the live source over the conversation whenever both exist. Then follow the procedure.

## Evidence Labels

| Label | Meaning |
|---|---|
| Observed | Directly shown by the authoritative source |
| Tool-reported | Asserted by a tool, not independently proven |
| Inferred | Derived from observations |
| Recalled | From model memory, without current retrieval |
| Self-attested | A component describing its own identity, path, or state |
| Blocked | The decisive source or test is inaccessible |

## Procedure

1. **Suspend the previous conclusion.** Do not defend it, repeat it as fact, or reassure the user. Do not treat the user's doubt as proof that it is false either.
2. **Isolate the disputed claim.** Rewrite it as one falsifiable sentence. Split adjacent claims so one true detail cannot shield a false conclusion.
3. **Audit the old evidence.** Label each supporting item with the table above. Name any leap from a weaker label to a stronger conclusion, such as a tool's own report treated as observed fact.
4. **Inspect the original source first.**
   - A named file or log: read or search it.
   - A live command, process, endpoint, or repository state: run the read-only command.
   - A URL or current documentation: fetch it.
   - An earlier exchange or tool trace: search the session history. If that session may still be active, re-read its newest messages; an earlier snapshot is stale evidence.

   Remembered conversation is never proof of current external state.
5. **Design one discriminating check.** Change the condition that could have produced a false positive. Never test a component by asking that same component whether it worked. Examples: disable a fallback, use a hidden nonce, query the target endpoint directly, read transport logs or telemetry.
6. **Retry once with the discriminating change.** Compare the new observation with the old claim. Stop after one failed retry unless new evidence points to a materially different test.
7. **Resolve without face-saving.** Report exactly one status:
   - **Confirmed:** independent evidence supports the old claim.
   - **Corrected:** evidence contradicts or weakens it; state the replacement.
   - **Blocked:** decisive verification is unavailable; state what is missing.
8. **Expose provenance.** Give the exact source or check, what it directly proves, and what remains inferred. If the old answer overstated its evidence, say so plainly.

## Pitfalls

- **Automatic agreement.** The user's doubt is a trigger to verify, not evidence that the user is right.
- **Defensive repetition.** Restating the same reasoning with more confidence is not verification.
- **Self-attestation.** Models and tools cannot reliably prove their own routing, identity, vision path, memory path, or completion state.
- **Contaminated tests.** A fallback, cache, summary, mock, or helper component can produce the expected answer while bypassing the mechanism under test.
- **History substitution.** Session history proves what was said or called, not the current state of an external system.
- **Evidence laundering.** A tool's confident prose stays Tool-reported until telemetry or an independent path confirms it.
- **Wrong-phase evidence.** Proof about one artifact does not certify another. Current `main` does not prove an old tag, a fixed live page does not prove what was already submitted, and a local build does not prove the published package. Check the artifact the claim names. If the claim bundles several phases, isolate the one the user disputed (step 2); the others go under remaining uncertainty.
- **Model-identity probes.** "Does the model know X" proves nothing when X's name gives the answer away: a benchmark called "VoxelBench" suggests "a voxel arena". Test details the name cannot give (launch month, rating system, submission mechanism) and check them against the primary source. A probe asked after the session already searched the topic is contaminated; say so, and present the retrieved answer as retrieved, not recalled. Provider-side logs or usage telemetry outrank any self-identification.
- **Emotional drift.** Frustration or distrust must not lead to reassurance, softened findings, or a lower bar of proof.

## Done When

The response contains:

1. The disputed claim as one sentence.
2. The old evidence, labeled.
3. One independent or discriminating check, with its result.
4. Exactly one status: Confirmed, Corrected, or Blocked.
5. Any remaining uncertainty.
