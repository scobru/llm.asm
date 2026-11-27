# CapRover / Docker: builds asm-llm, exports Qwen3-0.6B Q8_0, serves --chat in the browser via ttyd.
FROM python:3.12-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends nasm binutils make ca-certificates \
 && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir numpy huggingface_hub
WORKDIR /src
COPY . .
RUN make inference FAST_Q8=1
RUN hf download Qwen/Qwen3-0.6B --local-dir models/qwen3-0.6b-bf16 \
 && python3 scripts/export_weights.py --model-dir models/qwen3-0.6b-bf16 \
      --out models/qwen3-0.6b-q8_0.asmbin --scale-dtype fp16 \
 && rm -rf models/qwen3-0.6b-bf16

FROM ubuntu:24.04
RUN apt-get update && apt-get install -y --no-install-recommends ttyd && rm -rf /var/lib/apt/lists/*
COPY --from=build /src/build/asm-llm /app/asm-llm
COPY --from=build /src/models/qwen3-0.6b-q8_0.asmbin /app/model.asmbin
# Override both in CapRover App Configs. Never expose without credentials.
ENV TTYD_CRED=admin:changeme THREADS=4
EXPOSE 7681
CMD ttyd -W -p 7681 -c "$TTYD_CRED" /app/asm-llm -m /app/model.asmbin --chat -t "$THREADS"
