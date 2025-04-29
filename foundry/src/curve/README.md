# Curve Finance: Peg Controllers Reference Guide

This document explains the **peg controller contracts** in Curve Finance used to maintain a stablecoin's peg — like `Linear.sol`, `Sigmoid.sol`, and `Bip11.sol` — with simple explanations and Curve-specific context.

---

## 1. Linear.sol (Linear Controller)

**Purpose:**

- Introduce **small, continuous incentives** to bring price deviations back toward the target peg.
- Best for minor, frequent price fluctuations.

**How It Works:**

- Calculates a **linear penalty or reward** based on how far the current price is from the target (usually 1.0).
- The further the deviation, the stronger the corrective force.

**Formula:**

```
force = k * (price - target)
```

Where:

- `k` is a proportional constant.
- `price` is the current observed price.
- `target` is the desired peg (example: 1.0).

**Behavior:**

- Small deviations = small force
- Large deviations = proportionally larger force

**Use in Curve:**

- Early stablecoins like FRAX or crvUSD used a linear incentive system in initial pools.

---

## 2. Sigmoid.sol (Sigmoid Controller)

**Purpose:**

- Create a **gentle correction** for small price deviations but **stronger force** if deviations become extreme.
- More flexible and realistic than a pure linear model.

**How It Works:**

- Uses a **sigmoid (S-shaped) curve** to calculate the corrective force.
- Initially shallow response, sharpens near certain thresholds.

**Formula:**

```
force = max_force / (1 + exp(-a * (price - target)))
```

Where:

- `a` controls how steep the curve is.
- `exp` is the exponential function.
- `max_force` is the maximum possible correction.

**Behavior:**

- Small deviations = nearly flat response
- Larger deviations = rapid force growth ("kicking in")
- Massive deviations = saturates to maximum force

**Use in Curve:**

- Sigmoid pegs are preferred for highly volatile pegs to prevent "overreacting" to minor noise.
- Example: curve-stable swaps like crvUSD.

---

## 3. Bip11.sol (Dynamic Peg Controller, BIP-11 Proposal)

**Purpose:**

- Introduced to Curve in a specific **governance proposal** (BIP-11).
- Provides **adaptive control** based on **market volatility** and **trading conditions**.

**How It Works:**

- Adjusts incentive parameters **dynamically** based on observed volatility.
- If volatility is low, behaves like Linear.
- If volatility is high, behaves closer to Sigmoid.
- Also allows **time-decay** so incentives "relax" if the market stabilizes naturally.

**Behavior:**

- Self-adjusting controller.
- Strong, fast reactions to major events.
- Softer during calm periods.

**Use in Curve:**

- Used in more sophisticated stablecoin designs (e.g., crvUSD liquidation controller).

---

# Quick Comparison Table

| Controller | Behavior                                    | Best For                                   |
| ---------- | ------------------------------------------- | ------------------------------------------ |
| Linear     | Constant force                              | Small, frequent deviations                 |
| Sigmoid    | Gentle at first, aggressive after threshold | Larger volatility events                   |
| BIP-11     | Dynamic, adaptive                           | Volatile markets or uncertain environments |

---

# Visual Intuition

- **Linear**: Straight diagonal line.
- **Sigmoid**: "S" shape curve.
- **BIP-11**: Adaptive, dynamically changing curve.

---

# Summary for Future Use (Basis Cash + Curve)

If you are designing a stablecoin protocol (like Basis Cash) to integrate with Curve:

- **Linear** is best if you want simple, lightweight peg control.
- **Sigmoid** is better if you expect occasional bigger volatility.
- **BIP-11** is the most advanced, good if you expect market conditions to change over time.

When implementing, always test which curve stabilizes your coin **without creating unnecessary volatility** in normal conditions.

---

# References

- Curve Finance Github: `contracts/pegs/`
- Curve crvUSD Whitepaper
- BIP-11 Governance Proposal

---

# Notes

- All models are designed to work **incentive-compatible** with Curve's AMM engine.
- Controllers mainly **modulate fees, rewards, penalties**.
- Proper tuning of parameters (`k`, `a`, `max_force`) is crucial.

---
