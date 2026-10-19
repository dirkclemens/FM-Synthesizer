//
// Voice.swift
// Synthesizer
//
// A polyphonic FM voice: 6 operators connected via an algorithm.
// Renders one block of audio samples per call.
//

import AVFoundation
import Foundation

/// Voice lifecycle state.
enum VoiceState: Int {
    case free // Not allocated, available for noteOn
    case active // Playing a note (attack/decay/sustain)
    case releasing // Note off, in release phase
}

/// A 6-operator FM voice.
///
/// Operators are rendered in index order (0..<6). Each operator's output is
/// fed to the modulation inputs of its targets according to the algorithm.
/// Carrier outputs are summed to produce the voice output.
final class Voice {
 
    // MARK: - Voice management
 
    /// The sample rate.
    let sampleRate: Double
 
    /// Current voice state.
    private(set) var state: VoiceState = .free
 
    /// MIDI note currently playing (or -1 if none).
    private(set) var midiNote: UInt8 = 0
 
    /// The 6 operators.
    let operators: [Operator]
 
    /// The LFO for this voice (vibrato/tremolo source).
    let lfo: LFO
 
    /// Whether oscillator hard-sync is enabled. When on, the carrier's phase
    /// wrap resets modulator phases.
    var oscillatorSync: Bool = false
 
    /// The algorithm used by this voice.
    private(set) var algorithm: FMAlgorithm
 
    /// Feedback amount (0…1), driven by the engine's Feedback knob.
    /// Replaces the algorithm's hardcoded feedbackLevel so the UI knob works.
    var feedbackLevel: Float = 0.5
 
    /// Feedback sample buffer: previous output of the feedback operator.
    /// Used for one-sample-delayed self-modulation.
    private var feedbackSample: Float = 0
 
    /// Whether the voice has finished releasing and is silent.
    var isSilent: Bool {
        state == 
            .free || (
                state == .releasing && operators
                    .allSatisfy { $0.envelopeState == .off
                    })
    }
 
    init(sampleRate: Double, algorithm: FMAlgorithm) {
        self.sampleRate = sampleRate
        self.algorithm = algorithm
        self.operators = (0..<6)
            .map { Operator(index: $0, sampleRate: sampleRate) }
        self.lfo = LFO(sampleRate: sampleRate)
    }
 
    // MARK: - Configuration
 
    /// Sets the algorithm used by this voice.
    /// Does not reset feedbackSample — that happens only on noteOn/silence
    /// so one-sample-delayed feedback survives across render frames.
    func setAlgorithm(_ newAlgorithm: FMAlgorithm) {
        self.algorithm = newAlgorithm
    }
 
    /// Configures all operators from a parameter set.
    /// `params` is an array of 6 tuples: (ratio, detune, level, attack, decay, sustain, release).
    func configureOperators(
        _ params: [(
            ratio: Float,
            detune: Float,
            level: Float,
            attack: Float,
            decay: Float,
            sustain: Float,
            release: Float
        )]
    ) {
        for (op, p) in zip(operators, params) {
            op.ratio = p.ratio
            op.detune = p.detune
            op.level = p.level
            op.attack = p.attack
            op.decay = p.decay
            op.sustain = p.sustain
            op.release = p.release
        }
    }

    /// Sets the on/off state of a single operator.
    func setOperatorIsOn(_ isOn: Bool, at index: Int) {
        guard index >= 0, index < operators.count else { return }
        operators[index].isOn = isOn
    }
 
    // MARK: - LFO configuration
 
    /// Updates the LFO rate, waveform, and modulation depths.
    func setLFO(
        rate: Float,
        wave: LFOWave,
        pitchDepth: Float = 0.3,
        ampDepth: Float = 0.3
    ) {
        lfo.rate = rate
        lfo.wave = wave
        for op in operators {
            op.lfoPitchDepth = pitchDepth
            op.lfoAmpDepth = ampDepth
        }
    }
 
