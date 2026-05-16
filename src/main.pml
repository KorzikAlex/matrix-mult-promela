#define N 5

init {
// Инициализируем двумерный массив одним куском в памяти
	int arr[N * N];
	int i,j;

// заполним матрицу числами от 1 до 25
	i = 0;
	do
	:: i < N ->
		j = 0;
		do
		:: j < N ->
			arr[i * N + j] = i * N + j + 1;
			j++
		:: else ->
			break
		od;
		i++
	:: else ->
		break
	od;

// выведем матрицу построчно
	i = 0;
	do
	:: i < N ->
		j = 0;
		do
		:: j < N ->
			printf("%d",arr[i * N + j]);
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
