# Step 0 — Project Audit & Foundation (COMPLETE — v0.1)

**Status:** complete
**Depends on:** nothing

## Goal
Verify the existing Xcode project builds, decide on MIDI framework (CoreMIDI), initialize Git, and set up a clean baseline before any DSP work begins.

## Prerequisites
- Xcode installed (latest stable)
- macOS (latest, since this is personal use)
- The repo at `/Users/dirk/Projekte/xcode/MIDI-Synthesizer`

## Deliverables
- Project builds and runs without errors
- MIDI framework decision: Apple CoreMIDI (no external dependencies)
- Git repository initialized with initial commit
- `MASTER-PLAN.md` reflects current state
- List of files to keep / replace / delete for the rebuild

## Detailed tasks (ALL COMPLETE)

### 0.1 Open and build the project (DONE)
- Opened `Synthesizer.xcodeproj` in Xcode
- Built the `Synthesizer` target
- Ran the app to confirm it launches

### 0.2 MIDI framework decision (DONE)
- Decision: Apple CoreMIDI (future-proof, no external package dependency)
- Implemented in `MIDIManager.swift` using CoreMIDI framework directly

### 0.3 Review existing source files (DONE)
- `SynthesizerApp.swift` — app entry, fixed window size
- `ContentView.swift` — keyboard + MIDI observer, very basic
- `Keyboard.swift` — hard-coded key layout (MIDI 36–95), white/black key offsets
- `Oscillator.swift` — time-based sine + "piano" harmonics
- `Synth.swift` — `AVAudioEngine` with one `AVAudioSourceNode` per note
- `Synthesizer.entitlements` — app sandbox

### 0.4 Decide what to keep vs. rebuild (DONE)
Keep for reference: keyboard key offset dictionaries (note positions), `midiNoteToFreq` formula.
Rebuilt from scratch: audio engine (phase-accumulating, polyphony-safe), UI (resizable, native), preset system, CoreMIDI.

### 0.5 Initialize Git (DONE)
- `git init` in repo root
- Added `.gitignore` for Xcode
- `git add .`
- `git commit -m "Initial baseline"`

### 0.6 Update master plan (DONE)
- Marked Step 0 complete in `MASTER-PLAN.md`

## Definition of done (ALL COMPLETE)
- [x] Project builds and runs in Xcode
- [x] Git repo initialized with baseline commit
- [x] CoreMIDI selected as MIDI framework
- [x] Step 0 marked complete in `MASTER-PLAN.md`
