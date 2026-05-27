# 16-Bit Low-Power CMOS Multiplier

> **An energy-efficient 16-bit signed multiplier implemented in the GlobalFoundries (GF) 22nm CMOS process, featuring Modified Radix-4 Booth encoding and Dadda tree compression.**

## Overview
Arithmetic circuits, particularly multipliers, are fundamental components in digital signal processors (DSPs). Because multiplication is frequently performed within the arithmetic logic unit (ALU), standard multiplier architectures often become a primary bottleneck in terms of both system throughput and dynamic power consumption. 

This project presents an optimised behavioural RTL implementation of a 16-bit signed multiplier designed to address the strict power constraints of modern wireless devices. By moving away from a conventional linear accumulation grid, this architecture successfully synergises parallel reduction techniques with system-level data gating to achieve a **55.2% improvement in energy per calculation (PDP)** compared to a standard array baseline.

---

## 🏗️ Hardware Architecture

The datapath is partitioned into three distinct, interconnected modules to ensure synthesisability and allow for targeted logic-level optimisations:

1. **Partial Product Generation (Booth Encoder):** A Modified Radix-4 Booth Encoder scans the 16-bit multiplier operand in overlapping 3-bit windows. This strictly halves the initial partial product matrix from 16 discrete rows down to exactly 8 rows, drastically cutting the workload for the subsequent adder tree.
2. **Parallel Accumulation (Dadda Tree):** The 8 rows are compressed using a structurally instantiated Dadda reduction tree. By adhering to the optimal Dadda compression sequence (8 → 6 → 4 → 3 → 2 rows), the architecture guarantees the absolute minimum number of logic gates required to achieve a logarithmic $O(\log N)$ delay profile.
3. **Final Addition (CPA):** A terminal Carry Propagate Adder resolves the final two rows into the 32-bit product.

<img width="495" height="282" alt="image" src="https://github.com/user-attachments/assets/306af1bf-e4a0-4a80-b65d-6cc2e0907826" />

---

## ⚡ Power & Delay Optimisation Strategies

Beyond architectural changes, several techniques were employed to manage dynamic power dissipation ($P_{dyn}$):

* **Operand Isolation:** To directly minimise the switching activity factor ($\alpha$), system-level data gating was integrated. An external Enable (`EN`) signal governs the input registers. When unasserted, the combinational logic cloud is frozen, suppressing spurious logic transitions during idle clock cycles.
* **Clock Gating:** The synthesis tool inferred native Clock Gating cells from the behavioural `EN` logic to shut off the clock tree to isolated registers.
* **Logic-Level Optimisation:** Standard complex logic gates, such as AND-OR-Invert (AOI) cells, were inferred during synthesis to compute multiple Boolean operations within a single cohesive transistor structure, reducing parasitic wiring capacitance.

---

## 📊 Synthesis Results & PPA Evaluation

The design was synthesised using **Synopsys Design Compiler** targeting the **GF 22nm standard cell library** under typical Process, Voltage, and Temperature (PVT) conditions. It was evaluated against a conventional 16-bit array multiplier baseline.

| Architecture | Critical Path Delay (ns) | Dynamic Power (µW) | Total Cell Area (units) |
| :--- | :--- | :--- | :--- |
| **Array (Baseline)** | 2.45 | 62.32 | 501 |
| **Booth-Dadda (Proposed)** | 1.62 | 42.23 | 930 |
| **Improvement** | **-33.88%** | **-32.23%** | +85.63% |

**Conclusion:** While the complex routing of the Dadda tree and the encoding logic resulted in an 85% increase in total active cell area, the resulting **55.2% improvement in the Power-Delay Product (PDP)** (from 152.68 fJ down to 68.41 fJ) conclusively justifies this hardware trade-off for high-performance, power-constrained DSP environments.

---

## 📂 Repository Structure

```text
├── verilog codes/                  # Behavioural Verilog source files (.v)
│   ├── Multiplier_16bit.v
│   ├── Multiplier_16bit_array.v
│   └── Multiplier_16bit_booth_dadda.v
├── testbench/                   # Verilog testbenches for functional verification
├── report/                  # Synthesis output PPA reports (.rpt)
├── doc/                  # High-resolution schematics and simulation waveforms
└── README.md             # Project documentation
