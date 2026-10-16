# Detailed Plan — 6-Operator FM Synthesizer (macOS, Swift + SwiftUI)

> ⚠️ This file has been superseded by `MASTER-PLAN.md` + individual `STEP-*.md` files.
> Use `MASTER-PLAN.md` to track progress and execute one step file at a time.
> Each step file is self-contained and designed to be handed off to a lightweight LLM.

## 1. Goal

Turn the existing very-basic Swift/SwiftUI synthesizer into a software 6-operator FM Synthesizer running as a native macOS application.

Core target features (from the 6-operator FM synth spec):
- 6-operator FM synthesis engine with 32 algorithms
- 12-voice polyphony with voice stealing
- 128 preset slots (user + factory)
- Virtual 27-key keyboard + on-screen parameter controls (knobs/sliders)
- Per-operator ADSR envelopes, multi-wave LFO (pitch & amp), feedback, oscillator sync, transpose
- Effects: filter, reverb, delay, distortion, chorus, phaser
- Arpeggiator (7 modes) + 16-step sequencer
- CoreMIDI input/output (USB MIDI, Bluetooth MIDI), MIDI learn
- DX-7 SysEx preset import/export
- Native macOS window (resizable), not bound to the current 1000×150 size

## 2. Constraints & Decisions Needed (questions for you — see Section 7)

Before coding, I need your input on:
1. Target macOS / Swift / Xcode version (project looks like Xcode ~12 era; do we modernize?)
2. Standalone app only, or also AUv3 / VST plugin later?
3. How faithful should the UI be to the hardware (replicate TFT display + physical knobs) vs. a modern macOS-native UI?
4. Scope of MVP: synth engine + presets first, or include sequencer/arpeggiator/FX in v1?
5. DX-7 SysEx compatibility: import only, or import + export?
6. Keep using the Gong MIDI package, or switch to Apple's CoreMIDI directly?
7. Audio engine: keep `AVAudioEngine` + `AVAudioSourceNode` per voice, or render all voices in a single rendering block for efficiency?

## 3. Architecture Overview

### Audio engine
- `SynthEngine` (final class, `ObservableObject`) owns an `AVAudioEngine`
- One `AVAudioSourceNode` per active voice renders the full 6-operator FM stack for that voice
- All voice nodes → mixer → optional FX chain → output node
- Phase-accumulating oscillators (not time-based like the current `Oscillator`, which drifts on long notes)
- Sample-accurate per-operator envelopes and LFO

### FM voice model
- 6 operators per voice; each operator = oscillator + ADSR envelope + level + detune + ratio/fixed-freq mode
- 32 algorithm routing matrices define carrier/modulator connections and feedback
- Voice allocator: 12 voices, note-on → steal oldest/release-ready voice if none free; note-off → release envelope

### UI layer
- SwiftUI `ContentView` with:
 - Left panel: virtual keyboard (27 keys, velocity via UI or MIDI)
 - Center panel: algorithm selector + operator matrix visualization (6×6 grid)
 - Right panel: per-operator knobs (level, ratio, attack, decay, sustain, release), LFO, feedback, transpose
 - Bottom: preset browser (128 slots), FX controls, arpeggiator/sequencer toggles
- All audio parameters published via `@Published` / `Combine` so UI and engine stay in sync

### MIDI layer
- Gong (or CoreMIDI) for MIDI input: Note On/Off, CC, pitch bend, program change
- MIDI Learn: map any CC to any synth parameter
- MIDI output: send Sysex/CC for preset changes (optional)

### Preset model
- `Preset` struct: Codable, holds all operator/envelope/LFO/algorithm/FX settings
- 128-slot bank; save/load to JSON (user presets) + embedded factory bank
- DX-7 SysEx parser/writer for .syx import/export

## 4. Implementation Phases

### Phase 0 — Project audit & foundation (no audio changes yet)
- Verify the existing project builds in the installed Xcode
- Audit Gong package compatibility with current Swift toolchain
- Decide answers to Section 7 questions
- Set up Git (repo is not currently a git repo) + branching strategy

### Phase 1 — FM synthesis engine core
- Replace/rewrite `Oscillator` with phase-accumulating sine oscillator
- `Operator` struct: frequency mode (ratio/fixed), ratio/coarse/fine, detune, level, ADSR
- `Voice` struct: 6 operators + algorithm routing + render function
- 32 algorithm matrices (operator on/off graph + feedback path)
- Voice allocator (12 voices, note-stealing, release handling)
- `SynthEngine` wiring into `AVAudioEngine` (replace current per-note simple source node approach)
- Unit tests: midiNoteToFreq, envelope shapes, algorithm routing

### Phase 2 — Modulation & expressiveness
- Multi-wave LFO (sine, triangle, square, saw, random) → pitch and/or amplitude
- Per-operator key scaling & velocity sensitivity
- Pitch bend wheel range
- Global transpose, oscillator sync on/off, feedback level

