# Apricot Analysis — step-by-step walkthrough

One model, two engines. This guide walks through every tab of Apricot's
**Analysis** panel with the delivery-drone model in [drone.sysml](drone.sysml),
running each step with both engines, **OpenSysML** and the **SysML Toolkit**, and
pointing out where their answers differ.

Every step links to the output you should get in [output/](output/).

## The model

The model describes a delivery quadcopter: its parts, how much they weigh, a battery
and three requirements it must meet.

| Part | Qty | Unit mass | Power draw | Cost |
| --- | ---: | ---: | ---: | ---: |
| Airframe | 1 | 3.2 kg | — | 450 € |
| Battery | 1 | 4.4 kg | 1100 Wh | 900 € |
| Motors | 4 | 0.55 kg | — | 160 € |
| Flight controller | 1 | 0.25 kg | 12 W | 380 € |
| GPS | 1 | 0.1 kg | 2 W | 120 € |
| Camera | 1 | 0.6 kg | 15 W | 700 € |
| Gripper | 1 | 0.4 kg | 5 W | 150 € |

The drone also carries a **5 kg parcel** (`payload`). From this the model derives:

- **Takeoff mass** (`takeoffMass`) = the mass of every part + the parcel.
- **Hover power** (`hoverPower`) = 100 W per kg lifted + the avionics' draw.
- **Endurance** (`endurance`) = minutes of flight on one charge (20 % of the battery
  is kept in reserve).

The three **requirements**:

| ID | What it demands |
| --- | --- |
| R-01 | Takeoff mass of at most 25 kg |
| R-02 | At least 30 minutes of flight |
| R-03 | Carry at least 5 kg |

---

## The Analysis panel

The panel has six tabs and an engine selector:

- **Check**: is the model well formed?
- **Evaluate**: computes values ("how heavy is it?", "how long does it fly?").
- **Verify**: are the requirements met?
- **Query**: finds elements in the model.
- **Report**: renders a document from the model.
- **Diagram**: draws the system.

The **Engine** selector chooses who analyses the model: **OpenSysML** or **SysML
Toolkit**.

To start, open Apricot, create a model and paste the content of
[drone.sysml](drone.sysml) into the editor.

---

## 1. Load and check

**Message:** both engines accept the same model.

### 1.1 Check with the SysML Toolkit

- **Where:** `Check` tab → Engine `SysML Toolkit` → tick `Strict: reject notation the
  SysML v2 specification does not admit` → `Run`.
- **What it does:** checks the syntax and that every name resolves.
- **Output:** no rows, exit code **0**.
  → [output/01-check-toolkit.txt](output/01-check-toolkit.txt)

### 1.2 Check with OpenSysML

- **Where:** `Check` tab → Engine `OpenSysML` → `Run`.
- **What it does:** the same, with its own parser.
- **Output:** `✓ package Drone`, `✓ drone.sysml: no errors`, exit code **0**.
  → [output/01-check-opensysml.txt](output/01-check-opensysml.txt)

**What it shows:** the model is valid for both. OpenSysML is stricter: it rejects
some things the Toolkit only warns about (for example, using `sum` without importing
`RealFunctions`).

---

## 2. Evaluate: the first discrepancy

**Message:** same model, same data, two different numbers.

### 2.1 Evaluate with OpenSysML

- **Where:** `Evaluate` tab → Engine `OpenSysML` → in `Expressions`, one per line:

```text
Drone::drone.motorMass
Drone::drone.takeoffMass
Drone::drone.hoverPower
Drone::drone.endurance
```

- **What it does:** builds the drone with all its parts, then computes each value.
- **Output:** `2.2` · `16.15` · `1648.9999999999998` · `32.01940570042451`, exit
  code **0**. → [output/02-evaluate-opensysml.txt](output/02-evaluate-opensysml.txt)

### 2.2 Evaluate with the SysML Toolkit

