#include <cstdio>

// Run this program with less than four arguments to read from an unitialized
// memory location.
int main(int argc, char** argv)
{
    int* values = new int[5];

    printf("%d\n", values[argc]);

    delete[] values;
    return 0;
}
