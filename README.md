# MIDI-Synthesizer

A polyphonic FM synthesis software synthesizer for macOS, built with SwiftUI and AVAudioEngine. Playable via on-screen keyboard, Mac keyboard, or external MIDI controllers.

![Screenshot](screenshot1.png)

## Features

- **6-operator FM synthesis** with 32 DX7-style algorithms
- **Polyphonic** (12 voices) with voice stealing
- **ADSR envelope** per operator
- **LFO** with sine, triangle, square, saw and sample-and-hold waveforms
- **Feedback** per algorithm
- **Effects chain**: Filter, Distortion, Chorus, Delay, Reverb, Phaser
- **Oscilloscope** with real-time audio visualization
- **Arpeggiator** and 16-step sequencer
- **MIDI input** via CoreMIDI (external keyboards/controllers)
- **Mac keyboard piano mapping** (QWERTY layout, MIDI notes 36–62)
- **Preset system** with 128 slots and factory presets
- **AudioUnit-compatible** render thread for low-latency playback

## Requirements

- macOS 14.0+
- Xcode 15+
- Swift 5.9+

## Build & Run

1. Clone the repository:
 ```bash
 git clone https://github.com/dirkclemens/MIDI-Synthesizer.git
 cd MIDI-Synthesizer
 ```
2. Open `Synthesizer.xcodeproj` in Xcode.
3. Select the **Synthesizer** scheme and press **Run** (⌘R).

## Controls

| Input | Action |
|-------|--------|
| On-screen keyboard | Click keys to play notes |
| Mac keyboard | QWERTY → piano layout (C2–D4) |
| External MIDI | Connect any CoreMIDI source via the MIDI panel |
| Global panel | Volume, transpose, bend range, feedback, LFO, oscillator sync |
| Operator panels | Ratio, detune, level, ADSR per operator |
| Effects | Toggle and shape filter, distortion, chorus, delay, reverb, phaser |

## Audio Engine

The synth is built on `AVAudioEngine` with a custom phase-accumulating sine oscillator per operator, rendered at audio rate inside `AVAudioSourceNode` callbacks. A tanh soft-clip limiter prevents digital clipping when voices stack.

## Version

**v0.1** — Initial public release.

## License

MIT License

---

Made with ❤️ by [dirkclemens](https://github.com/dirkclemens)
