#!/bin/bash
# Qwen3.6-35B-A3B (MTP) on llama.cpp, Vulkan, via podman. Run on SteamOS.

# Max GPU clocks and CPU performance governor
echo "high" | sudo tee /sys/class/drm/card*/device/power_dpm_force_performance_level >/dev/null
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null

podman run -d --replace \
  --device /dev/dri --group-add keep-groups \
  -v ~/models:/models -p 8095:8095 \
  --name llamacpp \
  ghcr.io/ggml-org/llama.cpp:server-vulkan \
  -m /models/Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf \
  --host 0.0.0.0 --port 8095 \
  --n-gpu-layers 99 --n-cpu-moe 20 \
  --ctx-size 40960 --flash-attn on \
  --cache-type-k q8_0 --cache-type-v q8_0 \
  --context-shift --keep 512 \
  --cache-reuse 256 \
  --reasoning off \
  --temp 0.6 --top-p 0.95 --top-k 20 --min-p 0.00 \
  --spec-type draft-mtp \
  --spec-draft-n-max 3 \
  -np 1 \
  --ubatch-size 2048

echo "Loading 35B MTP (40k context, context-shift)..."
until curl -s http://127.0.0.1:8095/health | grep -q ok; do sleep 2; done
echo "Now serving: $(curl -s http://127.0.0.1:8095/v1/models | python3 -c 'import sys,json; print(json.load(sys.stdin)["data"][0]["id"])')"
