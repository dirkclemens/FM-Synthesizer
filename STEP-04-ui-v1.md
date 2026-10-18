# Step 4 — UI v1 (Native macOS SwiftUI) (COMPLETE — v0.1)

**Status:** complete
**Depends on:** Step 1 complete (Step 2 recommended but not strictly required)

## Goal
Build a resizable native macOS SwiftUI UI to play and program the FM synth: keyboard, operator matrix visualization, per-operator knobs, algorithm selector, global controls.

## Prerequisites
- `SynthEngine` with published parameters
- Native macOS SwiftUI

## Deliverables (ALL COMPLETE)
- `ContentView.swift` — main resizable window layout
- `KeyboardView.swift` — 27-key keyboard, visual note state, click to play
- `AlgorithmMatrixView.swift` — 6×6 grid showing selected algorithm routing
- `OperatorPanel.swift` — knobs/sliders for the 6 operators (level, ratio, detune, ADSR)
- `GlobalPanel.swift` — volume, transpose, LFO rate/wave/depths, feedback, sync
- Reusable `Knob.swift` / `LabeledSlider.swift` controls
- Window is resizable

## Detailed tasks (ALL COMPLETE)

### 4.1 App shell (DONE)
- `SynthesizerApp.swift`: `WindowGroup { ContentView() }` with default size (1000×700), resizable

### 4.2 Keyboard (DONE)
- 27 white keys + black keys (MIDI 36–62)
- Clicking a key triggers `SynthEngine.noteOn` / `noteOff`
- Visual highlight on active notes
- Mac keyboard keys also highlight corresponding piano keys

### 4.3 Operator matrix (6×6) (DONE)
- Rows = operators 1–6, columns = operators 1–6
- Dot/line at (modulator, carrier) shows modulation connection
- Highlight carriers vs. modulators per selected algorithm

### 4.4 Per-operator controls (DONE)
- For each operator: On/Off toggle, Ratio, Detune, Level, Attack, Decay, Sustain, Release

### 4.5 Global controls (DONE)
- Volume, Transpose, Algorithm picker (1–32), LFO rate/wave/pitch depth/amp depth, Feedback, Oscillator Sync

### 4.6 State binding (DONE)
- All UI controls read/write `SynthEngine` `@Published` properties
- `SynthEngine` instantiated as `@StateObject` in `ContentView`

## Files created
- `Synthesizer/ContentView.swift`
- `Synthesizer/Views/KeyboardView.swift`
- `Synthesizer/Views/AlgorithmMatrixView.swift`
- `Synthesizer/Views/OperatorPanel.swift`
- `Synthesizer/Views/GlobalPanel.swift`
- `Synthesizer/Views/Knob.swift`
- `Synthesizer/Views/LabeledSlider.swift`
- `Synthesizer/Views/BaseModuleView.swift`

## Definition of done (ALL COMPLETE)
- [x] Window opens resizable, shows keyboard + operator panels
- [x] Clicking keys produces sound via engine
- [x] Changing algorithm updates matrix visualization
- [x] Turning knobs changes sound in real time
- [x] Step 4 marked complete in `MASTER-PLAN.md`
