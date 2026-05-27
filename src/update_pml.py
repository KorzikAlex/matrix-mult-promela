#!/usr/bin/env python3
"""
update_pml.py — редактирует main.pml под заданные N, P и значения матриц.

Использование:
    python update_pml.py [опции]

Опции:
    -f, --file FILE     путь к .pml файлу (по умолчанию main.pml)
    -N INT              размер матрицы N×N
    -P INT              количество воркеров
    --A INT [INT ...]   N*N значений матрицы A (построчно)
    --B INT [INT ...]   N*N значений матрицы B (построчно)

Если --A / --B не указаны:
    A заполняется случайными значениями 0..5
    B заполняется случайными значениями 0..5
"""

import re
import sys
import argparse
from random import randint


# ─── матричное умножение ──────────────────────────────────────────────────────

def matmul(A: list[int], B: list[int], N: int) -> list[int]:
    """Вычисляет C = A*B для матриц N×N, хранящихся в плоском списке."""
    C = [0] * (N * N)
    for i in range(N):
        for j in range(N):
            s = 0
            for k in range(N):
                s += A[i * N + k] * B[k * N + j]
            C[i * N + j] = s
    return C


# ─── генераторы секций ────────────────────────────────────────────────────────

def gen_init_matrices(A: list[int], B: list[int], N: int) -> str:
    lines = ["inline init_matrices()", "{"]
    for i in range(N):
        row = "    " + " ".join(f"A[{i*N+j}] = {A[i*N+j]};" for j in range(N))
        lines.append(row)
    lines.append("")
    for i in range(N):
        row = "    " + " ".join(f"B[{i*N+j}] = {B[i*N+j]};" for j in range(N))
        lines.append(row)
    lines.append("}")
    return "\n".join(lines)


def gen_valid_product(C: list[int], N: int) -> str:
    """#define valid_product с проверкой всех N*N значений матрицы C."""
    terms = [f"C[{i}]=={C[i]}" for i in range(N * N)]
    # По 4 условия на строку для читаемости
    chunks = [terms[i:i+4] for i in range(0, len(terms), 4)]
    joined = " && \\\n     ".join(" && ".join(chunk) for chunk in chunks)
    return f"#define valid_product \\\n    ({joined})"


def gen_manager_if(P: int) -> str:
    """Недетерминированный if менеджера с P ветками."""
    lines = [
        "// менеджер: недетерминированно выбирает любого свободного воркера и выдаёт задачу",
        "    do",
        "    :: workers_active > 0 ->",
        "        if",
    ]
    for p in range(P):
        lines += [
            f"        :: task_column[{p}] == -1 ->",
            f"            if :: next_col < N -> task_column[{p}] = next_col; next_col++",
            f"               :: else         -> task_column[{p}] = N",
            f"            fi",
        ]
    lines += [
        "        :: workers_active == 0 -> break",
        "        fi",
        "    :: else -> break",
        "    od;",
    ]
    return "\n".join(lines)


def gen_ltl_defines(P: int) -> str:
    """#define-ы, зависящие от P."""
    lines = []

    # task_bounds_ok
    terms = [f"task_column[{p}] >= -1 && task_column[{p}] <= N" for p in range(P)]
    if len(terms) == 1:
        lines.append(f"#define task_bounds_ok ({terms[0]})")
    else:
        joined = " && \\\n     ".join(f"({t})" for t in terms)
        lines.append(f"#define task_bounds_ok \\\n    ({joined})")

    lines.append("")

    # no_dup_ij для каждой пары воркеров
    pairs = [(i, j) for i in range(P) for j in range(i + 1, P)]
    for i, j in pairs:
        lines.append(
            f"#define no_dup_{i}{j} "
            f"(task_column[{i}] == -1 || task_column[{i}] == N "
            f"|| task_column[{i}] != task_column[{j}])"
        )

    # no_col_conflict объединяет все пары
    if pairs:
        conflict = " && ".join(f"no_dup_{i}{j}" for i, j in pairs)
    else:
        conflict = "1"
    lines.append(f"#define no_col_conflict ({conflict})")

    return "\n".join(lines)


