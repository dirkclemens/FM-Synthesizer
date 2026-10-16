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
 VStack(alignment: .leading, spacing: 0) {
 // Header
 HStack {
 ZStack {
 Circle()
 .fill(Color.green.opacity(0.2))
 .frame(width: 24, height: 24)
 Circle()
 .stroke(Color.green, lineWidth: 2)
 .frame(width: 24, height: 24)
 Text("A")
 .font(.system(size: 10, weight: .bold, design: .monospaced))
 .foregroundColor(.green)
 }
 Text("Arpeggiator")
 .font(.headline)
 .foregroundColor(.primary)
 Spacer()
 Text(arpeggiator.isRunning ? "ON" : "OFF")
 .font(.caption2)
 .fontWeight(.bold)
 .foregroundColor(arpeggiator.isRunning ? .green : .secondary)
 }
 .padding(.horizontal, 10)
 .padding(.top, 10)
 .background(
 RoundedRectangle(cornerRadius: 8)
 .fill(Color.white.opacity(0.05))
 )
 .overlay(
 RoundedRectangle(cornerRadius: 8)
 .stroke(Color.green.opacity(0.3), lineWidth: 1)
 )

 VStack(alignment: .leading, spacing: 12) {
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
 Toggle("Arpeggiator", isOn: .constant(false))
 .opacity(0)
 Spacer()
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
 Knob(
 title: "Rate",
 value: Binding(
 get: { arpeggiator.rate },
 set: { arpeggiator.rate = $0 }
 ),
 range: 0.5...20,
 step: 0.1,
 formatter: { String(format: "%.1f", $0) }
 )
 .frame(maxWidth: .infinity)
 
 Knob(
 title: "Gate",
 value: Binding(
 get: { arpeggiator.gate },
 set: { arpeggiator.gate = $0 }
 ),
 range: 0.1...1.0,
 step: 0.05,
 formatter: { String(format: "%.2f", $0) }
 )
 .frame(maxWidth: .infinity)
 }
 
 // Octave range
 Knob(
 title: "Octaves",
 value: Binding(
 get: { Float(arpeggiator.octaveRange) },
 set: { arpeggiator.octaveRange = Int($0) }
 ),
 range: 1...4,
 step: 1,
 formatter: { String(format: "%.0f", $0) }
 )
 }
 .padding(10)
 }
 .background(
 RoundedRectangle(cornerRadius: 10)
 .fill(Color(NSColor.controlBackgroundColor).opacity(0.4))
 )
 .overlay(
 RoundedRectangle(cornerRadius: 10)
 .stroke(Color.green.opacity(0.4), lineWidth: 1.5)
 )
 .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
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
