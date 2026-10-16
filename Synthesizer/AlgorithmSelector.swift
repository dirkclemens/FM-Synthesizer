//
// AlgorithmSelector.swift
// Synthesizer
//
// Picker for selecting one of the 32 FM algorithms.
//

import SwiftUI

struct AlgorithmSelector: View {
 @Binding var algorithmIndex: Int

 var body: some View {
 VStack(alignment: .leading, spacing: 6) {
 Text("Algorithm")
 .font(.caption)
 .foregroundColor(.secondary)

 Picker("Algorithm", selection: $algorithmIndex) {
 ForEach(0..<fmAlgorithms.count, id: \.self) { index in
 Text("\(index + 1): \(fmAlgorithms[index].name)")
 .font(.caption)
 .tag(index)
 }
 }
 .pickerStyle(.menu)
 .frame(maxWidth: .infinity)
 }
 .padding(.horizontal, 8)
 }
}

struct AlgorithmSelector_Previews: PreviewProvider {
 static var previews: some View {
 AlgorithmSelector(algorithmIndex: .constant(0))
 .padding()
 }
}