# ─── замены в тексте файла ────────────────────────────────────────────────────

def replace_define(text: str, name: str, value) -> str:
    return re.sub(
        rf"(#define\s+{name}\s+)\S+",
        rf"\g<1>{value}",
        text,
    )


def replace_block(text: str, pattern: str, replacement: str, flags=re.DOTALL) -> str:
    m = re.search(pattern, text, flags)
    if not m:
        print(f"[WARN] блок не найден по паттерну: {pattern[:60]}...", file=sys.stderr)
        return text
    return text[: m.start()] + replacement + text[m.end() :]


# ─── дефолтные матрицы ────────────────────────────────────────────────────────

def default_A(N: int) -> list[int]:
    return [randint(0, 8) for _ in range(N * N)]


def default_B(N: int) -> list[int]:
    return [randint(0, 8) for _ in range(N * N)]


# ─── main ─────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Обновляет main.pml под заданные N, P и значения матриц"
    )
    parser.add_argument("-f", "--file", default="main.pml", help="путь к .pml файлу")
    parser.add_argument("-N", type=int, required=True, help="размер матрицы N×N")
    parser.add_argument("-P", type=int, required=True, help="количество воркеров")
    parser.add_argument("--A", type=int, nargs="+", help="N*N значений матрицы A")
    parser.add_argument("--B", type=int, nargs="+", help="N*N значений матрицы B")
    args = parser.parse_args()

    N, P = args.N, args.P

    # валидация
    if N < 1 or P < 1:
        sys.exit("Ошибка: N и P должны быть >= 1")

    A = args.A or default_A(N)
    B = args.B or default_B(N)

    if len(A) != N * N:
        sys.exit(f"Ошибка: для матрицы A нужно {N*N} значений, передано {len(A)}")
    if len(B) != N * N:
        sys.exit(f"Ошибка: для матрицы B нужно {N*N} значений, передано {len(B)}")

    # вычисляем ожидаемое произведение
    C = matmul(A, B, N)

    # предупреждение: byte в Promela хранит 0..255
    overflow = [(i, C[i]) for i in range(N * N) if not (0 <= C[i] <= 255)]
    if overflow:
        print("[WARN] некоторые значения C выходят за пределы byte (0..255):", file=sys.stderr)
        for idx, val in overflow:
            row, col = divmod(idx, N)
            print(f"  C[{row}][{col}] = {val}", file=sys.stderr)
        print("[WARN] измените тип массива C в .pml на int", file=sys.stderr)

    with open(args.file, encoding="utf-8") as f:
        text = f.read()

    # 1. #define N и #define P
    text = replace_define(text, "N", N)
    text = replace_define(text, "P", P)

    # 2. inline init_matrices()
    text = replace_block(
        text,
        r"inline init_matrices\(\)\s*\{.*?\}",
        gen_init_matrices(A, B, N),
    )

    # 3. #define valid_product — однострочный или многострочный (с \)
    #    flags=0: без re.DOTALL, чтобы . не захватывал переносы строк других #define
    text = replace_block(
        text,
        r"#define valid_product(?:.*?\\\n)*[^\n]*",
        gen_valid_product(C, N),
        flags=0,
    )

    # 4. блок менеджера — от комментария до od;
    text = replace_block(
        text,
        r"// менеджер:.*?od;",
        gen_manager_if(P),
    )

    # 5. #define task_bounds_ok … no_col_conflict (весь блок)
    text = replace_block(
        text,
        r"#define task_bounds_ok.*?#define no_col_conflict[^\n]*",
        gen_ltl_defines(P),
    )

    with open(args.file, "w", encoding="utf-8") as f:
        f.write(text)

    print(f"Обновлён {args.file}: N={N}, P={P}")
    print(f"  A = {A}")
    print(f"  B = {B}")
    print(f"  C = A*B = {C}")


if __name__ == "__main__":
    main()
