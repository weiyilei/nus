#include "HeaderFile.h"

int* return_local (){
	int buf[5];
	return buf;  /*ERROR: return - pointer to local variable */
}

int divided_by_zero(int dividend){
    dividend %= 0;  /* ERROR:division by zero */
    return dividend;
}

int buf_underrun(){
    int buf[10];
    for(int i = 4; i >= -1; i--){
        buf[i] = i;  /*ERROR:Buffer Underrun*/
    }
    return return_local();
}

int buf_overrun(int num){
    int buf[10];
    buf[20] = num;  /*ERROR: buffer overrun */
}

void useless_assignment(){
    int useless_assignment = 1;  /*ERROR:Useless Assignment */
}

int main(){
    int i = 5;
    if(i == 1){
        return_local();
    }else if(i == 2){
        buf_underrun();
    }else if(i == 3){
        useless_assignment();
    }else if(i == 4){
        buf_overrun(20);
    }else{
        divided_by_zero(200);
    }
    return 0;
}