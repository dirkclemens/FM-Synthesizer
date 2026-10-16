# Step 5 — Preset System (128 slots, JSON, Application Support)

**Suggested LLM:** Any lightweight model (Nemotron, GPT-4o-mini, Claude Haiku) 
**Status:** todo 
**Depends on:** Step 4 complete (UI exists to load/save presets)

## Goal
A 128-slot preset bank: factory presets embedded, user presets saved to JSON in Application Support, preset browser UI to load/save/clear slots. No DX-7 SysEx (per user).

## Prerequisites
- Step 4 complete (UI can display preset browser)
- `SynthEngine` exposes all parameters needed to save/load a full patch

## Deliverables
- `Preset.swift` — `Codable` struct holding all synth parameters (operators, algorithm, global, modulation)
- `PresetBank.swift` — 128 slots, factory bank + user bank, save/load JSON in Application Support
- `PresetBrowserView.swift` — SwiftUI grid/list of 128 slots, load/save/clear, slot naming
- Factory presets embedded (bass, electric piano, brass, pad, bell, etc.)
- Slot 0–127, user-editable names

## Detailed tasks

### 5.1 Preset data model
- `Preset` struct: `Codable`, `Equatable`
- Fields: `name`, `algorithm`, `transpose`, `feedbackLevel`, `oscillatorSync`, `lfo` settings, per-operator `[OperatorPreset]` (6 operators)
- `OperatorPreset`: `isOn`, `ratio`, `detune`, `level`, `attack`, `decay`, `sustain`, `release`, `lfoPitchDepth`, `lfoAmpDepth`

### 5.2 Preset bank
- `PresetBank` class: `ObservableObject`, 128 slots (`[Preset?]` or array with empty placeholder)
- `factoryPresets: [Preset]` embedded as static array
- `userPresets: [Preset]` loaded/saved to `Application Support/com.yourname.FM1/presets.json`
- `loadPreset(at:)`, `savePreset(_:at:)`, `clearPreset(at:)`, `renamePreset(at:to:)`
- Factory slots read-only (or copy to user slot before editing)

### 5.3 File persistence
- `FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)`
- Create folder if missing
- JSON encode/decode with `JSONEncoder` / `JSONDecoder`
- Handle missing/corrupt file gracefully

### 5.4 Preset browser UI
- `PresetBrowserView`: grid or list of 128 slots
- Each slot: number, name, "empty" indicator, load button
- Selected preset loads into `SynthEngine`
- "Save" writes current engine state to selected slot
- "Clear" empties slot

### 5.5 Engine ↔ Preset conversion
- `SynthEngine.preset` computed property: read all params into a `Preset`
- `SynthEngine.load(preset:)`: apply all params from a `Preset`

## Files to create
- `Synthesizer/Preset.swift`
- `Synthesizer/PresetBank.swift`
- `Synthesizer/PresetBrowserView.swift`

## Files to modify
- `Synthesizer/SynthEngine.swift` — add `preset` computed property + `load(preset:)`
- `Synthesizer/ContentView.swift` — add preset browser to layout
- `Synthesizer.entitlements` — may need `com.apple.security.files.user-selected.read-write` or Application Support is sandbox-allowed (verify)
- `MASTER-PLAN.md` — mark Step 5 complete

## Definition of done
- [ ] `Preset` encodes/decodes to JSON correctly
- [ ] Factory presets load and change the sound
- [ ] User edits are saved to Application Support and persist across relaunches
- [ ] Preset browser UI shows 128 slots, load/save/clear works
- [ ] Step 5 marked complete in `MASTER-PLAN.md`

## Stop here
Step 5 completes the v1 MVP (engine + UI + presets). Review with user before proceeding to FX/MIDI/sequencer (Steps 3, 6, 7, 8).
