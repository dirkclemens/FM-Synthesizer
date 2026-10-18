//
//  ContentView.swift
//  Synthesizer
//
//  Main window: FM synthesizer engine UI with preset browser, keyboard,
//  operator matrix, per-operator controls, global parameters, arpeggiator,
//  and sequencer.
//

import SwiftUI

struct ContentView: View {
                @StateObject private var engine = SynthEngine()
                @StateObject private var bank = PresetBank()
                @StateObject private var midiManager = MIDIManager()
                @StateObject private var macKeyboardHandler = MacKeyboardHandler()
                @State private var activeNotes: Set<UInt8> = []

                var body: some View {
                                VStack(spacing: 0) {
                                                // MARK: MIDI Connection
                                                MIDIConnectionView(midiManager: midiManager, engine: engine)

                                                Divider().padding(6)

                                                GlobalPanel(engine: engine)

                                                Divider().padding(6)

                                                // MARK: Oscilloscope + Audio Chain
                                                HStack(alignment: .top, spacing: 12) {
                                                                OscilloscopeView(engine: engine)
                                                                AudioChainView(engine: engine)
                                                                                .frame(minWidth: 1000)
                                                }

                                                Divider().padding(6)

                                                // MARK: Arpeggiator + Sequencer
                                                HStack(alignment: .top, spacing: 12) {
                                                                ArpeggiatorView(arpeggiator: engine.arpeggiator)
                                                                SequencerView(sequencer: engine.sequencer)
                                                }

                                                Divider().padding(6)

                                                // MARK: Preset Browser
                                                PresetBrowserView(bank: bank, engine: engine)

                                                Divider().padding(6)

                                                // MARK: Algorithm matrix + operator panels
                                                HStack(alignment: .top, spacing: 12) {
                                                                // Algorithm + operator matrix visualization
                                                                AlgorithmMatrixView(algorithmIndex: $engine.algorithmIndex)
                                                                                .frame(maxWidth: 260)

                                                                Divider()

                                                                // Six operator panels in a 2×3 grid
                                                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                                                                                ForEach(0..<6, id: \.self) { index in
                                                                                                OperatorPanel(operatorIndex: index, engine: engine)
                                                                                }
                                                                }
                                                                .frame(maxWidth: .infinity)
                                                }

                                                Divider().padding(6)

                                                // MARK: Keyboard
                                                HStack(alignment: .top, spacing: 0) {
                                                                Spacer()
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
                                                                                activeNotes: activeNotes.union(macKeyboardActiveNotes)
                                                                )
                                                                Spacer()
                                                }
                                                .padding(.bottom, 8)
                                }
                                .frame(minWidth: 900, maxWidth: .infinity, minHeight: 850, maxHeight: .infinity)
                                .padding(8)
                                .background(
                                                LinearGradient(
                                                                colors: [Color.black.opacity(0.8), Color(NSColor.controlBackgroundColor).opacity(0.3)],
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                )
                                )
                                .onAppear {
                                                midiManager.engine = engine
                                                engine.presetBank = bank
                                                macKeyboardHandler.engine = engine
                                                macKeyboardHandler.start()
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
                                                macKeyboardHandler.stop()
                                }
                }

                /// MIDI notes currently active from the Mac keyboard handler.
                private var macKeyboardActiveNotes: Set<UInt8> {
                                Set(macKeyboardHandler.activeKeys.compactMap { macKeyToMIDINote[$0] })
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
