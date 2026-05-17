/* * 
* \author Коршков А. А. (3343);Жучков О.Д. (3343)
* Вариант 2(3)
*/ 
// Размерность матриц
#define N 3 
// Количество процессов для параллельного умножения
#define P 2 
// Процесс, который будет выводить результат
#define STOP_P 0

// Инициализируем три матрицы для умножения
// A - первая матрица
int A[N * N];
// B - вторая матрица
int B[N * N];
// C - результат умножения A и B
int C[N * N];

// Печать матрицы N * N
inline printMatrix(M) 
{
	int id = 0;
	do
	:: id < N -> 
		int jd = 0;
		do
		:: jd < N -> 
			printf("%d ",M[id * N + jd]);
			jd++
		:: else -> 
			break
		od;
		printf("\n");
		id++
	:: else -> 
		break
	od;
}

init {
	int i,j,k;
	int sum;
	
// Инициализация матрицы A (заполняем числами от 1 до N*N)
	i = 0;
	do
	:: i < N -> 
		j = 0;
		do
		:: j < N -> 
			A[i * N + j] = i * N + j + 1;
			j++
		:: else -> 
			break
		od;
		i++
	:: else -> 
		break
	od;
	
// Инициализация матрицы B (единичная матрица)
	i = 0;
	do
	:: i < N -> 
		j = 0;
		do
		:: j < N -> 
			B[i * N + j] = 1;
			j++
		:: else -> 
			break
		od;
		i++
	:: else -> 
		break
	od;
	
// Умножение матриц A и B, результат сохраняется в C
	i = 0;
	do
	:: i < N -> 
		j = 0;
		do
		:: j < N -> 
			sum = 0;
			k = 0;
			do
			:: k < N -> 
				sum = sum + A[i * N + k] * B[k * N + j];
				k++
			:: else -> 
				break
			od;
			C[i * N + j] = sum;
			j++
		:: else -> 
			break
		od;
		i++
	:: else -> 
		break
	od;
	
// Вывод матрицы A
	printf("Matrix A:\n");
	printMatrix(A);
	
// Вывод матрицы B
	printf("Matrix B:\n");
	printMatrix(B);
	
// Вывод матрицы C
	printf("Matrix C:\n");
	printMatrix(C);

  // run Worker(STOP_P);
}

// proctype Worker(byte pid)
// {
//     if
//     :: pid == STOP_P ->
//         printMatrix(C)
//     :: else -> skip
//     fi
// }
