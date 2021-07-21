#include <cstdio>
#include <cassert>

struct some_struct
{
    int values[5] = {1, 2, 3, 4, 5};
    int post = 6;
};

// Run the program with four arguments to trigger a read from a struct field
// located after the expected array.
int main(int argc, char** argv)
{
    some_struct s;

    assert(&s.post == s.values + 5);
    printf("%d\n", s.values[argc]);
    return 0;
}
