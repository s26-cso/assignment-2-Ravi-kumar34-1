#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>

int main() {
    char op[10];
    int a, b;

    while (scanf("%s %d %d", op, &a, &b) == 3) {

        // build library name
        char libname[20];
        snprintf(libname, sizeof(libname), "./lib%s.so", op);

        // load library
        void *handle = dlopen(libname, RTLD_LAZY);
        if (!handle) {
            printf("Error loading library\n");
            continue;
        }

        // get function
        int (*func)(int, int);
        func = (int (*)(int, int)) dlsym(handle, op);

        if (!func) {
            printf("Function not found\n");
            dlclose(handle);
            continue;
        }

        // call function
        int result = func(a, b);
        printf("%d\n", result);

        // free library (IMPORTANT for memory)
        dlclose(handle);
    }

    return 0;
}