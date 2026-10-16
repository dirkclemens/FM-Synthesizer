//
// GlobalPanel.swift
// Synthesizer
//
// Global synthesizer controls: volume, transpose, algorithm, LFO, feedback, sync.
//

import SwiftUI

struct GlobalPanel: View {
 @ObservedObject var engine: SynthEngine

 var body: some View {
 VStack(alignment: .leading, spacing: 10) {
 Text("Global")
 .font(.headline)
 .foregroundColor(.secondary)

 // Volume
 Knob(
 title: "Volume",
 value: $engine.volume,
 range: 0...1,
 step: 0.01,
 formatter: { String(format: "%.2f", $0) }
 )

 HStack(spacing: 16) {
 // Transpose
 LabeledSlider(
 title: "Transpose",
 value: $engine.transpose,
 range: -24...24,
 step: 1,
 unit: " st",
 formatter: { String(format: "%.0f", $0) }
 )
 .frame(maxWidth: .infinity)

 // Pitch bend range
 LabeledSlider(
 title: "Bend Range",
 value: $engine.pitchBendRange,
 range: 0...24,
 step: 1,
 unit: " st",
 formatter: { String(format: "%.0f", $0) }
 )
 .frame(maxWidth: .infinity)
 }

 HStack(spacing: 16) {
 // Algorithm selector
 AlgorithmSelector(algorithmIndex: $engine.algorithmIndex)
 .frame(maxWidth: .infinity)

 // Feedback
 Knob(
 title: "Feedback",
 value: $engine.feedbackLevel,
 range: 0...1,
 step: 0.01,
 formatter: { String(format: "%.2f", $0) }
 )
 }

 HStack(spacing: 16) {
 // LFO rate
 LabeledSlider(
 title: "LFO Rate",
 value: $engine.lfoRate,
 range: 0.01...20,
 step: 0.01,
 unit: " Hz",
 formatter: { String(format: "%.2f", $0) }
 )
 .frame(maxWidth: .infinity)

 // LFO wave
 Picker("LFO Wave", selection: $engine.lfoWave) {
 ForEach(LFOWave.allCases, id: \.self) { wave in
 Text(waveLabel(wave)).tag(wave)
 }
 }
 .pickerStyle(.segmented)
 .frame(maxWidth: .infinity)
 }

 // Oscillator sync
 HStack {
 Toggle("Oscillator Sync", isOn: $engine.oscillatorSync)
 .font(.caption)
 Spacer()
 }
 }
 .padding(10)
 .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
 .cornerRadius(6)
 }

 private func waveLabel(_ wave: LFOWave) -> String {
 switch wave {
 case .sine: return "Sine"
 case .triangle: return "Triangle"
 case .square: return "Square"
 case .saw: return "Saw"
 case .random: return "Random"
 }
 }
}

struct GlobalPanel_Previews: PreviewProvider {
 static var previews: some View {
 GlobalPanel(engine: SynthEngine())
 .padding()
 }
}
