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
int workers_active = P;

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
	int i,j;
	int p;

	sequenceMatrix(A);
	identityMatrix(B);	

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

    workers_active--;
	// Один из процессов выводит матрицу по завершении умножения
	if
	:: wid == STOP_P ->
		int p = 0;
		do
		:: p < P ->
			// Ожидание завершения всех процессов
			(workers_active == 0);
			p++
		:: else -> break
		od;
		printf("Матрица A:\n");
		printMatrix(A);
		printf("Матрица B:\n");
		printMatrix(B);
		printf("Произведение A и B:\n");
		printMatrix(C);
	:: else -> skip
	fi
}
