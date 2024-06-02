#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <set>
#include <string>
#include <iostream>

// process each line
void process_line(const char *line, std::set<std::string>& string_set, std::set<int>& number_set) {
    char str[100];
    int num;
    sscanf(line, "%[^,],%d", str, &num); // get string and number of each line
    string_set.insert(str);
    number_set.insert(num);
}

int main() {
    FILE *file;
    char line[256]; // max len each line
    std::set<std::string> string_set;
    std::set<int> number_set;

    file = fopen("path_record.txt", "r");
    if (file == NULL) {
        printf("Unable to open file\n");
        return 1;
    }
    
    while (fgets(line, sizeof(line), file) != NULL) {
        // remove \n
        if (line[strlen(line) - 1] == '\n') {
            line[strlen(line) - 1] = '\0';
        }
        process_line(line, string_set, number_set);
    }

    fclose(file);

    printf("Number of strings: %lu\n", string_set.size());
    printf("Number of numbers: %lu\n", number_set.size());
    int bug_number = 0;
    for (auto it = number_set.begin(); it != number_set.end(); ++it) {
        if (*it >= 1) {
            bug_number++;
        }
    }
    std::cout << "Number of values lead to a bug: " << bug_number << std::endl;
    
    return 0;
}
