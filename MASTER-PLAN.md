# Master Plan — 6-Operator FM Software Clone (macOS)

## Project decisions (from user)
- Platform: macOS only, standalone app (no AU/VST)
- Target: latest macOS / Swift / Xcode (only for personal use)
- UI: native macOS SwiftUI (simpler, lower risk)
- MIDI: Apple CoreMIDI (future-proof, no Gong dependency)
- Scope v1: FM engine + UI + presets (Phase 0–5). FX, arpeggiator, sequencer deferred (Phase 6–8, optional)
- Presets: Application Support, JSON, no DX-7 SysEx
- Polyphony: 12 voices, 6 operators, 32 algorithms
- Progress tracking: this file

## Step files
| Step | File | Status | Suggested LLM |
|------|------|--------|---------------|
| 0 | `STEP-00-project-audit.md` | done | Any lightweight (Nemotron / GPT-4o-mini) |
| 1 | `STEP-01-fm-engine-core.md` | done | Strong coding (Claude Sonnet 4 / GPT-5 / Gemini 2.5 Pro) |
| 2 | `STEP-02-modulation.md` | done | Claude Sonnet 4 / Nemotron |
| 3 | `STEP-03-effects-chain.md` | deferred | Claude Sonnet 4 / Nemotron |
| 4 | `STEP-04-ui-v1.md` | done | Claude Sonnet 4 / Nemotron (SwiftUI) |
| 5 | `STEP-05-preset-system.md` | todo | Any lightweight (Nemotron / GPT-4o-mini) |
| 6 | `STEP-06-arpeggiator-sequencer.md` | deferred | Claude Sonnet 4 |
| 7 | `STEP-07-midi-integration.md` | deferred | Claude Sonnet 4 / Nemotron |
| 8 | `STEP-08-polish-release.md` | deferred | Any lightweight |

## Progress
- [x] Step 0: Project audit & foundation
- [x] Step 1: FM engine core (6 operators, 32 algorithms, 12 voices)
- [x] Step 2: Modulation (LFO, velocity, transpose, sync, pitch bend)
- [ ] Step 3: Effects chain (deferred)
- [x] Step 4: UI v1 (keyboard, operator matrix, knobs)
- [ ] Step 5: Preset system (128 slots, JSON, Application Support)
- [ ] Step 5: Preset system (128 slots, JSON, Application Support)
- [ ] Step 6: Arpeggiator & sequencer (deferred)
- [ ] Step 7: CoreMIDI integration (deferred)
- [ ] Step 8: Polish & release (deferred)

## How to use
Execute one step file at a time. Each file contains: goal, prerequisites, deliverables, detailed tasks, definition of done, files to touch, and suggested LLM. Mark the step complete in this file before moving to the next. Review with me after each step before coding the next.