### Phase 3 — Effects chain (insert after mixer, before output)
- Simple low-pass/high-pass filter
- Reverb (AVAudioUnitReverb or convolution)
- Delay (feedback delay)
- Chorus / flanger (LFO-modulated delay)
- Distortion / overdrive (tanh waveshaper)
- Phaser (all-pass filter stages)
- FX on/off + amount per effect

### Phase 4 — UI v1 (synth panel)
- Resizable window; drop the fixed 1000×150 frame
- Rebuild keyboard UI: 27 keys, visual note-on/off state, velocity coloring
- Operator matrix view (6×6) visualizing the selected algorithm
- Knobs/sliders for all engine parameters
- Algorithm selector (1–32)
- Global section: volume, transpose, LFO, sync, FX master

### Phase 5 — Preset system
- `Preset` Codable model + 128-slot bank
- Factory preset bank (embedded, DX-7 style starting sounds: bass, keys, brass, pad, bell)
- Preset browser UI (slot grid or list, load/save/clear)
- Save user presets to JSON in Application Support
- DX-7 SysEx import (.syx) — optional export

### Phase 6 — Arpeggiator & sequencer
- Arpeggiator: up/down/up-down/random/ordered/chord/note-repeat (7 modes), rate, gate, octave range
- 16-step sequencer: step on/off, velocity, gate, note; play/stop; tempo sync

### Phase 7 — MIDI & integration
- CoreMIDI device discovery: list MIDI sources, connect/disconnect
- Bluetooth MIDI support (macOS native)
- MIDI Learn UI: wiggle a knob, move a CC controller, bind them
- Program change → preset recall
- App sandbox entitlements review (user-selected file read-only may not be enough for preset save)

### Phase 8 — Polish, testing & release prep
- Performance testing (CPU at 12 voices + FX)
- Bug fixes: note stealing clicks, envelope clicks, UI/audio thread safety
- Accessibility & Dark Mode
- App icon, About window, versioning
- Code sign / notarize considerations if distributing outside App Store

## 5. File/Class Map (proposed)

| File | Responsibility |
|------|----------------|
| `SynthEngine.swift` | AVAudioEngine host, voice allocator, parameter publication |
| `Voice.swift` | 6-operator FM voice render block |
| `Operator.swift` | Oscillator + envelope + level per operator |
| `Algorithms.swift` | 32 routing matrices |
| `LFO.swift` | Multi-wave LFO |
| `Preset.swift` | Codable preset + bank + JSON/SysEx persistence |
| `Effects.swift` | AVAudioUnit-based FX chain |
| `Arpeggiator.swift` / `Sequencer.swift` | MIDI event generation |
| `MIDIManager.swift` | Gong/CoreMIDI wrapper, MIDI Learn |
| `ContentView.swift` | Main window layout |
| `KeyboardView.swift` | 27-key keyboard |
| `OperatorMatrixView.swift` | 6×6 algorithm visualization |
| `PresetBrowserView.swift` | 128-slot browser |
| `Knob.swift` / `Slider.swift` | Reusable parameter controls |

## 6. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| `AVAudioSourceNode` per voice × 6 ops is CPU-heavy | Start simple; if CPU too high, render all voices in one node |
| Envelope/note-off clicks | Always release through envelope; zero-crossing where practical |
| Gong package unmaintained | Fall back to Apple CoreMIDI directly |
| Thread safety (UI tweaks audio params on main thread) | Use `DispatchQueue` audio thread locks or `os_unfair_lock` for param updates |
| Preset save blocked by sandbox | Adjust entitlements (`files.user-selected.read-write` or Application Support) |
| DX-7 SysEx format complexity | Start with import only; use a known SysEx parser; test with DX-7 bank files |

## 7. Questions for you (please answer before I code)

1. **Target platform/toolchain:** Which macOS minimum deployment target, Swift version, and Xcode version should I target? Should I modernize the project (e.g., replace the old `Synth<SynthProtocol>` generic misuse, update package configurations)?
2. **UI style:** Should the synth reproduce a hardware look (display, rotary knobs, keys) as closely as possible, or would you prefer a clean, modern macOS-native synthesizer UI?
3. **MVP scope:** Should Phase 1–4 (engine + UI + presets) be the first deliverable, with FX/arpeggiator/sequencer as follow-ups? Or include everything in v1?
4. **Plug-in format:** Standalone macOS app only, or do you eventually want an AUv3/VST version too?
5. **MIDI library:** Keep using Gong, or switch to Apple's CoreMIDI framework directly?
6. **DX-7 SysEx:** Import-only factory/user presets, or also export .syx files?
7. **Preset storage:** Where should user presets live — Application Support, Documents, or a user-chosen folder (sandbox implications)?

Once you answer these, I'll finalize the plan and we can start with Phase 0.
