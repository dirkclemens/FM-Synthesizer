//
// ContentView.swift
// Synthesizer
//
// Main window: FM synthesizer engine UI with preset browser, keyboard,
// operator matrix, per-operator controls, and global parameters.
//

import SwiftUI

struct ContentView: View {
 @StateObject private var engine = SynthEngine()
 @StateObject private var bank = PresetBank()
 @State private var activeNotes: Set<UInt8> = []

 var body: some View {
 VStack(spacing: 0) {
 // MARK: Preset browser
 PresetBrowserView(bank: bank, engine: engine)

 Divider()

 // MARK: Global controls
 GlobalPanel(engine: engine)

 Divider()

 // MARK: Operator matrix + operator panels
 HStack(spacing: 12) {
 // Operator matrix (6x6 visualization)
 OperatorMatrixView(algorithm: fmAlgorithms[engine.algorithmIndex])
 .frame(maxWidth: .infinity)

 Divider()

 // Six operator panels in a scrollable row
 ScrollView(.horizontal, showsIndicators: false) {
 HStack(spacing: 8) {
 ForEach(0..<6, id: \.self) { index in
 OperatorPanel(operatorIndex: index, engine: engine)
 .frame(width: 200)
 }
 }
 .padding(.horizontal, 4)
 }
 }

 Divider()

 // MARK: Keyboard
 KeyboardView(
 onKeyDown: { note in
 activeNotes.insert(note)
 engine.noteOn(midiNote: note, velocity: 100)
 },
 onKeyUp: { note in
 activeNotes.remove(note)
 engine.noteOff(midiNote: note)
 },
 activeNotes: activeNotes
 )
 .padding(.bottom, 8)
 }
 .frame(minWidth: 900, minHeight: 750)
 .padding(8)
 .onAppear {
 do {
 try engine.start()
 } catch {
 print("Failed to start synth engine: \(error)")
 }
 }
 .onDisappear {
 engine.stop()
 }
 }
}

struct ContentView_Previews: PreviewProvider {
 static var previews: some View {
 ContentView()
 }
}
