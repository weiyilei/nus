#include "HeaderFile.h"

pthread_mutex_t livelock_mutex;

static int divisor = 1;
int zero_division(int dividend){
	dividend %= divisor;  /* ERROR:division by zero */
    return dividend;
}

void *mythread(void *pram){
    char buf[10];
    strcpy(buf, "ClangCons");
	while(1){
		int status=pthread_mutex_trylock(&livelock_mutex);  /* ERROR:Lock Never Unlock */  /* ERROR:Live Lock */  
		if(status==0){
	        int len = strlen(buf) - 1;
	        while(buf[len] != 'Z'){
		        len--;  /* Stack Under RUN error */
                if((len == 1) && (len == 2)){  /*ERROR:contradict condition*/
                    buf[-1] = 'Q';  /*ERROR:Buffer Underrun*/
                }
                divisor--;
                zero_division(999);
            }
		}else{
            status=pthread_mutex_trylock(&livelock_mutex);
        }
	}
    return NULL;
}

void live_lock(){
    pthread_t firstThread,secondThread;
	pthread_mutex_init(&livelock_mutex,NULL);
    pthread_create(&firstThread,NULL,mythread,NULL);
	pthread_create(&secondThread,NULL,mythread,NULL);
    pthread_join(firstThread,NULL);
	pthread_join(secondThread,NULL);
}

int main (){
	live_lock();
	return 0;
}