    // MARK: - Note control
 
    /// Starts a note.
    /// - Parameters:
    /// - midiNote: MIDI note number (0–127).
    /// - velocity: Note velocity (0–127).
    /// - baseFrequency: The fundamental frequency in Hz (before ratio/detune).
    func noteOn(midiNote: UInt8, velocity: Float, baseFrequency: Float) {
        // Silence any previous note on this voice to avoid clicks when stealing voices
        silence()
 
        self.midiNote = midiNote
        self.state = .active
 
        for op in operators {
            op
                .noteOn(
                    velocity: velocity,
                    noteFrequency: baseFrequency,
                    midiNote: midiNote
                )
        }
    }
 
    /// Starts the release phase for the current note.
    func noteOff() {
        guard state == .active || state == .releasing else { return }
        state = .releasing
        for op in operators {
            op.noteOff()
        }
    }
 
    /// Immediately silences the voice (for voice stealing).
    func silence() {
        state = .free
        midiNote = 0
        feedbackSample = 0
        lfo.reset()
        for op in operators {
            op.silence()
        }
    }
 
    // MARK: - Render
 
    /// Renders a block of mono samples using the voice's own LFO.
    ///
    /// - Parameter frameCount: Number of frames to render.
    /// - Returns: Array of `frameCount` mono samples.
    func render(frameCount: Int) -> [Float] {
        var samples = [Float](repeating: 0, count: frameCount)

        guard state != .free else { return samples }

        for frame in 0..<frameCount {
            let lfoValue = lfo.nextSample()
            let frameSample = renderFrame(lfoValue: lfoValue)
            samples[frame] = frameSample

            // Check if voice has finished releasing
            if state == .releasing && isSilent {
                state = .free
                // Fill remaining frames with silence
                for remaining in (frame + 1)..<frameCount {
                    samples[remaining] = 0
                }
                break
            }
        }

        return samples
    }
 
    /// Renders a single frame (one sample per operator, summed per algorithm).
    @inline(__always)
    private func renderFrame(lfoValue: Float) -> Float {
        // Modulation inputs for each operator, accumulated from modulators.
        var modInputs = [Float](repeating: 0, count: 6)
 
        // Apply feedback from the previous frame (one-sample delay).
        if let fbOp = algorithm.feedbackOperator {
            modInputs[fbOp] += feedbackSample * feedbackLevel
        }
 
        var carrierSum: Float = 0
        var currentSamples = [Float](repeating: 0, count: 6)
 
        for opIndex in 0..<6 {
            let op = operators[opIndex]
            let sample = op.render(
                modulationInput: modInputs[opIndex],
                lfoValue: lfoValue
            )
            currentSamples[opIndex] = sample
 
            // Feed this operator's output to its modulation targets.
            for connection in algorithm.modulationsFrom(source: opIndex) {
                modInputs[connection.target] += sample * connection.index
            }
 
            // Sum carrier outputs.
            if algorithm.carriers.contains(opIndex) {
                carrierSum += sample
            }
        }
 
        // Oscillator hard-sync: if enabled and the carrier (operator 5) phase
        // wrapped this frame, reset modulator (operator 0) phase.
        if oscillatorSync, algorithm.carriers.contains(5) {
            operators[0].resetOscillatorPhase()
        }
 
        // Save feedback sample for next frame.
        if let fbOp = algorithm.feedbackOperator {
            feedbackSample = currentSamples[fbOp]
        }

        // Clamp carrier output to prevent a single voice from exceeding
        // safe levels. When multiple voices sum in the engine, unclipped
        // voices would cause digital clipping (saw-like harsh harmonics).
        return clamp(carrierSum, -0.7, 0.7)
    }

    /// Clamps a value to the given range.
    private func clamp(_ value: Float, _ min: Float, _ max: Float) -> Float {
        Swift.min(Swift.max(value, min), max)
    }
}