- **Where:** `Evaluate` tab → Engine `SysML Toolkit` → the same values, written as
  qualified names with `::`. The Toolkit's `Evaluate` takes qualified names, not `.`
  expressions, and evaluates each one in the context of `drone`. In SysML, `::` only
  names a declaration and `.` navigates values, so outside this tab the two are not
  interchangeable:

```text
Drone::drone::motorMass
Drone::drone::takeoffMass
Drone::drone::hoverPower
Drone::drone::endurance
```

- **What it does:** evaluates the declared values without instantiating the drone.
- **Output:** `0.55` · `14.5` · `1484` · `35.57951482479785`, exit code **0**.
  → [output/02-evaluate-toolkit.txt](output/02-evaluate-toolkit.txt)

**The discrepancy.** The drone has **four motors of 0.55 kg**:

- OpenSysML materializes all four and adds them up: **2.2 kg** of motors.
- For the Toolkit there is only one motor (`size(drone.motors)` returns 1): **0.55 kg**.
  The redefinition `part :>> motors { ... }` in `drone` does not keep the inherited
  `[4]`.

Everything that depends on mass inherits the difference:

| | OpenSysML | SysML Toolkit |
| --- | ---: | ---: |
| Motor mass | 2.2 kg | 0.55 kg |
| Takeoff mass | 16.15 kg | 14.5 kg |
| Endurance | 32.0 min | 35.6 min |

**What it shows:** the model says "four motors". The Toolkit keeps the value of one;
OpenSysML counts all four. For this drone counting four is right: carrying four
motors weighs four times as much.

---

## 3. Verify the requirements

**Message:** "verify" means different things in each engine.

### 3.1 Verify with the SysML Toolkit

- **Where:** `Verify` tab → Engine `SysML Toolkit`, no boxes ticked → `Run`.
- **What it does:** checks **every** constraint in the model at once. When it lacks a
  value to decide, it answers "undecided" rather than guessing.
- **Output** (abridged), exit code **0**:
  → [output/03-verify-toolkit.txt](output/03-verify-toolkit.txt)

```text
powerBudget (AssertConstraintUsage): satisfied
flightTimeCheck (AssertConstraintUsage): satisfied
reserve (AssertConstraintUsage): satisfied
massOk (ConstraintUsage, satisfies Drone::mtow): satisfied
longEnough (ConstraintUsage, satisfies Drone::flightTime): satisfied
carriesParcel (ConstraintUsage, satisfies Drone::deliveryLoad): satisfied
6 satisfied, 0 violated, 23 undecided
```

`flightTimeCheck` is not a fourth requirement: it is R-02 applied to `drone`
(`drone.endurance >= 30.0`). It is in the model because OpenSysML only checks the
constraints you name, and R-02 is not bound to any particular drone.

The 23 "undecided" are checks on generic parts or on values left open; they are not
failures.

### 3.2 Verify with OpenSysML

- **Where:** `Verify` tab → Engine `OpenSysML` → in `Constraints`, one per line:

```text
Drone::powerBudget
Drone::flightTimeCheck
Drone::Sizing::heavyLift
```

- **What it does:** checks **only the constraints you name**, and states how
  confident it is in each result (`standing`).
- **Output**, exit code **2** (something could not be decided):
  → [output/03-verify-opensysml.txt](output/03-verify-opensysml.txt)

```text
✓ Constraint Drone::powerBudget passed
  standing: holds (observed: 1 run under reverse)
✓ Constraint Drone::flightTimeCheck passed
  standing: holds (observed: 1 run under reverse)
? Constraint Drone::Sizing::heavyLift could not be evaluated
  … payload has no value in the model
```

`heavyLift` cannot be decided because the model leaves `payload` open.

**What it shows:**

| | SysML Toolkit | OpenSysML |
| --- | --- | --- |
| What it checks | everything, on its own | the constraints you name |
| How | conservative evaluation of the declared values | by executing the model |
| A value is missing | "undecided", exit code 0 | "could not be evaluated", exit code 2 |
| Confidence | not reported | reported (`standing`) |

