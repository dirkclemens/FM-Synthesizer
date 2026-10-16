# Step 2 — Modulation & Expressiveness

**Suggested LLM:** Claude Sonnet 4 / Nemotron 
**Status:** todo 
**Depends on:** Step 1 complete

## Goal
Add per-voice expressiveness: multi-wave LFO (pitch + amplitude), key scaling, velocity sensitivity, transpose, oscillator sync, feedback level, and pitch bend. Audio only.

## Prerequisites
- Step 1 complete (FM engine renders audio)
- `SynthEngine`, `Voice`, `Operator` in place

## Deliverables
- `LFO.swift` — multi-wave LFO (sine, triangle, square, saw, sample-and-hold)
- Operator gains: `keyScaling`, `velocitySensitivity`
- `Voice` gains: pitch bend response, transpose
- `SynthEngine` gains: global `transpose`, `feedbackLevel`, `oscillatorSync`, `pitchBendRange`
- LFO can modulate operator frequency (pitch vibrato) and/or operator level (tremolo)
- No UI yet — controllable via code / unit tests

## Detailed tasks

### 2.1 Multi-wave LFO
- `LFO` class with `wave: sine | triangle | square | saw | random`
- `rate: Float` (Hz), `depth: Float` (0–1)
- `nextSample()` returns -1…1 value
- Runs at audio rate (per-sample)

### 2.2 Operator modulation sources
- Each operator gets `lfoPitchDepth` and `lfoAmpDepth` (0–1)
- Operator frequency = baseFreq * (1 + lfo * lfoPitchDepth) — vibrato
- Operator level = level * (1 + lfo * lfoAmpDepth) — tremolo

### 2.3 Key scaling & velocity
- Key scaling: higher notes have shorter attack / lower level (DX7 style)
- Velocity: note-on velocity scales operator level (0–127 → 0…1)

### 2.4 Global controls
- `transpose: Float` (semitones, -24…+24) applied to all voices
- `feedbackLevel: Float` (0–1) for algorithms with self-feedback
- `oscillatorSync: Bool` — hard sync resets modulator phase when carrier cycle restarts
- `pitchBendRange: Float` (semitones, default 2)

### 2.5 Thread-safe parameter updates
- All engine parameters updated from main thread, read on audio render thread
- Use `os_unfair_lock` or `DispatchQueue` synchronization

## Files to create
- `Synthesizer/LFO.swift`

## Files to modify
- `Synthesizer/Operator.swift` — add LFO depths, key scaling, velocity
- `Synthesizer/Voice.swift` — apply transpose, pitch bend
- `Synthesizer/SynthEngine.swift` — add global params, thread safety
- `SynthesizerTests/ModulationTests.swift` (optional)
- `MASTER-PLAN.md` — mark Step 2 complete

## Definition of done
- [ ] LFO produces correct waveforms at audio rate
- [ ] Vibrato and tremolo audible when LFO depths > 0
- [ ] Velocity changes note loudness
- [ ] Transpose shifts all notes by N semitones
- [ ] Feedback and sync toggle without crashes
- [ ] Step 2 marked complete in `MASTER-PLAN.md`

## Stop here
Do not start UI (Step 4) until modulation is verified. FX and presets come after UI.
