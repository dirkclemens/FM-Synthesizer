//
//  PresetBrowserView.swift
//  Synthesizer
//
//  Browser for the 128-slot preset bank: load, save, clear, rename.
//  All 128 slots are displayed in a scrollable list with factory presets
//  (read-only) and user presets (read/write).
//

import SwiftUI

struct PresetBrowserView: View {
    @ObservedObject var bank: PresetBank
    @ObservedObject var engine: SynthEngine
    
    /// Whether we're in rename mode for a given slot.
    @State private var renamingSlot: Int? = nil
    @State private var renameText: String = ""
    
    var body: some View {
        BaseModuleView(
            title: "Presets",
            icon: "P",
            color: .yellow
        ) {
            VStack(alignment: .leading, spacing: 10) {
                // Slot list - all 128 presets
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(0..<PresetBank.slotCount, id: \.self) { slot in
                            PresetRowView(
                                slot: slot,
                                preset: bank.preset(at: slot),
                                isSelected: bank.selectedSlot == slot,
                                isFactory: slot < Preset.factory.count,
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
                    .padding(.horizontal, 4)
                }
                .frame(maxHeight: 160)
                
                Divider()
                
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
                    .disabled(!bank.isOccupied(bank.selectedSlot) || slotIsFactory(bank.selectedSlot))
                    
                    Button("Rename") {
                        renamingSlot = bank.selectedSlot
                        renameText = bank.preset(at: bank.selectedSlot)?.name ?? "User \(bank.selectedSlot)"
                    }
                    .buttonStyle(.bordered)
                    .disabled(!bank.isOccupied(bank.selectedSlot) || slotIsFactory(bank.selectedSlot))
                    
                    Spacer()
                    
                    Text("Slot \(bank.selectedSlot + 1) / \(PresetBank.slotCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .overlay(
            renameOverlay
                .opacity(renamingSlot != nil ? 1.0 : 0.0)
                .scaleEffect(renamingSlot != nil ? 1.0 : 0.8)
                .animation(.easeInOut(duration: 0.2), value: renamingSlot != nil)
        )
    }
    
    /// Whether the slot is a factory preset slot (read-only).
    private func slotIsFactory(_ slot: Int) -> Bool {
        return slot < Preset.factory.count
    }
    
    // Rename overlay
    @ViewBuilder
    private var renameOverlay: some View {
        if renamingSlot != nil {
            VStack(spacing: 8) {
                Text("Rename Slot \(renamingSlot! + 1)")
                    .font(.headline)
                TextField("Preset name", text: $renameText)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("Cancel") {
                        renamingSlot = nil
                    }
                    .buttonStyle(.bordered)
                    Button("Save") {
                        bank.renamePreset(at: renamingSlot!, to: renameText)
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
}

/// A single preset row in the list.
struct PresetRowView: View {
    let slot: Int
    let preset: Preset?
    let isSelected: Bool
    let isFactory: Bool
    var onLoad: () -> Void
    var onSave: () -> Void
    var onClear: () -> Void
    var onRename: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            // Slot number
            Text("\(slot + 1)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 24, alignment: .trailing)
            
            // Factory indicator
            if isFactory {
                Image(systemName: "lock.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.green)
                    .frame(width: 14)
            }
            
            // Preset name
            if let preset = preset {
                Text(preset.name)
                    .font(.system(size: 11))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundColor(isFactory ? .green : .primary)
            } else {
                Text("Empty")
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(Color.gray.opacity(0.5))
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 2) {
                Button(action: onLoad) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 9))
                }
                .buttonStyle(.plain)
                .disabled(preset == nil)
                .help("Load")
                
                Button(action: onSave) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 9))
                }
                .buttonStyle(.plain)
                .disabled(isFactory)
                .help("Save")
                
                Button(action: onClear) {
                    Image(systemName: "trash")
                        .font(.system(size: 9))
                }
                .buttonStyle(.plain)
                .disabled(isFactory || preset == nil)
                .help("Clear")
                
                Button(action: onRename) {
                    Image(systemName: "pencil")
                        .font(.system(size: 9))
                }
                .buttonStyle(.plain)
                .disabled(isFactory || preset == nil)
                .help("Rename")
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected ? Color.blue : Color(NSColor.controlBackgroundColor).opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.blue.opacity(0.5), lineWidth: isSelected ? 2 : 0)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if preset != nil && !isFactory {
                onLoad()
            }
        }
    }
}

struct PresetBrowserView_Previews: PreviewProvider {
    static var previews: some View {
        PresetBrowserView(bank: PresetBank(), engine: SynthEngine())
            .padding()
    }
}
