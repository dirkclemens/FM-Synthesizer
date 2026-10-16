# Step 6 — Arpeggiator & 16-Step Sequencer (DEFERRED — post-v1)

**Suggested LLM:** Claude Sonnet 4 / Nemotron 
**Status:** deferred 
**Depends on:** Step 5 complete, Step 7 (CoreMIDI) recommended

## Goal
Add arpeggiator (7 modes) and 16-step sequencer that generate MIDI note events to drive the synth engine.

## Prerequisites
- Step 5 complete
- `SynthEngine` responds to programmatic note on/off

## Deliverables
- `Arpeggiator.swift` — up/down/up-down/random/ordered/chord/note-repeat, rate, gate, octave range
- `Sequencer.swift` — 16 steps, step on/off, velocity, gate, play/stop, tempo
- UI controls for arp/sequencer

## Detailed tasks
### 6.1 Arpeggiator
- Holds latched notes from keyboard/MIDI
- Modes: up, down, up-down, random, ordered, chord, note-repeat
- Rate (sync to tempo), gate length, octave range (1–4)
- Outputs note on/off to `SynthEngine`

### 6.2 Sequencer
- 16 steps, each: note (or rest), velocity, gate, on/off
- Play/stop, tempo (BPM), step visualization
- Loops continuously

### 6.3 UI
- Arpeggiator on/off, mode picker, rate, gate, octave
- Sequencer on/off, 16 step buttons, tempo
- Step LEDs light during playback

## Files to create
- `Synthesizer/Arpeggiator.swift`
- `Synthesizer/Sequencer.swift`
- `Synthesizer/ArpeggiatorView.swift`
- `Synthesizer/SequencerView.swift`

## Files to modify
- `Synthesizer/SynthEngine.swift` — accept programmatic note events
- `MASTER-PLAN.md` — mark Step 6 complete

## Definition of done
- [ ] Arpeggiator cycles through held notes in selected mode
- [ ] Sequencer plays 16-step pattern
- [ ] UI controls work in real time

## Stop here
MIDI integration (Step 7) should ideally come before or with this step so external MIDI can latch arp notes.
