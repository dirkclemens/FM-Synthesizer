//
// Operator.swift
// Synthesizer
//
// Single FM operator: phase-accumulating oscillator + ADSR envelope + level.
// An operator can be a carrier (output to mix) or a modulator (output
// frequency-modulates another operator).
//

import Foundation

/// ADSR envelope state.
enum EnvelopeState: Int, CaseIterable, Codable {
 case off
 case attack
 case decay
 case sustain
 case release
}

/// A single FM operator.
///
/// Each operator has its own oscillator, ADSR envelope, level, frequency mode
/// (ratio or fixed), detune, and LFO modulation depths.
final class Operator {
 
 // MARK: - Identification
 
 /// Operator index within a voice (0..<6).
 let index: Int
 
 /// Whether this operator is active (on/off).
 var isOn: Bool = true
 
 // MARK: - Frequency
 
 /// Frequency mode: ratio (relative to note frequency) or fixed (absolute Hz).
 var frequencyMode: FrequencyMode = .ratio
 
 enum FrequencyMode: Int, Codable {
 case ratio
 case fixed
 }
 
 /// Frequency ratio (used when mode is .ratio). Common values: 0.5, 1, 2, 3, 4...
 var ratio: Float = 1.0
 
 /// Fixed frequency in Hz (used when mode is .fixed).
 var fixedFreq: Float = 440.0
 
 /// Detune in cents (-100...+100).
 var detune: Float = 0.0
 
 /// Output level (0...1).
 var level: Float = 1.0
 
 // MARK: - Modulation
 
 /// How much LFO affects this operator's pitch (vibrato), 0...1.
 var lfoPitchDepth: Float = 0.0
 
 /// How much LFO affects this operator's amplitude (tremolo), 0...1.
 var lfoAmpDepth: Float = 0.0
 
 // MARK: - ADSR Envelope
 
 /// Attack time in seconds.
 var attack: Float = 0.1
 
 /// Decay time in seconds.
 var decay: Float = 0.1
 
 /// Sustain level (0...1).
 var sustain: Float = 0.5
 
 /// Release time in seconds.
 var release: Float = 0.5
 
 /// Current envelope state.
 private(set) var envelopeState: EnvelopeState = .off
 
 /// Current envelope value (0...1).
 private(set) var envelopeValue: Float = 0.0
 
 /// Time elapsed within the current envelope state (seconds).
 private var envelopeTime: Float = 0.0
 
 /// Whether the envelope is actively running (not .off).
 var isEnvelopeActive: Bool {
 envelopeState != .off
 }
 
 // MARK: - Oscillator
 
 /// The phase-accumulating sine oscillator.
 private let oscillator: PhaseOscillator
 
 /// The sample rate.
 let sampleRate: Double
 
 init(index: Int, sampleRate: Double) {
 self.index = index
 self.sampleRate = sampleRate
 self.oscillator = PhaseOscillator(sampleRate: sampleRate)
 }
 
 // MARK: - Note control
 
 /// Starts the note: resets phase and begins the attack phase.
 func noteOn(velocity: Float, noteFrequency: Float) {
 // Compute base frequency
 let baseFreq: Float
 switch frequencyMode {
 case .ratio:
 let detuneFactor = pow(2.0, detune / 1200.0)
 baseFreq = noteFrequency * ratio * detuneFactor
 case .fixed:
 baseFreq = fixedFreq
 }
 
 oscillator.frequency = baseFreq
 oscillator.resetPhase()
 
 // Velocity scales the initial level (0...127 -> 0...1)
 let velFactor = velocity / 127.0
 
 envelopeTime = 0
 envelopeState = .attack
 // Store velocity for use in envelope scaling
 _velocity = velFactor
 }
 
 /// Starts the release phase. The note will fade out over `release` seconds.
 func noteOff() {
 guard envelopeState != .off else { return }
 envelopeState = .release
 envelopeTime = 0
 }
 
 /// Forces the envelope to off immediately (for voice stealing).
 func silence() {
 envelopeState = .off
 envelopeValue = 0
 }
 
 // MARK: - Render
 
 /// Renders one sample.
 ///
 /// - Parameters:
 /// - modulationInput: Frequency modulation from other operators (added to base frequency).
 /// - lfoValue: Current LFO value (-1...1).
 /// - Returns: Sample value in range approximately -1...1.
 @inline(__always)
 func render(modulationInput: Float, lfoValue: Float = 0) -> Float {
 guard isOn else { return 0 }
 
 // Update envelope
 updateEnvelope()
 
 // Apply LFO to pitch (vibrato)
 let vibrato = lfoValue * lfoPitchDepth
 
 // Apply LFO to amplitude (tremolo)
 let tremolo = 1.0 + lfoValue * lfoAmpDepth
 
 // Effective frequency = base + FM modulation + vibrato
 let effectiveFreq = oscillator.frequency + modulationInput + vibrato
 oscillator.frequency = effectiveFreq
 
 // Generate sine sample
 let sample = oscillator.nextSample()
 
 // Apply envelope, level, and tremolo
 return sample * envelopeValue * level * tremolo
 }
 
 /// Updates the ADSR envelope state machine. Called once per sample.
 private func updateEnvelope() {
 let dt = Float(1.0 / sampleRate)
 
 switch envelopeState {
 case .off:
 envelopeValue = 0
 
 case .attack:
 envelopeTime += dt
 if attack > 0 {
 envelopeValue = min(envelopeTime / attack, 1.0) * _velocity
 } else {
 envelopeValue = _velocity
 }
 if envelopeTime >= attack {
 envelopeState = .decay
 envelopeTime = 0
 }
 
 case .decay:
 envelopeTime += dt
 if decay > 0 {
 let progress = min(envelopeTime / decay, 1.0)
 envelopeValue = _velocity * (1.0 - progress) + sustain * progress
 } else {
 envelopeValue = sustain * _velocity
 }
 if envelopeTime >= decay {
 envelopeState = .sustain
 }
 
 case .sustain:
 envelopeValue = sustain * _velocity
 
 case .release:
 envelopeTime += dt
 if release > 0 {
 let progress = min(envelopeTime / release, 1.0)
 envelopeValue = sustain * _velocity * (1.0 - progress)
 } else {
 envelopeValue = 0
 }
 if envelopeTime >= release {
 envelopeState = .off
 envelopeValue = 0
 }
 }
 }
 
 // MARK: - Private
 
 /// Velocity scaling factor (0...1), set on noteOn.
 private var _velocity: Float = 1.0
}
