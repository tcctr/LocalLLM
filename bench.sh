#!/usr/bin/env bash
# Usage: ./bench.sh /path/to/model.gguf [extra llama-bench flags]
# Example: ./bench.sh ~/models/qwen3.gguf -ngl 99 -fa 1
# Requires llama-bench (built with llama.cpp) on PATH.
set -euo pipefail

MODEL="${1:?usage: ./bench.sh model.gguf [llama-bench flags]}"
shift || true

mkdir -p results
OUT="results/$(date +%Y-%m-%d_%H%M)_$(basename "$MODEL" .gguf).md"

# pp512 = prompt processing tokens/s, tg128 = generation tokens/s (the "tps" people quote)
llama-bench -m "$MODEL" -p 512 -n 128 -r 3 -o md "$@" | tee "$OUT"
echo "Saved to $OUT"
