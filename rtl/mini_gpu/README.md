# mini_gpu/ — flagship SIMD datapath (Weeks 5-6)

This directory is intentionally empty until Week 5. Planned structure once
you start:

```
mini_gpu/
  alu_lane.v            - single ALU lane (add/multiply/load/store)
  simd_datapath.v        - top-level: N lanes + instruction fetch/decode
  instr_decode.v         - instruction fetch/decode logic
  mini_gpu_top.v         - integrates simd_datapath + fifo_sync + arbiter
```

## Before writing any RTL here (Week 5, Day 1)
Sketch the microarchitecture on paper or in draw.io first:
- How many lanes?
- What's the instruction format (opcode width, operand fields)?
- How do lanes share the memory interface — does this integrate the
  `arbiter_round_robin.v` you already built in Week 3?

## Design goals for this module (from the roadmap)
- Week 5: ALU lanes + fetch/decode simulate correctly for a single instruction
- Week 6: integrate `fifo_sync.v` and one of the arbiters as feeders;
  run a short multi-instruction program correctly across all lanes
- Week 7: cocotb randomized testbench + coverage on top of this module
- Week 8: bug injection + at least one formal property
