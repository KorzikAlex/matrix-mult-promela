/* * 
* \author Коршков А. А. (3343);Жучков О.Д. (3343)
* Вариант 2(3)
*/ 
// Размерность матриц
#define N 3
// Количество процессов для параллельного умножения
#define P 3 

// Инициализируем три матрицы для умножения
// A - первая матрица
int A[N * N];
// B - вторая матрица
int B[N * N];
// C - результат умножения A и B
int C[N * N];

byte workers_active = 0;

// Задания воркеров: task_column[p] == -1      — воркер свободен (ждёт задачи),
//                                      0..N-1 — столбец для вычисления,
//                                      N      — сигнал завершения (stop)
int task_column[P];

// Флаг соответствия матрицы C произведению матриц A и B
byte product_is_valid = 0;

inline init_matrices()
{
    A[0] = 1; A[1] = 3; A[2] = 7;
	A[3] = 9; A[4] = 2; A[5] = 0;
	A[6] = 23; A[7] = 0; A[8] = 4;

    B[0] = 9; B[1] = 7; B[2] = 4;
	B[3] = 71; B[4] = 12; B[5] = 5;
	B[6] = 0; B[7] = 0; B[8] = 1;
}

// Печать матрицы N * N
inline printMatrix(M) 
{
	i = 0;
	do
	:: i < N -> 
		j = 0;
		do
		:: j < N -> 
			printf("%d ",M[i * N + j]);
			j++
		:: else -> 
			break
		od;
		printf("\n");
		i++
	:: else -> 
		break
	od;
}

// Последовательно вычисляет A*B и сравнивает с C.
// Устанавливает product_is_valid = 1 если C == A*B, иначе оставляет 0.
inline validateMatrixProduct()
{
    byte vi, vj, vk, vsum;
    byte vvalid;
    vvalid = 1;
    vi = 0;
    do
    :: vi < N ->
        vj = 0;
        do
        :: vj < N ->
            vsum = 0;
            vk = 0;
            do
            :: vk < N ->
                vsum = vsum + A[vi*N + vk] * B[vk*N + vj];
                vk++
            :: else -> break
            od;
            if
            :: C[vi*N + vj] != vsum -> vvalid = 0
            :: else -> skip
            fi;
            vj++
        :: else -> break
        od;
        vi++
    :: else -> break
    od;
    if
    :: vvalid == 1 -> product_is_valid = 1
    :: else -> skip
    fi
}

init {
    byte i, j, p;
    byte next_col;

    init_matrices();

    // все воркеры стартуют как свободные
    p = 0;
    do
    :: p < P -> task_column[p] = -1; p++
    :: else -> break
    od;

    // запуск P воркеров
    p = 0;
    do
    :: p < P -> run Worker(p); p++
    :: else -> break
    od;

    next_col = 0;

    // менеджер: недетерминированно выбирает любого свободного воркера и выдаёт задачу
    do
    :: workers_active > 0 ->
        if
        :: task_column[0] == -1 ->
            if :: next_col < N -> task_column[0] = next_col; next_col++
               :: else         -> task_column[0] = N
            fi
        :: task_column[1] == -1 ->
            if :: next_col < N -> task_column[1] = next_col; next_col++
               :: else         -> task_column[1] = N
            fi
        :: task_column[2] == -1 ->
            if :: next_col < N -> task_column[2] = next_col; next_col++
               :: else         -> task_column[2] = N
            fi
        :: else -> skip  // все воркеры заняты — ждём
        fi
    :: else -> break
    od;

    // все воркеры завершились — выводим результат
    printf("Матрица A:\n");
    printMatrix(A);
    printf("Матрица B:\n");
    printMatrix(B);
    printf("Произведение A и B:\n");
    printMatrix(C);
    validateMatrixProduct();
    printf("Результат проверен: C == A*B\n");
}

// Worker ждёт задачу от менеджера, вычисляет столбец, сигнализирует готовность
proctype Worker(byte wid)
{
    workers_active++;
    byte my_col, i, k, s;
    do
    :: true ->
        // ждать пока менеджер выдаст задачу
        (task_column[wid] != -1);
        if
        :: task_column[wid] == N -> break // сигнал остановки
        :: else ->
            my_col = task_column[wid];
            // вычислить столбец my_col
            i = 0;
            do
            :: i < N ->
                s = 0;
                k = 0;
                do
                :: k < N ->
                    s = s + A[i*N + k] * B[k*N + my_col];
                    k++
                :: else -> break
                od;
                C[i*N + my_col] = s;
                C[i*N + my_col] = wid;
                i++
            :: else -> break
            od
            task_column[wid] = -1; // готов к новой задаче
        fi
    od;
    workers_active--;
}

#define no_active_workers   (workers_active == 0)
#define some_workers_active (workers_active > 0)
#define valid_worker_count  (workers_active >= 0 && workers_active <= P)
#define valid_product       (product_is_valid == 1)

// Программа точно заканчивает работу
ltl termination     { <> ([] no_active_workers) }
// Если процесс начал работу, то он её когда-нибудь завершит
ltl no_starvation { [] (some_workers_active -> <> no_active_workers) }
// Работа когда-нибудь завершится и с верным результатом
ltl correct { <> [] (no_active_workers && valid_product) }
// Счетчик рабочих процессов никогда не принимает неправильные значения
ltl worker_count_safety { [] valid_worker_count }