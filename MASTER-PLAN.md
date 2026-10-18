# Master Plan — 6-Operator FM Synthesizer (macOS)

## Project decisions
- Platform: macOS only, standalone app (no AU/VST)
- MIDI: Apple CoreMIDI (no external dependencies)
- UI: SwiftUI with BaseModuleView styling
- Audio: AVAudioEngine with custom phase-accumulating oscillators

## Implemented features (v0.1)
- [x] 6-operator FM synthesis engine with 32 algorithms
- [x] 12-voice polyphony with voice stealing
- [x] ADSR envelope per operator
- [x] LFO with sine, triangle, square, saw, random waveforms
- [x] LFO pitch and amplitude depth controls
- [x] Feedback per algorithm
- [x] Effects chain: Filter, Distortion, Chorus, Delay, Reverb, Phaser
- [x] Oscilloscope with real-time waveform visualization
- [x] Arpeggiator with multiple modes
- [x] 16-step sequencer
- [x] CoreMIDI input support
- [x] Mac keyboard piano mapping with visual key highlighting
- [x] Preset bank with 128 slots (factory + user)
- [x] Soft-clip limiter (tanh) to prevent digital clipping

## Project structure
- `Synthesizer/FMAudio/` — Audio engine (SynthEngine, Voice, Operator, Oscillator, Algorithms, Effects, LFO, MIDIManager, MacKeyboardHandler, Preset, PresetBank, Arpeggiator, Sequencer)
- `Synthesizer/Views/` — SwiftUI views (BaseModuleView, ContentView, GlobalPanel, OscilloscopeView, AudioChainView, AlgorithmMatrixView, OperatorPanel, KeyboardView, PresetBrowserView, MIDIConnectionView, ArpeggiatorView, SequencerView, etc.)
