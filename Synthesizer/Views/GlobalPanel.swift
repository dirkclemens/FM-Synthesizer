//
//  GlobalPanel.swift
//  Synthesizer
//
//  Global synthesizer controls: volume, transpose, algorithm, LFO, feedback, sync.
//

import SwiftUI

struct GlobalPanel: View {
    @ObservedObject var engine: SynthEngine
    
    var body: some View {
        BaseModuleView(
            title: "Global",
            icon: "G",
            color: .blue
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 16) {
                    // Volume
                    Knob(
                        title: "Volume",
                        value: $engine.volume,
                        range: 0...1,
                        step: 0.01,
                        formatter: { String(format: "%.2f", $0) }
                    )
                    
                    // Transpose
                    Knob(
                        title: "Transpose",
                        value: $engine.transpose,
                        range: -24...24,
                        step: 1,
                        formatter: { String(format: "%.0f", $0) }
                    )
                    
                    // Pitch bend range
                    Knob(
                        title: "Bend Range",
                        value: $engine.pitchBendRange,
                        range: 0...24,
                        step: 1,
                        formatter: { String(format: "%.0f", $0) }
                    )
                    
                    // Feedback
                    Knob(
                        title: "Feedback",
                        value: $engine.feedbackLevel,
                        range: 0...1,
                        step: 0.01,
                        formatter: { String(format: "%.2f", $0) }
                    )
                    
                    Spacer()
                    
                    // LFO rate
                    Knob(
                        title: "LFO Rate",
                        value: $engine.lfoRate,
                        range: 0.01...20,
                        step: 0.01,
                        formatter: { String(format: "%.2f", $0) }
                    )
                    
                    // LFO pitch depth
                    Knob(
                        title: "LFO Pitch",
                        value: $engine.lfoPitchDepth,
                        range: 0...1,
                        step: 0.01,
                        formatter: { String(format: "%.2f", $0) }
                    )
                    
                    // LFO amp depth
                    Knob(
                        title: "LFO Amp",
                        value: $engine.lfoAmpDepth,
                        range: 0...1,
                        step: 0.01,
                        formatter: { String(format: "%.2f", $0) }
                    )
                }
                
                Spacer()

                HStack() {
                    // LFO wave
                    Picker("LFO Wave", selection: $engine.lfoWave) {
                        ForEach(LFOWave.allCases, id: \.self) { wave in
                            Text(waveLabel(wave)).tag(wave)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: .infinity)
                    
                    Spacer()
                    
                    // Oscillator sync
                    Toggle("Oscillator Sync", isOn: $engine.oscillatorSync)
                        .font(.caption)
                }

                HStack {
                    Spacer()
                    
                    // Reset button
                    Button("Reset Engine") {
                        engine.reset()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .help("Silence all voices and reset engine state")
                }
            }
        }
    }
    
    private func waveLabel(_ wave: LFOWave) -> String {
        switch wave {
        case .sine: return "Sine"
        case .triangle: return "Triangle"
        case .square: return "Square"
        case .saw: return "Saw"
        case .random: return "Random"
        }
    }
}

struct GlobalPanel_Previews: PreviewProvider {
    static var previews: some View {
        GlobalPanel(engine: SynthEngine())
            .padding()
    }
}
