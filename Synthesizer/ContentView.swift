//
// ContentView.swift
// Synthesizer
//
// Main window: FM synthesizer engine UI with preset browser, keyboard,
// operator matrix, per-operator controls, global parameters, arpeggiator,
// and sequencer.
//

import SwiftUI

struct ContentView: View {
 @StateObject private var engine = SynthEngine()
 @StateObject private var bank = PresetBank()
 @StateObject private var midiManager: MIDIManager = {
 let m = MIDIManager()
 return m
 }()
 @State private var activeNotes: Set<UInt8> = []

 var body: some View {
 VStack(spacing: 0) {
 // MARK: Preset browser
 PresetBrowserView(bank: bank, engine: engine)

 Divider()

 // MARK: MIDI Connection
 HStack(spacing: 12) {
 Text("MIDI Input")
 .font(.caption)
 .foregroundColor(.secondary)
 
 if midiManager.availableSources.isEmpty {
 Text("No MIDI sources found")
 .font(.caption2)
 .foregroundColor(.secondary)
 } else {
 Picker("MIDI Source", selection: Binding(
 get: { midiManager.connectedSourceName.map { $0 } ?? "None" },
 set: { newValue in
 if let index = midiManager.availableSources.firstIndex(of: newValue) {
 midiManager.connect(to: index)
 } else {
 midiManager.disconnect()
 }
 }
 )) {
 Text("None").tag("None")
 ForEach(midiManager.availableSources, id: \.self) { name in
 Text(name).tag(name)
 }
 }
 .pickerStyle(.menu)
 .frame(maxWidth: 200)
 }
 
 Button(midiManager.isConnected ? "Disconnect" : "Connect") {
 if midiManager.isConnected {
 midiManager.disconnect()
 } else if let first = midiManager.availableSources.first,
 let index = midiManager.availableSources.firstIndex(of: first) {
 midiManager.connect(to: index)
 }
 }
 .buttonStyle(.bordered)
 .disabled(midiManager.availableSources.isEmpty)
 
 Button("Refresh") {
 midiManager.refreshSources()
 }
 .buttonStyle(.bordered)
 .controlSize(.small)
 
 Spacer()
 
 Text(midiManager.isConnected ? "Connected" : "Disconnected")
 .font(.caption2)
 .foregroundColor(midiManager.isConnected ? .green : .secondary)
 }

 // MARK: Arpeggiator + Sequencer
 HStack(spacing: 12) {
 ArpeggiatorView(arpeggiator: engine.arpeggiator)
 SequencerView(sequencer: engine.sequencer)
 }

 Divider()

 // MARK: Global controls
 GlobalPanel(engine: engine)

 Divider()

 // MARK: Operator panels (6 operators in 2×3 grid)
 LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
 ForEach(0..<6, id: \.self) { index in
 OperatorPanel(operatorIndex: index, engine: engine)
 }
 }

 Divider()

 // MARK: Keyboard
 KeyboardView(
 onKeyDown: { note in
 activeNotes.insert(note)
 if engine.arpeggiator.isRunning {
 engine.arpeggiator.holdNote(note)
 } else {
 engine.noteOn(midiNote: note, velocity: 100)
 }
 },
 onKeyUp: { note in
 activeNotes.remove(note)
 if engine.arpeggiator.isRunning {
 arpeggiatorKeyUp(note: note)
 } else {
 engine.noteOff(midiNote: note)
 }
 },
 activeNotes: activeNotes
 )
 .padding(.bottom, 8)
 }
 .frame(minWidth: 900, minHeight: 850)
 .padding(8)
 .onAppear {
 midiManager.engine = engine
 engine.presetBank = bank
 midiManager.refreshSources()
 do {
 try engine.start()
 } catch {
 print("Failed to start synth engine: \(error)")
 }
 }
 .onDisappear {
 engine.stop()
 engine.arpeggiator.stop()
 engine.sequencer.stop()
 }
 }

 /// Handle key up when arpeggiator is running: release from arpeggiator.
 private func arpeggiatorKeyUp(note: UInt8) {
 engine.arpeggiator.releaseNote(note)
 // If arpeggiator has no held notes, stop it.
 if engine.arpeggiator.heldNotes.isEmpty {
 engine.arpeggiator.stop()
 }
 }
}

struct ContentView_Previews: PreviewProvider {
 static var previews: some View {
 ContentView()
 }
}
