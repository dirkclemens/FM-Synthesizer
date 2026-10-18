//
// SynthEngine.swift
// Synthesizer
//
// Polyphonic FM synthesis engine built on AVAudioEngine.
//

import AVFoundation
import Foundation

let voiceCount: Int = 12
let midiNoteRange: ClosedRange<UInt8> = 21...108

private final class ParameterLock {
    private var lock = os_unfair_lock_s()
    func sync<T>(_ block: () throws -> T) rethrows -> T {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        return try block()
    }
}

final class SynthEngine: ObservableObject {
    private let audioEngine = AVAudioEngine()
    private let mainMixer: AVAudioMixerNode
    private let outputNode: AVAudioOutputNode
    private var voiceNodes: [AVAudioSourceNode] = []
    var voices: [Voice] = []
    @Published var isRunning: Bool = false
    let sampleRate: Double

    @Published var volume: Float = 0.8 {
        didSet { mainMixer.outputVolume = volume }
    }
    @Published var transpose: Float = 0
    @Published var algorithmIndex: Int = 0
    @Published var feedbackLevel: Float = 0.7
    @Published var oscillatorSync: Bool = false
    @Published var lfoRate: Float = 5.0
    @Published var lfoWave: LFOWave = .sine
    @Published var lfoPitchDepth: Float = 0.3
    @Published var lfoAmpDepth: Float = 0.3
    @Published var pitchBendRange: Float = 2.0
    @Published var pitchBendValue: Float = 0.0
    @Published var operatorParams: [(Float, Float, Float, Float, Float, Float, Float)] = [
        (1.0, 0, 0.0, 0.1, 0.2, 0.0, 0.3),
        (1.0, 0, 0.0, 0.1, 0.2, 0.0, 0.3),
        (1.0, 0, 0.0, 0.1, 0.2, 0.0, 0.3),
        (1.0, 0, 0.0, 0.1, 0.2, 0.0, 0.3),
        (1.0, 0, 0.5, 0.1, 0.2, 0.0, 0.3),
        (1.0, 0, 1.0, 0.1, 0.2, 1.0, 0.3),
    ]
    @Published var operatorIsOn: [Bool] = Array(repeating: true, count: 6)

    let effects: EffectsChain

