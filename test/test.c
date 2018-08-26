#include <stdlib.h>
#include <string.h>
#include "unicode/ustdio.h"
#include "unicode/ustring.h"

#define BUFFERSIZE 128

int main()
{
    char buffer[BUFFERSIZE];

    printf("Enter a message: ");
    fgets(buffer, BUFFERSIZE, stdin);

    UErrorCode error = U_ZERO_ERROR;
    UChar *s16 = malloc(256*sizeof(UChar));
    u_strFromUTF8(s16, 256, NULL, buffer, strlen(buffer), &error);
    u_printf_u(u"%S\n", s16);

    free(s16);
}
