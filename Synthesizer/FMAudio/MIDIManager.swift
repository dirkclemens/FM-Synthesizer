//
// MIDIManager.swift
// Synthesizer
//
// CoreMIDI wrapper for the FM synthesizer.
// Enumerates MIDI sources, connects/disconnects, and routes
// MIDI messages to SynthEngine.
//

import Foundation
import CoreMIDI

/// Manages CoreMIDI connections and message routing.
final class MIDIManager: ObservableObject {
 
  /// Reference to the synth engine.
  weak var engine: SynthEngine?
 
  /// MIDI client reference.
  private var midiClient: MIDIClientRef = 0
 
  /// MIDI input port reference.
  private var inputPort: MIDIPortRef = 0
 
  /// Currently connected source endpoint.
  private var connectedSource: MIDIEndpointRef = 0
 
  /// Whether MIDI is connected.
  @Published private(set) var isConnected: Bool = false
 
  /// List of available MIDI source names.
  @Published private(set) var availableSources: [String] = []
 
  /// The currently connected source name (nil if none).
  @Published private(set) var connectedSourceName: String? = nil
 
  init(engine: SynthEngine? = nil) {
  self.engine = engine
  setupMIDIClient()
  refreshSources()
  }
 
  deinit {
  disconnect()
  if midiClient != 0 {
  MIDIClientDispose(midiClient)
  }
  }
 
  // MARK: - MIDI Client Setup
 
  private func setupMIDIClient() {
  var client: MIDIClientRef = 0
  let result = MIDIClientCreate("Synthesizer" as CFString, nil, nil, &client)
  if result == noErr {
  midiClient = client
  } else {
  print("Failed to create MIDI client: \(result)")
  }
  }
 
  // MARK: - Source Enumeration
 
  /// Refreshes the list of available MIDI sources.
  func refreshSources() {
  var sources: [String] = []
  let count = MIDIGetNumberOfSources()
  for i in 0..<count {
  let endpoint = MIDIGetSource(i)
  if let name = getEndpointName(endpoint) {
  sources.append(name)
  }
  }
  availableSources = sources
  }
 
  private func getEndpointName(_ endpoint: MIDIEndpointRef) -> String? {
  var name: Unmanaged<CFString>?
  let result = MIDIObjectGetStringProperty(endpoint, kMIDIPropertyName, &name)
  if result == noErr, let cfString = name?.takeRetainedValue() {
  return cfString as String
  }
  return nil
  }
 
  // MARK: - Connect / Disconnect
 
  /// Connects to a MIDI source by index.
  func connect(to sourceIndex: Int) {
  guard sourceIndex >= 0, sourceIndex < availableSources.count else { return }
  let endpoint = MIDIGetSource(sourceIndex)
  connect(to: endpoint)
  }
 
  /// Connects to a specific MIDI endpoint.
  private func connect(to endpoint: MIDIEndpointRef) {
  disconnect() // Disconnect any existing connection first
 
  var port: MIDIPortRef = 0
  let result = MIDIInputPortCreate(midiClient, "Synthesizer Input" as CFString, { packetList, refCon, _ in
  let manager = Unmanaged<MIDIManager>.fromOpaque(refCon!).takeUnretainedValue()
  manager.processMIDIPacketList(packetList.pointee)
  }, Unmanaged<MIDIManager>.passUnretained(self).toOpaque(), &port)
 
  if result != noErr {
  print("Failed to create MIDI input port: \(result)")
  return
  }
 
  inputPort = port
 
  let connectResult = MIDIPortConnectSource(port, endpoint, nil)
  if connectResult != noErr {
  print("Failed to connect to MIDI source: \(connectResult)")
  return
  }
 
  connectedSource = endpoint
  connectedSourceName = getEndpointName(endpoint)
  isConnected = true
 
  print("Connected to MIDI source: \(connectedSourceName ?? "unknown")")
  }
 
