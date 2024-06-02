#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <stdint.h>
#include <signal.h> 

#define N 10 // problem size N, to adjust as needed, make sure it's much smaller than 64

int beta(unsigned long int output) { // beta function, to adjust as needed
    return output == 42; // very little chance to get bug
    // return output < 16; 
    // return output >= 1; // default being easy to find bugs
}

int main(int argc, char **argv) {
    unsigned long int input;
    unsigned long int output = 0;
    int k = 0;
    unsigned long int tmp;
    FILE *f = fopen("path_record.txt", "a"); 
    while (1){
        output = 0;
        input = 0;
        k = 0;
        for (int i = 0; i < 64; i += 32) {
            input |= ((unsigned long int)rand() << i);
        }
        tmp = input % (1UL << N);
        for (int i = 1; i <= N; i++) {
            if (tmp % 2) {
                output += 1UL << k;
                fprintf(f, "B"); // Newline for each input path
                // fprintf(f, "1"); // Newline for each input path
            }else{
                // fprintf(f, "0"); // Newline for each input path
            }
            fprintf(f, "A"); // Newline for each input path
            k++;
            tmp /= 2;
        }
        fprintf(f, ",%lu\n", output); // Newline for each input path
        if (beta(output)) {
            // raise(SIGSEGV); // Trigger a bug if the beta predicate is true
            fprintf(f, "Bug\n");
        }
    }
    fclose(f);
    return 0;
}
