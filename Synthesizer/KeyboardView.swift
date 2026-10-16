//
// KeyboardView.swift
// Synthesizer
//
// A 27-key piano keyboard (MIDI 36–62) with visual note-on highlighting.
//

import SwiftUI

let keyboardWhiteKeyWidth: CGFloat = 22
let keyboardWhiteKeyHeight: CGFloat = 120
let keyboardBlackKeyWidth: CGFloat = 14
let keyboardBlackKeyHeight: CGFloat = 75

/// MIDI note range for the 27-key keyboard.
let keyboardNoteRange: ClosedRange<UInt8> = 36...62

func isWhiteKey(midiCode: Int) -> Bool {
 let k = midiCode % 12
 return (k == 0 || k == 2 || k == 4 || k == 5 || k == 7 || k == 9 || k == 11)
}

/// Returns the x-offset for a white key, based on how many white keys precede it.
func whiteKeyXOffset(midiCode: Int) -> CGFloat {
 let whiteKeysBefore = (36...midiCode).filter { isWhiteKey(midiCode: $0) }
 return CGFloat(whiteKeysBefore.count - 1) * keyboardWhiteKeyWidth
}

/// Returns the x-offset for a black key, positioned just right of its lower white key.
func blackKeyXOffset(midiCode: Int) -> CGFloat {
 let lowerWhite = midiCode - 1
 let lowerWhiteX = whiteKeyXOffset(midiCode: lowerWhite)
 return lowerWhiteX + keyboardWhiteKeyWidth - keyboardBlackKeyWidth / 2
}

struct KeyboardView: View {
 var onKeyDown: ((UInt8) -> Void)?
 var onKeyUp: ((UInt8) -> Void)?
 var activeNotes: Set<UInt8> = []

 var body: some View {
 VStack(spacing: 0) {
 // Black keys layer (top)
 HStack(spacing: 0) {
 ForEach(Array(keyboardNoteRange), id: \.self) { code in
 if !isWhiteKey(midiCode: Int(code)) {
 BlackKeyView(
 midiCode: code,
 isActive: activeNotes.contains(code),
 onDown: { onKeyDown?(code) },
 onUp: { onKeyUp?(code) }
 )
 .offset(x: blackKeyXOffset(midiCode: Int(code)))
 } else {
 // Placeholder to maintain horizontal spacing
 Color.clear
 .frame(width: keyboardWhiteKeyWidth)
 }
 }
 }
 .frame(height: keyboardBlackKeyHeight)

 // White keys layer (bottom)
 HStack(spacing: 1) {
 ForEach(Array(keyboardNoteRange), id: \.self) { code in
 if isWhiteKey(midiCode: Int(code)) {
 WhiteKeyView(
 midiCode: code,
 isActive: activeNotes.contains(code),
 onDown: { onKeyDown?(code) },
 onUp: { onKeyUp?(code) }
 )
 } else {
 Color.clear.frame(width: keyboardWhiteKeyWidth)
 }
 }
 }
 .frame(height: keyboardWhiteKeyHeight)
 }
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
