PAiA OFFLINE PACK  (Windows x64)
================================

Contents
  - Default model: Qwen2.5 7B Instruct, Q4_K_M (4.7 GB, Apache-2.0).
    No account, token or download needed.
  - llama.cpp engine b9967, two builds:
      win-common_cpus-x64          CPU, works on any x64 machine
      win-vulkan-common_cpus-x64   GPU via Vulkan (NVIDIA / AMD / Intel)
    PAiA picks Vulkan automatically when a GPU with 6 GB+ memory is present.
  - manifest.sha256: checksums of every file, checked before install.

Install (no network needed)
  1. Run the PAiA installer (Jan_x.y.z_x64-setup.exe). It is unsigned, so
     Windows SmartScreen may warn: click "More info" > "Run anyway".
  2. Start PAiA once, wait for the main window, then close it fully
     (also from the system tray).
  3. Double-click Install-PAiA-Offline-Pack.cmd in this folder.
  4. Start PAiA, open a new chat, choose
     "Qwen2.5 7B Instruct (PAiA default)" and send a message.

Hardware guidance for Qwen2.5 7B Q4_K_M
  - RAM: 8 GB minimum free, 16 GB recommended.
  - CPU only: expect roughly 3-10 tokens/second depending on the CPU.
  - GPU with 8 GB+ VRAM: much faster (Vulkan engine).

Troubleshooting
  - "PAiA is running": close it from the tray icon and rerun step 3.
  - Model missing in the list: Settings > Model Providers > llama.cpp,
    check the model appears; restart PAiA.
  - Slow or failing on GPU: Settings > Model Providers > llama.cpp >
    Backend, choose win-common_cpus-x64 to force CPU.
  - Logs: %APPDATA%\Jan\data\logs
