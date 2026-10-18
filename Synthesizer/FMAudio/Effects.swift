//
// Effects.swift
// Synthesizer
//
// Effects chain for the FM synthesizer:
// Filter → Distortion → Chorus → Delay → Reverb → Phaser → Output
// Each effect can be enabled/disabled independently.
//

import AVFoundation
import Foundation

/// All available effects.
enum EffectType: Int, CaseIterable, Codable {
    case filter
    case distortion
    case chorus
    case delay
    case reverb
    case phaser
}

/// Configuration for a single effect.
struct EffectConfig: Codable, Equatable {
    var enabled: Bool = false
    var amount: Float = 0.5 // 0...1
}

/// Manages the effects chain: creates AVAudioUnit nodes, connects them,
/// and provides parameter updates.
final class EffectsChain {
 
    /// The audio engine to attach nodes to.
    private let audioEngine: AVAudioEngine
 
    /// Input node (comes from the mixer).
    private let inputNode: AVAudioNode
 
    /// Output node (goes to the output).
    private let outputNode: AVAudioNode
 
    /// Effect nodes (created lazily when first enabled).
    private var filterNode: AVAudioUnitEQ?
    private var distortionNode: AVAudioSourceNode?
    private var chorusNode: AVAudioSourceNode?
    private var delayNode: AVAudioUnitDelay?
    private var reverbNode: AVAudioUnitReverb?
    private var phaserNode: AVAudioSourceNode?
 
    /// Whether each effect is currently enabled.
    var configs: [EffectType: EffectConfig] = [:]
 
    /// The last connected node in the chain (before output).
    private var lastNode: AVAudioNode?
 
    /// Track which nodes have been created.
    private var createdNodes: Set<EffectType> = []
 
    init(
        audioEngine: AVAudioEngine,
        inputNode: AVAudioNode,
        outputNode: AVAudioNode
    ) {
        self.audioEngine = audioEngine
        self.inputNode = inputNode
        self.outputNode = outputNode
 
        // Initialize all configs as disabled.
        for type in EffectType.allCases {
            configs[type] = EffectConfig()
        }
 
        // Connect input directly to output (no effects yet).
        audioEngine.connect(inputNode, to: outputNode, format: nil)
    }
 
    // MARK: - Node creation (lazy)
 
    private func createNode(for type: EffectType) -> AVAudioNode? {
        guard !createdNodes.contains(type) else {
            return nodeFor(type)
        }
 
        let node: AVAudioNode?
 
        switch type {
        case .filter:
            let filter = AVAudioUnitEQ(numberOfBands: 4)
            filter.bands[0].filterType = .lowPass
            filter.bands[0].frequency = 5000
            filter.bands[0].gain = 0
 
            filter.bands[1].filterType = .parametric
            filter.bands[1].frequency = 1000
            filter.bands[1].gain = 0
 
            filter.bands[2].filterType = .parametric
            filter.bands[2].frequency = 3000
            filter.bands[2].gain = 0
 
            filter.bands[3].filterType = .highPass
            filter.bands[3].frequency = 100
            filter.bands[3].gain = 0
 
            filterNode = filter
            node = filter
 
        case .distortion:
            let dn = AVAudioSourceNode {
                [weak self] _,
                _,
                frameCount,
                audioBufferList -> OSStatus in
                self?.processDistortion(
                    frameCount: Int(frameCount),
                    audioBufferList: audioBufferList
                ) ?? noErr
            }
            distortionNode = dn
            node = dn
 
        case .chorus:
            let cn = AVAudioSourceNode {
                [weak self] _,
                _,
                frameCount,
                audioBufferList -> OSStatus in
                self?.processChorus(
                    frameCount: Int(frameCount),
                    audioBufferList: audioBufferList
                ) ?? noErr
            }
            chorusNode = cn
            node = cn
 
        case .delay:
            let dn = AVAudioUnitDelay()
            dn.delayTime = 0.25
            dn.feedback = 30
            dn.wetDryMix = 25
            delayNode = dn
            node = dn
 
        case .reverb:
            let rn = AVAudioUnitReverb()
            rn.loadFactoryPreset(.smallRoom)
            rn.wetDryMix = 20
            reverbNode = rn
            node = rn
 
        case .phaser:
            let pn = AVAudioSourceNode {
                [weak self] _,
                _,
                frameCount,
                audioBufferList -> OSStatus in
                self?.processPhaser(
                    frameCount: Int(frameCount),
                    audioBufferList: audioBufferList
                ) ?? noErr
            }
            phaserNode = pn
            node = pn
        }
 
        if let node = node {
            audioEngine.attach(node)
            createdNodes.insert(type)
        }
 
        return node
    }
 
