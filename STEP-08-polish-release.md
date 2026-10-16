# Step 8 — Polish & Release (DEFERRED — post-v1)

**Suggested LLM:** Any lightweight model (Nemotron, GPT-4o-mini, Claude Haiku) 
**Status:** deferred 
**Depends on:** Steps 1–5 complete (v1 MVP), Steps 3/6/7 optional

## Goal
Performance tuning, bug fixes, app icon, About window, code signing/notarization notes.

## Prerequisites
- App runs end-to-end: engine + UI + presets

## Deliverables
- CPU performance acceptable at 12 voices + FX (if enabled)
- No clicks/pops on note on/off or preset changes
- App icon + About window
- Dark Mode support
- Accessibility basics
- Build/archive checklist

## Detailed tasks
### 8.1 Performance
- Profile with Xcode Instruments (Time Profiler)
- Optimize audio render block if CPU too high (consider single shared rendering node instead of per-voice nodes)
- Reduce allocations in render loop

### 8.2 Click/pop fixes
- Ensure all note-offs go through release envelope
- Ramp volume changes over a few samples instead of instant jumps

### 8.3 UI polish
- App icon (`Assets.xcassets`)
- About window (version, copyright)
- Dark Mode aware colors
- Keyboard and knob accessibility labels

### 8.4 Build & distribute
- Archive build
- Code sign / notarize if distributing outside App Store (personal use: ad-hoc signing is fine)
- `Synthesizer.entitlements` review (Application Support access)

## Files to modify
- `Synthesizer/Assets.xcassets` — app icon
- `Synthesizer/AboutView.swift` (create)
- `Synthesizer.entitlements` — review
- `MASTER-PLAN.md` — mark Step 8 complete

## Definition of done
- [ ] App builds and runs smoothly
- [ ] No audible artifacts
- [ ] App icon + About window present
- [ ] Step 8 marked complete in `MASTER-PLAN.md`

## Done
v1 of the 6-operator FM synthesizer is complete.
