# Sahayak — an offline AI health worker in every pocket

**Phase 1 prototype · iQOO Hackathon 2026 (Hyderabad City Battle)**

India has ~1 million ASHA community health workers covering villages with
paper forms, no connectivity, and no diagnostic support. Sahayak turns the
phone in their pocket into an offline copilot: **camera + voice + a local
LLM running fully on-device**. No cloud, no per-query cost, works at zero
bars — and health data never leaves the phone.

## What works in this prototype (vertical slice)

| Module | Chain | Status |
|---|---|---|
| **Medicine Lens** | Camera → on-device OCR (ML Kit) → local LLM explanation → spoken answer (TTS) | ✅ working |
| **Voice Triage** | Speech-to-text → local LLM → structured JSON (urgency / advice / referral note) → spoken back | ✅ working |
| **Model Manager** | Import any GGUF, hot-swap models at runtime | ✅ working |
| **Prompt Lab** | On-device prompt editing + quick test + tokens/sec — the phone is the dev workstation | ✅ working |

Everything AI runs **offline**. Demo with airplane mode ON.

## Architecture

```
UI (Flutter, Material 3)
        │
ModelEngine interface          ← screens never know which model runs
   ├─ LlamaEngine  → llama.cpp via fllama (Dart FFI)   ← any GGUF model
   └─ DemoEngine   → clearly-labeled canned output (UX demo before a model is loaded)
        │
Perception: ML Kit OCR (on-device) · platform speech-to-text
Output:     platform TTS (English / हिंदी / తెలుగు)
State:      shared_preferences (prompts, model path, language)
```

**Model-agnostic by design.** The chat template ships inside GGUF metadata
and llama.cpp applies it, so Qwen3 0.6B, Gemma, IBM Granite Nano, MiniCPM,
Sarvam-1 — all load through the same Model Manager screen with zero code
changes. Swapping models is a file import, not a refactor.

**Low-end first.** Inference is CPU-first (ARM NEON) with GPU offload where
available, so the same APK runs on a ₹8,000 phone and the iQOO 15:

- 3–4 GB RAM → 0.3–1B models @ Q4 (Qwen3 0.6B, Granite Nano, Gemma 1B)
- 6–8 GB RAM → 1–2B models (Gemma 2B, Sarvam-1 2B)
- Flagship → 2–4B models, GPU/NPU accelerated

## Run it

```bash
flutter pub get
flutter run            # device or emulator; CMake required on the host
```

The app starts in **demo mode** (canned responses, clearly labeled) so the
UX is demoable immediately. For real on-device AI:

1. Download a small GGUF, e.g.
   [Qwen3-0.6B Q4_K_M](https://huggingface.co/Qwen/Qwen3-0.6B-GGUF) or
   [Gemma via ggml-org](https://huggingface.co/ggml-org) collections.
2. Copy it to the phone (or download on-device).
3. App → **Model Manager → Import GGUF model file**.

Release APK (arm64): see the **Releases** tab, or build with
`flutter build apk --release --target-platform android-arm64`.

## Honest scope note (for reviewers)

This repo is the **pre-event feasibility spike** submitted for Phase 1
shortlisting — it proves the risky plumbing (local GGUF inference, OCR, voice
I/O on Android) end-to-end. The competition build happens during the 30-hour
City Battle on this same repo; the pre-event state is tagged
[`pre-event`](../../releases) for transparent before/after comparison.

## 30-hour battle roadmap

- Whisper-class on-device STT for stronger Indic speech (current: platform STT)
- ASHA visit workflow: patient record → auto-filled govt health form → PDF
- Camera screening module (reference-band MUAC check for child malnutrition)
- Sarvam-1 2B as the default Indic model; NPU path via ONNX Runtime QNN
- Red-Light-window tooling: everything above tunable from the on-device Prompt Lab

## License note

Depends on [fllama](https://github.com/Telosnex/fllama) (GPL-2.0) and
[llama.cpp](https://github.com/ggml-org/llama.cpp) (MIT). If GPL matters for
a future distribution, any FFI llama.cpp binding can replace it behind the
`ModelEngine` interface.

---
*Sahayak is a screening aid, never a diagnosis. Danger signs always mean
immediate referral.*