  /// Disconnects from the current MIDI source.
  func disconnect() {
  if inputPort != 0 {
  if connectedSource != 0 {
  MIDIPortDisconnectSource(inputPort, connectedSource)
  }
  MIDIPortDispose(inputPort)
  inputPort = 0
  }
  connectedSource = 0
  connectedSourceName = nil
  isConnected = false
  }
 
  // MARK: - MIDI Message Processing
 
  private func processMIDIPacketList(_ packetList: MIDIPacketList) {
  var packet = packetList.packet
  for _ in 0..<packetList.numPackets {
  processMIDIPacket(packet)
  // Advance manually: each packet has variable-length data after the header
  let packetSize = MemoryLayout<MIDIPacket>.size + Int(packet.length)
  let nextPtr = withUnsafePointer(to: packet) { ptr in
  return UnsafeRawPointer(ptr).advanced(by: packetSize)
  .assumingMemoryBound(to: MIDIPacket.self)
  }
  packet = nextPtr.pointee
  }
  }
 
  private func processMIDIPacket(_ packet: MIDIPacket) {
  // Access packet data via unsafe pointer
  let data: [UInt8] = withUnsafePointer(to: packet.data) { ptr in
  let bytePtr = UnsafeRawPointer(ptr).assumingMemoryBound(to: UInt8.self)
  return Array(UnsafeBufferPointer(start: bytePtr, count: Int(packet.length)))
  }
 
  guard data.count >= 3 else { return }
 
  let status = data[0]
  let byte1 = data[1]
  let byte2 = data.count > 2 ? data[2] : 0
 
  let statusHigh = status & 0xF0
  let channel = status & 0x0F
 
  DispatchQueue.main.async { [weak self] in
  self?.handleMIDIMessage(statusHigh: statusHigh, byte1: byte1, byte2: byte2, channel: channel)
  }
  }
 
  private func handleMIDIMessage(statusHigh: UInt8, byte1: UInt8, byte2: UInt8, channel: UInt8) {
  guard let engine = engine else { return }
 
  switch statusHigh {
  case 0x80: // Note Off
  let note = byte1
  if engine.arpeggiator.isRunning {
  engine.arpeggiator.releaseNote(note)
  } else {
  engine.noteOff(midiNote: note)
  }
 
  case 0x90: // Note On
  let note = byte1
  let velocity = byte2
  if velocity == 0 {
  // Note On with velocity 0 = Note Off
  if engine.arpeggiator.isRunning {
  engine.arpeggiator.releaseNote(note)
  } else {
  engine.noteOff(midiNote: note)
  }
  } else {
  if engine.arpeggiator.isRunning {
  engine.arpeggiator.holdNote(note)
  } else {
  engine.noteOn(midiNote: note, velocity: Float(velocity))
  }
  }
 
  case 0xB0: // Control Change
  let ccNumber = byte1
  let ccValue = byte2
  handleMIDICC(ccNumber: ccNumber, ccValue: ccValue, engine: engine)
 
  case 0xE0: // Pitch Bend
  let lsb = byte1
  let msb = byte2
  let value = (Int(msb) << 7 | Int(lsb)) - 8192 // -8192...8191
  let normalized = Float(value) / 8192.0 // -1...1
  engine.pitchBendValue = normalized
 
  case 0xC0: // Program Change
  let program = byte1
  _ = engine.presetBank?.loadPreset(at: Int(program), into: engine)
  default:
  break
  }
  }
 
  private func handleMIDICC(ccNumber: UInt8, ccValue: UInt8, engine: SynthEngine) {
  let normalized = Float(ccValue) / 127.0
 
  switch ccNumber {
  case 1: // Modulation wheel → LFO rate
  engine.lfoRate = normalized * 20.0
  case 7: // Volume
  engine.volume = normalized
  case 10: // Pan (ignore for now)
  break
  case 11: // Expression
  engine.volume = normalized
  case 64: // Sustain pedal
  if ccValue >= 64 {
  // Sustain on - notes will hold (handled by voice release)
  break
  } else {
  // Sustain off - release all notes
  engine.allNotesOff()
  }
  default:
  break
  }
  }
}
