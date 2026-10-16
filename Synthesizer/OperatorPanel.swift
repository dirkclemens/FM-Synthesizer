//
// OperatorPanel.swift
// Synthesizer
//
// Per-operator controls: on/off, ratio, detune, level, ADSR.
// Binds to SynthEngine.operatorParams.
//

import SwiftUI

struct OperatorPanel: View {
 let operatorIndex: Int
 @ObservedObject var engine: SynthEngine

 var body: some View {
 let params = engine.operatorParams[safe: operatorIndex] ??
 (1.0, 0, 1.0, 0.1, 0.1, 0.5, 0.5)

 VStack(alignment: .leading, spacing: 8) {
 Text("Operator \(operatorIndex + 1)")
 .font(.headline)
 .foregroundColor(.secondary)
 .frame(maxWidth: .infinity, alignment: .leading)

 // Ratio
 LabeledSlider(
 title: "Ratio",
 value: Binding(
 get: { params.0 },
 set: { newValue in updateOperatorParam(index: 0, value: newValue) }
 ),
 range: 0.5...8.0,
 step: 0.5,
 unit: "",
 formatter: { String(format: "%.1f", $0) }
 )

 // Detune
 LabeledSlider(
 title: "Detune",
 value: Binding(
 get: { params.1 },
 set: { newValue in updateOperatorParam(index: 1, value: newValue) }
 ),
 range: -100...100,
 step: 1,
 unit: " ct",
 formatter: { String(format: "%.0f", $0) }
 )

 // Level
 Knob(
 title: "Level",
 value: Binding(
 get: { params.2 },
 set: { newValue in updateOperatorParam(index: 2, value: newValue) }
 ),
 range: 0...1,
 step: 0.01,
 formatter: { String(format: "%.2f", $0) }
 )

 // ADSR
 HStack(spacing: 12) {
 LabeledSlider(
 title: "A",
 value: Binding(
 get: { params.3 },
 set: { newValue in updateOperatorParam(index: 3, value: newValue) }
 ),
 range: 0...2,
 step: 0.01,
 unit: " s",
 formatter: { String(format: "%.2f", $0) }
 )
 .frame(maxWidth: .infinity)

 LabeledSlider(
 title: "D",
 value: Binding(
 get: { params.4 },
 set: { newValue in updateOperatorParam(index: 4, value: newValue) }
 ),
 range: 0...2,
 step: 0.01,
 unit: " s",
 formatter: { String(format: "%.2f", $0) }
 )
 .frame(maxWidth: .infinity)

 LabeledSlider(
 title: "S",
 value: Binding(
 get: { params.5 },
 set: { newValue in updateOperatorParam(index: 5, value: newValue) }
 ),
 range: 0...1,
 step: 0.01,
 unit: "",
 formatter: { String(format: "%.2f", $0) }
 )
 .frame(maxWidth: .infinity)

 LabeledSlider(
 title: "R",
 value: Binding(
 get: { params.6 },
 set: { newValue in updateOperatorParam(index: 6, value: newValue) }
 ),
 range: 0...5,
 step: 0.01,
 unit: " s",
 formatter: { String(format: "%.2f", $0) }
 )
 .frame(maxWidth: .infinity)
 }
 }
 .padding(10)
 .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
 .cornerRadius(6)
 }

 private func updateOperatorParam(index: Int, value: Float) {
 guard operatorIndex < engine.operatorParams.count else { return }
 var current = engine.operatorParams[operatorIndex]
 switch index {
 case 0: current.0 = value // ratio
 case 1: current.1 = value // detune
 case 2: current.2 = value // level
 case 3: current.3 = value // attack
 case 4: current.4 = value // decay
 case 5: current.5 = value // sustain
 case 6: current.6 = value // release
 default: break
 }
 engine.operatorParams[operatorIndex] = current
 }
}

/// Safe array subscript.
extension Collection {
 subscript(safe index: Index) -> Element? {
 return indices.contains(index) ? self[index] : nil
 }
}

struct OperatorPanel_Previews: PreviewProvider {
 static var previews: some View {
 OperatorPanel(operatorIndex: 0, engine: SynthEngine())
 .padding()
 }
}
