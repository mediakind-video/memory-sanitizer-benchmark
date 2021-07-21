#include <cstdio>

// Run the program with no argument to trigger an out of bounds read.
int main(int argc, char** argv)
{
    int* values = new int[5]{1, 2, 3, 4, 5};
    printf("%d\n", values[-argc]);
    delete[] values;
    return 0;
}
