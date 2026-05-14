# Matrix Multiplication Algorithm in Promela

This project implements a **parallel matrix multiplication algorithm** in **Promela**, verified using the **SPIN model checker**, with **iSpin compatibility**. The goal is to model a distributed‑style computation where `P` processes cooperatively multiply two `n × n` matrices, each process computing a portion of the result.

Before generating any code, **GitHub Copilot must**:

1. **Search the web** for the latest information on:
   - The **Promela language**.
   - The **SPIN model checker**.
   - The **iSpin GUI**.
2. **Review the `MasterTechReport.pdf`** manual, especially the **Promela grammar and modeling style** used in your course.
3. Ensure the generated Promela model matches your course’s conventions (macros, types, and structure).

---

## Overview

Implement a **parallel algorithm** that computes the product of **two** `n × n` matrices, `A` and `B`, producing a result matrix `C` of size `n × n`.

Your Promela model must:

- Be written in **Promela** (file extension `.pml`).
- Be **verifiable using SPIN** in both simulation and exhaustive verification modes.
- Be **compatible with iSpin** (loadable and verifiable via the iSpin GUI).
- Include a clear **task description** and **LTL properties** documented in this `README.md`.

---

## Task description

### Goal

Implement a **parallel algorithm** for matrix multiplication:

- Matrix size: `n × n`, where `n` is a fixed constant (e.g., `#define N 3`).
- Number of processes: `P` (`#define P ...`), where `P ≥ 1`.
- Each process is responsible for computing **one or more columns** of the result matrix `C` in parallel.
- The input matrices `A` and `B` are **loaded onto the processes beforehand** (e.g., via global arrays or pre‑initialized variables).
- Communication between processes (if needed) must use **shared variables** (global variables and optionally channels, but data exchange must be primarily via shared state).
- After multiplication completes, **process 0** outputs the result (e.g., via `printf` or model assertions).
- The algorithm should be of **medium complexity**: enough parallelism to be interesting, but not an overly complex distributed protocol.

### Mathematical formula

The standard matrix multiplication formula is:

\[
C[i][j] = \sum_{k=0}^{n-1} A[i][k] \cdot B[k][j]
\]

for all `0 ≤ i, j < n`.

If processes are assigned by **columns**, then process `p` computes `C[*, j]` for some subset of column indices `j`.

Use **shared variables** for coordination (e.g., completion flags, counters, or per‑column buffers), not complex message passing.

---

## Promela and SPIN specifics

### Promela model

- The implementation must be written in **Promela** in a file such as `matrix_mult.pml`.
- The model must:
  - Define global constants: `#define N ...` and `#define P ...`.
  - Declare global arrays for `A`, `B`, and `C` (e.g., `byte` or `int` arrays).
  - Define a `proctype` for the worker process that computes a range of columns.
  - Initialize the matrices and launch `P` processes.
  - Use **shared variables** (flags, counters, etc.) for synchronization.
  - Ensure that **process 0** prints or asserts the final result matrix.

Example high‑level structure (to guide GitHub Copilot):

```promela
#define N 3
#define P 3

byte A[N][N];
byte B[N][N];
byte C[N][N];

byte done[P];    /* shared completion flags */

active [P] proctype Worker()
{
    byte pid = _pid;
    int j_start, j_end;

    /* assign columns to this process */
    j_start = (N * pid) / P;
    j_end   = (N * (pid+1)) / P;

    /* compute C[*, j] for j in [j_start, j_end) */
    for (int i = 0; i < N; i++)
        for (int j = j_start; j < j_end; j++) {
            C[i][j] = 0;
            for (int k = 0; k < N; k++)
                C[i][j] += A[i][k] * B[k][j];
        }

    done[pid] = 1;
}

init
{
    /* initialize A and B */
    /* ... */

    /* launch P processes */
    /* ... */

    /* wait for all processes */
    /* ... */

    /* process 0 prints C */
    if (P > 0)
        printf("Result C:\n");
        for (int i = 0; i < N; i++) {
            for (int j = 0; j < N; j++)
                printf("%d ", C[i][j]);
            printf("\n");
        }
}
```

