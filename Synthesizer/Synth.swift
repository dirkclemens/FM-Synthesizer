//
// Synth.swift
// Synthesizer
//
// Created by Carlos Azuaje on 06/01/2023.
//
// ⚠️ DEPRECATED: This class is kept only for backward compatibility so the
// existing ContentView compiles. All new audio code uses SynthEngine instead.
// This class will be removed when ContentView is rewritten in Step 4.
//

import AVFoundation
import Foundation

protocol SynthProtocol: ObservableObject {
 func attachSourceNode(key: UInt8)
 func detachSourceNode(key: UInt8)
 func shutdownAVAudioEngine()
}

let LIST_MIDI_CODE = (21...108)

/// Deprecated placeholder. New code should use SynthEngine instead.
class Synth<SynthProtocol> {
 public var volume: Float = 0.5

 private var audioEngine: AVAudioEngine
 private let sampleRate: Double
 private let mainMixer: AVAudioMixerNode
 private let outputNode: AVAudioOutputNode

 init() {
 audioEngine = AVAudioEngine()
 self.mainMixer = audioEngine.mainMixerNode
 self.outputNode = audioEngine.outputNode
 self.sampleRate = outputNode.inputFormat(forBus: 0).sampleRate

 audioEngine.connect(mainMixer, to: outputNode, format: nil)
 mainMixer.outputVolume = 0

 do {
 try audioEngine.start()
 } catch {
 print("Could not start engine: \(error.localizedDescription)")
 }
 }

 deinit {
 shutdownAVAudioEngine()
 }

 public func attachSourceNode(midiKeyCode: UInt8) {
 // Deprecated: no-op. Use SynthEngine.noteOn instead.
 }

 public func detachSourceNode(midiKeyCode: UInt8) {
 // Deprecated: no-op. Use SynthEngine.noteOff instead.
 }

 public func shutdownAVAudioEngine() {
 audioEngine.disconnectNodeInput(mainMixer)
 audioEngine.disconnectNodeOutput(outputNode)
 }
}
