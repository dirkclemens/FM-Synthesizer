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
  BaseModuleView(
  title: "Sequencer",
  icon: "S",
  color: .orange
  ) {
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
  }
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
