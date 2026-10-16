//
// ArpeggiatorView.swift
// Synthesizer
//
// UI controls for the arpeggiator.
//

import SwiftUI

struct ArpeggiatorView: View {
 @ObservedObject var arpeggiator: Arpeggiator
 
 var body: some View {
 VStack(alignment: .leading, spacing: 8) {
 Text("Arpeggiator")
 .font(.headline)
 .foregroundColor(.secondary)
 
 // On/Off toggle
 HStack {
 Toggle("Arpeggiator", isOn: Binding(
 get: { arpeggiator.isRunning },
 set: { newValue in
 if newValue {
 arpeggiator.start()
 } else {
 arpeggiator.stop()
 }
 }
 ))
 .font(.caption)
 Spacer()
 Text(arpeggiator.isRunning ? "ON" : "OFF")
 .font(.caption2)
 .foregroundColor(arpeggiator.isRunning ? .green : .secondary)
 }
 
 // Mode picker
 Picker("Mode", selection: $arpeggiator.mode) {
 ForEach(ArpMode.allCases, id: \.self) { mode in
 Text(modeLabel(mode)).tag(mode)
 }
 }
 .pickerStyle(.segmented)
 .frame(maxWidth: .infinity)
 
 // Rate and gate
 HStack(spacing: 16) {
 LabeledSlider(
 title: "Rate",
 value: Binding(
 get: { arpeggiator.rate },
 set: { arpeggiator.rate = $0 }
 ),
 range: 0.5...20,
 step: 0.1,
 unit: " n/s",
 formatter: { String(format: "%.1f", $0) }
 )
 .frame(maxWidth: .infinity)
 
 LabeledSlider(
 title: "Gate",
 value: Binding(
 get: { arpeggiator.gate },
 set: { arpeggiator.gate = $0 }
 ),
 range: 0.1...1.0,
 step: 0.05,
 unit: "",
 formatter: { String(format: "%.2f", $0) }
 )
 .frame(maxWidth: .infinity)
 }
 
 // Octave range
 LabeledSlider(
 title: "Octaves",
 value: Binding(
 get: { Float(arpeggiator.octaveRange) },
 set: { arpeggiator.octaveRange = Int($0) }
 ),
 range: 1...4,
 step: 1,
 unit: "",
 formatter: { String(format: "%.0f", $0) }
 )
 }
 .padding(10)
 .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
 .cornerRadius(6)
 }
 
 private func modeLabel(_ mode: ArpMode) -> String {
 switch mode {
 case .up: return "Up"
 case .down: return "Down"
 case .upDown: return "Up/Down"
 case .random: return "Random"
 case .ordered: return "Ordered"
 case .chord: return "Chord"
 case .noteRepeat: return "Repeat"
 }
 }
}

struct ArpeggiatorView_Previews: PreviewProvider {
 static var previews: some View {
 ArpeggiatorView(arpeggiator: Arpeggiator())
 .padding()
 }
}
