# Step 7 — CoreMIDI Integration (COMPLETE — v0.1)

**Status:** complete
**Depends on:** Step 1 complete (audio engine must exist to receive MIDI notes)

## Goal
Apple CoreMIDI integration: enumerate MIDI sources, connect/disconnect, receive Note On/Off, CC, pitch bend, program change.

## Prerequisites
- Step 1 complete (SynthEngine handles note on/off)

## Deliverables
- `MIDIManager.swift` — CoreMIDI wrapper (`ObservableObject`)
- MIDI source picker in UI (connect/disconnect)
- Note On/Off → `SynthEngine.noteOn/noteOff`
- CC → parameter modulation
- Pitch bend → `SynthEngine.pitchBendValue`
- Program change → preset recall

## Detailed tasks
### 7.1 CoreMIDI setup (DONE)
- `MIDIClientCreate`, `MIDIInputPortCreate`
- Enumerate sources with `MIDIGetNumberOfSources` / `MIDIGetSource`
- Connect to selected source via `MIDIPortConnectSource`
- MIDI read callback (CoreMIDI C callback → dispatch to main queue → Swift)

### 7.2 MIDI message parsing (DONE)
- Parse `MIDIPacketList`: Note On (0x90), Note Off (0x80), CC (0xB0), Pitch Bend (0xE0), Program Change (0xC0)
- Convert MIDI note number → `SynthEngine.noteOn(midiNote:velocity:)`
- Velocity from Note On byte 2

### 7.3 Program change (DONE)
- MIDI program change 0–127 → load preset slot 0–127

## Files created
- `Synthesizer/FMAudio/MIDIManager.swift`

## Definition of done (ALL COMPLETE)
- [x] MIDI sources listed, connect/disconnect works
- [x] External MIDI keyboard plays the synth
- [x] CC/pitch bend/program change affect parameters
- [x] CoreMIDI used (no external MIDI package dependency)
