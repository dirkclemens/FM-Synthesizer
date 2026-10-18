//
// AudioChainView.swift
// Synthesizer
//
// Visualizes the audio signal chain: voice operators → voice source nodes →
// main mixer → effects chain → output node.
//

import SwiftUI

struct AudioChainView: View {
 @ObservedObject var engine: SynthEngine

 var body: some View {
 VStack(alignment: .leading, spacing: 8) {
 headerView

 HStack(alignment: .top, spacing: 6) {
 voiceNodesSection
 arrowNodeView
 mixerNodeView
 arrowNodeView
 effectsChainView
 arrowNodeView
 outputNodeView
 }
 .padding(8)
 .frame(maxWidth: .infinity, alignment: .leading)
 }
 .padding(10)
 .background(
 RoundedRectangle(cornerRadius: 10)
 .fill(Color.black.opacity(0.3))
 )
 .overlay(
 RoundedRectangle(cornerRadius: 10)
 .stroke(Color.cyan.opacity(0.4), lineWidth: 1.5)
 )
 }

 // MARK: - Header

 private var headerView: some View {
 HStack {
 ZStack {
 Circle()
 .fill(Color.cyan.opacity(0.2))
 .frame(width: 24, height: 24)
 Circle()
 .stroke(Color.cyan, lineWidth: 2)
 .frame(width: 24, height: 24)
 .overlay(
 Text("FM")
 .font(.system(size: 10, weight: .bold, design: .monospaced))
 .foregroundColor(.cyan)
 )
 }
 Text("FM Engine")
 .font(.headline)
 .foregroundColor(.primary)
 Spacer()
 Text(engine.isRunning ? "LIVE" : "OFF")
 .font(.caption2)
 .fontWeight(.bold)
 .foregroundColor(engine.isRunning ? .green : .secondary)
 }
 }

 // MARK: - Voice Nodes

 private var voiceNodesSection: some View {
 VStack(spacing: 6) {
 Text("Operators")
 .font(.caption2)
 .foregroundColor(.secondary)
 .frame(maxWidth: .infinity, alignment: .center)

 HStack(spacing: 4) {
 ForEach(0..<voiceCount, id: \.self) { index in
 voiceNodeView(voice: engine.voices[index], index: index)
 }
 }
 .frame(width: 240)
 }
 }

 // MARK: - Voice Node

 private func voiceNodeView(voice: Voice, index: Int) -> some View {
 VStack(spacing: 3) {
 Circle()
 .fill(voiceStateColor(voice.state))
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

 // MARK: - Mixer Node

 private var mixerNodeView: some View {
 VStack(spacing: 6) {
 Circle()
 .fill(mixerColor)
 .frame(width: 44, height: 44)
 .overlay(
 Text("MIX")
 .font(.system(size: 10, weight: .bold, design: .monospaced))
 .foregroundColor(.white)
 )
 .overlay(
 Circle()
 .stroke(mixerColor.opacity(0.5), lineWidth: 2)
 .scaleEffect(mixerPulse ? 1.4 : 1.0)
 .opacity(mixerPulse ? 0.4 : 0.0)
 .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: mixerPulse)
 )

 Text("Mixer")
 .font(.caption2)
 .foregroundColor(.secondary)
 }
 .frame(width: 70)
 }

 // MARK: - Effects Chain

 private var effectsChainView: some View {
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
 }

 // MARK: - Output Node

 private var outputNodeView: some View {
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

 // MARK: - Arrow

 private var arrowNodeView: some View {
 Image(systemName: "chevron.right")
 .font(.system(size: 10))
 .foregroundColor(.gray.opacity(0.5))
 }

 // MARK: - Effects Chain

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
 .frame(width: 62)
 }

 // MARK: - Computed Properties

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

 private func effectColor(_ type: EffectType) -> Color {
 switch type {
 case .filter: return Color.blue
 case .distortion: return Color.orange
 case .chorus: return Color.green
 case .delay: return Color.purple
 case .reverb: return Color.blue.opacity(0.7)
 case .phaser: return Color.purple.opacity(0.7)
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

struct AudioChainView_Previews: PreviewProvider {
 static var previews: some View {
 AudioChainView(engine: SynthEngine())
 .padding()
 }
}
