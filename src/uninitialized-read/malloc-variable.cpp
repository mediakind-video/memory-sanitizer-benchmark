#include <cstdio>
#include <cstdlib>

// Run this program with less than four arguments to read from an unitialized
// memory location.
int main(int argc, char** argv)
{
    int* values = (int*)malloc(5 * sizeof(int));

    printf("%d\n", values[argc]);

    free(values);
    return 0;
}
