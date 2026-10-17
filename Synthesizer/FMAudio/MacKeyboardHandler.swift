//
// MacKeyboardHandler.swift
// Synthesizer
//
// Maps physical Mac keyboard keys to the synthesizer's piano keys.
// Uses NSEvent.addLocalMonitorForEvents to capture keyDown/keyUp globally
// within the app.
//
// Layout follows a piano-style arrangement:
//
// Q W E R T Y U I O P [ ]
// A S D F G H J K L
// Z X C V B N M , .
//
// Corresponds to MIDI notes 36–62 (C2–D4), covering the full
// range of the on-screen piano keyboard.
//

import Foundation
import AppKit

/// Maps macOS keyboard key codes to MIDI note numbers.
/// No duplicate key codes — each physical key maps to exactly one note.
let macKeyToMIDINote: [UInt16: UInt8] = [ // Top row — white keys C3 … E4
 0x0C: 48, // Q → C3
 0x0D: 50, // W → D3
 0x0E: 52, // E → E3
 0x0F: 53, // R → F3
 0x11: 55, // T → G3
 0x10: 57, // Y → A3
 0x22: 59, // U → B3
 0x26: 60, // I → C4
 0x1F: 62, // O → D4
 0x1A: 64, // P → E4
 0x21: 65, // [ → F4
 0x1B: 67, // ] → G4

 // Home row — black keys C#2 … A#2
 0x00: 37, // A → C#2
 0x01: 39, // S → D#2
 0x02: 42, // D → F#2
 0x03: 44, // F → G#2
 0x05: 46, // G → A#2

 // Bottom row — white keys C2 … C3
 0x06: 36, // Z → C2
 0x07: 38, // X → D2
 0x08: 40, // C → E2
 0x09: 41, // V → F2
 0x0B: 43, // B → G2
 0x2D: 45, // N → A2
 0x2E: 47, // M → B2
 0x2C: 48, // , → C3
 0x2F: 50, // . → D3
]

/// Handles Mac keyboard key events and routes them to SynthEngine.
final class MacKeyboardHandler: ObservableObject {

 /// Reference to the synth engine.
 weak var engine: SynthEngine?

 /// Currently active (pressed) key codes — published for UI feedback.
 @Published private(set) var activeKeys: Set<UInt16> = []

 /// Whether keyboard handling is active.
 private var isActive: Bool = false

 init(engine: SynthEngine? = nil) {
 self.engine = engine
 }

 /// Starts listening for key events.
 func start() {
 guard !isActive else { return }
 isActive = true

 NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
 guard let self = self else { return event }
 self.handleKeyDown(event)
 return event
 }

 NSEvent.addLocalMonitorForEvents(matching: .keyUp) { [weak self] event in
 guard let self = self else { return event }
 self.handleKeyUp(event)
 return event
 }
 }

 /// Stops listening for key events.
 func stop() {
 isActive = false
 activeKeys.removeAll()
 }

 // MARK: - Event handling

 private func handleKeyDown(_ event: NSEvent) {
 let keyCode = event.keyCode

 // Ignore if already held (key repeat)
 if activeKeys.contains(keyCode) {
 return
 }

 // Check if this key maps to a MIDI note
 if let midiNote = macKeyToMIDINote[keyCode] {
 activeKeys.insert(keyCode)
 engine?.noteOn(midiNote: midiNote, velocity: 100)
 }
 }

 private func handleKeyUp(_ event: NSEvent) {
 let keyCode = event.keyCode
 activeKeys.remove(keyCode)

 if let midiNote = macKeyToMIDINote[keyCode] {
 engine?.noteOff(midiNote: midiNote)
 }
 }
}
