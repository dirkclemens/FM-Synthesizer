//
// Arpeggiator.swift
// Synthesizer
//
// Arpeggiator: cycles through held notes in various patterns.
// Outputs note on/off events to SynthEngine.
//

import Foundation

/// Arpeggiator modes.
enum ArpMode: Int, CaseIterable, Codable {
    case up // lowest → highest
    case down // highest → lowest
    case upDown // lowest → highest → lowest
    case random // random note from held set
    case ordered // in order notes were pressed
    case chord // all held notes simultaneously
    case noteRepeat // repeat the last note
}

/// The arpeggiator generates note on/off events based on held notes.
final class Arpeggiator: ObservableObject {
 
    /// Reference to the synth engine for note output.
    weak var engine: SynthEngine?
 
    /// Whether the arpeggiator is running.
    @Published private(set) var isRunning: Bool = false
 
    /// Current mode.
    @Published var mode: ArpMode = .up {
        didSet { resetPosition() }
    }
 
    /// Rate in notes per second (0.5...20).
    @Published var rate: Float = 4.0
 
    /// Gate length as fraction of step (0.1...1.0).
    @Published var gate: Float = 0.7
 
    /// Octave range (1...4).
    @Published var octaveRange: Int = 1
 
    /// Currently held notes (latched from keyboard/MIDI).
    private(set) var heldNotes: Set<UInt8> = []
 
    /// Order notes were pressed (for .ordered mode).
    private var noteOrder: [UInt8] = []
 
    /// Current position in the note sequence.
    private var position: Int = 0
 
    /// Direction for .upDown mode (1 = up, -1 = down).
    private var direction: Int = 1
 
    /// Timer for arpeggiation.
    private var timer: Timer?
 
    /// Last note played (for .noteRepeat and .chord modes).
    private var lastNote: UInt8 = 60
 
    /// Whether notes are currently sounding (gate phase).
    private var notesSounding: Set<UInt8> = []
 
    init(engine: SynthEngine? = nil) {
        self.engine = engine
    }
 
    // MARK: - Note holding
 
    /// Holds a note (called on key down).
    /// When the arpeggiator is running, the note is added to the held set
    /// and will be played on the next tick — it is not played immediately
    /// to avoid rapid note on/off cycling with the timer.
    func holdNote(_ note: UInt8) {
        heldNotes.insert(note)
        if !noteOrder.contains(note) {
            noteOrder.append(note)
        }
        resetPosition()
    }
 
    /// Releases a held note (called on key up).
    func releaseNote(_ note: UInt8) {
        heldNotes.remove(note)
        noteOrder.removeAll { $0 == note }
        notesSounding.remove(note)
        engine?.noteOff(midiNote: note)
        resetPosition()
    }
 
    /// Release all held notes.
    func releaseAll() {
        for note in notesSounding {
            engine?.noteOff(midiNote: note)
        }
        notesSounding.removeAll()
        heldNotes.removeAll()
        noteOrder.removeAll()
        position = 0
    }
 
    // MARK: - Start / Stop
 
    func start() {
        guard !isRunning else { return }
        isRunning = true
        position = 0
        direction = 1
        startTimer()
        // Play the first held note immediately so there's no delay
        // between turning on the arpeggiator and hearing sound.
        if !heldNotes.isEmpty {
            let sortedNotes = heldNotes.sorted()
            playNote(sortedNotes[0])
            // Release after gate duration
            let interval = 1.0 / Double(rate)
            let gateSeconds = interval * Double(gate)
            DispatchQueue.main
                .asyncAfter(deadline: .now() + gateSeconds) { [weak self] in
                    self?.engine?.noteOff(midiNote: sortedNotes[0])
                    self?.notesSounding.remove(sortedNotes[0])
                }
        }
    }
 
    func stop() {
        isRunning = false
        stopTimer()
        // Release all sounding notes.
        for note in notesSounding {
            engine?.noteOff(midiNote: note)
        }
        notesSounding.removeAll()
    }
 