    private func nodeFor(_ type: EffectType) -> AVAudioNode? {
        switch type {
        case .filter: return filterNode
        case .distortion: return distortionNode
        case .chorus: return chorusNode
        case .delay: return delayNode
        case .reverb: return reverbNode
        case .phaser: return phaserNode
        }
    }
 
    // MARK: - Chain management
 
    /// Rebuilds the effect chain based on current enabled/disabled states.
    func rebuildChain() {
        // Disconnect the output of inputNode (mainMixer) and input of outputNode.
        // The effects chain inserts between mainMixer and outputNode.
        audioEngine.disconnectNodeOutput(inputNode)
        audioEngine.disconnectNodeInput(outputNode)

        // Disconnect all created effect nodes.
        for type in createdNodes {
            if let node = nodeFor(type) {
                audioEngine.disconnectNodeInput(node)
                audioEngine.disconnectNodeOutput(node)
            }
        }

        // Build the chain: input → [enabled effects] → output
        var previousNode: AVAudioNode = inputNode

        for type in EffectType.allCases {
            guard let config = configs[type], config.enabled else { continue }

            let effectNode = createNode(for: type)
            if let effectNode = effectNode {
                audioEngine.connect(previousNode, to: effectNode, format: nil)
                previousNode = effectNode
            }
        }

        // Connect last effect to output.
        audioEngine.connect(previousNode, to: outputNode, format: nil)
        lastNode = previousNode
    }
 
    // MARK: - Parameter updates
 
    /// Enables or disables an effect and rebuilds the chain.
    /// Stops the audio engine before rebuilding the graph (AVAudioEngine requires
    /// the engine to be stopped when disconnecting/reconnecting nodes).
    func setEnabled(_ type: EffectType, enabled: Bool) {
        configs[type]?.enabled = enabled
        let wasRunning = audioEngine.isRunning
        if wasRunning { audioEngine.stop() }
        rebuildChain()
        if wasRunning {
            do { try audioEngine.start() } catch {
                print("Failed to restart audio engine after effect toggle: \(error)")
            }
        }
    }
 
    /// Sets the amount (wet/dry mix) for an effect.
    func setAmount(_ type: EffectType, amount: Float) {
        configs[type]?.amount = max(0, min(1, amount))
        updateEffectAmount(type, amount: amount)
    }
 
    private func updateEffectAmount(_ type: EffectType, amount: Float) {
        switch type {
        case .filter:
            if let filter = filterNode {
                let gain = (amount - 0.5) * 24 // -12 to +12 dB
                for band in filter.bands {
                    band.gain = gain
                }
            }
 
        case .delay:
            if let delay = delayNode {
                delay.wetDryMix = amount * 100
            }
 
        case .reverb:
            if let reverb = reverbNode {
                reverb.wetDryMix = amount * 100
            }
 
        default:
            break
        }
    }
 
    /// Filter cutoff frequency (Hz).
    func setFilterCutoff(_ cutoff: Float) {
        if let filter = filterNode {
            filter.bands[0].frequency = cutoff
            filter.bands[3].frequency = max(50, cutoff / 50)
        }
    }
 
    /// Filter resonance (Q).
    func setFilterResonance(_ resonance: Float) {
        // EQ Q parameter not directly accessible; bandwidth is fixed per band type.
        _ = resonance
    }
 
    // MARK: - Custom effect processing state
 
