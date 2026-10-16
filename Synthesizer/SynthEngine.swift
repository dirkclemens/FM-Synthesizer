//
// SynthEngine.swift
// Synthesizer
//
// Polyphonic FM synthesis engine built on AVAudioEngine.
// Manages 12 voices, voice allocation, note on/off, and parameter publication.
//

import AVFoundation
import Foundation

/// Number of simultaneous voices.
let voiceCount: Int = 12

/// MIDI note range supported by the engine.
let midiNoteRange: ClosedRange<UInt8> = 21...108

/// Thread-safe lock for audio parameter access between main (UI) and audio threads.
private final class ParameterLock {
 private var lock = os_unfair_lock_s()

 func sync<T>(_ block: () throws -> T) rethrows -> T {
 os_unfair_lock_lock(&lock)
 defer { os_unfair_lock_unlock(&lock) }
 return try block()
 }
}

/// The synthesis engine. An ObservableObject so the UI can observe parameter changes.
final class SynthEngine: ObservableObject {

 // MARK: - Audio engine

 private let audioEngine: AVAudioEngine
 private let mainMixer: AVAudioMixerNode
 private let outputNode: AVAudioOutputNode

 /// One source node per voice.
 private var voiceNodes: [AVAudioSourceNode] = []

 /// The voices (internal for testing).
 var voices: [Voice] = []

 /// Whether the engine is running.
 private(set) var isRunning: Bool = false

 /// The sample rate.
 let sampleRate: Double

 // MARK: - Published parameters (UI-observable)

 /// Master volume (0...1).
 @Published var volume: Float = 0.5 {
 didSet { mainMixer.outputVolume = volume }
 }

 /// Global transpose in semitones (-24...+24).
 @Published var transpose: Float = 0

 /// Current algorithm index (0..<32).
 @Published var algorithmIndex: Int = 0

 /// Feedback level (0...1) for algorithms that use feedback.
 @Published var feedbackLevel: Float = 0.5

 /// Oscillator sync enabled.
 @Published var oscillatorSync: Bool = false

 /// LFO rate in Hz (0.01...20).
 @Published var lfoRate: Float = 5.0

 /// LFO waveform.
 @Published var lfoWave: LFOWave = .sine

 /// Pitch bend range in semitones (0...24).
 @Published var pitchBendRange: Float = 2.0

 /// Pitch bend value (-1...1). -1 = down range, +1 = up range, 0 = center.
 @Published var pitchBendValue: Float = 0.0

 /// Per-operator parameters, indexed by operator (0..<6).
 /// Each entry: (ratio, detune, level, attack, decay, sustain, release).
 @Published var operatorParams: [(Float, Float, Float, Float, Float, Float, Float)] = [
 (1.0, 0, 1.0, 0.1, 0.1, 0.5, 0.5), // Operator 1
 (2.0, 0, 0.8, 0.1, 0.1, 0.5, 0.5), // Operator 2
 (3.0, 0, 0.6, 0.1, 0.1, 0.5, 0.5), // Operator 3
 (4.0, 0, 0.4, 0.1, 0.1, 0.5, 0.5), // Operator 4
 (5.0, 0, 0.3, 0.1, 0.1, 0.5, 0.5), // Operator 5
 (6.0, 0, 0.2, 0.1, 0.1, 0.5, 0.5), // Operator 6
 ]

 /// Per-operator on/off state.
 @Published var operatorIsOn: [Bool] = Array(repeating: true, count: 6)

 /// Effects chain (filter → distortion → chorus → delay → reverb → phaser).
 let effects: EffectsChain

