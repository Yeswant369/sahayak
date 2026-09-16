# Sahayak
## An offline AI health worker in every pocket

**iQOO Hackathon 2026 · Hyderabad City Battle · Track: HealthTech**
**Phase 1 Idea Submission — with a working prototype**

Repo: `github.com/<your-username>/sahayak` · APK: Releases → v0.1.0 · Demo video: `<link>`

---

## 1 · The problem

India's last mile of healthcare runs on **~1 million ASHA workers** — community
health workers who walk village to village with paper forms, no diagnostic
support, and often **no network coverage at all**. Meanwhile, the patients they
serve — many with low literacy — routinely misread medicine labels, miss danger
signs, and travel hours to a Primary Health Centre for questions a trained
assistant could answer on the spot.

Cloud AI cannot fix this:

- **No connectivity.** Village visits happen at zero bars. A chatbot that needs
  the internet is useless exactly where it is needed most.
- **No budget.** Per-query API costs don't scale to a million workers making
  daily visits.
- **No trust.** Health conversations are private. Data leaving the phone is a
  barrier to adoption — and a real risk.

## 2 · The solution

**Sahayak turns the phone already in every pocket into an offline AI health
assistant.** Camera, microphone, and a small language model running fully
on-device — no cloud, no cost per question, nothing leaves the phone.

| Module | What it does | Status |
|---|---|---|
| **Medicine Lens** | Point the camera at any medicine strip or prescription → the phone reads it (on-device OCR) and **speaks** what it is, the printed dosage, and warnings — in English, Hindi, or Telugu | ✅ **Built — working in the prototype** |
| **Voice Triage** | The patient describes symptoms by voice → on-device AI returns a cautious screening summary: urgency level (green/amber/red), practical advice, and a ready-to-read **referral note** for the PHC | ✅ **Built — working in the prototype** |
| **Model Manager + Prompt Lab** | Hot-swap any open-source model; tune and test prompts on the phone itself | ✅ **Built — working in the prototype** |
| **Camera screening** | Reference-band mid-upper-arm check for child malnutrition screening | 🔨 30-hour battle build |
| **Auto-filled paperwork** | The visit transcript auto-populates the government health form; exports PDF; syncs when network appears | 🔨 30-hour battle build |

Everything AI runs offline. **Our demo runs with airplane mode ON.**

## 3 · Proof: the prototype already works

We didn't just write this idea — we built it, to de-risk the 30-hour battle.
The repository and installable APK are linked on the cover page.

- **Full chain working end-to-end:** camera → on-device OCR (ML Kit) → local
  LLM (llama.cpp) → spoken answer (TTS). Voice input → structured triage JSON
  → spoken advice.
- **Real on-device inference:** any open-source GGUF model — Qwen3 0.6B,
  Gemma, IBM Granite Nano, Sarvam-1 — imports at runtime and runs locally via
  llama.cpp. No API keys anywhere in the codebase.
- **Measured, not promised:** the in-app Prompt Lab displays live
  tokens-per-second for every run.
- **Installable today:** signed arm64 release APK (62 MB) attached to the
  GitHub release, built by CI on every version tag.

*Transparency:* this prototype is our pre-event feasibility spike. The last
commit before the battle will be tagged `pre-event`, so judges can diff exactly
what was built during the 30 hours.

## 4 · Architecture (built and running)

```
        Flutter UI (Material 3) — English / हिंदी / తెలుగు
                          │
              ModelEngine interface
     "screens never know which model is running"
                          │
        llama.cpp via Dart FFI  ←  any GGUF file
   (Qwen · Gemma · Granite · MiniCPM · Sarvam-1)
                          │
   Perception                    Output & data
   • ML Kit OCR (on-device)      • Platform TTS (3 languages)
   • Speech-to-text              • Local storage only
```