Adjust the column assignment and synchronization details to match your course style and complexity level.

### LTL properties (must be formulated)

On top of the implementation, formulate **LTL properties** that describe correctness, safety, and liveness of the algorithm. Document them in this `README.md` and also include them in the Promela file using `ltl` declarations.

Examples of LTL properties:

- **Correctness of result:**  
  Once computation finishes, every `C[i][j]` equals the sum of `A[i][k] * B[k][j]`.  
  In SPIN terms, you can model this as an invariant and assert it after completion, and then express it as an LTL property such as:

  ```promela
  ltl p1 { [] (completed -> invariant_holds) }
  ```

- **Deadlock freedom:**  
  The system never reaches a deadlock:

  ```promela
  ltl p2 { !<>(deadlock) }
  ```

- **Termination guarantee:**  
  Eventually all processes finish:

  ```promela
  ltl p3 { <> (all_done) }
  ```

- **Process coordination:**  
  E.g., processes do not write to each other’s critical columns without synchronization.

Formulate at least three meaningful LTL properties and document them clearly.

---

## Required project structure

GitHub Copilot should generate a structure similar to:

```text
project/
├── README.md            # This file (human‑readable task description)
├── matrix_mult.pml      # Main Promela model
├── properties.ltl       # Optional: LTL properties in separate file (if allowed)
└── notes/               # Optional: notes on design choices, SPIN flags, etc.
```

Inside `matrix_mult.pml`, aim for:

1. Global constants: `#define N ...`, `#define P ...`.
2. Global arrays for `A`, `B`, `C`.
3. A `proctype Worker()` that computes a range of columns.
4. An `init` block that initializes matrices and launches `P` processes.
5. Synchronization via shared variables (flags, counters, etc.).
6. At the end, process 0 printing or asserting the result matrix.
7. LTL properties declared with `ltl`.

---

## Instructions for GitHub Copilot (internal)

These are **internal instructions** for GitHub Copilot to guide how it generates and edits this project.

1. **Before writing any Promela code:**
   - Search the web for the latest materials on:
     - Promela language.
     - SPIN model checker.
     - iSpin GUI.
   - Open/inspect the `MasterTechReport.pdf` (especially the Promela section) and respect its style, macros, and conventions.
   - If Promela examples in the manual use particular patterns (e.g., `#define`, `mtype`, `active` prefixes), mirror them.

2. **When generating Promela syntax:**
   - Use `byte` or `int` arrays for matrices if the model does not require floating‑point.
   - Prefer simple shared variables (global variables) over complex channel‑based patterns unless explicitly required.
   - Keep the model **readable** and close to the course’s idioms.
   - Ensure the model is **compile‑ and verifiable** with SPIN and iSpin.

3. **When suggesting LTL properties:**
   - Use proper SPIN‑style LTL syntax: `ltl p1 { ... }`, etc.
   - Focus on:
     - **Safety** (deadlock freedom, absence of bad states).
     - **Liveness** (eventual completion, progress).
     - **Correctness** (final result matches the expected formula).
   - Avoid overly complex temporal formulas; keep them aligned with the conceptual level of the course.

4. **When editing this README.md:**
   - Keep the description clear and aligned with the code.
   - Explicitly note any assumptions (e.g., fixed `N`, `P` values, specific initialization strategy, or column assignment rule).
   - If the model is extended (more processes, channels, or more complex coordination), update the README accordingly.

---

## Final note for the student

As a student, you should:

- Ensure the generated Promela model **compiles and runs** in SPIN and iSpin.
- Manually inspect the LTL properties and verify that they match the intended behavior.
- Test the model with **multiple values of `N` and `P`** (if allowed) to confirm scalability and absence of races.

This `README.md` should always accurately reflect the implemented algorithm and the verification strategy.
