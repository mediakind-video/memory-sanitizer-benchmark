// From
// https://www.usenix.org/legacy/publications/library/proceedings/usenix05/tech/general/full_papers/seward/seward_html/usenix2005.html

#include <cstdlib>
#include <cstdio>

void set_bit(int* array, int n)
{
    array[n/32] |= (1 << (n%32));
}

int get_bit(int* array, int n)
{
    return 1 & (array[n/32] >> (n%32));
}

int main(int argc, char** argv)
{
    int* array = (int*)malloc(10 * sizeof(int));
    set_bit(array, argc);

    // Reading from a bit that has never been set.
    printf("%d\n", get_bit(array, argc - 1));
    return 0;
}