    private func startTimer() {
        stopTimer()
        let interval = 1.0 / Double(rate)
        timer = Timer
            .scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                self?.tick()
            }
    }
 
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
 
    // MARK: - Arpeggiation tick
 
    private func tick() {
        guard isRunning, !heldNotes.isEmpty else { return }
 
        let interval = 1.0 / Double(rate)
        let gateSeconds = interval * Double(gate)
 
        switch mode {
        case .chord:
            // Play all notes simultaneously.
            for note in heldNotes.sorted() {
                engine?.noteOn(midiNote: note, velocity: 100)
                notesSounding.insert(note)
            }
            // Release all chord notes after gate duration
            DispatchQueue.main
                .asyncAfter(deadline: .now() + gateSeconds) { [weak self] in
                    self?.releaseSoundingNotes()
                }
            return // Don't advance position for chord mode
 
        default:
            // Release the previously sounding note (if any) before playing the next one.
            // We only release the last played note, not all held notes — held notes
            // remain available for subsequent ticks.
            releaseLastSoundingNote()

            let sortedNotes = heldNotes.sorted()

            let note: UInt8
            switch mode {
            case .up:
                note = sortedNotes[position % sortedNotes.count]
            case .down:
                let reversed = Array(sortedNotes.reversed())
                note = reversed[position % reversed.count]
            case .upDown:
                note = playUpDownNote(sortedNotes)
            case .random:
                note = sortedNotes.randomElement() ?? 60
            case .ordered:
                guard !noteOrder.isEmpty else { return }
                note = noteOrder[position % noteOrder.count]
            case .noteRepeat:
                note = lastNote
            default:
                note = sortedNotes[position % sortedNotes.count]
            }

            playNote(note)

            // Release this note after gate duration
            DispatchQueue.main
                .asyncAfter(deadline: .now() + gateSeconds) { [
                    weak self,
                    note
                ] in
                    self?.engine?.noteOff(midiNote: note)
                    self?.notesSounding.remove(note)
                }

            advancePosition()
        }
    }
 
    private func playUpDownNote(_ sortedNotes: [UInt8]) -> UInt8 {
        let count = sortedNotes.count
        guard count > 0 else { return 60 }
 
        // Up-down pattern: 0, 1, 2, ..., n-1, n-2, ..., 1, 0, 1, ...
        let cycleLength = max(1, (count - 1) * 2)
        let idx = position % cycleLength
 
        let noteIndex: Int
        if idx < count {
            noteIndex = idx
        } else {
            noteIndex = cycleLength - idx
        }
 
        return sortedNotes[noteIndex]
    }
 
    private func playNote(_ note: UInt8) {
        lastNote = note
        engine?.noteOn(midiNote: note, velocity: 100)
        notesSounding.insert(note)
    }
 
    private func releaseSoundingNotes() {
        for note in notesSounding {
            engine?.noteOff(midiNote: note)
        }
        notesSounding.removeAll()
    }

    /// Releases only the last played note (used between ticks to avoid cutting
    /// off notes that are still being held by the user).
    private func releaseLastSoundingNote() {
        engine?.noteOff(midiNote: lastNote)
        notesSounding.remove(lastNote)
    }
 
    private func advancePosition() {
        position += 1
    }
 
    private func resetPosition() {
        position = 0
        direction = 1
    }
 
    // MARK: - Octave range
 
    /// Applies octave range to held notes (shifts copies up).
    /// This is called when generating notes to create multi-octave arpeggios.
    func notesWithOctaves(_ baseNotes: [UInt8]) -> [UInt8] {
        var result: [UInt8] = []
        for note in baseNotes {
            for octave in 0..<octaveRange {
                let shifted = note + UInt8(octave * 12)
                if shifted <= 108 {
                    result.append(shifted)
                }
            }
        }
        return result.sorted()
    }
}
