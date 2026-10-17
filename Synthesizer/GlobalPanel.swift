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
 VStack(alignment: .leading, spacing: 0) {
 // Header
 HStack {
 ZStack {
 Circle()
 .fill(Color.blue.opacity(0.2))
 .frame(width: 24, height: 24)
 Circle()
 .stroke(Color.blue, lineWidth: 2)
 .frame(width: 24, height: 24)
 Text("G")
 .font(.system(size: 10, weight: .bold, design: .monospaced))
 .foregroundColor(.blue)
 }
 Text("Global")
 .font(.headline)
 .foregroundColor(.primary)
 Spacer()
 }
 .padding(.horizontal, 10)
 .padding(.top, 10)
 .background(
 RoundedRectangle(cornerRadius: 8)
 .fill(Color.white.opacity(0.05))
 )
 .overlay(
 RoundedRectangle(cornerRadius: 8)
 .stroke(Color.blue.opacity(0.3), lineWidth: 1)
 )

 VStack(alignment: .leading, spacing: 12) {
 HStack(spacing: 16) {
 // Volume
 Knob(
 title: "Volume",
 value: $engine.volume,
 range: 0...1,
 step: 0.01,
 formatter: { String(format: "%.2f", $0) }
 )

 Spacer()
 
 // Transpose
 Knob(
 title: "Transpose",
 value: $engine.transpose,
 range: -24...24,
 step: 1,
 formatter: { String(format: "%.0f", $0) }
 )
 
 // Pitch bend range
 Knob(
 title: "Bend Range",
 value: $engine.pitchBendRange,
 range: 0...24,
 step: 1,
 formatter: { String(format: "%.0f", $0) }
 )
 
 }
 
 HStack(spacing: 16) {
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
 Knob(
 title: "LFO Rate",
 value: $engine.lfoRate,
 range: 0.01...20,
 step: 0.01,
 formatter: { String(format: "%.2f", $0) }
 )

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
 }
 .background(
 RoundedRectangle(cornerRadius: 10)
 .fill(Color(NSColor.controlBackgroundColor).opacity(0.4))
 )
 .overlay(
 RoundedRectangle(cornerRadius: 10)
 .stroke(Color.blue.opacity(0.4), lineWidth: 1.5)
 )
 .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
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
