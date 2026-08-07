/* ************************************************************************* */
/* *                       Decompiled code via GHIDRA                      * */
/* ************************************************************************* */

// /* Function: FUN_080484a0. Address: 080484a0 */

// void FUN_080484a0(void)

// {
//   (*(code *)PTR_08049b4c)();
//   return;
// }


// /* Function: ~Init. Address: 08048500 */

// /* WARNING: Switch with 1 destination removed at 0x08048500 */
// /* std::ios_base::Init::~Init() */

// void __thiscall std::ios_base::Init::~Init(Init *this)

// {
//   do {
//                     /* WARNING: Do nothing block with infinite loop */
//   } while( true );
// }


// /* Function: frame_dummy. Address: 080485d0 */

// /* WARNING: Removing unreachable block (ram,0x080485e8) */

// void frame_dummy(void)

// {
//   return;
// }


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