---

## 4. The verdicts differ

### 4.1 Change the parcel

In the editor, inside `part drone`, change:

```sysml
attribute :>> payload = 5.0;
```

to:

```sysml
attribute :>> payload = 6.5;
```

### 4.2 SysML Toolkit: everything still passes

- **Where:** `Verify` tab → `SysML Toolkit` → `Run`.
- **Output**, exit code **0**: `flightTimeCheck: satisfied` and
  `longEnough (…satisfies Drone::flightTime): satisfied`.
  → [output/04-payload-6.5-verify-toolkit.txt](output/04-payload-6.5-verify-toolkit.txt)
- With `Evaluate`: endurance = **32.31 min**.
  → [output/04-payload-6.5-evaluate-toolkit.txt](output/04-payload-6.5-evaluate-toolkit.txt)

### 4.3 OpenSysML: R-02 fails

The same constraint that passed in section 3 now fails.

- **Where:** `Verify` tab → `OpenSysML` → `Constraints`: `Drone::flightTimeCheck` →
  `Run`.
- **Output**, exit code **1**:
  → [output/04-payload-6.5-verify-opensysml.txt](output/04-payload-6.5-verify-opensysml.txt)

```text
✗ Constraint Drone::flightTimeCheck failed
  standing: violated (witnessed: 1 run under reverse)
```

- With `Evaluate`: endurance = **29.35 min**.
  → [output/04-payload-6.5-evaluate-opensysml.txt](output/04-payload-6.5-evaluate-opensysml.txt)

**The discrepancy.** R-02 demands ≥ 30 min:

| | SysML Toolkit | OpenSysML |
| --- | ---: | ---: |
| Endurance with 6.5 kg | 32.31 min | 29.35 min |
| R-02 | passes | **fails** |

The cause is the same as in section 2: four motors weigh more, and a heavier drone
flies for less time.

Set `payload` back to `5.0` before continuing.

---

## 5. Z3: searching for values, not computing them

**Message:** evaluation answers "what is the value?". Z3 answers "does any value
exist?", "is it impossible?" and "which one is best?".

In section 3, `heavyLift` stayed undecided because `payload` and the battery
capacity have no value. They are **unknowns**: they are not computed, they are
searched for. That is the job of the **Z3** solver.

### 5.1 Ranges, without a solver

- **Where:** `Verify` tab → `SysML Toolkit` → tick `Also report the value ranges that
  satisfy each constraint` → `Run`.
- **What it does:** narrows the unknowns with interval arithmetic, without Z3. It
  only works on **asserted** constraints (`assert constraint`): they are design
  commitments, not questions.
- **Output** (abridged), exit code **1**:
  → [output/05-verify-ranges-toolkit.txt](output/05-verify-ranges-toolkit.txt)

```text
packCatalogue: satisfied (propagation: holds for all values in the narrowed ranges)
packUnder25: satisfied (propagation: …)
packFlies30: satisfied (propagation: …)
bayFits: VIOLATED (propagation: domains contract to empty — unsatisfiable)
bayFlies30: VIOLATED (propagation: …)
9 satisfied, 2 violated, 18 undecided

narrowed ranges:
  packWh ∈ [1008, 2000]
  bayPackWh ∈ ∅
```

Without the box, those five constraints are "undecided" (`6 satisfied, 0 violated,
23 undecided`), because the next battery has no value yet. With the box, the Toolkit
combines the constraints and narrows the value:

| Unknown | Asserted constraints | Result |
| --- | --- | --- |
| `packWh`, the next battery pack | a catalogue size (800–2000 Wh), ≤ 25 kg, 30 min with 5 kg | **[1008, 2000] Wh**: every battery in that range meets all three |
| `bayPackWh`, a battery for a compact bay | fits the bay (≤ 1000 Wh), 30 min with 5 kg | **∅**: it needs ≥ 1008 Wh, so it is impossible |

