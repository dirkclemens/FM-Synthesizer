//
// Knob.swift
// Synthesizer
//
// A circular rotary knob control for synthesizer parameters.
// Drag vertically to change the value.
//

import SwiftUI

struct Knob: View {
 let title: String
 @Binding var value: Float
 let range: ClosedRange<Float>
 let step: Float
 let formatter: (Float) -> String

 @State private var isDragging = false
 @State private var startValue: Float = 0
 @State private var startLocation: CGPoint = .zero

 private let knobSize: CGFloat = 70

 var body: some View {
 VStack(spacing: 6) {
 Text(title)
 .font(.caption)
 .foregroundColor(.secondary)

 ZStack {
 // Background ring
 Circle()
 .stroke(Color.gray.opacity(0.3), lineWidth: 6)
 .frame(width: knobSize, height: knobSize)

 // Value ring
 Circle()
 .trim(from: 0, to: CGFloat(normalizedValue))
 .stroke(Color.blue, lineWidth: 6)
 .rotationEffect(.degrees(-90))
 .frame(width: knobSize, height: knobSize)

 // Center knob
 Circle()
 .fill(Color(NSColor.controlBackgroundColor))
 .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
 .frame(width: knobSize * 0.55, height: knobSize * 0.55)
 .overlay(
 Text(formatter(value))
 .font(.system(size: 11, design: .monospaced))
 .foregroundColor(.primary)
 )
 }
 .gesture(
 DragGesture(minimumDistance: 0)
 .onChanged { gesture in
 if !isDragging {
 isDragging = true
 startValue = value
 startLocation = gesture.location
 }
 let deltaY = startLocation.y - gesture.location.y
 let sensitivity: Float = 0.005
 let newValue = startValue + Float(deltaY) * sensitivity * (range.upperBound - range.lowerBound)
 let stepped = round(newValue / step) * step
 value = max(range.lowerBound, min(range.upperBound, stepped))
 }
 .onEnded { _ in
 isDragging = false
 }
 )
 }
 }

 private var normalizedValue: Float {
 (value - range.lowerBound) / (range.upperBound - range.lowerBound)
 }
}

struct Knob_Previews: PreviewProvider {
 static var previews: some View {
 VStack {
 Knob(title: "Level", value: .constant(0.5), range: 0...1, step: 0.01) { String(format: "%.2f", $0) }
 Knob(title: "Ratio", value: .constant(1.0), range: 0.5...8, step: 0.5) { String(format: "%.1f", $0) }
 }
 .padding()
 }
}
