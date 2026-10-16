# FM Synthesizer — User Manual

> **Management Summary** 
> This is a macOS 6-operator FM synthesizer. It is a **6-operator FM synthesis engine** with **32 algorithms**, **12-voice polyphony**, **128 preset slots**, built-in **effects** (filter, distortion, chorus, delay, reverb, phaser), an **arpeggiator** (7 modes), a **16-step sequencer**, and **CoreMIDI** support. Play it with the on-screen piano keyboard, your Mac's computer keyboard (QWERTY layout mapped like a piano), or an external MIDI keyboard. Designed for personal use, standalone, native macOS SwiftUI.

---

## Table of Contents

1. [Management Summary](#management-summary)
2. [Getting Started](#getting-started)
3. [Main Window Layout](#main-window-layout)
 - [Preset Browser](#preset-browser)
 - [MIDI Connection](#midi-connection)
 - [Arpeggiator](#arpeggiator)
 - [Sequencer](#sequencer)
 - [Global Controls](#global-controls)
 - [Operator Matrix & Operator Panels](#operator-matrix--operator-panels)
 - [Piano Keyboard](#piano-keyboard)
4. [Playing the Synthesizer](#playing-the-synthesizer)
 - [On-Screen Keyboard](#on-screen-keyboard)
 - [Mac Computer Keyboard](#mac-computer-keyboard)
 - [External MIDI Keyboard](#external-midi-keyboard)
5. [Understanding FM Synthesis Basics](#understanding-fm-synthesis-basics)
 - [Operators](#operators)
 - [Algorithms](#algorithms)
 - [ADSR Envelope](#adsr-envelope)
 - [Feedback](#feedback)
 - [LFO](#lfo)
6. [Preset System](#preset-system)
7. [Effects](#effects)
8. [Arpeggiator & Sequencer](#arpeggiator--sequencer)
9. [Keyboard Shortcuts & Mac Key Mapping](#keyboard-shortcuts--mac-key-mapping)
10. [Tips & Sound Design](#tips--sound-design)
11. [Technical Details](#technical-details)
12. [Document History](#document-history)

---

## Management Summary

| Feature | Details |
|---------|---------|
| **Synthesis type** | 6-operator Frequency Modulation (FM) |
| **Algorithms** | 32 routing matrices (how operators connect) |
| **Polyphony** | 12 simultaneous voices |
| **Presets** | 128 slots (factory + user), saved as JSON |
| **Effects** | Filter, Distortion, Chorus, Delay, Reverb, Phaser |
| **Arpeggiator** | 7 modes (Up, Down, Up/Down, Random, Ordered, Chord, Note Repeat) |
| **Sequencer** | 16 steps, programmable note/velocity/gate per step |
| **MIDI** | CoreMIDI input (USB/Bluetooth), program change, CC control |
| **Computer keyboard** | QWERTY keys mapped to piano notes |
| **Platform** | macOS standalone app (no plug-in format) |
| **Audio engine** | AVAudioEngine, phase-accumulating oscillators |

---

## Getting Started

1. **Build & run** the project in Xcode (`Cmd+R`).
2. The main window opens showing the full synthesizer interface.
3. Click keys on the piano keyboard at the bottom to hear sound.
4. Load a factory preset from the preset browser (top section) to hear different sounds.
5. Tweak knobs and sliders in real time — changes are heard immediately.

---

## Main Window Layout

The window is arranged vertically in sections:

```
┌─────────────────────────────────────────────────────┐
│ [Preset Browser] 128 slots, load/save/clear │
├─────────────────────────────────────────────────────┤
│ [MIDI Connection] Source picker, connect/disconnect│
├─────────────────────────────────────────────────────┤
│ [Arpeggiator] [Sequencer] │
├─────────────────────────────────────────────────────┤
│ [Global Controls] Volume, Transpose, Algorithm... │
├─────────────────────────────────────────────────────┤
│ [Operator Matrix] [Operator Panels 1–6] │
├─────────────────────────────────────────────────────┤
│ [Piano Keyboard] 27 keys, centered at bottom │
└─────────────────────────────────────────────────────┘
```

---

### Preset Browser

- **128 slots** numbered 1–128.
- Factory presets are pre-loaded in the first slots (green names).
- Empty slots show "Empty".
- **Load**: Click the play button (▶) on a slot to load that preset.
- **Save**: Click the save button (⬇) to store the current sound in a slot.
- **Clear**: Click the trash button (🗑) to empty a slot.
- **Rename**: Click "Rename" to change a preset's name.
- **Save Current**: Saves the current engine state to the currently selected slot.
- User presets are saved automatically to your Mac's Application Support folder and persist when you quit and reopen the app.

---

### MIDI Connection

- Shows available MIDI sources (USB keyboards, Bluetooth MIDI devices, etc.).
- **Connect**: Select a source from the dropdown, or click "Connect" to use the first available source.
- **Disconnect**: Cut the MIDI connection.
- **Refresh**: Re-scan for MIDI devices.
- Status shows "Connected" (green) or "Disconnected".
- Once connected, an external MIDI keyboard plays the synthesizer. MIDI Program Change (0–127) recalls preset slots 1–128.

---

### Arpeggiator

Plays held notes automatically in patterns.

| Control | What it does |
|---------|-------------|
| **On/Off** | Starts or stops the arpeggiator |
| **Mode** | Choose the note pattern (see below) |
| **Rate** | How fast notes play (notes per second, 0.5–20) |
| **Gate** | How long each note sounds within its step (0.1–1.0) |
| **Octaves** | How many octaves above the held notes to also play (1–4) |

**Modes:**
- **Up**: Plays notes from lowest to highest
- **Down**: Plays notes from highest to lowest
- **Up/Down**: Plays up then back down
- **Random**: Plays a random held note each step
- **Ordered**: Plays notes in the order you pressed them
- **Chord**: Plays all held notes simultaneously
- **Note Repeat**: Repeats the last played note

Hold keys on the keyboard (on-screen or MIDI) and turn the arpeggiator on to hear the pattern.

---

### Sequencer

A 16-step pattern programmer. Each step can play a note with its own velocity and gate length.

| Control | What it does |
|---------|-------------|
| **On/Off** | Starts or stops the sequencer loop |
| **Step buttons (1–16)** | Click to toggle a step on (green) or off |
| **Tempo** | Speed in BPM (30–300) |

To program a step: click a step button to turn it on, then click the key you want on the piano keyboard while the step is active (or edit via code in a future version). The sequencer loops continuously when running.

---

### Global Controls

| Control | Range | What it does |
|---------|-------|-------------|
| **Volume** | 0–1 | Master output volume |
| **Transpose** | -24 to +24 | Shift all notes by semitones (octaves) |
| **Bend Range** | 0 to 24 | Pitch bend wheel range in semitones |
| **Algorithm** | 1–32 | Selects the FM routing topology (see Algorithms below) |
| **Feedback** | 0–1 | Amount of self-modulation for algorithms that use feedback |
| **LFO Rate** | 0.01–20 Hz | Speed of the low-frequency oscillator |
| **LFO Wave** | Sine, Triangle, Square, Saw, Random | Shape of the modulation wave |
| **Oscillator Sync** | On/Off | Hard-sync resets modulator phase on carrier cycle |

---

### Operator Matrix & Operator Panels

**Operator Matrix** (left side): A 6×6 grid showing the selected algorithm.
- **Blue dots** = Carriers (operators whose output goes to the main mix)
- **Green dots** = Modulators (operators that frequency-modulate others)
- **Orange rings** = Modulation connections between operators
- This is a visualization only — you cannot edit the algorithm routing here; use the Algorithm selector in Global Controls.

**Operator Panels** (right side, 2×3 grid): One panel per operator (1–6).

| Control | Range | What it does |
|---------|-------|-------------|
| **Ratio** | 0.5–8 | Frequency multiplier relative to the played note (1.0 = same pitch, 2.0 = one octave higher, etc.) |
| **Detune** | -100 to +100 cents | Fine-tune the operator's pitch |
| **Level** | 0–1 | Output volume of this operator |
| **Attack** | 0–2 s | How fast the sound reaches full level after key press |
| **Decay** | 0–2 s | How fast the sound drops from full to sustain level |
| **Sustain** | 0–1 | Level held while the key is pressed |
| **Release** | 0–5 s | How fast the sound fades after key release |

Operators can be carriers (heard directly) or modulators (change the timbre of other operators), depending on the selected algorithm.

---

### Piano Keyboard

- **27 keys** (MIDI 36–62, approximately C2–D4).
- White keys and black keys arranged like a real piano.
- Active keys light up in blue.
- Click a key to play; release to stop.
- The keyboard is centered horizontally at the bottom of the window.

---

## Playing the Synthesizer

### On-Screen Keyboard

Click any key with your mouse. The key lights up and sounds until you release (or the envelope finishes).

### Mac Computer Keyboard

Your QWERTY keyboard is mapped like a piano:

```
 Q W E R T Y U I O P [ ]
 C3 D3 E3 F3 G3 A3 B3 C4 D4 E4 F4 G4
 A S D F G
 C#2 D#2 F#2 G#2 A#2
 Z X C V B N M , .
 C2 D2 E2 F2 G2 A2 B2 C3 D3
```

Press a key to start the note, release to stop. Key repeat is suppressed (holding a key does not re-trigger the note).

### External MIDI Keyboard

1. Connect your MIDI device via USB or Bluetooth.
2. In the MIDI Connection section, select your device from the dropdown and click "Connect".
3. Play on your external keyboard.
4. MIDI Program Change (0–127) loads preset slots 1–128.
5. MIDI CC messages control parameters:
 - **CC 1 (Mod Wheel)**: LFO rate
 - **CC 7 / 11 (Volume/Expression)**: Master volume
 - **CC 64 (Sustain)**: Hold/release notes

---

## Understanding FM Synthesis Basics

### Operators

An **operator** is a sine-wave oscillator with its own volume envelope (ADSR). In this synth there are 6 operators per voice.

- **Carrier**: An operator whose output is heard directly in the final mix.
- **Modulator**: An operator whose output changes the frequency (pitch) of another operator, creating complex timbres.

### Algorithms

An **algorithm** defines how the 6 operators are connected:
- Which operators are carriers (heard directly)
- Which operators modulate which other operators
- Whether feedback exists (an operator modulating itself)

There are 32 algorithms. Algorithm 1 has feedback on operator 6; Algorithm 24 has all 6 operators as carriers (additive synthesis, no modulation). Try different algorithms with the same operator settings to hear dramatically different sounds.

### ADSR Envelope

Each operator has a 4-stage volume envelope:

| Stage | What happens |
|-------|-------------|
| **Attack** | Time from key press to full volume |
| **Decay** | Time from full volume down to sustain level |
| **Sustain** | Volume level held while key is pressed |
| **Release** | Time from key release to silence |

Short attack = percussive (drums, bells). Long attack = swelling (pads, strings).

### Feedback

In algorithms with feedback, an operator's output is fed back into its own input. Higher feedback = more complex, sometimes harsher or more metallic timbres. Algorithm 1 and 32 have strong feedback on operator 6.

### LFO

The **Low-Frequency Oscillator** creates slow modulation (below hearing range) used for:
- **Vibrato**: Pitch wobble (applied to operator frequency)
- **Tremolo**: Volume wobble (applied to operator level)

The LFO rate and waveform are global controls in the Global section.

---

## Preset System

- **128 slots**: Numbered 1–128.
- **Factory presets**: Pre-loaded sounds (FM Bass, Electric Piano, Brass, Warm Pad, Digital Bell, Organ, Synth Lead, Vibraphone). These are read-only but can be copied to any user slot.
- **User presets**: Your own sounds. Save any slot, edit it, save again.
- **Persistence**: User presets are saved to `~/Library/Application Support/charlyjazz.Synthesizer/presets.json` and load automatically when you restart the app.
- **MIDI Program Change**: External MIDI program change messages (0–127) load preset slots 1–128.

---

## Effects

Applied after the synthesizer mixer, before the output. Each effect has an on/off toggle and an amount knob.

| Effect | What it does |
|--------|-------------|
| **Filter** | Cuts high or low frequencies. Cutoff sets the frequency; resonance boosts around the cutoff. |
| **Distortion** | Overdrives the signal (tanh waveshaping) for grit or warmth. |
| **Chorus** | Adds a detuned, delayed copy for width and movement. |
| **Delay** | Echo effect with feedback. |
| **Reverb** | Simulates room/space ambience. |
| **Phaser** | Sweeping filter effect for whooshing movement. |

---

## Arpeggiator & Sequencer

These are **note generators** — they create note on/off events that drive the synth engine, just like pressing keys.

- Use the **Arpeggiator** to automatically play patterns from held notes.
- Use the **Sequencer** to program a repeating 16-note pattern.
- Both can run simultaneously.
- Both output through the same synth engine, so they're affected by the same algorithms, operators, and effects.

---

## Keyboard Shortcuts & Mac Key Mapping

| Key | Note |
|-----|------|
| Q | C3 |
| W | D3 |
| E | E3 |
| R | F3 |
| T | G3 |
| Y | A3 |
| U | B3 |
| I | C4 |
| O | D4 |
| P | E4 |
| [ | F4 |
| ] | G4 |
| A | C#2 |
| S | D#2 |
| D | F#2 |
| F | G#2 |
| G | A#2 |
| Z | C2 |
| X | D2 |
| C | E2 |
| V | F2 |
| B | G2 |
| N | A2 |
| M | B2 |
| , | C3 |
| . | D3 |

---

## Tips & Sound Design

| Goal | Suggested Approach |
|------|-------------------|
| **Bass sound** | Algorithm 1 (feedback), operator 6 as carrier with low ratio (1.0), short decay |
| **Electric piano** | Algorithm 23, multiple carriers with different ratios (1, 2, 3, 4), fast decay |
| **Brass** | Algorithm 1 with feedback, moderate attack, medium sustain |
| **Pad** | Algorithm 31, long attack (1s+), long release (2s+), multiple carriers |
| **Bell** | Algorithm 15, very short attack (0.001s), medium decay, high ratios |
| **Organ** | Algorithm 23, all carriers, sustain = 1.0, short attack/release |
| **Lead synth** | Algorithm 1 with high feedback (0.8), all operators on ratio 1.0 |

**General tips:**
- Start with a factory preset and tweak one operator at a time to learn what each does.
- Higher ratios = brighter, more metallic tones. Lower ratios = warmer, more harmonic tones.
- Use the LFO for vibrato (pitch) or tremolo (volume) to add life to sustained notes.
- Turn on oscillator sync for harder, more aggressive sync sounds.
- Save sounds you like to user preset slots before experimenting further.

---

## Technical Details

| Item | Value |
|------|-------|
| Audio engine | AVAudioEngine with per-voice AVAudioSourceNode |
| Oscillator type | Phase-accumulating sine oscillator |
| Sample rate | Matches system output (typically 44.1 kHz or 48 kHz) |
| Voices | 12, with voice stealing (oldest releasing voice stolen first) |
| Thread safety | Audio parameters updated via `os_unfair_lock` between UI and render threads |
| Preset format | JSON, stored in Application Support |
| MIDI framework | Apple CoreMIDI (native macOS) |
| UI framework | SwiftUI |

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.1 | 2026-10-16 | Removed all brand references from manual and plan files; renamed to generic "6-Operator FM Synthesizer" |
| 1.0 | 2026-10-16 | Initial manual covering Steps 0–7 (FM engine, modulation, effects, UI, presets, arpeggiator, sequencer, CoreMIDI, Mac keyboard) |

---

> **Note**: This manual should be updated whenever functions are added, changed, or removed. If a new feature is implemented (e.g., Step 8 polish, additional effects, preset export), please add a section here.
