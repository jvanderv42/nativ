#version 450
layout(location = 0) out vec4 outColor;
// Diagnostic-only: the GPU's existing stencil test decides whether this
// fullscreen fragment executes; colour writes white for surviving pixels.
// Pipeline stencil ops are KEEP and depth testing is disabled.
void main() { outColor = vec4(1.0); }
