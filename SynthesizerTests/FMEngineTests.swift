//
// FMEngineTests.swift
// SynthesizerTests
//
// Unit tests for the FM synthesis engine core (Step 1).
// Tests oscillator, envelope, algorithms, and voice allocation.
// Does not require AVAudioEngine to be running.
//

import XCTest
@testable import Synthesizer

final class FMEngineTests: XCTestCase {

 // MARK: - midiNoteToFreq

 func testMidiNoteToFreq_A4Is440Hz() {
 let freq = midiNoteToFreq(midiNumber: 69) // A4
 XCTAssertEqual(freq, 440.0, accuracy: 0.01)
 }

 func testMidiNoteToFreq_A5Is880Hz() {
 let freq = midiNoteToFreq(midiNumber: 81) // A5
 XCTAssertEqual(freq, 880.0, accuracy: 0.1)
 }

 func testMidiNoteToFreq_C0IsAbout16Hz() {
 let freq = midiNoteToFreq(midiNumber: 24) // C1
 XCTAssertEqual(freq, 32.70, accuracy: 0.05)
 }

 func testMidiNoteToFreq_SemitoneRatio() {
 let a4 = midiNoteToFreq(midiNumber: 69)
 let aSharp4 = midiNoteToFreq(midiNumber: 70)
 let ratio = aSharp4 / a4
 XCTAssertEqual(ratio, pow(2.0, 1.0 / 12.0), accuracy: 0.001)
 }

 // MARK: - PhaseOscillator

 func testOscillatorProducesSineWave() {
 let osc = PhaseOscillator(sampleRate: 44100)
 osc.frequency = 440.0
 let sample1 = osc.nextSample()
 let sample2 = osc.nextSample()
 // First sample should be sin(0) = 0
 XCTAssertEqual(sample1, 0.0, accuracy: 0.001)
 // Second sample should be sin(phaseIncrement) > 0 for 440 Hz at 44.1k
 XCTAssertGreaterThan(sample2, 0)
 }

 func testOscillatorPhaseWraps() {
 let osc = PhaseOscillator(sampleRate: 44100)
 osc.frequency = 44100.0 / (2.0 * Float.pi) // 1 radian per sample
 var phases: [Float] = []
 for _ in 0..<100 {
 _ = osc.nextSample()
 phases.append(osc.phase)
 }
 // Phase should always be in [0, 2*pi)
 for phase in phases {
 XCTAssertGreaterThanOrEqual(phase, 0.0)
 XCTAssertLessThan(phase, 2.0 * Float.pi)
 }
 }

 func testOscillatorResetPhase() {
 let osc = PhaseOscillator(sampleRate: 44100)
 osc.frequency = 440.0
 _ = osc.nextSample()
 _ = osc.nextSample()
 XCTAssertNotEqual(osc.phase, 0.0)
 osc.resetPhase()
 XCTAssertEqual(osc.phase, 0.0)
 }

 // MARK: - Envelope

 func testEnvelopeAttackReachesPeak() {
 let osc = PhaseOscillator(sampleRate: 44100)
 let op = Operator(index: 0, sampleRate: 44100)
 op.attack = 0.01 // 10 ms
 op.decay = 0
 op.sustain = 1.0
 op.release = 0
 op.noteOn(velocity: 127, noteFrequency: 440.0)

 // Render enough samples to cover the attack phase
 let attackSamples = Int(0.01 * 44100) + 10
 var reachedPeak = false
 for _ in 0..<attackSamples {
 let sample = op.render(modulationInput: 0)
 if op.envelopeValue >= 0.99 {
 reachedPeak = true
 break
 }
 }
 XCTAssertTrue(reachedPeak, "Envelope should reach peak during attack")
 }

 func testEnvelopeReleaseGoesToZero() {
 let osc = PhaseOscillator(sampleRate: 44100)
 let op = Operator(index: 0, sampleRate: 44100)
 op.attack = 0
 op.decay = 0
 op.sustain = 0.5
 op.release = 0.01
 op.noteOn(velocity: 127, noteFrequency: 440.0)

 // Let it reach sustain
 for _ in 0..<10 {
 _ = op.render(modulationInput: 0)
 }
 XCTAssertEqual(op.envelopeState, .sustain)
 XCTAssertGreaterThan(op.envelopeValue, 0)

 // Release
 op.noteOff()
 let releaseSamples = Int(0.01 * 44100) + 10
 for _ in 0..<releaseSamples {
 _ = op.render(modulationInput: 0)
 }
 XCTAssertEqual(op.envelopeState, .off)
 XCTAssertEqual(op.envelopeValue, 0, accuracy: 0.001)
 }

 // MARK: - Algorithms

 func testAlgorithmCountIs32() {
 XCTAssertEqual(fmAlgorithms.count, 32)
 XCTAssertEqual(fmAlgorithmCount, 32)
 }

