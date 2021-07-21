#include <cstdio>
#include <cstdlib>

int main(int argc, char** argv)
{
    int* values = new int[5];

    for (int i = 0; i != 5; ++i)
        values[i] = i;

    delete[] values;

    // values has been deleted, so values[argc] is indeterminate.
    printf("%d\n", values[argc]);

    return 0;
}
