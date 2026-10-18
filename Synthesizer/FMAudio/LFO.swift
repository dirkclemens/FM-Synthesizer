//
// LFO.swift
// Synthesizer
//
// Multi-wave Low-Frequency Oscillator for modulation (vibrato, tremolo).
// Runs at audio rate; produces values in the range -1...1.
//

import Foundation

/// Available LFO waveforms.
enum LFOWave: Int, CaseIterable, Codable {
  case sine
  case triangle
  case square
  case saw
  case random // sample-and-hold
}

/// Low-frequency oscillator that generates modulation values at audio rate.
final class LFO {
 
  /// Modulation rate in Hz.
  var rate: Float = 5.0
 
  /// Waveform shape.
  var wave: LFOWave = .sine
 
  /// Current phase in radians (0 ..< 2*pi).
  private(set) var phase: Float = 0
 
  /// The sample rate.
  private let sampleRate: Double
 
  /// For sample-and-hold (random) mode: last held value.
  private var lastRandomValue: Float = 0
 
  /// For sample-and-hold: counter to determine when to pick a new value.
  private var randomCounter: Float = 0
 
  init(sampleRate: Double) {
  self.sampleRate = sampleRate
  }
 
  /// Advances the LFO by one sample and returns the modulation value (-1...1).
  @inline(__always)
  func nextSample() -> Float {
  phase += 2.0 * Float.pi * rate / Float(sampleRate)
  if phase >= 2.0 * Float.pi {
  phase -= 2.0 * Float.pi
  } else if phase < 0 {
  phase += 2.0 * Float.pi
  }
 
  switch wave {
  case .sine:
  return sin(phase)
 
  case .triangle:
  return triangleWave(phase)
 
  case .square:
  return phase < Float.pi ? 1.0 : -1.0
 
  case .saw:
  return 2.0 * (phase / (2.0 * Float.pi)) - 1.0
 
  case .random:
  // Sample-and-hold: pick a new random value at a fraction of the rate.
  randomCounter += 1.0
  let holdInterval = Float(sampleRate) / (rate * 8.0) // change ~8x per cycle
  if randomCounter >= holdInterval {
  lastRandomValue = Float.random(in: -1.0...1.0)
  randomCounter = 0
  }
  return lastRandomValue
  }
  }
 
  /// Triangle wave from phase (0..<2π).
  private func triangleWave(_ phase: Float) -> Float {
  let x = phase / Float.pi // 0 to 2
  if x < 1.0 {
  return 2.0 * x - 1.0 // -1 to 1 (rising)
  } else {
  return 2.0 * (2.0 - x) - 1.0 // 1 to -1 (falling)
  }
  }
 
  /// Resets phase to zero.
  func reset() {
  phase = 0
  randomCounter = 0
  lastRandomValue = 0
  }
}