**Model-agnostic by design.** The chat template ships inside GGUF metadata and
llama.cpp applies it — so swapping models is a *file import, not a refactor*.
We benchmark models per task and per device, and we are not locked to any
vendor.

**Low-end first, flagship best.** Inference is CPU-first (runs on any Android
phone), with GPU offload where available:

| Device class | Model tier (Q4 quantized) |
|---|---|
| 3–4 GB RAM (entry phones) | 0.3–1B — Qwen3 0.6B, Granite Nano, Gemma 1B |
| 6–8 GB RAM | 1–2B — Gemma 2B, **Sarvam-1 2B** (built for Indic languages) |
| Flagship — **iQOO 15** | 2–4B models, GPU/NPU accelerated via Snapdragon |

The same APK serves an ₹8,000 phone and the iQOO 15 — because ASHA workers
don't carry flagships. On the iQOO 15 we additionally target the Snapdragon
NPU (ONNX Runtime QNN path) during the battle for faster-than-cloud latency.

## 5 · Built for this hackathon's format

Details most teams will miss — and our plan for each:

- **Red Light windows (phone-only) are productive for us, by design.** The
  in-app **Prompt Lab** lets us tune prompts, swap models, and measure
  tokens/sec *on the phone itself* — no laptop needed. Phone-only hours become
  our tuning and field-testing hours.
- **Office Kit is in the loop, not bolted on.** Green Light development runs
  through phone-laptop bridging (screen mirror, file transfer for GGUF models,
  clipboard for prompts) — the workflow the format is designed to showcase.
- **The demo is native and theatrical.** Airplane mode ON, in front of the
  judges: scan a real medicine strip, it speaks in Telugu; describe symptoms,
  get an urgency verdict and referral note. No wifi, no excuses, ~90 seconds.
- **AI is necessary here, not decorative.** Offline villages + private health
  data means on-device inference is the *only* architecture that works — the
  strongest possible answer to "why local AI?"

## 6 · 30-hour battle plan

| Phase | Work |
|---|---|
| Hours 0–6 | Wire NPU acceleration on iQOO 15; load Sarvam-1 2B as default Indic model; field-tune triage prompts (Prompt Lab, on-device) |
| Hours 6–16 | ASHA visit workflow: patient record → auto-filled government health form → PDF export; offline-first sync stub |
| Hours 16–24 | Camera screening module (reference-band malnutrition check); Telugu/Hindi voice polish |
| Hours 24–30 | End-to-end field rehearsal on the iQOO 15, latency benchmarks vs. cloud, demo recording, pitch |

Risk is low because the risky part is already done: local inference, OCR, and
voice I/O are proven in the prototype. The battle adds features to a working
foundation.

## 7 · Impact and where this goes

- **Wedge:** medicine explanation + triage support for ASHA workers in
  Telangana — a concrete user we can reach and test with.
- **Scale:** ~1M ASHA workers × multiple home visits daily = tens of millions
  of assisted interactions per month, at **zero marginal cost** — no cloud
  bill stands between this and national scale.
- **Beyond ASHA:** the same offline engine serves elders living alone,
  low-literacy patients, and any rural household — an AI health assistant that
  works because it *doesn't* need the internet.

## 8 · Safety, honestly

Sahayak is a **screening and explanation aid — never a diagnosis**. Dosage is
read from the label, never invented. Danger signs (chest pain, severe
bleeding, breathing difficulty, high fever in infants) always trigger a "refer
immediately" response. Every answer ends with direction to a doctor or
pharmacist. All health data stays on the device.

## 9 · Team

| Name | Role | Focus |
|---|---|---|
| `<Team lead name>` | Team lead · AI/app build | LLM integration, Flutter |
| `<Member 2>` | `<role>` | `<focus>` |
| `<Member 3>` | `<role>` | `<focus>` |

---

**Sahayak — because the last mile of healthcare shouldn't depend on the
nearest cell tower.**

*Repo, installable APK, and demo video linked on the cover page. We're ready
to build.*
