# Uncharted 1.03 halo: ambient/specular register mapping

**Status:** GXP extraction prepared; exact normal / N-dot-V / specular register assignments **NOT established**. No visual correction implemented. Experimental branch only.

## Reason for switching methods

The previous F11 GPU-versus-software comparison measured 40,875/294,912 different pixels in a scene containing Drake, but the software reference was using reset stencil history. The subsequent GPU-side stencil-coverage diagnostic is retained as an optional parity tool; its source has compiled on Windows, but **no hardware test of that revision** has been completed.

GPU/interpreter agreement would not establish original Vita fidelity because both backends use related USSE decoding code. The strongest current evidence is the warm halo in the lit HDR target before bloom. The new priority is identifying the *actual* inputs and intermediate computations in fragment program `0x1fa2e708` (ambient/specular lighting).

The target's source-level guest address is **not** an instruction listing and does not identify the register indices. Do not invent register-to-effect mappings from the shader address, a pixel screenshot, or the generic `RECOMP_PROBE` syntax.

## Step 1: acquire exact GXP program bytes (no source modifications needed)

On the **Windows gaming PC**, in PowerShell 5.1 or 7, use the checked-in helper in `dev/Get-UnchartedShaderPrograms.ps1`. Replace the placeholder paths with the actual game executable and helper location:

```powershell
& 'C:\path\to\Get-UnchartedShaderPrograms.ps1' `
    -gameExecutable 'C:\path\to\your\recompiled-uncharted.exe' `
    -dumpFolder 'C:\tmp\unchartedShaderDump'
```

The helper sets `RECOMP_DUMP_GXP` for the launched game only, preserves the caller's prior environment setting, and reports whether the shader program files were **freshly** captured. The runtime writes `<guest-address>.gxp` when a program is registered, using `sceGxmShaderPatcherRegisterProgram` in `runtime/gfx/gxm_sony.c`. The supplied destination folder is created if absent. The executable must have been built using runtime code containing this existing dump feature.

Collect:

- `1fa2e708.gxp` — ambient/specular target.
- `1fa44f08.gxp` — character outfit G-buffer fragment shader.
- `1fa14d08.gxp` — suspected character-light fragment shader (if registered).

When collection is complete, leave the game and upload the files. A match in the output folder that predates launch does **not** prove the current run used that program.

No new recompilation is required **if** the installed executable already includes `RECOMP_DUMP_GXP`. This is separate from testing the new stencil-coverage runtime, which requires a newly compiled game executable.

## Step 2: disassemble and map instructions

The repository contains `runtime/debug/usse_dis.c`, which disassembles saved GXP files and lists fragment iterators and parameter tables. With an already built `usse_dis` tool, run `usse_dis 1fa2e708.gxp` and retain the entire output.

Inspect both primary and secondary instruction streams, the texture iterator layout, register banks, packing formats (F16/F32), and VDUAL instruction operands. Determine *where sampled WorldNrmGloss enters*, its normalization and view-vector construction, the computed N·V, any Fresnel/power/specular intermediates, and the final contribution written or blended to the lit HDR target.

Do not label variables as normal / N·V / specular solely because the associated register appears near an `SMP` or dot product: inspect data flow from sample to output first. It may be necessary to inspect adjacent program code and constant uniforms.

## Step 3: use existing register probe

`runtime/gfx/usse_spirv.c` already supports
`RECOMP_PROBE=t|p|o:<word>[@<instruction>]`
and `RECOMP_PROBE_FPROG=<hex address>` to restrict the modification to the chosen fragment program.

**After instruction/register mapping**, choose a *small number* of exact probes, one at a time, to expose:

1. World normal sample and/or decoded/normalized world normal.
2. View vector or N·V dot product.
3. Fresnel/specular term immediately before its final addition.

Document the exact bank, word, instruction index, storage format, and interpretation for each. `RECOMP_PROBE_F32` displays one F32 word; otherwise the output decodes low/high F16 halves. Probes alter the selected shader's output **for diagnosis only** and should never be treated as normal gameplay visuals.

An `@instruction` probe snapshots that register at the chosen **primary instruction index**. These probes operate when the shader is translated; an existing cached or already compiled game executable may need recompilation/retranslation to include the selected environment configuration. Use a known single draw and capture location, not a free-running screenshot of unrelated passes.

## Step 4: interpret outcome and stop

- Abnormal sampled/decoded normals at Drake's edge: inspect character G-buffer `0x1fa44f08`, texture sampler/filtering, packing, and coordinate alignment.
- Smooth normal and plausible N·V but spiking specular intermediate: inspect specular math, precision, uniforms, or nearby VDUAL instructions.
- Both plausible while halo remains: verify pass contribution, blend/stencil region, and original Vita appearance. Do **not** claim original renderer fidelity from Nativ GPU/CPU agreement.

Keep the original Vita halo reports in `docs/uncharted-character-halo.md` as historical evidence of an artifact, **not** a matched quantitative reference for this specific game scene.

## Limits and rollback

No global lighting, bloom, DOF, FXAA, SSAO, shader translation, or upscaling changes are justified yet. Preserve Uncharted v1.00, Killzone, audio, input, and 120 FPS behavior. Keep the feature branch separate from `main`.

To exit the dump diagnostic, simply launch the game without `RECOMP_DUMP_GXP` (the helper restores that environment variable on exit). Do not merge source-only mapping notes or runtime diagnostics into `main` without explicit approval.
