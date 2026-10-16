//
// PresetBrowserView.swift
// Synthesizer
//
// Browser for the 128-slot preset bank: load, save, clear, rename.
//

import SwiftUI

struct PresetBrowserView: View {
 @ObservedObject var bank: PresetBank
 @ObservedObject var engine: SynthEngine

 /// Whether we're in rename mode for a given slot.
 @State private var renamingSlot: Int? = nil
 @State private var renameText: String = ""

 let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 8)

 var body: some View {
 VStack(alignment: .leading, spacing: 8) {
 Text("Presets (128 slots)")
 .font(.headline)
 .foregroundColor(.secondary)

 // Slot grid
 LazyVGrid(columns: columns, spacing: 6) {
 ForEach(0..<PresetBank.slotCount, id: \.self) { slot in
 PresetSlotView(
 slot: slot,
 preset: bank.preset(at: slot),
 isSelected: bank.selectedSlot == slot,
 isFactory: isFactorySlot(slot),
 onLoad: {
 _ = bank.loadPreset(at: slot, into: engine)
 },
 onSave: {
 bank.savePreset(engine.preset, at: slot)
 },
 onClear: {
 bank.clearPreset(at: slot)
 },
 onRename: {
 renamingSlot = slot
 renameText = bank.preset(at: slot)?.name ?? "User \(slot)"
 }
 )
 }
 }
 .frame(maxHeight: 300)

 // Quick actions
 HStack(spacing: 12) {
 Button("Save Current") {
 bank.savePreset(engine.preset, at: bank.selectedSlot)
 }
 .buttonStyle(.bordered)
 .disabled(bank.userPresets[bank.selectedSlot] == nil && bank.preset(at: bank.selectedSlot) == nil)

 Button("Clear Slot") {
 bank.clearPreset(at: bank.selectedSlot)
 }
 .buttonStyle(.bordered)
 .disabled(!bank.isOccupied(bank.selectedSlot))

 Button("Rename") {
 renamingSlot = bank.selectedSlot
 renameText = bank.preset(at: bank.selectedSlot)?.name ?? "User \(bank.selectedSlot)"
 }
 .buttonStyle(.bordered)
 .disabled(!bank.isOccupied(bank.selectedSlot))

 Spacer()

 Text("Slot \(bank.selectedSlot + 1) / \(PresetBank.slotCount)")
 .font(.caption)
 .foregroundColor(.secondary)
 }

 // Rename overlay
 if let slot = renamingSlot {
 VStack(spacing: 8) {
 Text("Rename Slot \(slot + 1)")
 .font(.headline)
 TextField("Preset name", text: $renameText)
 .textFieldStyle(.roundedBorder)
 HStack {
 Button("Cancel") {
 renamingSlot = nil
 }
 .buttonStyle(.bordered)
 Button("Save") {
 bank.renamePreset(at: slot, to: renameText)
 renamingSlot = nil
 }
 .buttonStyle(.borderedProminent)
 .disabled(renameText.isEmpty)
 }
 }
 .padding(16)
 .background(Color(NSColor.controlBackgroundColor))
 .cornerRadius(8)
 .shadow(radius: 4)
 }
 }
 .padding(8)
 .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
 .cornerRadius(6)
 }

 /// Whether the slot is a factory preset slot (first N slots).
 private func isFactorySlot(_ slot: Int) -> Bool {
 return slot < Preset.factory.count
 }
}

/// A single preset slot button.
struct PresetSlotView: View {
 let slot: Int
 let preset: Preset?
 let isSelected: Bool
 let isFactory: Bool
 var onLoad: () -> Void
 var onSave: () -> Void
 var onClear: () -> Void
 var onRename: () -> Void

 var body: some View {
 VStack(spacing: 2) {
 Text("\(slot + 1)")
 .font(.system(size: 9, design: .monospaced))
 .foregroundColor(.secondary)

 if let preset = preset {
 Text(preset.name)
 .font(.system(size: 9))
 .lineLimit(1)
 .truncationMode(.middle)
 .foregroundColor(isFactory ? .green : .primary)
 } else {
 Text("Empty")
 .font(.system(size: 8, weight: .light))
 .foregroundColor(Color.gray.opacity(0.5))
 }

 HStack(spacing: 2) {
 Button(action: onLoad) {
 Image(systemName: "play.fill")
 .font(.system(size: 8))
 }
 .buttonStyle(.plain)
 .help("Load")

 Button(action: onSave) {
 Image(systemName: "arrow.down.circle.fill")
 .font(.system(size: 8))
 }
 .buttonStyle(.plain)
 .help("Save")

 Button(action: onClear) {
 Image(systemName: "trash")
 .font(.system(size: 8))
 }
 .buttonStyle(.plain)
 .help("Clear")
 }
 }
 .frame(width: 55, height: 55)
 .background(
 RoundedRectangle(cornerRadius: 4)
 .fill(isSelected ? Color.blue : Color(NSColor.controlBackgroundColor).opacity(0.5))
 )
 .overlay(
 RoundedRectangle(cornerRadius: 4)
 .stroke(Color.blue.opacity(0.5), lineWidth: isSelected ? 2 : 0)
 )
 }
}

struct PresetBrowserView_Previews: PreviewProvider {
 static var previews: some View {
 PresetBrowserView(bank: PresetBank(), engine: SynthEngine())
 .padding()
 }
}
