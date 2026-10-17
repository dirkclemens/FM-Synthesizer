//
// KeyboardView.swift
// Synthesizer
//
// A 27-key piano keyboard (MIDI 36–62) with real piano layout:
// white keys evenly spaced, black keys overlaid in 2-key and 3-key groups.
//

import SwiftUI

let keyboardWhiteKeyWidth: CGFloat = 22
let keyboardWhiteKeyHeight: CGFloat = 120
let keyboardBlackKeyWidth: CGFloat = 14
let keyboardBlackKeyHeight: CGFloat = 75

/// MIDI note range for the 27-key keyboard.
let keyboardNoteRange: ClosedRange<UInt8> = 36...74

/// Whether a MIDI note is a white key.
func isWhiteKey(midiCode: Int) -> Bool {
 let k = midiCode % 12
 return (k == 0 || k == 2 || k == 4 || k == 5 || k == 7 || k == 9 || k == 11)
}

/// Maps a MIDI note to its white-key index within the keyboard.
/// White keys within an octave: C=0, D=1, E=2, F=3, G=4, A=5, B=6
private let whiteKeyIndexInOctave: [Int: Int] = [
 0: 0, // C
 2: 1, // D
 4: 2, // E
 5: 3, // F
 7: 4, // G
 9: 5, // A
 11: 6, // B
]

/// Returns the zero-based index of a white key across the whole keyboard.
func whiteKeyIndex(midiCode: Int) -> Int {
 let octave = midiCode / 12
 let noteInOctave = midiCode % 12
 guard let indexInOctave = whiteKeyIndexInOctave[noteInOctave] else { return 0 }
 return (octave - 3) * 7 + indexInOctave
}

/// Returns the x-position of a white key.
func whiteKeyXOffset(midiCode: Int) -> CGFloat {
 return CGFloat(whiteKeyIndex(midiCode: midiCode)) * keyboardWhiteKeyWidth
}

/// Returns the center X position for a black key, centered on the boundary
/// between its left white key and the right white key.
/// Black keys exist for: C#(1), D#(3), F#(6), G#(8), A#(10)
private let blackKeyLeftWhiteNote: [Int: Int] = [
 1: 0, // C# → C is to the left
 3: 2, // D# → D is to the left
 6: 5, // F# → F is to the left
 8: 7, // G# → G is to the left
 10: 9, // A# → A is to the left
]

func blackKeyCenterX(midiCode: Int) -> CGFloat {
 let noteInOctave = midiCode % 12
 guard let leftWhiteNote = blackKeyLeftWhiteNote[noteInOctave] else { return 0 }
 let leftWhiteMidi = (midiCode / 12) * 12 + leftWhiteNote
 let leftWhiteX = whiteKeyXOffset(midiCode: leftWhiteMidi)
 // Center the black key on the boundary between two white keys:
 // the right edge of the left white key (with spacing: 0 in HStack).
 return leftWhiteX + keyboardWhiteKeyWidth
}

struct KeyboardView: View {
 var onKeyDown: ((UInt8) -> Void)?
 var onKeyUp: ((UInt8) -> Void)?
 var activeNotes: Set<UInt8> = []

 /// Only the white keys, in order.
 private var whiteKeys: [UInt8] {
 return Array(keyboardNoteRange).filter { isWhiteKey(midiCode: Int($0)) }
 }

 /// Only the black keys, in order.
 private var blackKeys: [UInt8] {
 return Array(keyboardNoteRange).filter { !isWhiteKey(midiCode: Int($0)) }
 }

 var body: some View {
 let keyboardWidth = CGFloat(whiteKeys.count) * keyboardWhiteKeyWidth
 
 ZStack(alignment: .topLeading) {
 // Bottom layer: white keys evenly spaced
 HStack(spacing: 0) {
 ForEach(whiteKeys, id: \.self) { code in
 WhiteKeyView(
 midiCode: code,
 isActive: activeNotes.contains(code),
 onDown: { onKeyDown?(code) },
 onUp: { onKeyUp?(code) }
 )
 }
 }
 .frame(height: keyboardWhiteKeyHeight)

 // Top layer: black keys positioned absolutely between white keys
 ForEach(blackKeys, id: \.self) { code in
 BlackKeyView(
 midiCode: code,
 isActive: activeNotes.contains(code),
 onDown: { onKeyDown?(code) },
 onUp: { onKeyUp?(code) }
 )
 .position(
 x: blackKeyCenterX(midiCode: Int(code)),
 y: keyboardBlackKeyHeight / 2
 )
 }
 }
 .frame(width: keyboardWidth, height: keyboardWhiteKeyHeight)
 }
}

struct WhiteKeyView: View {
 let midiCode: UInt8
 let isActive: Bool
 var onDown: (() -> Void)?
 var onUp: (() -> Void)?

 var label: String {
 let octave = Int(midiCode) / 12 - 1
 let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
 let note = noteNames[Int(midiCode) % 12]
 return "\(note)\(octave)"
 }

 var body: some View {
 ZStack {
 RoundedRectangle(cornerRadius: 2)
 .fill(isActive ? Color.blue : Color.white)
 RoundedRectangle(cornerRadius: 2)
 .stroke(Color.black, lineWidth: 1)

 if !label.contains("#") {
 Text(label)
 .font(.system(size: 9, weight: .medium))
 .foregroundColor(isActive ? .white : .black)
 .offset(y: 35)
 }
 }
 .frame(width: keyboardWhiteKeyWidth, height: keyboardWhiteKeyHeight)
 .gesture(
 DragGesture(minimumDistance: 0)
 .onChanged { _ in
 if !isActive { onDown?() }
 }
 .onEnded { _ in
 onUp?()
 }
 )
 .simultaneousGesture(
 TapGesture()
 .onEnded {
 onDown?()
 DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
 onUp?()
 }
 }
 )
 }
}

struct BlackKeyView: View {
 let midiCode: UInt8
 let isActive: Bool
 var onDown: (() -> Void)?
 var onUp: (() -> Void)?

 var label: String {
 let octave = Int(midiCode) / 12 - 1
 let noteNames = ["C#", "D#", "", "F#", "G#", "A#", ""]
 let idx = Int(midiCode) % 12
 guard idx < noteNames.count, !noteNames[idx].isEmpty else { return "" }
 return "\(noteNames[idx])\(octave)"
 }

 var body: some View {
 ZStack {
 RoundedRectangle(cornerRadius: 2)
 .fill(isActive ? Color.blue : Color.black)
 RoundedRectangle(cornerRadius: 2)
 .stroke(Color.black, lineWidth: 1)

 if !label.isEmpty {
 Text(label)
 .font(.system(size: 8, weight: .medium))
 .foregroundColor(isActive ? .white : .white.opacity(0.7))
 .offset(y: 25)
 }
 }
 .frame(width: keyboardBlackKeyWidth, height: keyboardBlackKeyHeight)
 .gesture(
 DragGesture(minimumDistance: 0)
 .onChanged { _ in
 if !isActive { onDown?() }
 }
 .onEnded { _ in
 onUp?()
 }
 )
 .simultaneousGesture(
 TapGesture()
 .onEnded {
 onDown?()
 DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
 onUp?()
 }
 }
 )
 }
}

struct KeyboardView_Previews: PreviewProvider {
 static var previews: some View {
 KeyboardView(
 onKeyDown: { _ in },
 onKeyUp: { _ in },
 activeNotes: [60, 64]
 )
 .padding()
 }
}
