// Switching between debug and release versions
{$DEFINE Debug}
{.$DEFINE Release}

// Enable x86-assembly optimized routines
{$DEFINE CPUASM}

// For Delphi, restrict the assembly code to generating 386-compatible opcodes only,
// disabling MMX/SSE support and some 80486 instructions
//{$DEFINE I386COMPAT}


{$I ..\Default.inc}