    @Published var effectFilterEnabled: Bool = false {
        didSet { effects.setEnabled(.filter, enabled: effectFilterEnabled) }
    }
    @Published var effectDistortionEnabled: Bool = false {
        didSet {
            effects.setEnabled(.distortion, enabled: effectDistortionEnabled)
        }
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
    @Published var effectFilterAmount: Float = 0.5 {
        didSet { effects.setAmount(.filter, amount: effectFilterAmount) }
    }
    @Published var effectDistortionAmount: Float = 0.5 {
        didSet {
            effects.setAmount(.distortion, amount: effectDistortionAmount)
        }
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
    @Published var effectFilterCutoff: Float = 5000 {
        didSet { effects.setFilterCutoff(effectFilterCutoff) }
    }
    @Published var effectFilterResonance: Float = 1.0 {
        didSet { effects.setFilterResonance(effectFilterResonance) }
    }

    lazy var arpeggiator: Arpeggiator = Arpeggiator(engine: self)
    lazy var sequencer: Sequencer = Sequencer(engine: self)
    weak var presetBank: PresetBank?
    private let paramLock = ParameterLock()

    @Published var scopeSamples: [Float] = Array(repeating: 0, count: 512)

    /// Number of currently active voices (for voice stealing compensation).
    var activeVoiceCount: Int {
        voices.count { $0.state == .active || $0.state == .releasing }
    }

    /// Diagnostic counter for render callback invocations.
    private var renderDiagnosticCount = 0

    init() {
        self.mainMixer = audioEngine.mainMixerNode
        self.outputNode = audioEngine.outputNode
        self.sampleRate = outputNode.inputFormat(forBus: 0).sampleRate

        print("[SynthEngine] Sample rate: \(sampleRate)")
        print("[SYNTH] Main mixer: \(mainMixer)")
        print("[SynthEngine] Output node: \(outputNode)")

        effects = EffectsChain(
            audioEngine: audioEngine,
            inputNode: mainMixer,
            outputNode: outputNode
        )

        for i in 0..<voiceCount {
            let algo = fmAlgorithms[i % fmAlgorithms.count]
            voices.append(Voice(sampleRate: sampleRate, algorithm: algo))
            print(
                "[SynthEngine] Voice \(i): algorithm \(fmAlgorithms[i % fmAlgorithms.count].name)"
            )
        }

        for i in 0..<voiceCount {
            let node = AVAudioSourceNode {
                [weak self] _,
                _,
                frameCount,
                audioBufferList -> OSStatus in
                self?.renderVoiceNode(
                    i: Int(i),
                    frameCount: Int(frameCount),
                    audioBufferList: audioBufferList
                ) ?? noErr
            }
            voiceNodes.append(node)
            audioEngine.attach(node)
            audioEngine.connect(node, to: mainMixer, format: nil)
            print(
                "[SynthEngine] Voice node \(i) attached and connected to mainMixer"
            )
        }

        audioEngine.connect(mainMixer, to: outputNode, format: nil)
        print("[SynthEngine] mainMixer connected to outputNode")

        effects.rebuildChain()
        print("[SynthEngine] effects.rebuildChain() called")

        mainMixer.outputVolume = volume
        print("[SynthEngine] Volume set to \(volume)")

        setupScopeTap()
        print("[SynthEngine] Init complete")
    }

    deinit {
        stop()
        saveSettings()
    }

    func start() throws {
        guard !isRunning else { return }
        print("[SynthEngine] Starting audio engine...")
        try audioEngine.start()
        isRunning = true
        print("[SynthEngine] Audio engine STARTED successfully")
    }

    func stop() {
        guard isRunning else { return }
        audioEngine.stop()
        isRunning = false
        print("[SynthEngine] Audio engine stopped")
    }

    private func setupScopeTap() {
        mainMixer
            .installTap(onBus: 0, bufferSize: 1024, format: outputNode.inputFormat(forBus: 0)) { (
                buffer,
                time
            ) in
                let ablPointer = UnsafeMutableAudioBufferListPointer(
                    UnsafeMutablePointer(mutating: buffer.audioBufferList)
                )
                guard let data = ablPointer[0].mData?.assumingMemoryBound(to: Float.self) else {
                    return
                }
                let count = min(
                    Int(
                        ablPointer[0].mDataByteSize
                    ) / MemoryLayout<Float>.stride,
                    512
                )
                var samples = [Float](repeating: 0, count: count)
                for i in 0..<count { samples[i] = data[i] }
                DispatchQueue.main.async {
                    self.scopeSamples = samples
                }
            }
    }

    private func renderVoiceNode(i: Int, frameCount: Int, audioBufferList: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
        let numChannels = ablPointer.count

        let params = paramLock.sync {
            (
                transpose: self.transpose,
                algorithmIndex: self.algorithmIndex,
                feedbackLevel: self.feedbackLevel,
                oscillatorSync: self.oscillatorSync,
                lfoRate: self.lfoRate,
                lfoWave: self.lfoWave,
                lfoPitchDepth: self.lfoPitchDepth,
                lfoAmpDepth: self.lfoAmpDepth,
                pitchBendRange: self.pitchBendRange,
                pitchBendValue: self.pitchBendValue,
                operatorParams: self.operatorParams,
                operatorIsOn: self.operatorIsOn,
                activeVoiceCount: voices
                    .count { $0.state == .active || $0.state == .releasing }
            )
        }

        let voice = voices[i]
        voice.setAlgorithm(fmAlgorithms[params.algorithmIndex])
        voice.configureOperators(params.operatorParams)

        for (index, isOn) in params.operatorIsOn.enumerated() {
            voice.setOperatorIsOn(isOn, at: index)
        }

        voice.oscillatorSync = params.oscillatorSync
        voice
            .setLFO(
                rate: params.lfoRate,
                wave: params.lfoWave,
                pitchDepth: params.lfoPitchDepth,
                ampDepth: params.lfoAmpDepth
            )
        voice.feedbackLevel = params.feedbackLevel

        let samples = voice.render(frameCount: frameCount)
        let voiceCount = max(1, params.activeVoiceCount)
        renderDiagnosticCount += 1
        if renderDiagnosticCount <= 3 {
            let maxSample = samples.map { abs($0) }.max() ?? 0
            print(
                "[SynthEngine] renderVoiceNode(\(i)) call #\(renderDiagnosticCount): frameCount=\(frameCount), maxSample=\(maxSample), activeVoiceCount=\(params.activeVoiceCount)"
            )
        }
        for buffer in ablPointer {
            guard let data = buffer.mData?.assumingMemoryBound(to: Float.self) else {
                continue
            }
            let numChannels = Int(buffer.mNumberChannels)
            let numFrames = Int(
                buffer.mDataByteSize
            ) / MemoryLayout<Float>.stride / numChannels
            for frame in 0..<min(numFrames, frameCount) {
                // Voice-count compensation keeps the summed output from clipping
                // when several voices play at once; tanh() is a soft-clip limiter
                // that rounds only the loudest peaks (gentle overdrive character).
                let sample = tanh(samples[frame] / Float(voiceCount))
                for ch in 0..<numChannels {
                    data[frame * numChannels + ch] = sample
                }
            }
        }
        return noErr
    }

    func noteOn(midiNote: UInt8, velocity: Float) {
        print("[SynthEngine] noteOn: midi=\(midiNote), velocity=\(velocity)")
        guard midiNoteRange.contains(midiNote) else {
            print("[SynthEngine] NOTE OUT OF RANGE: \(midiNote)")
            return
        }

        let transposeSemitones = Int(clamp(transpose, -24, 24))
        let bendSemitones = pitchBendValue * pitchBendRange
        let transposedNoteFloat = Float(midiNote) + Float(
            transposeSemitones
        ) + bendSemitones
        let clampedNote = max(21, min(108, Int(transposedNoteFloat.rounded())))
        let transposedNote = UInt8(clampedNote)
        let baseFreq = midiNoteToFreq(midiNumber: transposedNote)

        print(
            "[SynthEngine] Note \(midiNote) -> transposed \(transposedNote), freq \(baseFreq) Hz"
        )

        paramLock.sync {
            if let freeIndex = voices.firstIndex(where: { $0.state == .free }) {
                voices[freeIndex]
                    .noteOn(
                        midiNote: midiNote,
                        velocity: velocity,
                        baseFrequency: baseFreq
                    )
                print(
                    "[SynthEngine] Note \(midiNote) assigned to free voice \(freeIndex)"
                )
                return
            }
            let victimIndex = stealVoice()
            voices[victimIndex]
                .noteOn(
                    midiNote: midiNote,
                    velocity: velocity,
                    baseFrequency: baseFreq
                )
            print(
                "[SynthEngine] Note \(midiNote) assigned to stolen voice \(victimIndex)"
            )
        }
    }

    func noteOff(midiNote: UInt8) {
        print("[SynthEngine] noteOff: \(midiNote)")
        paramLock.sync {
            for voice in voices where voice.midiNote == midiNote && voice.state == .active {
                voice.noteOff()
            }
        }
    }

    func allNotesOff() {
        paramLock.sync {
            for voice in voices where voice.state == .active {
                voice.noteOff()
            }
        }
    }

    func reset() {
        paramLock.sync {
            for voice in voices {
                voice.silence()
            }
        }
        renderDiagnosticCount = 0
        print("[SynthEngine] Engine reset — all voices silenced")
    }

    private func stealVoice() -> Int {
        var bestIndex: Int? = nil
        var bestLevel: Float = .greatestFiniteMagnitude
        for (i, voice) in voices.enumerated() where voice.state == .releasing {
            let level = voice.operators.map { $0.envelopeValue }.max() ?? 0
            if level < bestLevel {
                bestLevel = level
                bestIndex = i
            }
        }
        if let bestIndex = bestIndex { return bestIndex }
        if let activeIndex = voices.firstIndex(where: { $0.state == .active }) {
            return activeIndex
        }
        return 0
    }

    private func clamp<T: Comparable>(_ value: T, _ min: T, _ max: T) -> T {
        Swift.min(Swift.max(value, min), max)
    }

    var preset: Preset {
        var p = Preset(name: "Current")
        p.algorithm = algorithmIndex
        p.transpose = transpose
        p.feedbackLevel = feedbackLevel
        p.oscillatorSync = oscillatorSync
        p.lfoRate = lfoRate
        p.lfoWave = lfoWave.rawValue
        for index in 0..<6 {
            let params = operatorParams[safe: index] ?? (
                1.0,
                0,
                1.0,
                0.1,
                0.1,
                0.5,
                0.5
            )
            p.operators[index] = OperatorPreset(
                isOn: operatorIsOn[safe: index] ?? true,
                ratio: params.0, detune: params.1, level: params.2,
                attack: params.3, decay: params.4, sustain: params.5, release: params.6
            )
        }
        for type in EffectType.allCases {
            if let config = effects.configs[type] {
                p.effects[type.rawValue] = config
            }
        }
        p.arpeggiatorMode = arpeggiator.mode.rawValue
        p.arpeggiatorRate = arpeggiator.rate
        p.arpeggiatorOctaveRange = arpeggiator.octaveRange
        p.sequencerTempo = sequencer.tempo
        p.sequencerSteps = sequencer.steps
        return p
    }

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
                    op.ratio, op.detune, op.level,
                    op.attack, op.decay, op.sustain, op.release
                )
                operatorIsOn[index] = op.isOn
            }
            for type in EffectType.allCases {
                if let config = preset.effects[type.rawValue] {
                    effects.configs[type] = config
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
            effects.rebuildChain()
        }
        if let mode = ArpMode(rawValue: preset.arpeggiatorMode) {
            arpeggiator.mode = mode
        }
        arpeggiator.rate = preset.arpeggiatorRate
        arpeggiator.gate = preset.arpeggiatorGate
        arpeggiator.octaveRange = preset.arpeggiatorOctaveRange
        sequencer.tempo = preset.sequencerTempo
        sequencer.steps = preset.sequencerSteps
    }

