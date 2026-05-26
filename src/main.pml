/* * 
* \author Коршков А. А. (3343);Жучков О.Д. (3343)
* Вариант 2(3)
*/ 
// Размерность матриц
#define N 3
// Количество процессов для параллельного умножения
#define P 3 
// Процесс, который будет выводить результат
#define STOP_P 0

// Инициализируем три матрицы для умножения
// A - первая матрица
int A[N * N];
// B - вторая матрица
int B[N * N];
// C - результат умножения A и B
int C[N * N];

// Счетчик работающих Workerов
int workers_active = 0;

// Флаг соответствия матрицы C произведению матриц A и B
byte product_is_valid = 0;

//Заполняет единичную матрицу
inline identityMatrix(M)
{
	i = 0;
	i = 0;
    do
    :: i < N ->
        j = 0;
        do
        :: j < N ->
            if
            :: i == j -> M[i*N + j] = 1
            :: else   -> M[i*N + j] = 0
            fi;
            j++
        :: else -> break
        od;
        i++
    :: else -> break
    od;
}

// Заполняет матрицу числами от 1 до N*N
inline sequenceMatrix(M)
{
	i = 0;
	do
	:: i < N -> 
		j = 0;
		do
		:: j < N -> 
			M[i * N + j] = i * N + j + 1;
			j++
		:: else -> 
			break
		od;
		i++
	:: else -> 
		break
	od;
}

inline Matrix3_1(M){
	M[0] = 1; M[1] = 3; M[2] = 7;
	M[3] = 9; M[4] = 2; M[5] = 0;
	M[6] = 23; M[7] = 0; M[8] = 4;
}

inline Matrix3_2(M){
	M[0] = 9; M[1] = 7; M[2] = 4;
	M[3] = 71; M[4] =12; M[5] = 5;
	M[6] = 0; M[7] = 0; M[8] = 1;
}

inline init_matrices(M1, M2)
{
	Matrix3_1(M1);
	Matrix3_2(M2);
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
    int vi, vj, vk, vsum;
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
	int i,j;
	int p;

	init_matrices(A, B)

// Запуск P параллельных Worker'ов
    p = 0;
    do
    :: p < P ->
        run Worker(p);
        p++
    :: else -> break
    od;
}

// Worker wid вычисляет столбцы C[*, j] для j_start >= j > j_end 
proctype Worker(byte wid)
{
	workers_active++;
    int j_start, j_end;
    int i, j, k;
    int s;

    j_start = (N * wid) / P;
    j_end   = (N * (wid + 1)) / P;

    i = 0;
    do
    :: i < N ->
        j = j_start;
        do
        :: j < j_end ->
            s = 0;
            k = 0;
            do
            :: k < N ->
                s = s + A[i*N + k] * B[k*N + j];
                k++
            :: else -> break
            od;
            C[i*N + j] = s;
			// можно увидеть, какой по счету процесс ответственный за какие столбцы
			// C[i*N + j] = wid;
            j++
        :: else -> break
        od;
        i++
    :: else -> break
    od;

	// Один из процессов выводит матрицу по завершении умножения
	if
	:: wid == STOP_P ->
		int p = 0;
		do
		:: p < P ->
			// Ожидание завершения всех остальных процессов
			(workers_active == 1);
			p++
		:: else -> break
		od;
		printf("Матрица A:\n");
		printMatrix(A);
		printf("Матрица B:\n");
		printMatrix(B);
		printf("Произведение A и B:\n");
		printMatrix(C);
		validateMatrixProduct();
		printf("Результат проверен: C == A*B\n");
	:: else -> skip
	fi
	workers_active--;
}

#define no_active_workers   (workers_active == 0)
#define all_workers_active  (workers_active == P)
#define some_workers_active (workers_active > 0)
#define valid_worker_count (workers_active >= 0 && workers_active <= P)
#define valid_product (product_is_valid == 1)

// Программа точно заканчивает работу
ltl termination     { <> ([] no_active_workers) }
// Если процесс начал работу, то он её когда-нибудь завершит
ltl no_starvation { [] (some_workers_active -> <> no_active_workers) }
// Работа когда-нибудь завершится и с верным результатом
ltl correct { <> [] (no_active_workers && valid_product) }
// Счетчик рабочих процессов никогда не принимает неправильные значения
ltl worker_count_safety { [] valid_worker_count }