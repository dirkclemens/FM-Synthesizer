//
// Sequencer.swift
// Synthesizer
//
// 16-step sequencer: programmable note pattern with tempo.
// Outputs note on/off events to SynthEngine.
//

import Foundation

/// A single step in the sequencer.
struct SequencerStep: Codable, Equatable {
 var isOn: Bool = false
 var note: UInt8 = 60
 var velocity: Float = 100
 var gate: Float = 0.7 // fraction of step duration
}

/// The 16-step sequencer generates note events in a loop.
final class Sequencer: ObservableObject {
 
 /// Reference to the synth engine for note output.
 weak var engine: SynthEngine?
 
 /// Number of steps.
 static let stepCount = 16
 
 /// Whether the sequencer is running.
 @Published private(set) var isRunning: Bool = false
 
 /// Tempo in BPM (30...300).
 @Published var tempo: Float = 120.0 {
 didSet { restartTimer() }
 }
 
 /// The 16 steps.
 @Published var steps: [SequencerStep] = Array(repeating: SequencerStep(), count: SequencerStepCount)
 
 /// Current step position (0..<16).
 @Published private(set) var currentStep: Int = 0
 
 /// Timer for sequencer ticks.
 private var timer: Timer?
 
 /// Notes currently sounding (for gate release).
 private var notesSounding: Set<UInt8> = []
 
 init(engine: SynthEngine? = nil) {
 self.engine = engine
 }
 
 // MARK: - Step editing
 
 /// Toggles a step on/off.
 func toggleStep(_ index: Int) {
 guard index >= 0, index < SequencerStepCount else { return }
 var newSteps = steps
 newSteps[index].isOn.toggle()
 steps = newSteps
 }
 
 /// Sets the note for a step.
 func setNote(_ note: UInt8, at index: Int) {
 guard index >= 0, index < SequencerStepCount else { return }
 var newSteps = steps
 newSteps[index].note = note
 steps = newSteps
 }
 
 /// Sets the velocity for a step.
 func setVelocity(_ velocity: Float, at index: Int) {
 guard index >= 0, index < SequencerStepCount else { return }
 var newSteps = steps
 newSteps[index].velocity = max(0, min(127, velocity))
 steps = newSteps
 }
 
 /// Sets the gate for a step.
 func setGate(_ gate: Float, at index: Int) {
 guard index >= 0, index < SequencerStepCount else { return }
 var newSteps = steps
 newSteps[index].gate = max(0.1, min(1.0, gate))
 steps = newSteps
 }
 
 /// Clears all steps.
 func clearAll() {
 steps = Array(repeating: SequencerStep(), count: SequencerStepCount)
 }
 
 // MARK: - Start / Stop
 
 func start() {
 guard !isRunning else { return }
 isRunning = true
 currentStep = 0
 startTimer()
 }
 
 func stop() {
 isRunning = false
 stopTimer()
 // Release all sounding notes.
 for note in notesSounding {
 engine?.noteOff(midiNote: note)
 }
 notesSounding.removeAll()
 currentStep = 0
 }
 
 private func startTimer() {
 stopTimer()
 let interval = stepInterval()
 timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
 self?.tick()
 }
 }
 
 private func stopTimer() {
 timer?.invalidate()
 timer = nil
 }
 
 private func restartTimer() {
 if isRunning {
 startTimer()
 }
 }
 
 /// Step interval in seconds based on tempo.
 private func stepInterval() -> Double {
 // 16th notes: 4 beats per measure, 16 steps = 4 measures of 16th notes
 // Actually, each step is a 16th note, so 4 steps per beat.
 let beatsPerSecond = Double(tempo) / 60.0
 let secondsPerBeat = 1.0 / beatsPerSecond
 let secondsPerStep = secondsPerBeat / 4.0 // 16th note
 return secondsPerStep
 }
 
 // MARK: - Sequencer tick
 
 private func tick() {
 guard isRunning else { return }
 
 // Release notes from previous step (gate).
 releaseSoundingNotes()
 
 // Play current step if active.
 let step = steps[currentStep]
 if step.isOn {
 engine?.noteOn(midiNote: step.note, velocity: step.velocity)
 notesSounding.insert(step.note)
 }
 
 // Advance to next step.
 currentStep = (currentStep + 1) % SequencerStepCount
 }
 
 private func releaseSoundingNotes() {
 for note in notesSounding {
 engine?.noteOff(midiNote: note)
 }
 notesSounding.removeAll()
 }
}

private let SequencerStepCount = 16
