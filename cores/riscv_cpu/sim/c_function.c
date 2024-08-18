int add(int x, int y) {
   return x + y;
}

int sub(int x, int y) {
   return x - y;
}

int add2(int x) {
   return x + x;
}

int main() {
   int a = 1;
   int b = 2;
   int c = add(a, b);
   int d = sub(a, b);
   int e = add2(a);
   return 0;
}