**What it shows:** with no Z3 and no trial values, the Toolkit turns "undecided" into
a safe answer: a range where everything holds, or a proof that nothing does.
`heavyLift` and the like stay undecided, because they are **questions** ("does a
value exist?") rather than commitments: that is Z3's job.

### 5.2 Z3 (takes about 12 s)

- **Where:** `Verify` tab → `SysML Toolkit` → tick `Ask the Z3 solver about undecided
  constraints` → `Run`.
- **What it does:** sends what is still undecided to Z3, one constraint at a time. Z3
  returns an example that satisfies it, proves it impossible, or gives up.
- **Output** (abridged), exit code **1** (two more impossibilities, now proved by Z3):
  → [output/06-verify-z3-toolkit.txt](output/06-verify-z3-toolkit.txt)

```text
heavyLift … — z3: satisfiable, e.g. payload = 10000, capacity = 1425
bigBattery: VIOLATED (z3: unsatisfiable — no assignment can make this hold)
rotorFits … — z3: satisfiable, e.g. krpm = 3, propInches = 30
rotorCompact: VIOLATED (z3: unsatisfiable — no assignment can make this hold)
squarePanel … — z3: satisfiable, e.g. panelSide = (root-obj (+ (^ x 2) (- 2)) 2)
lifts (ConstraintUsage): undecided (…; z3: solver timed out)
9 satisfied, 4 violated, 16 undecided
```

Z3 starts from the ranges of 5.1, which come out the same (`packWh`, `bayPackWh`),
and only receives what is still undecided. Hence the 4 impossibilities: `bayFits`
and `bayFlies30` from the ranges, `bigBattery` and `rotorCompact` from Z3.

**The key lines:**

| Constraint | The question | Z3's answer | What it teaches |
| --- | --- | --- | --- |
| `heavyLift` | 10 kg, 30 min and ≤ 25 kg at once? | yes, with a 1425 Wh battery | **Finding a design** |
| `bigBattery` | ≤ 25 kg with a 5000 Wh battery? | **impossible** | Z3 replaces the mass by its formula and proves it does not fit |
| `rotorFits` | rpm and a ≤ 30" propeller that lift? | yes (3000 rpm, 30") | Solves a nonlinear problem |
| `rotorCompact` | the same with a ≤ 20" propeller | **impossible** | Proves that too |
| `squarePanel` | side of a 2 m² panel | exactly √2 | Z3 handles irrational numbers |
| `lifts` | thrust with no tip-speed limit | *timeout* | With no bounds Z3 does not finish (hence the ~12 s) |

**What it shows:** Z3 answers questions ordinary evaluation cannot (does it exist?
is it impossible? which is best?) and proves its answers.

---

## 6. Query: two languages in one panel

The `Query` tab takes a different language depending on the engine.

### 6.1 OpenSysML style (OSLC)

- **Where:** `Query` tab → Engine `OpenSysML` → type the query → `Run`.
- **Format:** filters such as `rdf:type="RequirementUsage"`, `sysml:name`, etc.

| Query | Output | Use |
| --- | --- | --- |
| `oslc.where=rdf:type="RequirementUsage"&oslc.select=sysml:shortName,sysml:type` | R-01, R-02, R-03 with their type (plus `ambitious`, which has no ID) | List requirements by ID → [output](output/07-query-opensysml-requirements.txt) |
| `oslc.where=sysml:type="Drone::Motor"&oslc.select=sysml:multiplicityLower,sysml:multiplicityUpper` | `motors … =4` | Find by part type → [output](output/07-query-opensysml-motors.txt) |
| `oslc.where=rdf:type="PartUsage" and sysml:owner="Drone::drone"&oslc.select=sysml:name&oslc.orderBy=-sysml:name` | the 7 parts, sorted | List an element's parts → [output](output/07-query-opensysml-parts.txt) |

