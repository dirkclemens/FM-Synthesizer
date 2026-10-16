//
// Preset.swift
// Synthesizer
//
// Codable preset data model for the FM synthesizer.
// Captures all engine parameters needed to restore a patch.
//

import Foundation

/// Parameters for a single FM operator.
struct OperatorPreset: Codable, Equatable {
 var isOn: Bool = true
 var ratio: Float = 1.0
 var detune: Float = 0
 var level: Float = 1.0
 var attack: Float = 0.1
 var decay: Float = 0.1
 var sustain: Float = 0.5
 var release: Float = 0.5
 var keyScaling: Float = 0.0
 var velocitySensitivity: Float = 1.0
 var lfoPitchDepth: Float = 0.0
 var lfoAmpDepth: Float = 0.0
}

/// A complete FM synthesizer preset.
struct Preset: Codable, Equatable {
 var name: String
 var algorithm: Int = 0
 var transpose: Float = 0
 var feedbackLevel: Float = 0.5
 var oscillatorSync: Bool = false
 var lfoRate: Float = 5.0
 var lfoWave: Int = 0 // LFOWave.rawValue
 var operators: [OperatorPreset] = Array(repeating: OperatorPreset(), count: 6)

 init(name: String) {
 self.name = name
 }

 init(
 name: String,
 algorithm: Int = 0,
 transpose: Float = 0,
 feedbackLevel: Float = 0.5,
 oscillatorSync: Bool = false,
 lfoRate: Float = 5.0,
 lfoWave: Int = 0,
 operators: [OperatorPreset] = Array(repeating: OperatorPreset(), count: 6)
 ) {
 self.name = name
 self.algorithm = algorithm
 self.transpose = transpose
 self.feedbackLevel = feedbackLevel
 self.oscillatorSync = oscillatorSync
 self.lfoRate = lfoRate
 self.lfoWave = lfoWave
 self.operators = operators
 }
}

// MARK: - Factory presets

