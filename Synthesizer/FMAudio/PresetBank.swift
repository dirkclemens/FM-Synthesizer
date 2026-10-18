//
// PresetBank.swift
// Synthesizer
//
// 128-slot preset bank with factory presets and user preset persistence
// to JSON in Application Support.
//

import Foundation
import SwiftUI

/// Manages 128 preset slots: factory (read-only) + user (read/write).
final class PresetBank: ObservableObject {
 
  /// Total number of preset slots.
  static let slotCount = 128
 
  /// Factory presets (read-only, embedded).
  let factoryPresets: [Preset]
 
  /// User presets, indexed by slot (0..<128). Nil = empty slot.
  @Published var userPresets: [Preset?]
 
  /// Currently selected slot (0..<127).
  @Published var selectedSlot: Int = 0
 
  /// URL to the user presets JSON file in Application Support.
  private let presetsURL: URL
 
  init() {
  self.factoryPresets = Preset.factory
 
  // Initialize all slots as empty.
  self.userPresets = Array(repeating: nil, count: PresetBank.slotCount)
 
  // Determine the presets file URL in Application Support.
  let appSupport = FileManager.default.urls(
  for: .applicationSupportDirectory,
  in: .userDomainMask
  )
  let appFolder = appSupport[0].appendingPathComponent("charlyjazz.Synthesizer", isDirectory: true)
 
  // Create the folder if it doesn't exist.
  try? FileManager.default.createDirectory(
  at: appFolder,
  withIntermediateDirectories: true,
  attributes: nil
  )
 
  self.presetsURL = appFolder.appendingPathComponent("presets.json")
 
  // Load existing user presets.
  loadUserPresets()
  }
 
  // MARK: - Slot access
 
  /// Returns the preset at the given slot, or nil if empty.
  func preset(at slot: Int) -> Preset? {
  guard slot >= 0, slot < PresetBank.slotCount else { return nil }
  return userPresets[slot]
  }
 
  /// Whether the slot is occupied by a user preset.
  func isOccupied(_ slot: Int) -> Bool {
  guard slot >= 0, slot < PresetBank.slotCount else { return false }
  return userPresets[slot] != nil
  }
 
  // MARK: - Load / Save / Clear
 
  /// Loads the preset at the given slot into the engine.
  /// Returns the preset, or nil if the slot is empty.
  func loadPreset(at slot: Int, into engine: SynthEngine) -> Preset? {
  guard let preset = userPresets[slot] else { return nil }
  engine.load(preset: preset)
  selectedSlot = slot
  return preset
  }
 
  /// Saves the current engine state as a preset in the given slot.
  func savePreset(_ preset: Preset, at slot: Int) {
  guard slot >= 0, slot < PresetBank.slotCount else { return }
  userPresets[slot] = preset
  selectedSlot = slot
  saveUserPresets()
  }
 
  /// Clears the preset at the given slot.
  func clearPreset(at slot: Int) {
  guard slot >= 0, slot < PresetBank.slotCount else { return }
  userPresets[slot] = nil
  saveUserPresets()
  }
 
  /// Renames the preset at the given slot.
  func renamePreset(at slot: Int, to name: String) {
  guard slot >= 0, slot < PresetBank.slotCount,
  var preset = userPresets[slot] else { return }
  preset.name = name
  userPresets[slot] = preset
  saveUserPresets()
  }
 
  // MARK: - Factory preset loading
 
  /// Copies a factory preset into a user slot.
  func loadFactoryPreset(_ index: Int, intoSlot slot: Int, into engine: SynthEngine) {
  guard index >= 0, index < factoryPresets.count,
  slot >= 0, slot < PresetBank.slotCount else { return }
  let factory = factoryPresets[index]
  userPresets[slot] = factory
  engine.load(preset: factory)
  selectedSlot = slot
  saveUserPresets()
  }
 
  // MARK: - Persistence
 
  private func loadUserPresets() {
  guard FileManager.default.fileExists(atPath: presetsURL.path) else { return }
 
  do {
  let data = try Data(contentsOf: presetsURL)
  let decoded = try JSONDecoder().decode([Preset?].self, from: data)
  // Ensure array is the right size.
  var presets = Array(repeating: Preset?.none, count: PresetBank.slotCount)
  for (index, preset) in decoded.enumerated() where index < PresetBank.slotCount {
  presets[index] = preset
  }
  self.userPresets = presets
  } catch {
  print("Failed to load user presets: \(error.localizedDescription)")
  }
  }
 
  private func saveUserPresets() {
  do {
  let data = try JSONEncoder().encode(userPresets)
  try data.write(to: presetsURL, options: .atomic)
  } catch {
  print("Failed to save user presets: \(error.localizedDescription)")
  }
  }
}
