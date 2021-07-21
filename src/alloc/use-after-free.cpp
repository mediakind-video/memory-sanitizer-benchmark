#include <cstdio>
#include <cstdlib>

int main(int argc, char** argv)
{
    int* values = (int*)malloc(5 * sizeof(int));
    for (int i = 0; i != 5; ++i)
        values[i] = i;

    free(values);

    // values has been released, so values[argc] is indeterminate.
    printf("%d\n", values[argc]);

    return 0;
}
