# Step 3 — Effects Chain (DEFERRED — optional for v1)

**Suggested LLM:** Claude Sonnet 4 / Nemotron 
**Status:** deferred 
**Depends on:** Step 2 complete

## Goal
Add insert effects after the mixer: filter, reverb, delay, distortion, chorus, phaser. Each effect on/off with amount control.

## Prerequisites
- Step 2 complete
- `SynthEngine` with `AVAudioEngine` mixer

## Deliverables
- `Effects.swift` — `AVAudioUnit` chain wrapped in Swift
- Filter (low-pass/high-pass), reverb, delay, distortion, chorus, phaser
- `SynthEngine` exposes `effects` parameters as `@Published`
- Bypass per effect

## Detailed tasks
### 3.1 Effect chain architecture
- `AVAudioUnitEQ` or `AVAudioUnitFilter` for filter
- `AVAudioUnitReverb` for reverb
- Custom `AVAudioUnit` / `AVAudioSourceNode` for delay, distortion, chorus, phaser (or use AVAudioUnitDelay where available)
- Chain: mixer → filter → distortion → chorus → delay → reverb → output (order can be adjusted)

### 3.2 Per-effect controls
- `enabled: Bool`, `amount: Float` (0–1) per effect
- Filter: `cutoff: Float`, `resonance: Float`

### 3.3 Thread-safe updates
- Effect parameters updated from main thread

## Files to create
- `Synthesizer/Effects.swift`

## Files to modify
- `Synthesizer/SynthEngine.swift` — add effects chain nodes
- `MASTER-PLAN.md` — mark Step 3 complete

## Definition of done
- [ ] Each effect toggles on/off without audio glitches
- [ ] Effect amount is audible
- [ ] Step 3 marked complete in `MASTER-PLAN.md`

## Stop here
Presets (Step 5) can proceed independently of effects.