 func testAlgorithm1HasFeedback() {
 let alg = fmAlgorithms[0] // Algorithm 1
 XCTAssertNotNil(alg.feedbackOperator)
 XCTAssertEqual(alg.feedbackOperator, 5)
 XCTAssertEqual(alg.carriers, [5])
 XCTAssertFalse(alg.modulations.isEmpty)
 }

 func testAlgorithm24IsAllCarriers() {
 let alg = fmAlgorithms[23] // Algorithm 24
 XCTAssertEqual(alg.carriers, [0, 1, 2, 3, 4, 5])
 XCTAssertTrue(alg.modulations.isEmpty)
 XCTAssertNil(alg.feedbackOperator)
 }

 func testAlgorithmHasValidOperatorIndices() {
 for alg in fmAlgorithms {
 for carrier in alg.carriers {
 XCTAssertGreaterThanOrEqual(carrier, 0)
 XCTAssertLessThan(carrier, 6)
 }
 for mod in alg.modulations {
 XCTAssertGreaterThanOrEqual(mod.source, 0)
 XCTAssertLessThan(mod.source, 6)
 XCTAssertGreaterThanOrEqual(mod.target, 0)
 XCTAssertLessThan(mod.target, 6)
 }
 if let fb = alg.feedbackOperator {
 XCTAssertGreaterThanOrEqual(fb, 0)
 XCTAssertLessThan(fb, 6)
 }
 }
 }

 // MARK: - Voice

 func testVoiceProducesSoundOnNoteOn() {
 let voice = Voice(sampleRate: 44100, algorithm: fmAlgorithms[0])
 voice.noteOn(midiNote: 69, velocity: 100, baseFrequency: 440.0)

 let samples = voice.render(frameCount: 441)
 let maxAbs = samples.map { abs($0) }.max() ?? 0
 XCTAssertGreaterThan(maxAbs, 0.001, "Voice should produce non-zero output when note is on")
 }

 func testVoiceSilencesOnNoteOff() {
 let voice = Voice(sampleRate: 44100, algorithm: fmAlgorithms[0])
 voice.noteOn(midiNote: 69, velocity: 100, baseFrequency: 440.0)

 let onSamples = voice.render(frameCount: 441)
 let onMax = onSamples.map { abs($0) }.max() ?? 0
 XCTAssertGreaterThan(onMax, 0.001)

 voice.noteOff()
 let releaseSamples = voice.render(frameCount: 44100) // ~1 second
 // Check the tail of the buffer — release takes up to 0.5s,
 // so the last half-second should be silent.
 let tailSamples = Array(releaseSamples.suffix(22050))
 let tailMax = tailSamples.map { abs($0) }.max() ?? 0
 XCTAssertLessThan(tailMax, 0.001, "Voice should be silent after release completes")
 }

 func testVoiceIsFreeInitially() {
 let voice = Voice(sampleRate: 44100, algorithm: fmAlgorithms[0])
 XCTAssertEqual(voice.state, .free)
 XCTAssertTrue(voice.isSilent)
 }

 func testVoiceStateTransitions() {
 let voice = Voice(sampleRate: 44100, algorithm: fmAlgorithms[0])
 XCTAssertEqual(voice.state, .free)

 voice.noteOn(midiNote: 60, velocity: 80, baseFrequency: 261.63)
 XCTAssertEqual(voice.state, .active)
 XCTAssertEqual(voice.midiNote, 60)

 voice.noteOff()
 XCTAssertEqual(voice.state, .releasing)

 // Render enough to complete release
 _ = voice.render(frameCount: Int(2.0 * 44100))
 XCTAssertEqual(voice.state, .free)
 XCTAssertTrue(voice.isSilent)
 }

 // MARK: - Operator configuration

 func testOperatorConfiguredWithParams() {
 let voice = Voice(sampleRate: 44100, algorithm: fmAlgorithms[0])
 let params: [(Float, Float, Float, Float, Float, Float, Float)] = [
 (1.0, 0, 1.0, 0.1, 0.1, 0.5, 0.5),
 (2.0, 0, 0.8, 0.1, 0.1, 0.5, 0.5),
 (3.0, 0, 0.6, 0.1, 0.1, 0.5, 0.5),
 (4.0, 0, 0.4, 0.1, 0.1, 0.5, 0.5),
 (5.0, 0, 0.3, 0.1, 0.1, 0.5, 0.5),
 (6.0, 0, 0.2, 0.1, 0.1, 0.5, 0.5),
 ]
 voice.configureOperators(params)
 XCTAssertEqual(voice.operators[0].ratio, 1.0)
 XCTAssertEqual(voice.operators[1].ratio, 2.0)
 XCTAssertEqual(voice.operators[5].level, 0.2)
 }
}
