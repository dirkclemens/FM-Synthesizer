# Step 4 — UI v1 (Native macOS SwiftUI)

**Suggested LLM:** Claude Sonnet 4 / Nemotron (strong SwiftUI) 
**Status:** todo 
**Depends on:** Step 1 complete (Step 2 recommended but not strictly required)

## Goal
Build a resizable native macOS SwiftUI UI to play and program the FM synth: keyboard, operator matrix visualization, per-operator knobs, algorithm selector, global controls. No preset browser yet (Step 5).

## Prerequisites
- `SynthEngine` with published parameters
- Native macOS SwiftUI (user choice: simpler, lower risk)

## Deliverables
- `ContentView.swift` — main resizable window layout
- `KeyboardView.swift` — 27-key keyboard, visual note state, click to play
- `OperatorMatrixView.swift` — 6×6 grid showing selected algorithm routing
- `AlgorithmSelector.swift` — picker for 1–32 algorithms
- `OperatorPanel.swift` — knobs/sliders for the 6 operators (level, ratio, detune, ADSR)
- `GlobalPanel.swift` — volume, transpose, LFO, feedback, sync
- Reusable `Knob.swift` / `LabeledSlider.swift` controls
- Window is resizable (drop the fixed 1000×150 frame)

## Detailed tasks

### 4.1 App shell
- `SynthesizerApp.swift`: `WindowGroup { ContentView() }` with default size (e.g., 1000×700), resizable
- Remove Gong MIDI connect calls (CoreMIDI comes in Step 7)

### 4.2 Keyboard
- 27 white keys + black keys (MIDI 36–62 approximately, or full 21–108 range)
- Clicking a key triggers `SynthEngine.noteOn` / `noteOff`
- Visual highlight on active notes
- Use existing offset dictionaries from `Keyboard.swift` as reference

### 4.3 Operator matrix (6×6)
- Rows = operators 1–6, columns = operators 1–6
- Dot/line at (modulator, carrier) shows modulation connection
- Highlight carriers vs. modulators per selected algorithm
- Read-only visualization (editing algorithms in UI is post-v1)

### 4.4 Per-operator controls
- For each operator: On/Off toggle, Ratio, Detune, Level, Attack, Decay, Sustain, Release
- Knobs/sliders bound to `SynthEngine` published parameters
- Operator 6 usually has feedback control

### 4.5 Global controls
- Volume, Transpose, Algorithm picker (1–32), LFO rate/depth/wave, Feedback, Oscillator Sync

### 4.6 State binding
- All UI controls read/write `SynthEngine` `@Published` properties
- `SynthEngine` instantiated as `@StateObject` or `@ObservedObject` in `ContentView`

## Files to create
- `Synthesizer/ContentView.swift` (rewrite)
- `Synthesizer/KeyboardView.swift`
- `Synthesizer/OperatorMatrixView.swift`
- `Synthesizer/OperatorPanel.swift`
- `Synthesizer/GlobalPanel.swift`
- `Synthesizer/Knob.swift`
- `Synthesizer/LabeledSlider.swift`

## Files to modify
- `Synthesizer/SynthesizerApp.swift` — resizable window, remove Gong
- `Synthesizer/SynthEngine.swift` — ensure all params are `@Published`
- `MASTER-PLAN.md` — mark Step 4 complete

## Definition of done
- [ ] Window opens resizable, shows keyboard + operator panels
- [ ] Clicking keys produces sound via engine
- [ ] Changing algorithm updates matrix visualization
- [ ] Turning knobs changes sound in real time
- [ ] Step 4 marked complete in `MASTER-PLAN.md`

## Stop here
Presets (Step 5) come next. FX (Step 3) and MIDI (Step 7) are deferred but can be added after presets.
