//
// OscilloscopeView.swift
// Synthesizer
//
// Real-time oscilloscope visualization of the FM synthesis output.
// Shows the mixed audio waveform as it's being rendered.
//

import SwiftUI

struct OscilloscopeView: View {
 @ObservedObject var engine: SynthEngine

 private let displaySamples = 256
 @State private var refreshTick: Int = 0

 var body: some View {
 VStack(alignment: .leading, spacing: 8) {
 headerView

 OscilloscopeDisplayView(
 samples: engine.scopeSamples,
 count: min(engine.scopeSamples.count, displaySamples)
 )
 .frame(height: 140)
 .padding(8)
 .background(Color.black.opacity(0.4))
 .cornerRadius(8)
 }
 .padding(10)
 .background(
 RoundedRectangle(cornerRadius: 10)
 .fill(Color(NSColor.controlBackgroundColor).opacity(0.4))
 )
 .overlay(
 RoundedRectangle(cornerRadius: 10)
 .stroke(Color.cyan.opacity(0.4), lineWidth: 1.5)
 )
 .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
 .onReceive(Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()) { _ in
 refreshTick += 1
 }
 }

 private var headerView: some View {
 HStack {
 circleIcon
 Text("Oscilloscope")
 .font(.headline)
 .foregroundColor(.primary)
 Spacer()
 statusText
 }
 .padding(.horizontal, 10)
 .padding(.top, 10)
 .background(
 RoundedRectangle(cornerRadius: 8)
 .fill(Color.white.opacity(0.05))
 )
 .overlay(
 RoundedRectangle(cornerRadius: 8)
 .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
 )
 }

 private var circleIcon: some View {
 ZStack {
 Circle()
 .fill(Color.cyan.opacity(0.2))
 .frame(width: 24, height: 24)
 Circle()
 .stroke(Color.cyan, lineWidth: 2)
 .frame(width: 24, height: 24)
 Text("SCOPE")
 .font(.system(size: 9, weight: .bold, design: .monospaced))
 .foregroundColor(.cyan)
 }
 }

 private var statusText: some View {
 Text(engine.isRunning ? "LIVE" : "OFF")
 .font(.caption2)
 .fontWeight(.bold)
 .foregroundColor(engine.isRunning ? .green : .secondary)
 }
}

/// Draws the oscilloscope grid (horizontal lines).
struct OscilloscopeGrid: View {
 var body: some View {
 GeometryReader { geometry in
 let width = geometry.size.width
 let height = geometry.size.height
 let midY = height / 2
 let quarterY = height / 4
 let threeQuarterY = 3 * height / 4

 Path { path in
 path.move(to: CGPoint(x: 0, y: midY))
 path.addLine(to: CGPoint(x: width, y: midY))
 path.move(to: CGPoint(x: 0, y: quarterY))
 path.addLine(to: CGPoint(x: width, y: quarterY))
 path.move(to: CGPoint(x: 0, y: threeQuarterY))
 path.addLine(to: CGPoint(x: width, y: threeQuarterY))
 }
 .stroke(Color.white.opacity(0.08), lineWidth: 1)
 }
 }
}

/// Draws the waveform trace from audio samples.
struct OscilloscopeWaveformShape: Shape {
 let samples: [Float]
 let count: Int

 func path(in rect: CGRect) -> Path {
 Path { path in
 guard samples.count > 1 else { return }

 let step = rect.width / CGFloat(max(count - 1, 1))
 let midY = rect.height / 2
 let amplitude = rect.height * 0.4

 let firstSample = CGFloat(clamp(samples[0], -1, 1))
 path.move(to: CGPoint(x: 0, y: midY - firstSample * amplitude))

 for i in 1..<min(count, samples.count) {
 let x = CGFloat(i) * step
 let sample = CGFloat(clamp(samples[i], -1, 1))
 let y = midY - sample * amplitude
 path.addLine(to: CGPoint(x: x, y: y))
 }
 }
 }

 private func clamp(_ value: Float, _ min: Float, _ max: Float) -> Float {
 Swift.min(Swift.max(value, min), max)
 }
}

/// Combined display: grid + waveform + center line.
struct OscilloscopeDisplayView: View {
 let samples: [Float]
 let count: Int

 var body: some View {
 GeometryReader { geometry in
 ZStack {
 OscilloscopeGrid()

 OscilloscopeWaveformShape(
 samples: samples,
 count: count
 )
 .stroke(Color.cyan, lineWidth: 2)
 .opacity(0.9)

 Path { path in
 let midY = geometry.size.height / 2
 path.move(to: CGPoint(x: 0, y: midY))
 path.addLine(to: CGPoint(x: geometry.size.width, y: midY))
 }
 .stroke(Color.white.opacity(0.2), lineWidth: 1)
 }
 }
 }
}

struct OscilloscopeView_Previews: PreviewProvider {
 static var previews: some View {
 OscilloscopeView(engine: SynthEngine())
 .padding()
 }
}
