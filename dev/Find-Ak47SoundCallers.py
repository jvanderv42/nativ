#!/usr/bin/env python3
"""Read-only reverse call graph for Uncharted's common NGS wrapper.

Usage: py dev/Find-Ak47SoundCallers.py <eboot.data.json> --lr 0x815acd3d
Requires capstone (already used by Nativ's recompiler).
Results are candidate upstream callers, NOT identified gunfire start/stop functions.
"""
import argparse
import bisect
import collections
import json
from pathlib import Path


def inspect(data, return_address, depth, top):
    try:
        from capstone import Cs, CS_ARCH_ARM, CS_MODE_ARM, CS_MODE_THUMB, CS_MODE_LITTLE_ENDIAN
        from capstone.arm import ARM_OP_IMM
    except ImportError as error:
        raise SystemExit("Capstone is required: py -m pip install capstone") from error

    functions = {int(value) & ~1: name for name, value in data["functions"].items()}
    spans = sorted((int(b[0]), int(b[1]), int(b[2]) if len(b) > 2 else None)
                   for b in data["bodies"])
    ranges = []
    for lo, hi, owner in spans:
        if owner is None:
            owner = max((a for a in functions if a <= lo), default=None)
        ranges.append((lo, hi, owner))
    ranges.sort()
    starts = [lo for lo, _, _ in ranges]

    def owner_of(addr):
        index = bisect.bisect_right(starts, addr) - 1
        if index >= 0:
            lo, hi, owner = ranges[index]
            if lo <= addr <= hi:
                return owner
        return None

    wrapper = owner_of(return_address & ~1)
    if wrapper is None:
        raise ValueError(f"No analyzed function contains LR {return_address:#x}; check game version")

    blocks = [(int(b["start"]), bytes.fromhex(b["bytes"]))
              for b in data["blocks"] if b.get("init") and b.get("bytes")]
    arm_entries = {int(a) & ~1 for a in data.get("arm", [])}
    thumb = Cs(CS_ARCH_ARM, CS_MODE_THUMB | CS_MODE_LITTLE_ENDIAN)
    arm = Cs(CS_ARCH_ARM, CS_MODE_ARM | CS_MODE_LITTLE_ENDIAN)
    thumb.detail = True
    arm.detail = True
    reverse = collections.defaultdict(set)
    edges = 0

    for lo, hi, caller in ranges:
        if caller is None:
            continue
        source = next((blob[lo - start:hi - start + 1] for start, blob in blocks
                       if start <= lo and hi < start + len(blob)), None)
        if source is None:
            continue
        for insn in (arm if caller in arm_entries else thumb).disasm(source, lo):
            if insn.mnemonic not in ("bl", "blx") or not insn.operands:
                continue
            if insn.operands[0].type != ARM_OP_IMM:
                continue
            target = insn.operands[0].imm & 0xfffffffe
            callee = owner_of(target)
            if callee is None or callee == caller:
                continue
            reverse[callee].add((caller, insn.address))
            edges += 1

    print(f"Guest NGS Play return LR: {return_address:#010x}")
    print(f"Containing function: {wrapper:#010x} ({functions.get(wrapper, 'unnamed')})")
    print(f"Decoded static direct-call edges: {edges}; reverse graph nodes: {len(reverse)}")
    print("Limitation: indirect calls, inlined calls and branch-to-tail calls may be absent.")
    frontier, seen = [wrapper], {wrapper}
    for level in range(1, depth + 1):
        parents = collections.defaultdict(set)
        for callee in frontier:
            for parent, site in reverse.get(callee, set()):
                parents[parent].add((callee, site))
        unseen = sorted((p for p in parents if p not in seen),
                        key=lambda p: (-len(parents[p]), p))
        print(f"\nUPSTREAM LEVEL {level}: {len(unseen)} previously unseen functions")
        for parent in unseen[:top]:
            examples = ", ".join(f"{site:#x}->{callee:#x}"
                                 for callee, site in sorted(parents[parent])[:3])
            print(f"  {parent:#010x} {functions.get(parent, 'unnamed')}: {examples}")
        if len(unseen) > top:
            print(f"  ... {len(unseen) - top} omitted; increase --top")
        seen.update(unseen)
        frontier = unseen
        if not frontier:
            break


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("analysis", type=Path, help="Uncharted analysis/eboot.data.json")
    parser.add_argument("--lr", type=lambda value: int(value, 0), default=0x815acd3d)
    parser.add_argument("--depth", type=int, default=3)
    parser.add_argument("--top", type=int, default=30)
    args = parser.parse_args()
    if args.depth < 1 or args.top < 1:
        parser.error("--depth and --top must be positive")
    if not args.analysis.is_file():
        parser.error(f"Analysis file not found: {args.analysis}")
    with args.analysis.open(encoding="utf-8") as file:
        data = json.load(file)
    try:
        inspect(data, args.lr, args.depth, args.top)
    except (KeyError, ValueError, TypeError) as error:
        parser.error(f"Invalid or incompatible analysis export: {error}")


if __name__ == "__main__":
    main()
