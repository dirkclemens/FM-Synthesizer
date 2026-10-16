//
// OperatorMatrixView.swift
// Synthesizer
//
// Visualizes the selected FM algorithm as a 6×6 operator routing matrix.
// Dots show modulation connections; carriers are highlighted.
//

import SwiftUI

struct OperatorMatrixView: View {
 let algorithm: FMAlgorithm
 let carrierColor = Color.blue
 let modulatorColor = Color.green
 let connectionColor = Color.orange

 var body: some View {
 VStack(alignment: .leading, spacing: 8) {
 Text("Operator Matrix")
 .font(.headline)
 .foregroundColor(.secondary)

 // Column header (operators 1-6)
 HStack(spacing: 0) {
 Text("")
 .frame(width: 24)
 ForEach(0..<6) { col in
 Text("\(col + 1)")
 .font(.caption2)
 .foregroundColor(.secondary)
 .frame(width: 24, alignment: .center)
 }
 }

 // Matrix grid
 VStack(spacing: 0) {
 ForEach(0..<6) { row in
 HStack(spacing: 0) {
 // Row label
 Text("\(row + 1)")
 .font(.caption2)
 .foregroundColor(.secondary)
 .frame(width: 24, alignment: .trailing)

 ForEach(0..<6) { col in
 MatrixCell(
 row: row,
 col: col,
 algorithm: algorithm,
 carrierColor: carrierColor,
 modulatorColor: modulatorColor,
 connectionColor: connectionColor
 )
 .frame(width: 24, height: 24)
 }
 }
 }
 }
 .border(Color.gray.opacity(0.3), width: 1)

 // Legend
 HStack(spacing: 12) {
 LegendDot(color: carrierColor, label: "Carrier")
 LegendDot(color: modulatorColor, label: "Modulator")
 LegendDot(color: connectionColor, label: "Modulation")
 }
 .font(.caption2)
 }
 .padding(8)
 .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
 .cornerRadius(6)
 }
}

/// A single cell in the operator matrix.
struct MatrixCell: View {
 let row: Int
 let col: Int
 let algorithm: FMAlgorithm
 let carrierColor: Color
 let modulatorColor: Color
 let connectionColor: Color

 var body: some View {
 let isCarrier = algorithm.carriers.contains(row)
 let isModulator = algorithm.modulations.contains { $0.source == row }
 let hasConnection = algorithm.modulations.contains { $0.source == row && $0.target == col }
 let hasFeedback = algorithm.feedbackOperator == row && row == col

 Circle()
 .fill(cellFillColor(isCarrier: isCarrier, isModulator: isModulator))
 .opacity(hasConnection || hasFeedback || isCarrier ? 1.0 : 0.15)
 .overlay(
 Group {
 if hasConnection || hasFeedback {
 Circle()
 .stroke(connectionColor, lineWidth: 1.5)
 }
 }
 )
 }

 private func cellFillColor(isCarrier: Bool, isModulator: Bool) -> Color {
 if isCarrier && isModulator {
 return Color.purple
 } else if isCarrier {
 return carrierColor
 } else if isModulator {
 return modulatorColor
 } else {
 return Color.clear
 }
 }
}

struct LegendDot: View {
 let color: Color
 let label: String

 var body: some View {
 HStack(spacing: 4) {
 Circle().fill(color).frame(width: 6, height: 6)
 Text(label)
 }
 }
}

struct OperatorMatrixView_Previews: PreviewProvider {
 static var previews: some View {
 OperatorMatrixView(algorithm: fmAlgorithms[0])
 .padding()
 }
}
