# Step 1 — FM Engine Core

**Suggested LLM:** Strong coding model (Claude Sonnet 4, GPT-5, or Gemini 2.5 Pro) 
**Status:** todo 
**Depends on:** Step 0 complete

## Goal
Build a polyphonic 6-operator FM synthesis engine with 32 algorithms and 12-voice voice allocation, wired into `AVAudioEngine`. No UI yet — audio only, controllable via code.

## Prerequisites
- Step 0 complete (project builds, Git baseline)
- Understanding of the existing `Synth.swift` / `Oscillator.swift` structure

## Deliverables
- `Oscillator.swift` — phase-accumulating sine oscillator (replaces time-based version)
- `Operator.swift` — single FM operator (oscillator + envelope + level + ratio/detune)
- `Voice.swift` — 6-operator FM voice with algorithm routing
- `Algorithms.swift` — 32 algorithm routing matrices (operator on/off graph + feedback)
- `SynthEngine.swift` — `AVAudioEngine` host, 12-voice allocator, note on/off, parameter publication
- Unit tests for `midiNoteToFreq`, envelope shapes, and algorithm routing
- Engine starts/stops cleanly, no clicks on note on/off

## Detailed tasks

### 1.1 Replace the oscillator
- Write a phase-accumulating sine oscillator: `phase += phaseIncrement` per sample, `phaseIncrement = 2π * frequency / sampleRate`
- `midiNoteToFreq(midiNumber:)` formula: `(440.0 / 32.0) * pow(2.0, (Float(midiNumber) - 9.0) / 12.0)`
- Do NOT use time-based `sin(2π * f * t)` — it drifts and makes phase-continuous FM impossible

### 1.2 Operator model
- `Operator` struct/class with:
 - `isOn: Bool`
 - `frequencyMode: ratio | fixed`
 - `ratio: Float` (e.g., 0.5, 1, 2, 3...)
 - `fixedFreq: Float` (Hz, used when fixed mode)
 - `detune: Float` (cents)
 - `level: Float` (0–1, output volume)
 - `attack, decay, sustain, release: Float` (ADSR, seconds / level)
 - `phase: Float` (internal accumulator)
 - `envelopeState: attack | decay | sustain | release | off`
- `render(sampleCount:)` -> `[Float]` producing one block of samples

### 1.3 Voice model (6 operators)
- `Voice` holds 6 `Operator`s
- `noteOn(midiKey:velocity:)` — starts all operators per algorithm
- `noteOff(midiKey:)` — triggers release on all operators
- `render(sampleCount:)` -> `[Float]` — mixes operator outputs according to algorithm
- Voice lifecycle: `active | releasing | free`

### 1.4 Algorithms (32 routing matrices)
Each algorithm defines:
- Which operators are carriers (output directly to mix)
- Which operators are modulators (frequency-modulate another operator)
- Feedback path (operator modulating itself, e.g., algorithm 1)
- Represent as a graph: for each operator, list of operators it modulates + modulation index
- Store 32 static matrices in `Algorithms.swift`
- Operator 6 is typically the final carrier; feedback usually on operator 6 (self-modulation)

### 1.5 Voice allocator (12 voices)
- `SynthEngine` owns `[Voice]` (12 voices)
- `noteOn(midiKey:velocity:)`:
 - Find free voice; if none, steal the oldest voice in `releasing` state with lowest envelope level, or the oldest `active` voice
 - Start voice
- `noteOff(midiKey:)` — find voice(s) playing that note, trigger release
- `allNotesOff()` / `reset()`

### 1.6 AVAudioEngine wiring
- One `AVAudioSourceNode` per voice (or one shared rendering node if CPU demands — start with per-voice for simplicity)
- Voice source nodes → `mainMixerNode` → `outputNode`
- `SynthEngine.volume` maps to `mainMixerNode.outputVolume`
- Start engine in init, stop on deinit

### 1.7 Parameter publication (for UI later)
- `SynthEngine` is an `ObservableObject`
- `@Published` parameters: `volume`, `transpose`, `algorithmIndex`, per-operator settings
- Thread-safe parameter updates (audio thread reads, main thread writes) — use `os_unfair_lock` or `DispatchQueue` sync

### 1.8 Unit tests
- `testMidiNoteToFreq()` — A4 = 440 Hz, A5 = 880 Hz
- `testEnvelopeAttackDecayRelease()` — envelope reaches expected levels
- `testAlgorithmRouting()` — algorithm 1 (feedback) produces self-modulation, algorithm 32 (all carriers) produces sum of sines
- `testVoiceStealing()` — 13th note steals a voice

## Files to create
- `Synthesizer/Oscillator.swift` (rewrite)
- `Synthesizer/Operator.swift`
- `Synthesizer/Voice.swift`
- `Synthesizer/Algorithms.swift`
- `Synthesizer/SynthEngine.swift`
- `SynthesizerTests/FMEngineTests.swift`

## Files to modify
- `Synthesizer/Synth.swift` — keep for reference or mark deprecated; new code uses `SynthEngine`
- `MASTER-PLAN.md` — mark Step 1 complete when done

## Definition of done
- [ ] Phase-accumulating oscillator renders correct sine at 440 Hz
- [ ] Single operator with ADSR envelope shapes correctly
- [ ] 6-operator voice renders FM tone per selected algorithm
- [ ] 12-voice polyphony with note stealing works
- [ ] `AVAudioEngine` starts and produces audio without crashes
- [ ] No audible clicks on note on/off
- [ ] Unit tests pass
- [ ] Step 1 marked complete in `MASTER-PLAN.md`

## Stop here
Do not start Step 2 until Step 1 is complete and audio is verified working.