This language identifies elements by type, name or owner. **It does not read
values** (it cannot ask "which parts weigh more than 1 kg?"), and it reports a
malformed query instead of silently returning nothing.

### 6.2 SysML Toolkit style (KerML)

- **Where:** `Query` tab → Engine `SysML Toolkit` → type the expression → `Run`.
- **What it is:** expressions with functions, which **do compute**.

| Expression | Output | Use |
| --- | --- | --- |
| `size(ownedMember(Drone))` | `35` | Count elements → [output](output/07-query-toolkit-count.txt) |
| `ownedMember(Drone::Sizing)` | 22 rows | List with their type → [output](output/07-query-toolkit-sizing.txt) |
| `sum(ownedFeature(Drone::drone)->select { in p; p istype Drone::Component }->collect { in p; p.cost })` | `2860` | Add up a value (cost) → [output](output/07-query-toolkit-cost.txt) |
| `Drone::drone.endurance - 30.0` | `5.58` | Margin on a requirement → [output](output/07-query-toolkit-margin.txt) |
| `Drone::drone.battery istype Drone::Motor` | `false` | Yes/no questions → [output](output/07-query-toolkit-istype.txt) |

**Watch the cost:** the query returns €2860, but the real drone costs €3340. The
four motors again: the query counts one, not four.

**What it shows:** OSLC is convenient to **identify** elements; KerML is the only
one that **computes**. Neither follows relationships (who satisfies a requirement,
which test verifies it).

---

## 7. The report

**Message:** a report generated from the model, always up to date.

- **Setup:** paste the content of [drone-report.sysml](drone-report.sysml) **after**
  `drone.sysml` in the editor (the report needs both packages).
- **Where:** `Report` tab → `Document`: `DroneReport::DesignReport` → `Format`:
  `Markdown` → `Run`.
- **What it does:** walks the model and writes tables: bill of materials (sorted by
  mass), safety-critical parts, requirements and who satisfies them, plus a diagram
  of the part tree.

**Output** (trimmed): → [output/08-report-opensysml.md](output/08-report-opensysml.md)

```text
# Delivery Drone Design Report
## Bill of materials
| name | mass | power | cost | costPerKg | label |
| battery | 4.4 | 0 | 900 | 204.54545454545453 | part: battery |
| airframe | 3.2 | 0 | 450 | 140.625 | part: airframe |
## Safety-critical components
| battery | motors | controller |
## Requirements
| R-01 | mtow | Drone::MaxTakeoffMass |
*Parts satisfying R-01* → drone
## Structure   (mermaid diagram)
```

With `Format: HTML` and `Table of contents (HTML)` ticked, you also get an index
linking to each section. → [output/08-report-opensysml.html](output/08-report-opensysml.html)

**What it shows:** the report is not written by hand: it is **computed** from the
model. Change a mass and the table changes. The report is also the only thing that
answers "who satisfies R-01?" or "which part is safety-critical?".

**Important:** remove `drone-report.sysml` from the editor before continuing. The
report uses `Documents` and `DocumentQueries`, an OpenSysML library that is not part
of the OMG standard library, so the Toolkit reports 106 unresolved-name warnings.
That is expected, not an error in the model.
→ [output/08-report-check-toolkit.txt](output/08-report-check-toolkit.txt)

---

## 8. Diagrams

### 8.1 Diagrams with the SysML Toolkit

- **Where:** `Diagram` tab → pick a `View` and, if needed, an `Element` → `Run`.
  The Diagram tab always uses the SysML Toolkit.

| View | Element | What it draws | Output |
| --- | --- | --- | --- |
| `interconnection` | `Drone::Quadcopter` | The 7 parts and their connections: battery → controller and motors, etc. **The most striking one** | [PlantUML](output/09-diagram-interconnection-toolkit.puml) |
| `state` | — | The flight modes: idle → cruising → delivering… | [PlantUML](output/09-diagram-state-toolkit.puml) |
| `action` | — | The delivery mission step by step | [PlantUML](output/09-diagram-action-toolkit.puml) |
| `tree` | — | The full part tree (very long) | [PlantUML](output/09-diagram-tree-toolkit.puml) |

