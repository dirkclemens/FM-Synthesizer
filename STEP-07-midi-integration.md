# Step 7 — CoreMIDI Integration (DEFERRED — post-v1)

**Suggested LLM:** Claude Sonnet 4 / Nemotron 
**Status:** deferred 
**Depends on:** Step 1 complete (audio engine must exist to receive MIDI notes)

## Goal
Replace Gong with Apple CoreMIDI: enumerate MIDI sources, connect/disconnect, receive Note On/Off, CC, pitch bend, program change. Optional MIDI Learn.

## Prerequisites
- Step 1 complete (SynthEngine handles note on/off)
- Remove Gong dependency from Xcode project

## Deliverables
- `MIDIManager.swift` — CoreMIDI wrapper (`ObservableObject`)
- MIDI source picker in UI (connect/disconnect)
- Note On/Off → `SynthEngine.noteOn/noteOff`
- CC → parameter modulation (or MIDI Learn)
- Pitch bend → `SynthEngine.pitchBend`
- Program change → preset recall
- Bluetooth MIDI support (native macOS)

## Detailed tasks
### 7.1 CoreMIDI setup
- `MIDIClientCreate`, `MIDIInputPortCreate`, `MIDISourceCreate` (optional output)
- Enumerate sources with `MIDIGetNumberOfSources` / `MIDIGetSource`
- Connect to selected source via `MIDIPortConnectSource`
- MIDI read callback (CoreMIDI C callback → dispatch to main queue → Swift)

### 7.2 MIDI message parsing
- Parse `MIDIPacketList`: Note On (0x90), Note Off (0x80), CC (0xB0), Pitch Bend (0xE0), Program Change (0xC0)
- Convert MIDI note number → `SynthEngine.noteOn(midiKey:velocity:)`
- Velocity from Note On byte 2

### 7.3 MIDI Learn (optional but useful)
- Wiggle a knob → enter learn mode → move CC controller → bind CC to parameter
- Store bindings in user defaults or preset

### 7.4 Program change
- MIDI program change 0–127 → load preset slot 0–127

### 7.5 Remove Gong
- Remove `Gong` package from `Package.resolved` / Xcode project
- Remove `import Gong` from `SynthesizerApp.swift` / `ContentView.swift`

## Files to create
- `Synthesizer/MIDIManager.swift`

## Files to modify
- `Synthesizer/SynthesizerApp.swift` — remove Gong, add MIDIManager
- `Synthesizer/ContentView.swift` — add MIDI connect UI
- `Synthesizer.xcodeproj` — remove Gong package dependency
- `MASTER-PLAN.md` — mark Step 7 complete

## Definition of done
- [ ] MIDI sources listed, connect/disconnect works
- [ ] External MIDI keyboard plays the synth
- [ ] CC/pitch bend/program change affect parameters
- [ ] Gong removed from project
- [ ] Step 7 marked complete in `MASTER-PLAN.md`

## Stop here
CoreMIDI done. Polish (Step 8) is last.
