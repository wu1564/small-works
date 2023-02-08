#include <iostream>
#include "Test.h"

using namespace std;

int main()
{
    int num;
    cin >> num;
    cout << num + 1 << "\n1";
    Test t(10);

    cout << t.show() << "\n";
    t.add();
    cout << t.show() << "\n";
}
