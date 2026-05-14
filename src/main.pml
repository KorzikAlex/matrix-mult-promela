#define N 5

init {
	int arr[N] = 0;
	int i;
	
// заполним массив числами от 1 до 5
	i = 0;
	do
	:: i < N -> 
		arr[i] = i + 1;
		i++
	:: else -> 
		break
	od;
	
// теперь выведем массив построчно
	i = 0;
	do
	:: i < N -> 
		printf("%d\n",arr[i]);
		i++
	:: else -> 
		break // просто завершаем процесс
	od;
}