//
// Algorithms.swift
// Synthesizer
//
// 32 FM synthesis algorithms (DX7-style operator routing).
//
// Each algorithm defines how the 6 operators (indexed 0–5) connect:
// - Carriers: operators whose output is summed to the voice output.
// - Modulations: (source, target, index) meaning operator `source`
// frequency-modulates operator `target` with the given modulation index.
// - Feedback: an operator that modulates itself (one-sample delay to avoid
// a direct feedback loop).
//

import Foundation

/// A single modulation connection: source operator modulates target operator.
struct ModulationConnection {
  /// Index of the modulating operator (0..<6).
  let source: Int
  /// Index of the modulated operator (0..<6).
  let target: Int
  /// Modulation index (0...1+). Higher = stronger frequency modulation.
  let index: Float
}

/// Describes one FM algorithm routing topology.
struct FMAlgorithm {
    /// Human-readable name.
    let name: String
    /// Operator indices that are carriers (output summed to mix).
    let carriers: [Int]
    /// Modulation connections between operators.
    let modulations: [ModulationConnection]
    /// Optional operator index that has self-feedback.
    let feedbackOperator: Int?
    /// Feedback level (0...1), only used if feedbackOperator is set.
    let feedbackLevel: Float
    
    /// Returns modulation connections for a given source operator.
    func modulationsFrom(source: Int) -> [ModulationConnection] {
        return modulations.filter { $0.source == source }
    }
}