    /// Chorus state.
    private var chorusPhase: Float = 0
    private var chorusBuffer: [Float] = []
    private var chorusWriteIndex: Int = 0
 
    /// Phaser state.
    private var phaserFeedback: Float = 0.5
    private var phaserLFOPhase: Float = 0
    private var phaserAllPass1: Float = 0
    private var phaserAllPass2: Float = 0
 
    private func processDistortion(frameCount: Int, audioBufferList: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
        let config = configs[.distortion] ?? EffectConfig()
 
        let drive = 1.0 + config.amount * 19.0
 
        for buffer in ablPointer {
            guard let data = buffer.mData?.assumingMemoryBound(to: Float.self) else {
                continue
            }
            let buf = UnsafeMutableBufferPointer(start: data, count: frameCount)
 
            for i in 0..<frameCount {
                let sample = buf[i]
                let driven = sample * drive
                buf[i] = tanh(driven)
            }
        }
        return noErr
    }
 
    private func processChorus(frameCount: Int, audioBufferList: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
        let config = configs[.chorus] ?? EffectConfig()
 
        let maxDelay = Int(0.02 * 44100) // 20ms max delay
        if chorusBuffer.count < maxDelay {
            chorusBuffer = Array(repeating: 0, count: maxDelay)
            chorusWriteIndex = 0
        }
 
        let sampleRate: Float = 44100
        let lfoRate: Float = 1.5
        let depth: Float = config.amount * 0.005
 
        for buffer in ablPointer {
            guard let data = buffer.mData?.assumingMemoryBound(to: Float.self) else {
                continue
            }
            let buf = UnsafeMutableBufferPointer(start: data, count: frameCount)
 
            for i in 0..<frameCount {
                let input = buf[i]
                chorusBuffer[chorusWriteIndex] = input
 
                chorusPhase += 2.0 * Float.pi * lfoRate / sampleRate
                if chorusPhase >= 2.0 * Float.pi {
                    chorusPhase -= 2.0 * Float.pi
                }
 
                let lfo = sin(chorusPhase)
                let delaySamples = Int((0.5 + lfo * 0.5) * depth * sampleRate)
                let readIndex = (
                    chorusWriteIndex + chorusBuffer.count - delaySamples
                ) % chorusBuffer.count
 
                let delayed = chorusBuffer[readIndex]
                let mix = config.amount
                buf[i] = input * (1.0 - mix) + delayed * mix
 
                chorusWriteIndex = (chorusWriteIndex + 1) % chorusBuffer.count
            }
        }
        return noErr
    }
 
    private func processPhaser(frameCount: Int, audioBufferList: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
        let config = configs[.phaser] ?? EffectConfig()
 
        let sampleRate: Float = 44100
        let lfoRate: Float = 0.5
 
        for buffer in ablPointer {
            guard let data = buffer.mData?.assumingMemoryBound(to: Float.self) else {
                continue
            }
            let buf = UnsafeMutableBufferPointer(start: data, count: frameCount)
 
            for i in 0..<frameCount {
                let input = buf[i]
 
                phaserLFOPhase += 2.0 * Float.pi * lfoRate / sampleRate
                if phaserLFOPhase >= 2.0 * Float.pi {
                    phaserLFOPhase -= 2.0 * Float.pi
                }
 
                let lfo = sin(phaserLFOPhase)
                let freq = 200.0 + (lfo + 1.0) * 400.0
 
                let wc = 2.0 * Float.pi * freq / sampleRate
                let alpha = (1.0 - sin(wc)) / (1.0 + sin(wc))
 
                let ap1Input = input + phaserFeedback * phaserAllPass1
                let ap1Out = alpha * ap1Input - phaserAllPass1
                phaserAllPass1 = ap1Input
 
                let ap2Input = ap1Out + phaserFeedback * phaserAllPass2
                let ap2Out = alpha * ap2Input - phaserAllPass2
                phaserAllPass2 = ap2Input
 
                let mix = config.amount
                buf[i] = input * (1.0 - mix) + ap2Out * mix
            }
        }
        return noErr
    }
}
