# Step 0 — Project Audit & Foundation

**Suggested LLM:** Any lightweight model (Nemotron, GPT-4o-mini, Claude Haiku) 
**Status:** todo 
**Depends on:** nothing

## Goal
Verify the existing Xcode project builds, audit the Gong MIDI dependency, decide on CoreMIDI migration, initialize Git, and set up a clean baseline before any DSP work begins.

## Prerequisites
- Xcode installed (latest stable)
- macOS (latest, since this is personal use)
- The repo at `/Users/dirk/Projekte/xcode/MIDI-Synthesizer`

## Deliverables
- Project builds and runs without errors
- Gong package audit note (keep or replace with CoreMIDI)
- Git repository initialized with initial commit
- `MASTER-PLAN.md` reflects current state
- List of files to keep / replace / delete for the rebuild

## Detailed tasks

### 0.1 Open and build the project
- Open `Synthesizer.xcodeproj` in Xcode
- Build the `Synthesizer` target
- Run the app to confirm it launches
- Note any build warnings / errors
- Note the deployment target, Swift version, and Xcode project format version

### 0.2 Audit the Gong dependency
- `Gong` is a Swift Package (`https://github.com/dclelland/Gong`) used for MIDI
- Check if the package resolves and builds in current Xcode
- Decision: user prefers Apple CoreMIDI (future-proof, easier). Plan to remove Gong and use CoreMIDI framework directly in Step 7. For now, leave Gong in place but mark for removal.

### 0.3 Review existing source files
- `SynthesizerApp.swift` — app entry, fixed 1000×150 window, MIDI connect on appear/disappear
- `ContentView.swift` — keyboard + MIDI observer, very basic
- `Keyboard.swift` — hard-coded 60-key layout (MIDI 36–95), white/black key offsets
- `Oscillator.swift` — time-based sine + "piano" harmonics, static ADSR (shared across all notes — a bug for polyphony)
- `Synth.swift` — `AVAudioEngine` with one `AVAudioSourceNode` per note, generic `Synth<SynthProtocol>` misuse
- `Synthesizer.entitlements` — app sandbox, user-selected read-only

### 0.4 Decide what to keep vs. rebuild
Keep for reference: keyboard key offset dictionaries (note positions), `midiNoteToFreq` formula.
Rebuild from scratch: audio engine (phase-accumulating, polyphony-safe), UI (resizable, native), preset system, CoreMIDI.

### 0.5 Initialize Git
- `git init` in repo root
- Add `.gitignore` for Xcode (DerivedData, .xcuserdata, *.xcuserstate, build/)
- `git add .`
- `git commit -m "Initial baseline: original basic synthesizer project"`

### 0.6 Update master plan
- Mark Step 0 complete in `MASTER-PLAN.md`
- Confirm Step 1 is next

## Files to touch
- `Synthesizer.xcodeproj/` (inspect only, no code changes yet)
- `.gitignore` (create)
- `MASTER-PLAN.md` (update progress)

## Definition of done
- [ ] Project builds and runs in Xcode
- [ ] Git repo initialized with baseline commit
- [ ] Audit notes recorded (Gong to be replaced by CoreMIDI later)
- [ ] Step 0 marked complete in `MASTER-PLAN.md`

## Stop here
Do not start Step 1 until Step 0 is complete and reviewed.