 /// Effect enabled states.
 @Published var effectFilterEnabled: Bool = false {
 didSet { effects.setEnabled(.filter, enabled: effectFilterEnabled) }
 }
 @Published var effectDistortionEnabled: Bool = false {
 didSet { effects.setEnabled(.distortion, enabled: effectDistortionEnabled) }
 }
 @Published var effectChorusEnabled: Bool = false {
 didSet { effects.setEnabled(.chorus, enabled: effectChorusEnabled) }
 }
 @Published var effectDelayEnabled: Bool = false {
 didSet { effects.setEnabled(.delay, enabled: effectDelayEnabled) }
 }
 @Published var effectReverbEnabled: Bool = false {
 didSet { effects.setEnabled(.reverb, enabled: effectReverbEnabled) }
 }
 @Published var effectPhaserEnabled: Bool = false {
 didSet { effects.setEnabled(.phaser, enabled: effectPhaserEnabled) }
 }

 /// Effect amounts (wet/dry mix, 0...1).
 @Published var effectFilterAmount: Float = 0.5 {
 didSet { effects.setAmount(.filter, amount: effectFilterAmount) }
 }
 @Published var effectDistortionAmount: Float = 0.5 {
 didSet { effects.setAmount(.distortion, amount: effectDistortionAmount) }
 }
 @Published var effectChorusAmount: Float = 0.5 {
 didSet { effects.setAmount(.chorus, amount: effectChorusAmount) }
 }
 @Published var effectDelayAmount: Float = 0.5 {
 didSet { effects.setAmount(.delay, amount: effectDelayAmount) }
 }
 @Published var effectReverbAmount: Float = 0.5 {
 didSet { effects.setAmount(.reverb, amount: effectReverbAmount) }
 }
 @Published var effectPhaserAmount: Float = 0.5 {
 didSet { effects.setAmount(.phaser, amount: effectPhaserAmount) }
 }

 /// Filter cutoff frequency (Hz).
 @Published var effectFilterCutoff: Float = 5000 {
 didSet { effects.setFilterCutoff(effectFilterCutoff) }
 }
 /// Filter resonance (Q).
 @Published var effectFilterResonance: Float = 1.0 {
 didSet { effects.setFilterResonance(effectFilterResonance) }
 }

 /// Arpeggiator.
 lazy var arpeggiator: Arpeggiator = Arpeggiator(engine: self)

 /// Sequencer.
 lazy var sequencer: Sequencer = Sequencer(engine: self)

 /// Reference to the preset bank (set from ContentView for MIDI program change).
 weak var presetBank: PresetBank?

 /// Parameter lock for thread-safe reads on the audio thread.
 private let paramLock = ParameterLock()

 // MARK: - Initialization

 init() {
 audioEngine = AVAudioEngine()
 mainMixer = audioEngine.mainMixerNode
 outputNode = audioEngine.outputNode
 sampleRate = outputNode.inputFormat(forBus: 0).sampleRate

 // Create effects chain early (before self is used in closures).
 effects = EffectsChain(
 audioEngine: audioEngine,
 inputNode: mainMixer,
 outputNode: outputNode
 )

 // Create voices.
 for i in 0..<voiceCount {
 let algo = fmAlgorithms[i % fmAlgorithms.count]
 voices.append(Voice(sampleRate: sampleRate, algorithm: algo))
 }

 // Create one source node per voice.
 for i in 0..<voiceCount {
 let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
 self?.renderVoiceNode(i: Int(i), frameCount: Int(frameCount), audioBufferList: audioBufferList) ?? noErr
 }
 voiceNodes.append(node)
 audioEngine.attach(node)
 audioEngine.connect(node, to: mainMixer, format: nil)
 }

 // Disconnect the direct mixer→output connection;
 // the effects chain will wire its own connections on rebuild.
 audioEngine.disconnectNodeInput(outputNode)
 audioEngine.disconnectNodeOutput(mainMixer)

 // Build initial chain (all effects disabled = mixer → output).
 effects.rebuildChain()