/// All 32 FM algorithms (DX7-style).
///
/// Operator numbering: 0–5. In most DX7 algorithms, operator 5 (the 6th)
/// is the final carrier, and feedback is typically on operator 5.
let fmAlgorithms: [FMAlgorithm] = [

    // MARK: - Algorithms 1–8: Series chains with feedback/modulation variations

    FMAlgorithm(
        name: "Alg 1: Series + Feedback",
        carriers: [5],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 1, target: 2, index: 1.0),
            ModulationConnection(source: 2, target: 3, index: 1.0),
            ModulationConnection(source: 3, target: 4, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
        ],
        feedbackOperator: 5,
        feedbackLevel: 0.5
    ),

    FMAlgorithm(
        name: "Alg 2: Series + Op0→Op5",
        carriers: [5],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 1, target: 2, index: 1.0),
            ModulationConnection(source: 2, target: 3, index: 1.0),
            ModulationConnection(source: 3, target: 4, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
            ModulationConnection(source: 0, target: 5, index: 0.5),
        ],
        feedbackOperator: nil,
        feedbackLevel: 0
    ),

    FMAlgorithm(
        name: "Alg 3: Series + Op1→Op5",
        carriers: [5],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 1, target: 2, index: 1.0),
            ModulationConnection(source: 2, target: 3, index: 1.0),
            ModulationConnection(source: 3, target: 4, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
            ModulationConnection(source: 1, target: 5, index: 0.5),
        ],
        feedbackOperator: nil,
        feedbackLevel: 0
    ),

    FMAlgorithm(
        name: "Alg 4: Series + Op2→Op5",
        carriers: [5],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 1, target: 2, index: 1.0),
            ModulationConnection(source: 2, target: 3, index: 1.0),
            ModulationConnection(source: 3, target: 4, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
            ModulationConnection(source: 2, target: 5, index: 0.5),
        ],
        feedbackOperator: nil,
        feedbackLevel: 0
    ),

    FMAlgorithm(
        name: "Alg 5: Series + Op3→Op5",
        carriers: [5],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 1, target: 2, index: 1.0),
            ModulationConnection(source: 2, target: 3, index: 1.0),
            ModulationConnection(source: 3, target: 4, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
            ModulationConnection(source: 3, target: 5, index: 0.5),
        ],
        feedbackOperator: nil,
        feedbackLevel: 0
    ),

    FMAlgorithm(
        name: "Alg 6: Series + Op4→Op5",
        carriers: [5],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 1, target: 2, index: 1.0),
            ModulationConnection(source: 2, target: 3, index: 1.0),
            ModulationConnection(source: 3, target: 4, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 0.5),
        ],
        feedbackOperator: nil,
        feedbackLevel: 0
    ),

    FMAlgorithm(
        name: "Alg 7: Dual series 0→1→3→5 + 2→4→5",
        carriers: [5],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 1, target: 3, index: 1.0),
            ModulationConnection(source: 3, target: 5, index: 1.0),
            ModulationConnection(source: 2, target: 4, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
        ],
        feedbackOperator: nil,
        feedbackLevel: 0
    ),

    FMAlgorithm(
        name: "Alg 8: 0→1→2→3→5 + 4→5",
        carriers: [5],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 1, target: 2, index: 1.0),
            ModulationConnection(source: 2, target: 3, index: 1.0),
            ModulationConnection(source: 3, target: 5, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
        ],
        feedbackOperator: nil,
        feedbackLevel: 0
    ),

    // MARK: - Algorithms 9–16: Split carriers and parallel paths

    FMAlgorithm(
        name: "Alg 9: 0→1→2→5 + 3→4→5",
        carriers: [5],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 1, target: 2, index: 1.0),
            ModulationConnection(source: 2, target: 5, index: 1.0),
            ModulationConnection(source: 3, target: 4, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
        ],
        feedbackOperator: nil,
        feedbackLevel: 0
    ),

    FMAlgorithm(
        name: "Alg 10: Carriers 3+5, 0→1→2→3, 4→5",
        carriers: [3, 5],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 1, target: 2, index: 1.0),
            ModulationConnection(source: 2, target: 3, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
        ],
        feedbackOperator: nil,
        feedbackLevel: 0
    ),

    FMAlgorithm(
        name: "Alg 11: Carriers 2+5, 0→1→2, 3→4→5",
        carriers: [2, 5],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 1, target: 2, index: 1.0),
            ModulationConnection(source: 3, target: 4, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
        ],
        feedbackOperator: nil,
        feedbackLevel: 0
    ),

    FMAlgorithm(
        name: "Alg 12: Carriers 1+5, 0→1, 2→3→4→5",
        carriers: [1, 5],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 2, target: 3, index: 1.0),
            ModulationConnection(source: 3, target: 4, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
        ],
        feedbackOperator: nil,
        feedbackLevel: 0
    ),

    FMAlgorithm(
        name: "Alg 13: Carrier 5 only, 0→1→2→3→4→5 + feedback",
        carriers: [5],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 1, target: 2, index: 1.0),
            ModulationConnection(source: 2, target: 3, index: 1.0),
            ModulationConnection(source: 3, target: 4, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
        ],
        feedbackOperator: 5,
        feedbackLevel: 0.7
    ),

    FMAlgorithm(
        name: "Alg 14: 0→1→5, 2→3→5, 4→5",
        carriers: [5],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 1, target: 5, index: 1.0),
            ModulationConnection(source: 2, target: 3, index: 1.0),
            ModulationConnection(source: 3, target: 5, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
        ],
        feedbackOperator: nil,
        feedbackLevel: 0
    ),

    FMAlgorithm(
        name: "Alg 15: 0→5, 1→2→3→4→5",
        carriers: [5],
        modulations: [
            ModulationConnection(source: 0, target: 5, index: 1.0),
            ModulationConnection(source: 1, target: 2, index: 1.0),
            ModulationConnection(source: 2, target: 3, index: 1.0),
            ModulationConnection(source: 3, target: 4, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
        ],
        feedbackOperator: nil,
        feedbackLevel: 0
    ),

    FMAlgorithm(
        name: "Alg 16: All operators modulate 5, no chain",
        carriers: [5],
        modulations: [
            ModulationConnection(source: 0, target: 5, index: 0.5),
            ModulationConnection(source: 1, target: 5, index: 0.5),
            ModulationConnection(source: 2, target: 5, index: 0.5),
            ModulationConnection(source: 3, target: 5, index: 0.5),
            ModulationConnection(source: 4, target: 5, index: 0.5),
        ],
        feedbackOperator: nil,
        feedbackLevel: 0
    ),

    // MARK: - Algorithms 17–24: Multiple carriers

    FMAlgorithm(
        name: "Alg 17: Carriers 4+5, 0→1→2→3→4",
        carriers: [4, 5],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 1, target: 2, index: 1.0),
            ModulationConnection(source: 2, target: 3, index: 1.0),
            ModulationConnection(source: 3, target: 4, index: 1.0),
        ],
        feedbackOperator: nil,
        feedbackLevel: 0
    ),

    FMAlgorithm(
        name: "Alg 18: Carriers 3+5, 0→1→2→3, 4→5",
        carriers: [3, 5],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 1, target: 2, index: 1.0),
            ModulationConnection(source: 2, target: 3, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
        ],
        feedbackOperator: nil,
        feedbackLevel: 0
    ),

    FMAlgorithm(
        name: "Alg 19: Carriers 2+5, 0→1→2, 3→4→5",
        carriers: [2, 5],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 1, target: 2, index: 1.0),
            ModulationConnection(source: 3, target: 4, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
        ],
        feedbackOperator: nil,
        feedbackLevel: 0
    ),

    FMAlgorithm(
        name: "Alg 20: Carriers 1+5, 0→1, 2→3→4→5",
        carriers: [1, 5],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 2, target: 3, index: 1.0),
            ModulationConnection(source: 3, target: 4, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
        ],
        feedbackOperator: nil,
        feedbackLevel: 0
    ),

    FMAlgorithm(
        name: "Alg 21: Carriers 0+5, 1→2→3→4→5",
        carriers: [0, 5],
        modulations: [
            ModulationConnection(source: 1, target: 2, index: 1.0),
            ModulationConnection(source: 2, target: 3, index: 1.0),
            ModulationConnection(source: 3, target: 4, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
        ],
        feedbackOperator: nil,
        feedbackLevel: 0
    ),

    FMAlgorithm(
        name: "Alg 22: Carriers 2+4, 0→1→2, 3→4, 5 alone",
        carriers: [2, 4],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 1, target: 2, index: 1.0),
            ModulationConnection(source: 3, target: 4, index: 1.0),
        ],
        feedbackOperator: nil,
        feedbackLevel: 0
    ),

    FMAlgorithm(
        name: "Alg 23: Carriers 1+3+5, 0→1, 2→3, 4→5",
        carriers: [1, 3, 5],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 2, target: 3, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
        ],
        feedbackOperator: nil,
        feedbackLevel: 0
    ),

    FMAlgorithm(
        name: "Alg 24: All carriers (additive synthesis)",
        carriers: [0, 1, 2, 3, 4, 5],
        modulations: [],
        feedbackOperator: nil,
        feedbackLevel: 0
    ),

    // MARK: - Algorithms 25–32: Complex routings with feedback

    FMAlgorithm(
        name: "Alg 25: 0→1→2→3→4→5 with feedback on 4",
        carriers: [5],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 1, target: 2, index: 1.0),
            ModulationConnection(source: 2, target: 3, index: 1.0),
            ModulationConnection(source: 3, target: 4, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
        ],
        feedbackOperator: 4,
        feedbackLevel: 0.5
    ),

    FMAlgorithm(
        name: "Alg 26: 0→1→5, 2→3→4→5 with feedback on 5",
        carriers: [5],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 1, target: 5, index: 1.0),
            ModulationConnection(source: 2, target: 3, index: 1.0),
            ModulationConnection(source: 3, target: 4, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
        ],
        feedbackOperator: 5,
        feedbackLevel: 0.4
    ),

    FMAlgorithm(
        name: "Alg 27: 0→2→4→5 + 1→3→5",
        carriers: [5],
        modulations: [
            ModulationConnection(source: 0, target: 2, index: 1.0),
            ModulationConnection(source: 2, target: 4, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
            ModulationConnection(source: 1, target: 3, index: 1.0),
            ModulationConnection(source: 3, target: 5, index: 1.0),
        ],
        feedbackOperator: nil,
        feedbackLevel: 0
    ),

    FMAlgorithm(
        name: "Alg 28: 0→1→2→5 + 3→4→5 + feedback on 2",
        carriers: [5],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 1, target: 2, index: 1.0),
            ModulationConnection(source: 2, target: 5, index: 1.0),
            ModulationConnection(source: 3, target: 4, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
        ],
        feedbackOperator: 2,
        feedbackLevel: 0.4
    ),

    FMAlgorithm(
        name: "Alg 29: 0→5, 1→2→5, 3→4→5",
        carriers: [5],
        modulations: [
            ModulationConnection(source: 0, target: 5, index: 0.7),
            ModulationConnection(source: 1, target: 2, index: 1.0),
            ModulationConnection(source: 2, target: 5, index: 1.0),
            ModulationConnection(source: 3, target: 4, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
        ],
        feedbackOperator: nil,
        feedbackLevel: 0
    ),

    FMAlgorithm(
        name: "Alg 30: 0→1→3→5 + 2→4→5 + feedback on 5",
        carriers: [5],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 1, target: 3, index: 1.0),
            ModulationConnection(source: 3, target: 5, index: 1.0),
            ModulationConnection(source: 2, target: 4, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
        ],
        feedbackOperator: 5,
        feedbackLevel: 0.5
    ),

    FMAlgorithm(
        name: "Alg 31: 0→1→2→3→5 + feedback on 3, 4→5",
        carriers: [5],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 1, target: 2, index: 1.0),
            ModulationConnection(source: 2, target: 3, index: 1.0),
            ModulationConnection(source: 3, target: 5, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
        ],
        feedbackOperator: 3,
        feedbackLevel: 0.4
    ),

    FMAlgorithm(
        name: "Alg 32: 0→1→2→3→4→5 + feedback on 5 (strong)",
        carriers: [5],
        modulations: [
            ModulationConnection(source: 0, target: 1, index: 1.0),
            ModulationConnection(source: 1, target: 2, index: 1.0),
            ModulationConnection(source: 2, target: 3, index: 1.0),
            ModulationConnection(source: 3, target: 4, index: 1.0),
            ModulationConnection(source: 4, target: 5, index: 1.0),
        ],
        feedbackOperator: 5,
        feedbackLevel: 0.8
    ),
]

/// Total number of algorithms.
let fmAlgorithmCount: Int = fmAlgorithms.count
