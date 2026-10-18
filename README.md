# FM-Synthesizer

A polyphonic 6-operator FM synthesis software synthesizer for macOS, built with SwiftUI and AVAudioEngine. Playable via on-screen keyboard, Mac keyboard, or external MIDI controllers.

![Screenshot](screenshot1.png)

## Features

- **6-operator FM synthesis** with 32 DX7-style algorithms
- **Polyphonic** (12 voices) with voice stealing
- **ADSR envelope** per operator
- **LFO** with sine, triangle, square, saw and sample-and-hold waveforms, with pitch and amplitude depth controls
- **Feedback** per algorithm
- **Effects chain**: Filter, Distortion, Chorus, Delay, Reverb, Phaser (each individually toggleable)
- **Oscilloscope** with real-time audio visualization
- **Arpeggiator** with multiple modes
- **16-step sequencer**
- **MIDI input** via Apple CoreMIDI (external keyboards/controllers)
- **Mac keyboard piano mapping** (QWERTY layout, MIDI notes 36–62) with visual key highlighting
- **Preset system** with 128 slots (factory + user), save, load, rename, clear
- **AudioUnit-compatible** render thread for low-latency playback

## Requirements

- macOS 14.0+
- Xcode 15+
- Swift 5.9+

## Build & Run

1. Clone the repository:
   ```bash
   git clone https://github.com/dirkclemens/FM-Synthesizer.git
   cd FM-Synthesizer
   ```
2. Open `Synthesizer.xcodeproj` in Xcode.
3. Select the **Synthesizer** scheme and press **Run** (⌘R).

## Controls

| Input | Action |
|-------|--------|
| On-screen keyboard | Click keys to play notes |
| Mac keyboard | QWERTY → piano layout (C2–D4), keys highlight on press |
| External MIDI | Connect any CoreMIDI source via the MIDI panel |
| Global panel | Volume, transpose, bend range, feedback, LFO rate/wave/depths, oscillator sync |
| Operator panels | Ratio, detune, level, ADSR per operator |
| Effects | Toggle filter, distortion, chorus, delay, reverb, phaser individually |
| Presets | 128 slots: load, save, rename, clear user presets |

## Audio Engine

The synth is built on `AVAudioEngine` with a custom phase-accumulating sine oscillator per operator, rendered at audio rate inside `AVAudioSourceNode` callbacks. A tanh soft-clip limiter prevents digital clipping when voices stack.

## Version

**v0.1** — Initial public release.

## License

MIT License

---

Made with ❤️ by [dirkclemens](https://github.com/dirkclemens)
