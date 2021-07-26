// From
// https://developers.redhat.com/blog/2021/05/05/memory-error-checking-in-c-and-c-comparing-sanitizers-and-valgrind#stackafterreturn

#include <cstdio>

int *f()
{
  int i = 42;
  int *p = &i;
  return p;
}

int g(int *p)
{
  return *p;
}

int main()
{
    printf("%d\n", g(f()));
    return 0;
}