 // Initial volume.
 mainMixer.outputVolume = volume
 }

 deinit {
 stop()
 saveSettings()
 }

 // MARK: - Start / Stop

 func start() throws {
 guard !isRunning else { return }
 try audioEngine.start()
 isRunning = true
 }

 func stop() {
 guard isRunning else { return }
 audioEngine.stop()
 isRunning = false
 }

 // MARK: - Voice rendering (audio thread callback)

 private func renderVoiceNode(i: Int, frameCount: Int, audioBufferList: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
 let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
 let numChannels = ablPointer.count

 // Snapshot parameters under lock (thread-safe copy).
 let params = paramLock.sync {
 (
 transpose: self.transpose,
 algorithmIndex: self.algorithmIndex,
 feedbackLevel: self.feedbackLevel,
 oscillatorSync: self.oscillatorSync,
 lfoRate: self.lfoRate,
 lfoWave: self.lfoWave,
 pitchBendRange: self.pitchBendRange,
 pitchBendValue: self.pitchBendValue,
 operatorParams: self.operatorParams,
 operatorIsOn: self.operatorIsOn
 )
 }

 let voice = voices[i]

 // Update voice algorithm if changed.
 voice.setAlgorithm(fmAlgorithms[params.algorithmIndex])
 voice.configureOperators(params.operatorParams)

 // Apply per-operator on/off state.
 for (index, isOn) in params.operatorIsOn.enumerated() {
 voice.setOperatorIsOn(isOn, at: index)
 }

 // Apply global modulation controls.
 voice.oscillatorSync = params.oscillatorSync
 voice.setLFO(rate: params.lfoRate, wave: params.lfoWave)

 // Render samples using the voice's own LFO.
 let samples = voice.render(frameCount: frameCount)

 for frame in 0..<frameCount {
 let sample = samples[frame]
 for channel in 0..<numChannels {
 guard let channelData = ablPointer[channel].mData?.assumingMemoryBound(to: Float.self) else {
 continue
 }
 let buf = UnsafeMutableBufferPointer(start: channelData, count: frameCount)
 buf[frame] = sample
 }
 }

 return noErr
 }

 // MARK: - Note on / off (called from main thread or MIDI thread)

 /// Starts a note. Called from the main thread (UI) or MIDI thread.
 func noteOn(midiNote: UInt8, velocity: Float) {
 guard midiNoteRange.contains(midiNote) else { return }

 // Apply transpose and pitch bend.
 let transposeSemitones = Int(clamp(transpose, -24, 24))
 let bendSemitones = pitchBendValue * pitchBendRange
 let transposedNoteFloat = Float(midiNote) + Float(transposeSemitones) + bendSemitones
 let clampedNote = max(21, min(108, Int(transposedNoteFloat.rounded())))
 let transposedNote = UInt8(clampedNote)
 let baseFreq = midiNoteToFreq(midiNumber: transposedNote)

 paramLock.sync {
 // Find a free voice.
 if let freeIndex = voices.firstIndex(where: { $0.state == .free }) {
 voices[freeIndex].noteOn(midiNote: midiNote, velocity: velocity, baseFrequency: baseFreq)
 return
 }

 // No free voice: steal from releasing voices first (lowest envelope), then active.
 let victimIndex = stealVoice()
 voices[victimIndex].noteOn(midiNote: midiNote, velocity: velocity, baseFrequency: baseFreq)
 }
 }

 /// Stops a note (triggers release). Called from the main thread or MIDI thread.
 func noteOff(midiNote: UInt8) {
 paramLock.sync {
 for voice in voices where voice.midiNote == midiNote && voice.state == .active {
 voice.noteOff()
 }
 }
 }

 /// Releases all active notes.
 func allNotesOff() {
 paramLock.sync {
 for voice in voices where voice.state == .active {
 voice.noteOff()
 }
 }
 }

 /// Silence all voices immediately.
 func reset() {
 paramLock.sync {
 for voice in voices {
 voice.silence()
 }
 }
 }

 // MARK: - Voice stealing

 /// Selects a voice to steal: prefers releasing voices with lowest envelope,
 /// then the oldest active voice.
 private func stealVoice() -> Int {
 // Find releasing voice with lowest envelope level.
 var bestIndex: Int? = nil
 var bestLevel: Float = .greatestFiniteMagnitude

 for (i, voice) in voices.enumerated() where voice.state == .releasing {
 let level = voice.operators.map { $0.envelopeValue }.max() ?? 0
 if level < bestLevel {
 bestLevel = level
 bestIndex = i
 }
 }

 if let bestIndex = bestIndex {
 return bestIndex
 }

 // Fall back: steal the first active voice.
 if let activeIndex = voices.firstIndex(where: { $0.state == .active }) {
 return activeIndex
 }

 return 0
 }

 // MARK: - Helpers

 /// Clamps a value to a range.
 private func clamp<T: Comparable>(_ value: T, _ min: T, _ max: T) -> T {
 return Swift.min(Swift.max(value, min), max)
 }

 // MARK: - Preset support

 /// Current engine state as a `Preset`.
 var preset: Preset {
 var p = Preset(name: "Current")
 p.algorithm = algorithmIndex
 p.transpose = transpose
 p.feedbackLevel = feedbackLevel
 p.oscillatorSync = oscillatorSync
 p.lfoRate = lfoRate
 p.lfoWave = lfoWave.rawValue
 for index in 0..<6 {
 let params = operatorParams[safe: index] ?? (1.0, 0, 1.0, 0.1, 0.1, 0.5, 0.5)
 p.operators[index] = OperatorPreset(
 isOn: operatorIsOn[safe: index] ?? true,
 ratio: params.0,
 detune: params.1,
 level: params.2,
 attack: params.3,
 decay: params.4,
 sustain: params.5,
 release: params.6
 )
 }
 // Effect states.
 for type in EffectType.allCases {
 if let config = effects.configs[type] {
 p.effects[type.rawValue] = config
 }
 }
 // Arpeggiator state.
 p.arpeggiatorMode = arpeggiator.mode.rawValue
 p.arpeggiatorRate = arpeggiator.rate
 p.arpeggiatorGate = arpeggiator.gate
 p.arpeggiatorOctaveRange = arpeggiator.octaveRange
 // Sequencer state.
 p.sequencerTempo = sequencer.tempo
 p.sequencerSteps = sequencer.steps
 return p
 }

 /// Applies a `Preset` to the engine.
 func load(preset: Preset) {
 paramLock.sync {
 algorithmIndex = preset.algorithm
 transpose = preset.transpose
 feedbackLevel = preset.feedbackLevel
 oscillatorSync = preset.oscillatorSync
 lfoRate = preset.lfoRate
 lfoWave = LFOWave(rawValue: preset.lfoWave) ?? .sine

 for index in 0..<6 {
 let op = preset.operators[safe: index] ?? OperatorPreset()
 operatorParams[index] = (
 op.ratio,
 op.detune,
 op.level,
 op.attack,
 op.decay,
 op.sustain,
 op.release
 )
 operatorIsOn[index] = op.isOn
 }

 // Effect states.
 for type in EffectType.allCases {
 if let config = preset.effects[type.rawValue] {
 effects.configs[type] = config
 // Update published properties to match.
 DispatchQueue.main.async {
 switch type {
 case .filter:
 self.effectFilterEnabled = config.enabled
 self.effectFilterAmount = config.amount
 case .distortion:
 self.effectDistortionEnabled = config.enabled
 self.effectDistortionAmount = config.amount
 case .chorus:
 self.effectChorusEnabled = config.enabled
 self.effectChorusAmount = config.amount
 case .delay:
 self.effectDelayEnabled = config.enabled
 self.effectDelayAmount = config.amount
 case .reverb:
 self.effectReverbEnabled = config.enabled
 self.effectReverbAmount = config.amount
 case .phaser:
 self.effectPhaserEnabled = config.enabled
 self.effectPhaserAmount = config.amount
 }
 }
 }
 }
 // Rebuild chain with new effect states.
 effects.rebuildChain()
 }
 
 // Arpeggiator state.
 if let mode = ArpMode(rawValue: preset.arpeggiatorMode) {
 arpeggiator.mode = mode
 }
 arpeggiator.rate = preset.arpeggiatorRate
 arpeggiator.gate = preset.arpeggiatorGate
 arpeggiator.octaveRange = preset.arpeggiatorOctaveRange
 
 // Sequencer state.
 sequencer.tempo = preset.sequencerTempo
 sequencer.steps = preset.sequencerSteps
 }

 // MARK: - Settings persistence (Application Support)

 private let settingsFileName = "SynthEngineSettings.json"

 private var settingsFileURL: URL? {
 FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
 .first?.appendingPathComponent("charlyjazz.Synthesizer", isDirectory: true)
 .appendingPathComponent(settingsFileName)
 }

 /// Saves all engine parameters to a JSON file in Application Support.
 /// Called on app quit to preserve the current state.
 func saveSettings() {
 guard let url = settingsFileURL else { return }

 var dict: [String: Any] = [:]

 // Global parameters
 dict["volume"] = volume
 dict["transpose"] = transpose
 dict["algorithmIndex"] = algorithmIndex
 dict["feedbackLevel"] = feedbackLevel
 dict["oscillatorSync"] = oscillatorSync
 dict["lfoRate"] = lfoRate
 dict["lfoWave"] = lfoWave.rawValue
 dict["pitchBendRange"] = pitchBendRange
 dict["pitchBendValue"] = pitchBendValue

 // Operator parameters
 var opParams: [[Float]] = []
 for params in operatorParams {
 opParams.append([params.0, params.1, params.2, params.3, params.4, params.5, params.6])
 }
 dict["operatorParams"] = opParams

 // Operator on/off
 dict["operatorIsOn"] = operatorIsOn

 // Effects
 dict["effectFilterEnabled"] = effectFilterEnabled
 dict["effectFilterAmount"] = effectFilterAmount
 dict["effectFilterCutoff"] = effectFilterCutoff
 dict["effectFilterResonance"] = effectFilterResonance
 dict["effectDistortionEnabled"] = effectDistortionEnabled
 dict["effectDistortionAmount"] = effectDistortionAmount
 dict["effectChorusEnabled"] = effectChorusEnabled
 dict["effectChorusAmount"] = effectChorusAmount
 dict["effectDelayEnabled"] = effectDelayEnabled
 dict["effectDelayAmount"] = effectDelayAmount
 dict["effectReverbEnabled"] = effectReverbEnabled
 dict["effectReverbAmount"] = effectReverbAmount
 dict["effectPhaserEnabled"] = effectPhaserEnabled
 dict["effectPhaserAmount"] = effectPhaserAmount

 // Arpeggiator
 dict["arpeggiatorMode"] = arpeggiator.mode.rawValue
 dict["arpeggiatorRate"] = arpeggiator.rate
 dict["arpeggiatorGate"] = arpeggiator.gate
 dict["arpeggiatorOctaveRange"] = arpeggiator.octaveRange

 // Sequencer
 dict["sequencerTempo"] = sequencer.tempo
 var seqSteps: [[String: Any]] = []
 for step in sequencer.steps {
 seqSteps.append([
 "isOn": step.isOn,
 "note": Int(step.note),
 "velocity": step.velocity,
 "gate": step.gate,
 ])
 }
 dict["sequencerSteps"] = seqSteps

 do {
 let data = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
 try? FileManager.default.createDirectory(
 at: url.deletingLastPathComponent(),
 withIntermediateDirectories: true
 )
 try data.write(to: url, options: .atomic)
 } catch {
 print("Failed to save settings: \(error)")
 }
 }

 /// Loads engine parameters from the JSON file in Application Support.
 /// Call this when the user wants to restore the last saved state.
 func loadSettings() {
 guard let url = settingsFileURL,
 FileManager.default.fileExists(atPath: url.path) else { return }

 do {
 let data = try Data(contentsOf: url)
 guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

 // Global parameters
 if let v = dict["volume"] as? Float { volume = v }
 if let v = dict["transpose"] as? Float { transpose = v }
 if let v = dict["algorithmIndex"] as? Int { algorithmIndex = v }
 if let v = dict["feedbackLevel"] as? Float { feedbackLevel = v }
 if let v = dict["oscillatorSync"] as? Bool { oscillatorSync = v }
 if let v = dict["lfoRate"] as? Float { lfoRate = v }
 if let v = dict["lfoWave"] as? Int { lfoWave = LFOWave(rawValue: v) ?? .sine }
 if let v = dict["pitchBendRange"] as? Float { pitchBendRange = v }
 if let v = dict["pitchBendValue"] as? Float { pitchBendValue = v }

 // Operator parameters
 if let opParams = dict["operatorParams"] as? [[Float]] {
 for (index, params) in opParams.enumerated() where index < 6 && params.count == 7 {
 operatorParams[index] = (params[0], params[1], params[2], params[3], params[4], params[5], params[6])
 }
 }

 // Operator on/off
 if let opIsOn = dict["operatorIsOn"] as? [Bool] {
 for (index, isOn) in opIsOn.enumerated() where index < 6 {
 operatorIsOn[index] = isOn
 }
 }

 // Effects
 if let v = dict["effectFilterEnabled"] as? Bool { effectFilterEnabled = v }
 if let v = dict["effectFilterAmount"] as? Float { effectFilterAmount = v }
 if let v = dict["effectFilterCutoff"] as? Float { effectFilterCutoff = v }
 if let v = dict["effectFilterResonance"] as? Float { effectFilterResonance = v }
 if let v = dict["effectDistortionEnabled"] as? Bool { effectDistortionEnabled = v }
 if let v = dict["effectDistortionAmount"] as? Float { effectDistortionAmount = v }
 if let v = dict["effectChorusEnabled"] as? Bool { effectChorusEnabled = v }
 if let v = dict["effectChorusAmount"] as? Float { effectChorusAmount = v }
 if let v = dict["effectDelayEnabled"] as? Bool { effectDelayEnabled = v }
 if let v = dict["effectDelayAmount"] as? Float { effectDelayAmount = v }
 if let v = dict["effectReverbEnabled"] as? Bool { effectReverbEnabled = v }
 if let v = dict["effectReverbAmount"] as? Float { effectReverbAmount = v }
 if let v = dict["effectPhaserEnabled"] as? Bool { effectPhaserEnabled = v }
 if let v = dict["effectPhaserAmount"] as? Float { effectPhaserAmount = v }

 // Rebuild effects chain with loaded states
 effects.rebuildChain()

 // Arpeggiator
 if let v = dict["arpeggiatorMode"] as? Int {
 arpeggiator.mode = ArpMode(rawValue: v) ?? .up
 }
 if let v = dict["arpeggiatorRate"] as? Float { arpeggiator.rate = v }
 if let v = dict["arpeggiatorGate"] as? Float { arpeggiator.gate = v }
 if let v = dict["arpeggiatorOctaveRange"] as? Int { arpeggiator.octaveRange = v }

 // Sequencer
 if let v = dict["sequencerTempo"] as? Float { sequencer.tempo = v }
 if let seqSteps = dict["sequencerSteps"] as? [[String: Any]] {
 for (index, stepDict) in seqSteps.enumerated() where index < Sequencer.stepCount {
 var step = sequencer.steps[index]
 if let isOn = stepDict["isOn"] as? Bool { step.isOn = isOn }
 if let note = stepDict["note"] as? Int { step.note = UInt8(note) }
 if let velocity = stepDict["velocity"] as? Float { step.velocity = velocity }
 if let gate = stepDict["gate"] as? Float { step.gate = gate }
 sequencer.steps[index] = step
 }
 }
 } catch {
 print("Failed to load settings: \(error)")
 }
 }
}
