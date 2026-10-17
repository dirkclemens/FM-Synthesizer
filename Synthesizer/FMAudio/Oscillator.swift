//
// Oscillator.swift
// Synthesizer
//
// Phase-accumulating sine oscillator for FM synthesis.
// Replaces the time-based oscillator from the original project.
//

import Foundation

/// Converts a MIDI note number (0–127) to frequency in Hz.
/// Standard formula: f = 440 * 2^((n - 69) / 12)
/// Equivalent to: (440 / 32) * 2^((n - 9) / 12)
public func midiNoteToFreq(midiNumber: UInt8) -> Float {
 return (440.0 / 32.0) * pow(2.0, (Float(midiNumber) - 9.0) / 12.0)
}

/// Phase-accumulating sine oscillator.
///
/// Unlike the old time-based oscillator (sin(2*pi*f*t)), this oscillator
/// accumulates phase sample-by-sample, which is essential for phase-continuous
/// FM synthesis where one oscillator's output modulates another's frequency.
final class PhaseOscillator {
 
 /// The sample rate of the audio system (Hz).
 let sampleRate: Double
 
 /// Current phase in radians (0 ..< 2*pi).
 private(set) var phase: Float = 0
 
 /// Frequency in Hz.
 var frequency: Float = 440.0 {
 didSet {
 updatePhaseIncrement()
 }
 }
 
 /// Phase increment per sample (radians).
 private var phaseIncrement: Float = 0
 
 init(sampleRate: Double) {
 self.sampleRate = sampleRate
 self.frequency = 440.0
 updatePhaseIncrement()
 }
 
 private func updatePhaseIncrement() {
 phaseIncrement = 2.0 * Float.pi * frequency / Float(sampleRate)
 }
 
 /// Generates the next sample and advances the phase.
 /// Returns a sine value in the range -1...1.
 @inline(__always)
 func nextSample() -> Float {
 let sample = sin(phase)
 phase += phaseIncrement
 if phase >= 2.0 * Float.pi {
 phase -= 2.0 * Float.pi
 } else if phase < 0 {
 phase += 2.0 * Float.pi
 }
 return sample
 }
 
 /// Resets phase to zero (useful for oscillator sync).
 func resetPhase() {
 phase = 0
 }
}

/// Applies a frequency modulation offset to an oscillator's base frequency.
/// The modulation input is added to the base frequency to produce the
/// effective frequency for the current sample.
@inline(__always)
public func modulatedFrequency(base: Float, modulationInput: Float, modulationIndex: Float) -> Float {
 return base + modulationInput * modulationIndex
}