**What it shows:** diagrams are generated from the model, like the report.

The Toolkit draws `motors : Motor [4]` yet, as section 2 showed, computes with one
motor. OpenSysML can also draw (only through the API, `-render`); its
interconnection drops the `[4]` yet computes with four.
→ [output/09-diagram-interconnection-opensysml.puml](output/09-diagram-interconnection-opensysml.puml)

---

## 9. Ask in natural language (Alicia)

**Message:** the same, asked in words. Alicia does not make up numbers: it calls
the engine and quotes it.

Open the **Alicia** panel and try prompts like:

| Prompt | It should |
| --- | --- |
| "Does this model have errors?" | Run Check, no problems |
| "How heavy is the drone at takeoff according to each engine?" | Evaluate with both and **point out the discrepancy** |
| "Does the drone meet its requirements?" | Run Verify, all three met |
| "Use Z3 to see whether a 10 kg parcel can fly for 30 minutes" | Z3: `capacity = 1425` |
| "Draw the interconnection of the Quadcopter" | A PlantUML diagram |

**A limit worth mentioning:** Alicia's Z3 option only works with the **SysML
Toolkit**. OpenSysML's Z3 (appendix) is not within Alicia's reach.

---

## Appendix: what is not in the panel

These features exist in the engines but have no button in Apricot. They are used
through the API or the command line, and are listed to complete the comparison.

| Feature | Engine | Why it matters | Output |
| --- | --- | --- | --- |
| **Check every satisfy relationship** (`-satisfy`) | OpenSysML | The Toolkit does this automatically; OpenSysML only through the API. It also **runs the verification case** `weighDrone` and returns a verdict | [output](output/10-satisfy-opensysml.txt) |
| **Z3 over whole requirements** (`%check`, `%explain`) | OpenSysML | On `ambitious` it proves that 3 conditions conflict and **says which**; the Toolkit sees them one by one | [output](output/10-explain-opensysml.txt) |
| **Optimize** (`%optimize`) | OpenSysML | The maximum parcel is 11.9 kg, with a 1584 Wh battery | [output](output/10-optimize-opensysml.txt) |
| **Explain impossibilities** (`%explain`) | OpenSysML | Names the exact conditions that fail | [output](output/10-explain-opensysml.txt) |
| **Run analyses and sweep parameters** (`-analysis`, `-sweep`) | OpenSysML | A table showing the endurance margin lies between 1.0 and 1.25 kg of extra load | [output](output/10-sweep-opensysml.txt) |
| **Z3 over behavior** (`smt` engine) | OpenSysML | Finds that with a cruise cost of 32.75 % the battery reserve breaks; the Toolkit only sees the initial value | [output](output/10-smt-mission-opensysml.txt) |
| **Document queries** (`-run-query`) | OpenSysML | The ones the report uses, also available on their own through the API | — |
| **Diagrams** | OpenSysML | It also draws, but only through the API | [output](output/09-diagram-interconnection-opensysml.puml) |

`%check`, `%explain` and `%optimize` are commands of OpenSysML's REPL
(`sysml drone.sysml`).

**Two points in the Toolkit's favor** (where OpenSysML gets it wrong):

- **Mass with a big battery:** the Toolkit replaces the mass by its formula and
  **proves** it impossible; OpenSysML's Z3 treats the mass as one more unknown and
  "finds" a false solution (`takeoffMass = 25000`).
  → [output/10-check-bigBattery-opensysml.txt](output/10-check-bigBattery-opensysml.txt)
- **Exact number (√2):** the Toolkit returns it as an exact number; OpenSysML
  **refuses**, because its evaluator uses rationals and cannot hold it.
  → [output/10-check-squarePanel-opensysml.txt](output/10-check-squarePanel-opensysml.txt)
