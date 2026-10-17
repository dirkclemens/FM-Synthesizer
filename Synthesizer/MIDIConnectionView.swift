//
// MIDIConnectionView.swift
// Synthesizer
//
// MIDI connection panel: source selection, connect/disconnect, refresh,
// connection status, and restore last state.
//

import SwiftUI

struct MIDIConnectionView: View {
 @ObservedObject var midiManager: MIDIManager
 let engine: SynthEngine

 var body: some View {
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

 Button("Restore Last State") {
 engine.loadSettings()
 }
 .buttonStyle(.bordered)
 .controlSize(.small)
 .help("Restore previously saved engine state")
 }
 .padding(10)
 .background(
 RoundedRectangle(cornerRadius: 10)
 .fill(Color(NSColor.controlBackgroundColor).opacity(0.4))
 )
 .overlay(
 RoundedRectangle(cornerRadius: 10)
 .stroke(Color.blue.opacity(0.4), lineWidth: 1.5)
 )
 .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
 }
}

struct MIDIConnectionView_Previews: PreviewProvider {
 static var previews: some View {
 MIDIConnectionView(midiManager: MIDIManager(), engine: SynthEngine())
 .padding()
 }
}
