//
// SequencerView.swift
// Synthesizer
//
// UI controls for the 16-step sequencer.
//

import SwiftUI

struct SequencerView: View {
 @ObservedObject var sequencer: Sequencer
 
 let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 16)
 
 var body: some View {
 VStack(alignment: .leading, spacing: 0) {
 // Header
 HStack {
 ZStack {
 Circle()
 .fill(Color.orange.opacity(0.2))
 .frame(width: 24, height: 24)
 Circle()
 .stroke(Color.orange, lineWidth: 2)
 .frame(width: 24, height: 24)
 Text("S")
 .font(.system(size: 10, weight: .bold, design: .monospaced))
 .foregroundColor(.orange)
 }
 Text("Sequencer")
 .font(.headline)
 .foregroundColor(.primary)
 Spacer()
 Text(sequencer.isRunning ? "ON" : "OFF")
 .font(.caption2)
 .fontWeight(.bold)
 .foregroundColor(sequencer.isRunning ? .orange : .secondary)
 }
 .padding(.horizontal, 10)
 .padding(.top, 10)
 .background(
 RoundedRectangle(cornerRadius: 8)
 .fill(Color.white.opacity(0.05))
 )
 .overlay(
 RoundedRectangle(cornerRadius: 8)
 .stroke(Color.orange.opacity(0.3), lineWidth: 1)
 )

 VStack(alignment: .leading, spacing: 12) {
 // On/Off toggle
 HStack {
 Toggle("Sequencer", isOn: Binding(
 get: { sequencer.isRunning },
 set: { newValue in
 if newValue {
 sequencer.start()
 } else {
 sequencer.stop()
 }
 }
 ))
 .font(.caption)
 Spacer()
 }

 // Step grid
 LazyVGrid(columns: columns, spacing: 2) {
 ForEach(0..<Sequencer.stepCount, id: \.self) { index in
 StepButton(
 index: index,
 isOn: sequencer.steps[index].isOn,
 isActive: sequencer.currentStep == index && sequencer.isRunning,
 onToggle: {
 sequencer.toggleStep(index)
 }
 )
 }
 }
 .frame(maxHeight: 60)
 
 // Tempo
 LabeledSlider(
 title: "Tempo",
 value: Binding(
 get: { sequencer.tempo },
 set: { sequencer.tempo = $0 }
 ),
 range: 30...300,
 step: 1,
 unit: " BPM",
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
 .stroke(Color.orange.opacity(0.4), lineWidth: 1.5)
 )
 .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
 }
}

/// A single step button in the sequencer grid.
struct StepButton: View {
 let index: Int
 let isOn: Bool
 let isActive: Bool
 var onToggle: () -> Void
 
 var body: some View {
 Button(action: onToggle) {
 RoundedRectangle(cornerRadius: 2)
 .fill(stepColor)
 .overlay(
 RoundedRectangle(cornerRadius: 2)
 .stroke(isActive ? Color.blue : Color.clear, lineWidth: 2)
 )
 }
 .buttonStyle(.plain)
 .help("Step \(index + 1)")
 }
 
 private var stepColor: Color {
 if isActive {
 return .blue
 } else if isOn {
 return .green
 } else {
 return Color(NSColor.controlBackgroundColor).opacity(0.5)
 }
 }
}

struct SequencerView_Previews: PreviewProvider {
 static var previews: some View {
 SequencerView(sequencer: Sequencer())
 .padding()
 }
}
