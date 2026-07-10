/* ************************************************************************* */
/* *                       Code décompilé via GHIDRA                       * */
/* ************************************************************************* */

// void main(void)

// {
//   char local_50 [76];
  
//   gets(local_50);
//   return;
// }

/* ************************************************************************* */
/* *                       Code restitué manuellement                      * */
/* ************************************************************************* */

/*
* Ce code n'est pas 100% fidèle à l'original, mais il est fonctionnel,
* plus lisible et conserve la vulnérabilité à exploiter.
*/

#include <stdio.h>

int	main(void) {
	char	buffer[76];

	gets(buffer);
	return 0;
}
