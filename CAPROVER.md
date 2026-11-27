# Deploy on CapRover

Requires an x86-64 host with AVX2, FMA, F16C (`grep -o -w -E 'avx2|fma|f16c' /proc/cpuinfo | sort -u`),
~1 GB free RAM and ~3 GB disk for the build.

1. Create an app in CapRover.
2. HTTP Settings: **Container HTTP Port = 7681**, enable **Websocket Support** and HTTPS.
3. App Configs: set `TTYD_CRED=user:strongpassword` and `THREADS=<nproc>`.
4. Deployment: point it at this repo (branch with `captain-definition`), or run `caprover deploy` from the repo root.
5. Open the app URL, log in, chat.

The first build downloads ~1.2 GB from Hugging Face and converts the weights.
