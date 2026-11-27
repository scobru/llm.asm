# CapRover / Docker: builds asm-llm, exports Qwen3-0.6B Q8_0, serves --chat in the browser via ttyd.
FROM python:3.12-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends nasm binutils make ca-certificates \
 && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir numpy huggingface_hub
WORKDIR /src
COPY . .
RUN make inference FAST_Q8=1
# Qwen/Qwen3-0.6B (~0.6 GB, fast) or Qwen/Qwen3-1.7B (~1.8 GB, ~3x slower, ~3 GB RAM)
ARG MODEL=Qwen/Qwen3-0.6B
RUN hf download "$MODEL" --local-dir models/src \
 && python3 scripts/export_weights.py --model-dir models/src \
      --out models/model-q8_0.asmbin --scale-dtype fp16 \
 && rm -rf models/src

FROM ubuntu:24.04
RUN apt-get update && apt-get install -y --no-install-recommends ttyd && rm -rf /var/lib/apt/lists/*
COPY --from=build /src/build/asm-llm /app/asm-llm
COPY --from=build /src/models/model-q8_0.asmbin /app/model.asmbin
# Override both in CapRover App Configs. Never expose without credentials.
ENV TTYD_CRED=admin:changeme THREADS=4
EXPOSE 7681
CMD ttyd -W -p 7681 -c "$TTYD_CRED" /app/asm-llm -m /app/model.asmbin --chat -t "$THREADS"
