#include "HeaderFile.h"

int cmp_funcadr_variable;
int* cmp_funcadr_function(){
	return &cmp_funcadr_variable;
}

int* return_local_function (){
	int buf[5];
	return buf;  /*ERROR: return - pointer to local variable */
}

int int_not_return_function (int flag){
	char buf[10];
	int ret = flag / 0;  /* ERROR:division by zero */
	buf[10] = ret;  /*ERROR: buffer overrun */
	if (flag == 0){
		if (cmp_funcadr_function == NULL){  /*ERROR:compare function address with NULL*/
			int *p;
			p = return_local_function();
			return *p;
		}
	}
}  /*ERROR: No return value */

int main (){
	int_not_return_function (1);
	return 0;
}