extension Preset {
 /// A curated set of factory presets demonstrating FM synthesis.
 static var factory: [Preset] = [
 Preset(name: "FM Bass", algorithm: 0, feedbackLevel: 0.7, operators: [
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 0.0, attack: 0.01, decay: 0.1, sustain: 0.0, release: 0.2), // op 1 - modulator
 OperatorPreset(isOn: true, ratio: 2.0, detune: 0, level: 0.0, attack: 0.01, decay: 0.1, sustain: 0.0, release: 0.2), // op 2 - modulator
 OperatorPreset(isOn: true, ratio: 3.0, detune: 0, level: 0.0, attack: 0.01, decay: 0.1, sustain: 0.0, release: 0.2), // op 3 - modulator
 OperatorPreset(isOn: true, ratio: 4.0, detune: 0, level: 0.0, attack: 0.01, decay: 0.1, sustain: 0.0, release: 0.2), // op 4 - modulator
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 1.0, attack: 0.01, decay: 0.2, sustain: 0.3, release: 0.3), // op 5 - modulator
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 1.0, attack: 0.01, decay: 0.2, sustain: 0.4, release: 0.4), // op 6 - carrier
 ]),

 Preset(name: "Electric Piano", algorithm: 23, feedbackLevel: 0.0, operators: [
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 1.0, attack: 0.01, decay: 0.3, sustain: 0.6, release: 0.5),
 OperatorPreset(isOn: true, ratio: 2.0, detune: 0, level: 0.6, attack: 0.01, decay: 0.2, sustain: 0.4, release: 0.4),
 OperatorPreset(isOn: true, ratio: 3.0, detune: 0, level: 0.4, attack: 0.01, decay: 0.15, sustain: 0.3, release: 0.3),
 OperatorPreset(isOn: true, ratio: 4.0, detune: 0, level: 0.3, attack: 0.01, decay: 0.1, sustain: 0.2, release: 0.2),
 OperatorPreset(isOn: true, ratio: 1.0, detune: 7, level: 0.2, attack: 0.01, decay: 0.1, sustain: 0.1, release: 0.1),
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 1.0, attack: 0.01, decay: 0.4, sustain: 0.7, release: 0.6),
 ]),

 Preset(name: "Brass", algorithm: 0, feedbackLevel: 0.4, operators: [
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 0.0, attack: 0.1, decay: 0.2, sustain: 0.0, release: 0.3),
 OperatorPreset(isOn: true, ratio: 2.0, detune: 0, level: 0.0, attack: 0.1, decay: 0.2, sustain: 0.0, release: 0.3),
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 0.0, attack: 0.1, decay: 0.2, sustain: 0.0, release: 0.3),
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 0.8, attack: 0.1, decay: 0.3, sustain: 0.6, release: 0.4),
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 0.6, attack: 0.1, decay: 0.3, sustain: 0.5, release: 0.4),
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 1.0, attack: 0.1, decay: 0.3, sustain: 0.8, release: 0.5),
 ]),

 Preset(name: "Warm Pad", algorithm: 31, feedbackLevel: 0.2, operators: [
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 0.0, attack: 1.0, decay: 1.0, sustain: 0.0, release: 2.0),
 OperatorPreset(isOn: true, ratio: 1.5, detune: 0, level: 0.0, attack: 1.0, decay: 1.0, sustain: 0.0, release: 2.0),
 OperatorPreset(isOn: true, ratio: 2.0, detune: 0, level: 0.0, attack: 1.0, decay: 1.0, sustain: 0.0, release: 2.0),
 OperatorPreset(isOn: true, ratio: 3.0, detune: 0, level: 0.0, attack: 1.0, decay: 1.0, sustain: 0.0, release: 2.0),
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 0.5, attack: 1.0, decay: 1.0, sustain: 0.6, release: 2.0),
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 0.8, attack: 1.0, decay: 1.0, sustain: 0.8, release: 2.0),
 ]),

 Preset(name: "Digital Bell", algorithm: 15, feedbackLevel: 0.0, operators: [
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 1.0, attack: 0.001, decay: 0.2, sustain: 0.1, release: 1.0),
 OperatorPreset(isOn: true, ratio: 2.0, detune: 0, level: 0.7, attack: 0.001, decay: 0.15, sustain: 0.0, release: 0.8),
 OperatorPreset(isOn: true, ratio: 3.0, detune: 0, level: 0.5, attack: 0.001, decay: 0.1, sustain: 0.0, release: 0.6),
 OperatorPreset(isOn: true, ratio: 5.0, detune: 0, level: 0.3, attack: 0.001, decay: 0.08, sustain: 0.0, release: 0.4),
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 0.0, attack: 0.001, decay: 0.05, sustain: 0.0, release: 0.2),
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 1.0, attack: 0.001, decay: 0.3, sustain: 0.2, release: 1.5),
 ]),

 Preset(name: "Organ", algorithm: 23, feedbackLevel: 0.0, operators: [
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 1.0, attack: 0.01, decay: 0.1, sustain: 1.0, release: 0.1),
 OperatorPreset(isOn: true, ratio: 2.0, detune: 0, level: 0.6, attack: 0.01, decay: 0.1, sustain: 1.0, release: 0.1),
 OperatorPreset(isOn: true, ratio: 3.0, detune: 0, level: 0.4, attack: 0.01, decay: 0.1, sustain: 1.0, release: 0.1),
 OperatorPreset(isOn: true, ratio: 4.0, detune: 0, level: 0.3, attack: 0.01, decay: 0.1, sustain: 1.0, release: 0.1),
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 0.0, attack: 0.01, decay: 0.1, sustain: 0.0, release: 0.1),
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 0.0, attack: 0.01, decay: 0.1, sustain: 0.0, release: 0.1),
 ]),

 Preset(name: "Synth Lead", algorithm: 1, feedbackLevel: 0.8, operators: [
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 0.0, attack: 0.1, decay: 0.2, sustain: 0.0, release: 0.3),
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 0.0, attack: 0.1, decay: 0.2, sustain: 0.0, release: 0.3),
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 0.0, attack: 0.1, decay: 0.2, sustain: 0.0, release: 0.3),
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 0.0, attack: 0.1, decay: 0.2, sustain: 0.0, release: 0.3),
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 0.0, attack: 0.1, decay: 0.2, sustain: 0.0, release: 0.3),
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 1.0, attack: 0.1, decay: 0.2, sustain: 1.0, release: 0.3),
 ]),

 Preset(name: "Vibraphone", algorithm: 23, feedbackLevel: 0.0, lfoRate: 6.0, operators: [
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 1.0, attack: 0.01, decay: 0.3, sustain: 0.5, release: 1.0, lfoAmpDepth: 0.3),
 OperatorPreset(isOn: true, ratio: 2.0, detune: 0, level: 0.6, attack: 0.01, decay: 0.2, sustain: 0.4, release: 0.8),
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 0.0, attack: 0.01, decay: 0.1, sustain: 0.0, release: 0.4),
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 0.0, attack: 0.01, decay: 0.1, sustain: 0.0, release: 0.4),
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 0.0, attack: 0.01, decay: 0.1, sustain: 0.0, release: 0.4),
 OperatorPreset(isOn: true, ratio: 1.0, detune: 0, level: 1.0, attack: 0.01, decay: 0.3, sustain: 0.6, release: 1.0),
 ]),
 ]
}
