/* * 
* \author Коршков А. А. (3343);Жучков О.Д. (3343)
* Вариант 2(3)
*/ 
// Размерность матриц
#define N 4
// Количество процессов для параллельного умножения
#define P 3 

// Инициализируем три матрицы для умножения
// A - первая матрица
byte A[N * N];
// B - вторая матрица
byte B[N * N];
// C - результат умножения A и B
byte C[N * N];

byte workers_active = 0;
byte done = 0;
byte columns_completed = 0;

// Задания воркеров: task_column[p] == -1      — воркер свободен (ждёт задачи),
//                                      0..N-1 — столбец для вычисления,
//                                      N      — сигнал завершения (stop)
int task_column[P];
byte next_col = 0;

inline init_matrices()
{
    A[0] = 3; A[1] = 4; A[2] = 4; A[3] = 2;
    A[4] = 3; A[5] = 6; A[6] = 1; A[7] = 4;
    A[8] = 3; A[9] = 1; A[10] = 0; A[11] = 8;
    A[12] = 3; A[13] = 6; A[14] = 5; A[15] = 5;

    B[0] = 0; B[1] = 5; B[2] = 2; B[3] = 3;
    B[4] = 8; B[5] = 4; B[6] = 7; B[7] = 0;
    B[8] = 6; B[9] = 8; B[10] = 7; B[11] = 5;
    B[12] = 2; B[13] = 7; B[14] = 6; B[15] = 5;
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

init {
    byte i, j, p;

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
    :: p < P -> workers_active++; run Worker(p); p++
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
        :: else ->  // все воркеры заняты - ждём: завершения или освобождения слота
            (workers_active == 0 ||
             task_column[0] == -1 || task_column[1] == -1 || task_column[2] == -1)
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
    done = 1;
}

// Worker ждёт задачу от менеджера, вычисляет столбец, сигнализирует готовность
proctype Worker(byte wid)
{
    byte my_col, i, k;
    byte s;
    do
    :: true ->
        // ждать пока менеджер выдаст задачу
        (task_column[wid] != -1);
        if
        :: (task_column[wid] == N) -> break // сигнал остановки
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
                //C[i*N + my_col] = wid;
                i++
            :: else -> break
            od
            task_column[wid] = -1; // освобождаем слот (менеджер увидит при пробуждении)
            columns_completed++;   // сигнал менеджеру: прогресс сделан
        fi
    od;
    workers_active--;
}

#define all_cols_completed columns_completed == N
#define no_active_workers   (workers_active == 0)
#define some_workers_active (workers_active > 0)
#define valid_product \
    (C[0]==60 && C[1]==77 && C[2]==74 && C[3]==39 && \
     C[4]==62 && C[5]==75 && C[6]==79 && C[7]==34 && \
     C[8]==24 && C[9]==75 && C[10]==61 && C[11]==49 && \
     C[12]==88 && C[13]==114 && C[14]==113 && C[15]==59)
#define valid_worker_count  (workers_active >= 0 && workers_active <= P)
#define task_bounds_ok \
    ((task_column[0] >= -1 && task_column[0] <= N) && \
     (task_column[1] >= -1 && task_column[1] <= N) && \
     (task_column[2] >= -1 && task_column[2] <= N))

#define no_dup_01 (task_column[0] == -1 || task_column[0] == N || task_column[0] != task_column[1])
#define no_dup_02 (task_column[0] == -1 || task_column[0] == N || task_column[0] != task_column[2])
#define no_dup_12 (task_column[1] == -1 || task_column[1] == N || task_column[1] != task_column[2])
#define no_col_conflict (no_dup_01 && no_dup_02 && no_dup_12)


// счётчик воркеров никогда не выходит за [0, P]
ltl worker_count_safety { [] valid_worker_count }
// task_column[p] принимает только допустимые значения
ltl task_bounds        { [] task_bounds_ok }
// менеджер никогда не назначает один столбец двум воркерам одновременно
ltl no_duplicate_cols  { [] (some_workers_active -> no_col_conflict) }
// программа точно завершит работу
ltl termination        { <> done }
// Завершение работы только после обработки всех столбцов
ltl done_after_all     { [] (done -> all_cols_completed) }
// работа когда-нибудь завершится с корректным результатом
ltl correct            { <> (done && valid_product) }