    private let settingsFileName = "SynthEngineSettings.json"
    private var settingsFileURL: URL? {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("charlyjazz.Synthesizer", isDirectory: true)
            .appendingPathComponent(settingsFileName)
    }

    func saveSettings() {
        guard let url = settingsFileURL else { return }
        var dict: [String: Any] = [:]
        dict["volume"] = volume
        dict["transpose"] = transpose
        dict["algorithmIndex"] = algorithmIndex
        dict["feedbackLevel"] = feedbackLevel
        dict["oscillatorSync"] = oscillatorSync
        dict["lfoRate"] = lfoRate
        dict["lfoWave"] = lfoWave.rawValue
        dict["pitchBendRange"] = pitchBendRange
        dict["pitchBendValue"] = pitchBendValue
        var opParams: [[Float]] = []
        for params in operatorParams {
            opParams
                .append(
                    [
                        params.0,
                        params.1,
                        params.2,
                        params.3,
                        params.4,
                        params.5,
                        params.6
                    ]
                )
        }
        dict["operatorParams"] = opParams
        dict["operatorIsOn"] = operatorIsOn
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
        dict["arpeggiatorMode"] = arpeggiator.mode.rawValue
        dict["arpeggiatorRate"] = arpeggiator.rate
        dict["arpeggiatorGate"] = arpeggiator.gate
        dict["arpeggiatorOctaveRange"] = arpeggiator.octaveRange
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
            let data = try JSONSerialization.data(
                withJSONObject: dict,
                options: .prettyPrinted
            )
            try? FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url, options: .atomic)
        } catch {
            print("Failed to save settings: \(error)")
        }
    }

    func loadSettings() {
        guard let url = settingsFileURL,
              FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return
            }
            if let v = dict["volume"] as? Float { volume = v }
            if let v = dict["transpose"] as? Float { transpose = v }
            if let v = dict["algorithmIndex"] as? Int { algorithmIndex = v }
            if let v = dict["feedbackLevel"] as? Float { feedbackLevel = v }
            if let v = dict["oscillatorSync"] as? Bool { oscillatorSync = v }
            if let v = dict["lfoRate"] as? Float { lfoRate = v }
            if let v = dict["lfoWave"] as? Int {
                lfoWave = LFOWave(rawValue: v) ?? .sine
            }
            if let v = dict["pitchBendRange"] as? Float { pitchBendRange = v }
            if let v = dict["pitchBendValue"] as? Float { pitchBendValue = v }
            if let opParams = dict["operatorParams"] as? [[Float]] {
                for (index, params) in opParams
                    .enumerated() where index < 6 && params.count == 7 {
                    operatorParams[index] = (
                        params[0],
                        params[1],
                        params[2],
                        params[3],
                        params[4],
                        params[5],
                        params[6]
                    )
                }
            }
            if let opIsOn = dict["operatorIsOn"] as? [Bool] {
                for (index, isOn) in opIsOn.enumerated() where index < 6 {
                    operatorIsOn[index] = isOn
                }
            }
            if let v = dict["effectFilterEnabled"] as? Bool {
                effectFilterEnabled = v
            }
            if let v = dict["effectFilterAmount"] as? Float {
                effectFilterAmount = v
            }
            if let v = dict["effectFilterCutoff"] as? Float {
                effectFilterCutoff = v
            }
            if let v = dict["effectFilterResonance"] as? Float {
                effectFilterResonance = v
            }
            if let v = dict["effectDistortionEnabled"] as? Bool {
                effectDistortionEnabled = v
            }
            if let v = dict["effectDistortionAmount"] as? Float {
                effectDistortionAmount = v
            }
            if let v = dict["effectChorusEnabled"] as? Bool {
                effectChorusEnabled = v
            }
            if let v = dict["effectChorusAmount"] as? Float {
                effectChorusAmount = v
            }
            if let v = dict["effectDelayEnabled"] as? Bool {
                effectDelayEnabled = v
            }
            if let v = dict["effectDelayAmount"] as? Float {
                effectDelayAmount = v
            }
            if let v = dict["effectReverbEnabled"] as? Bool {
                effectReverbEnabled = v
            }
            if let v = dict["effectReverbAmount"] as? Float {
                effectReverbAmount = v
            }
            if let v = dict["effectPhaserEnabled"] as? Bool {
                effectPhaserEnabled = v
            }
            if let v = dict["effectPhaserAmount"] as? Float {
                effectPhaserAmount = v
            }
            let wasRunning = isRunning
            if wasRunning { audioEngine.stop() }
            effects.rebuildChain()
            if wasRunning {
                do { try audioEngine.start() } catch {
                    print("Failed to restart audio engine after loadSettings: \(error)")
                }
            }
            if let v = dict["arpeggiatorMode"] as? Int {
                arpeggiator.mode = ArpMode(rawValue: v) ?? .up
            }
            if let v = dict["arpeggiatorRate"] as? Float {
                arpeggiator.rate = v
            }
            if let v = dict["arpeggiatorGate"] as? Float {
                arpeggiator.gate = v
            }
            if let v = dict["arpeggiatorOctaveRange"] as? Int {
                arpeggiator.octaveRange = v
            }
            if let v = dict["sequencerTempo"] as? Float { sequencer.tempo = v }
            if let seqSteps = dict["sequencerSteps"] as? [[String: Any]] {
                for (index, stepDict) in seqSteps
                    .enumerated() where index < Sequencer.stepCount {
                    var step = sequencer.steps[index]
                    if let isOn = stepDict["isOn"] as? Bool { step.isOn = isOn }
                    if let note = stepDict["note"] as? Int {
                        step.note = UInt8(note)
                    }
                    if let velocity = stepDict["velocity"] as? Float {
                        step.velocity = velocity
                    }
                    if let gate = stepDict["gate"] as? Float {
                        step.gate = gate
                    }
                    sequencer.steps[index] = step
                }
            }
        } catch {
            print("Failed to load settings: \(error)")
        }
    }
}
