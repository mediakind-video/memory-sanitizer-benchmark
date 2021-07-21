#include <cstdio>

int main(int argc, char** argv)
{
    // Values on the stack are default-initialized, so the printed value is
    // indeterminate.
    int values[5];
    printf("%d\n", values[argc]);
    return 0;
}
