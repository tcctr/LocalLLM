# Local LLM: Qwen3.6-35B-A3B (MTP) on llama.cpp

My personal setup for running Qwen3.6-35B-A3B, a mixture-of-experts model with multi-token-prediction (MTP) speculative decoding, on a mid-range AMD desktop under SteamOS.

**Result: 66.04 tokens/s** on a 16 GB GPU with 32 GB of system RAM.

## Hardware

| Part | Spec |
|------|------|
| CPU  | AMD Ryzen 7 5800X3D |
| RAM  | 32 GB DDR4-3600 |
| GPU  | AMD Radeon RX 9060 XT 16 GB |
| OS   | SteamOS |

## Software

- llama.cpp: official container `ghcr.io/ggml-org/llama.cpp:server-vulkan` (Vulkan backend), run with podman
- Model: Qwen3.6-35B-A3B MTP GGUF, quant `UD-Q4_K_XL` (`Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf`). Weights are not stored in this repo; download them yourself and put them in `~/models`.

## Run

See [`run-server.sh`](run-server.sh). It also sets the GPU power level to `high` and the CPU governor to `performance` (needs sudo).

Key flags:

| Flag | Why |
|------|-----|
| `--n-gpu-layers 99 --n-cpu-moe 20` | Put everything on the GPU except the expert weights of the first 20 layers, which stay on the CPU. The 35B model doesn't fit in 16 GB of VRAM, so this is the VRAM/speed trade-off. |
| `--spec-type draft-mtp --spec-draft-n-max 3` | Use the model's built-in MTP head to draft up to 3 tokens per step (speculative decoding). |
| `--flash-attn on` + `--cache-type-k/v q8_0` | Flash attention and an 8-bit KV cache to fit a 40k context in VRAM. |
| `--ctx-size 40960 --context-shift --keep 512` | 40k context; when full, shift the window but keep the first 512 tokens. |
| `--cache-reuse 256` | Reuse the cached prefix when prompts share a start (faster multi-turn). |
| `--reasoning off` | Skip the thinking phase for faster replies. |
| `--ubatch-size 2048` | Larger micro-batch for faster prompt processing. |
| `-np 1` | One slot, so all memory goes to a single user. |
| `--temp 0.6 --top-p 0.95 --top-k 20 --min-p 0` | Sampling settings. |

The server is set to port 8095 (my choice, not a llama.cpp default) and exposes an OpenAI-compatible API (`/v1/...`). `--host 0.0.0.0` makes it reachable on every network interface, so only expose it on a network you trust.

## Usage

- Front end: Odysseus, an AI tool that runs locally on the same desktop. It's started from `~/odysseus` with `podman compose` (the script does this after the server starts).
- Remote access: the desktop is on my Tailscale network, so I reach the server (and Odysseus) from my other devices at the desktop's Tailscale address, e.g. `http://<tailscale-name>:8095`.

## Benchmark

| Metric | Value |
|--------|-------|
| Generation speed | 66.04 tokens/s |
