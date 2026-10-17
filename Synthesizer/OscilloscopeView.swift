//
// OscilloscopeView.swift
// Synthesizer
//
// Real-time oscilloscope visualization of the FM synthesis output.
// Shows the mixed audio waveform as it's being rendered, plus an audio
// chain diagram showing signal flow through the synth engine.
//

import SwiftUI

struct OscilloscopeView: View {
 @ObservedObject var engine: SynthEngine

 private let displaySamples = 256
 @State private var refreshTick: Int = 0

 var body: some View {
 VStack(alignment: .leading, spacing: 8) {
 // Header
 HStack {
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
 Text("Oscilloscope")
 .font(.headline)
 .foregroundColor(.primary)
 Spacer()
 Text(engine.isRunning ? "LIVE" : "OFF")
 .font(.caption2)
 .fontWeight(.bold)
 .foregroundColor(engine.isRunning ? .green : .secondary)
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

 // Waveform display
 OscilloscopeDisplayView(
 samples: engine.scopeSamples,
 count: min(engine.scopeSamples.count, displaySamples)
 )
 .frame(height: 140)
 .padding(8)
 .background(Color.black.opacity(0.4))
 .cornerRadius(8)

 // Audio chain diagram
 AudioChainMiniView(
 engine: engine
 )
 .frame(height: 120)
 .padding(8)
 .background(Color.black.opacity(0.3))
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

/// Audio chain visualization showing voice nodes → mixer → effects → output.
struct AudioChainView: View {
 let engine: SynthEngine

 var body: some View {
 VStack(alignment: .leading, spacing: 8) {
 HStack {
 ZStack {
 Circle()
 .fill(Color.blue.opacity(0.2))
 .frame(width: 24, height: 24)
 Circle()
 .stroke(Color.blue, lineWidth: 2)
 .frame(width: 24, height: 24)
 Text("FM")
 .font(.system(size: 10, weight: .bold, design: .monospaced))
 .foregroundColor(.blue)
 }
 Text("FM Engine Signal Chain")
 .font(.headline)
 .foregroundColor(.primary)
 Spacer()
 Text(engine.isRunning ? "LIVE" : "OFF")
 .font(.caption2)
 .fontWeight(.bold)
 .foregroundColor(engine.isRunning ? .green : .secondary)
 }
 .padding(.horizontal, 10)
 .padding(.top, 10)

 HStack(alignment: .top, spacing: 6) {
 // Voice nodes section
 VStack(spacing: 6) {
 Text("Voices (12)")
 .font(.caption2)
 .foregroundColor(.secondary)
 .frame(maxWidth: .infinity, alignment: .center)

 HStack(spacing: 4) {
 ForEach(0..<voiceCount, id: \.self) { index in
 VoiceNodeView(voice: engine.voices[index], index: index)
 }
 }
 .frame(width: 220)
 }

 // Mixer node
 VStack(spacing: 6) {
 Circle()
 .fill(mixerColor)
 .frame(width: 44, height: 44)
 .overlay(
 Text("M")
 .font(.system(size: 10, weight: .bold, design: .monospaced))
 .foregroundColor(.white)
 )
 .overlay(
 Circle()
 .stroke(mixerColor.opacity(0.5), lineWidth: 2)
 .scaleEffect(mixerPulse ? 1.3 : 1.0)
 .opacity(mixerPulse ? 0.4 : 0.0)
 .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: mixerPulse)
 )

 Text("Mixer")
 .font(.caption2)
 .foregroundColor(.secondary)
 }
 .frame(width: 70)

 // Effects chain
 VStack(spacing: 6) {
 Text("FX Chain")
 .font(.caption2)
 .foregroundColor(.secondary)
 .frame(maxWidth: .infinity, alignment: .center)

 VStack(spacing: 4) {
 effectNodeView(effect: .filter, isOn: engine.effectFilterEnabled)
 effectNodeView(effect: .distortion, isOn: engine.effectDistortionEnabled)
 effectNodeView(effect: .chorus, isOn: engine.effectChorusEnabled)
 effectNodeView(effect: .delay, isOn: engine.effectDelayEnabled)
 effectNodeView(effect: .reverb, isOn: engine.effectReverbEnabled)
 effectNodeView(effect: .phaser, isOn: engine.effectPhaserEnabled)
 }
 }
 .frame(width: 100)

 // Output node
 VStack(spacing: 8) {
 Circle()
 .fill(outputColor)
 .frame(width: 44, height: 44)
 .overlay(
 Text("OUT")
 .font(.system(size: 10, weight: .bold, design: .monospaced))
 .foregroundColor(.white)
 )
 .overlay(
 Circle()
 .stroke(outputColor.opacity(0.5), lineWidth: 2)
 .scaleEffect(outputPulse ? 1.3 : 1.0)
 .opacity(outputPulse ? 0.4 : 0.0)
 .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: outputPulse)
 )

 Text("Output")
 .font(.caption2)
 .foregroundColor(.secondary)
 }
 .frame(width: 80)
 }
 }
 }

 // MARK: - Subviews

 private var voiceNodeView: some View {
 VStack(spacing: 4) {
 Circle()
 .fill(voiceStateColor)
 .frame(width: 22, height: 22)
 .overlay(
 Text("\(index + 1)")
 .font(.system(size: 8, weight: .bold, design: .monospaced))
 .foregroundColor(.white)
 )
 Text("\(index + 1)")
 .font(.caption2)
 .foregroundColor(.secondary)
 }
 .frame(width: 34)
 }

 private func effectNodeView(effect: EffectType, isOn: Bool) -> some View {
 HStack(spacing: 4) {
 Image(systemName: effectIcon(effect))
 .font(.system(size: 10))
 .foregroundColor(isOn ? effectColor(effect) : .gray.opacity(0.3))
 Text(effectShortName(effect))
 .font(.caption2)
 .foregroundColor(isOn ? .primary : .secondary)
 .frame(width: 44, alignment: .center)
 }
 .frame(width: 70)
 }

 // MARK: - Helpers

 private var mixerColor: Color {
 engine.isRunning ? Color.blue : Color.gray.opacity(0.3)
 }

 private var outputColor: Color {
 engine.isRunning ? Color.green : Color.gray.opacity(0.3)
 }

 @State private var mixerPulse: Bool = false
 @State private var outputPulse: Bool = false

 private func voiceStateColor(_ state: VoiceState) -> Color {
 switch state {
 case .free: return Color.gray.opacity(0.3)
 case .active: return Color.green
 case .releasing: return Color.yellow
 }
 }

 private func voiceStateColorForOutput(_ voice: Voice) -> Color {
 switch voice.state {
 case .free: return Color.gray.opacity(0.3)
 case .active: return Color.green
 case .releasing: return Color.yellow
 }
 }

 private func effectIcon(_ type: EffectType) -> String {
 switch type {
 case .filter: return "circle.fill"
 case .distortion: return "waveform"
 case .chorus: return "wave.3.left"
 case .delay: return "repeat"
 case .reverb: return "wave.3.right"
 case .phaser: return "waveform.circle"
 }
 }

 private func effectShortName(_ type: EffectType) -> String {
 switch type {
 case .filter: return "Filter"
 case .distortion: return "Distort"
 case .chorus: return "Chorus"
 case .delay: return "Delay"
 case .reverb: return "Reverb"
 case .phaser: return "Phaser"
 }
 }
}

struct OscilloscopeView_Previews: PreviewProvider {
 static var previews: some View {
 OscilloscopeView(engine: SynthEngine())
 .padding()
 }
}
