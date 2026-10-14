/* ************************************************************************* */
/* *                       Decompiled code via GHIDRA                      * */
/* ************************************************************************* */

// /* Function: main. Address: 080485f4 */

// void main(int param_1,int param_2)

// {
//   N *this;
//   N *this_00;
  
//   if (param_1 < 2) {
//                     /* WARNING: Subroutine does not return */
//     _exit(1);
//   }
//   this = operator_new(0x6c);
//   N::N(this,5);
//   this_00 = operator_new(0x6c);
//   N::N(this_00,6);
//   N::setAnnotation(this,*(char **)(param_2 + 4));
//   (*(code *)**(undefined4 **)this_00)(this_00,this);
//   return;
// }


// /* Function: _GLOBAL__sub_I_main. Address: 080486da */

// void _GLOBAL__sub_I_main(void)

// {
//   __static_initialization_and_destruction_0(1,0xffff);
//   return;
// }


// /* Function: N. Address: 080486f6 */

// /* N::N(int) */

// void __thiscall N::N(N *this,int param_1)

// {
//   *(undefined ***)this = &PTR_operator__08048848;
//   *(int *)(this + 0x68) = param_1;
//   return;
// }


// /* Function: setAnnotation. Address: 0804870e */

// /* N::setAnnotation(char*) */

// void __thiscall N::setAnnotation(N *this,char *param_1)

// {
//   size_t __n;
  
//   __n = strlen(param_1);
//   memcpy(this + 4,param_1,__n);
//   return;
// }


// /* Function: operator+. Address: 0804873a */

// /* N::TEMPNAMEPLACEHOLDERVALUE(N&) */

// int __thiscall N::operator+(N *this,N *param_1)

// {
//   return *(int *)(param_1 + 0x68) + *(int *)(this + 0x68);
// }


// /* Function: operator-. Address: 0804874e */

// /* N::TEMPNAMEPLACEHOLDERVALUE(N&) */

// int __thiscall N::operator-(N *this,N *param_1)

// {
//   return *(int *)(this + 0x68) - *(int *)(param_1 + 0x68);
// }

/* ************************************************************************* */
/* *                      Manually reconstructed code                      * */
/* ************************************************************************* */

#include <cstring>
#include <iostream>

class N {
    private:
        // This is injected by the compiler when at least one virtual function is declared.
        // Given a static offset, it allows to call the correct virtual function implementation for a given object.
        void    ***vtbl;
        char    annotation[100];
        int     nbr;

    protected:

    public:

        N(int nbr): nbr(nbr) {}

        ~N() {}

        void    setAnnotation(char *annotation) {
            memcpy(this->annotation, annotation, strlen(annotation));
        }

        virtual int operator+(N &other) {
            return this->nbr + other.nbr;
        }

        virtual int operator-(N &other) {
            return this->nbr - other.nbr;
        }
};

/* Function: main. Address: 080485f4 */

int main(int argc, char **argv) {
    N *n1 = NULL;
    N *n2 = NULL;

    if (argc < 2)
        return 1;

    n1 = new N(5); // <=> malloc(108) <=> malloc(sizeof(N))
    n2 = new N(6); // <=> malloc(108) <=> malloc(sizeof(N))

    n1->setAnnotation(argv[1]);
    *n2 + *n1;

    return 0;
};
