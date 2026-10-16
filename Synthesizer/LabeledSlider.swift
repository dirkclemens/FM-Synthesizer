//
// LabeledSlider.swift
// Synthesizer
//
// A horizontal slider with a label and numeric value readout.
//

import SwiftUI

struct LabeledSlider: View {
 let title: String
 @Binding var value: Float
 let range: ClosedRange<Float>
 let step: Float
 let unit: String
 let formatter: (Float) -> String

 var body: some View {
 VStack(alignment: .leading, spacing: 4) {
 HStack {
 Text(title)
 .font(.caption)
 .foregroundColor(.secondary)
 Spacer()
 Text(formatter(value) + unit)
 .font(.system(size: 11, design: .monospaced))
 .foregroundColor(.primary)
 .frame(width: 45, alignment: .trailing)
 }

 Slider(value: $value, in: range, step: step)
 .accentColor(.blue)
 }
 .padding(.horizontal, 8)
 }
}

struct LabeledSlider_Previews: PreviewProvider {
 static var previews: some View {
 VStack {
 LabeledSlider(
 title: "Attack",
 value: .constant(0.1),
 range: 0...2,
 step: 0.01,
 unit: " s",
 formatter: { String(format: "%.2f", $0) }
 )
 LabeledSlider(
 title: "Level",
 value: .constant(0.8),
 range: 0...1,
 step: 0.01,
 unit: "",
 formatter: { String(format: "%.2f", $0) }
 )
 }
 .padding()
 }
}
