//
//  AlgorithmMatrixView.swift
//  Synthesizer
//
//  Combined algorithm selector + operator matrix visualization.
//  Shows the selected FM algorithm as a 6×6 operator routing matrix
//  with a dropdown to change algorithms.
//

import SwiftUI

struct AlgorithmMatrixView: View {
    @Binding var algorithmIndex: Int
    
    var body: some View {
        BaseModuleView(
            title: "Algorithm \(algorithmIndex + 1)",
            icon: "FM",
            color: .blue,
            minHeight: 320
        ) {
            VStack(alignment: .leading, spacing: 12) {
                // Algorithm picker
                Picker("Algorithm", selection: $algorithmIndex) {
                    ForEach(0..<fmAlgorithms.count, id: \.self) { index in
                        Text("\(index + 1): \(fmAlgorithms[index].name)")
                            .font(.caption)
                            .tag(index)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
                
                // Operator matrix
                VStack(alignment: .leading, spacing: 6) {
                    Text("Operator Matrix")
                        .font(.caption2)
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
                                        algorithm: fmAlgorithms[algorithmIndex]
                                    )
                                    .frame(width: 24, height: 24)
                                }
                            }
                        }
                    }
                    .border(Color.gray.opacity(0.3), width: 1)
                    
                    // Legend
                    HStack(spacing: 12) {
                        LegendDot(color: .blue, label: "Carrier")
                        LegendDot(color: .green, label: "Modulator")
                        LegendDot(color: .orange, label: "Modulation")
                    }
                    .font(.caption2)
                }
            }
        }
    }
    
    /// A single cell in the operator matrix.
    struct MatrixCell: View {
        let row: Int
        let col: Int
        let algorithm: FMAlgorithm
        
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
                                .stroke(Color.orange, lineWidth: 1.5)
                        }
                    }
                )
        }
        
        private func cellFillColor(isCarrier: Bool, isModulator: Bool) -> Color {
            if isCarrier && isModulator {
                return Color.purple
            } else if isCarrier {
                return Color.blue
            } else if isModulator {
                return Color.green
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
}

struct AlgorithmMatrixView_Previews: PreviewProvider {
    static var previews: some View {
        AlgorithmMatrixView(algorithmIndex: .constant(0))
            .padding()
    }
}
