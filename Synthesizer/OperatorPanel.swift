//
// OperatorPanel.swift
// Synthesizer
//
// Per-operator controls: on/off, ratio, detune, level, ADSR.
// Binds to SynthEngine.operatorParams.
//
//
import SwiftUI

struct OperatorPanel: View {
 let operatorIndex: Int
 @ObservedObject var engine: SynthEngine

 var body: some View {
 let params = engine.operatorParams[safe: operatorIndex] ??
 (1.0, 0, 1.0, 0.1, 0.1, 0.5, 0.5)

 BaseModuleView(
 title: "Operator \(operatorIndex + 1)",
 icon: "O\(operatorIndex + 1)",
 color: operatorColor
 ) {
 VStack(alignment: .leading, spacing: 8) {
 
 HStack(spacing: 12) {
 // Ratio
 Knob(
 title: "Ratio",
 value: Binding(
 get: { params.0 },
 set: { newValue in updateOperatorParam(index: 0, value: newValue) }
 ),
 range: 0.5...8.0,
 step: 0.5,
 formatter: { String(format: "%.1f", $0) }
 )
 .frame(maxWidth: .infinity)

// Spacer()
 
 // Detune
 Knob(
 title: "Detune",
 value: Binding(
 get: { params.1 },
 set: { newValue in updateOperatorParam(index: 1, value: newValue) }
 ),
 range: -100...100,
 step: 1,
 formatter: { String(format: "%.0f", $0) }
 )
 .frame(maxWidth: .infinity)

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
 .frame(maxWidth: .infinity)
 }
 
 // ADSR
 HStack(spacing: 12) {
 Knob(
 title: "Attack",
 value: Binding(
 get: { params.3 },
 set: { newValue in updateOperatorParam(index: 3, value: newValue) }
 ),
 range: 0...2,
 step: 0.01,
 formatter: { String(format: "%.2f", $0) }
 )
 .frame(maxWidth: .infinity)

 Knob(
 title: "Decay",
 value: Binding(
 get: { params.4 },
 set: { newValue in updateOperatorParam(index: 4, value: newValue) }
 ),
 range: 0...2,
 step: 0.01,
 formatter: { String(format: "%.2f", $0) }
 )
 .frame(maxWidth: .infinity)

 Knob(
 title: "Sustain",
 value: Binding(
 get: { params.5 },
 set: { newValue in updateOperatorParam(index: 5, value: newValue) }
 ),
 range: 0...1,
 step: 0.01,
 formatter: { String(format: "%.2f", $0) }
 )
 .frame(maxWidth: .infinity)

 Knob(
 title: "Release",
 value: Binding(
 get: { params.6 },
 set: { newValue in updateOperatorParam(index: 6, value: newValue) }
 ),
 range: 0...5,
 step: 0.01,
 formatter: { String(format: "%.2f", $0) }
 )
 .frame(maxWidth: .infinity)
 }
 }
 }
 }

 private var operatorColor: Color {
 let colors: [Color] = [.cyan, .purple, .indigo, .blue, .green, .orange]
 return colors[operatorIndex % colors.count]
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
