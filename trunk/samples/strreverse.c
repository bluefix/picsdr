   Fog Creek Software
Discussion Board




	

Reverse a string


The solution seems to assume a programming language, most likely C. The "solution" would be different if the language is Perl or Java, for example.

Java would let you use a string tokenizer on each word thereby eliminating the need for the second pass of reversing each word.

MPerico
Thursday, June 24, 2004

hmm, what do you mean, You can reverse a string with one pass in C/C++ using exclusive or.

colin nickerson
Friday, June 25, 2004

>You can reverse a string with one pass in C/C++ using exclusive or.

I am interested in the solution with the XOR  operator in one pass. Please, if you can post it here or send it to me via email, I'll be doubly grateful.

Sathyaish Chakravarthy
Wednesday, July 21, 2004

Basically, these were the possible implementations I could think of. For the last one, StrReverse4, I got the idea from a website the URL of which is mentioned in the code below:


#include <stdio.h>
#include <stdlib.h>
#include <string.h>


char* StrReverse(char*);
char* StrReverse1(char*);
char* StrReverse2(char*);
void StrReverse3(char*);
void StrReverse4(char*);

int main(void)
{

    char str[50];
    int temp=0;

    printf("Enter a string: ");
    scanf("%s", str);
    printf("The reverse of the string is: %s\n", StrReverse(str));
    printf("The reverse of the string is: %s\n", StrReverse1(str));
    printf("The reverse of the string is: %s\n", StrReverse2(str));

    StrReverse3(str);
    printf("The reverse of the string is: %s\n", str);
    
    //Get back the original string
    StrReverse3(str);
    
    //Reverse it again
    printf("The reverse of the string is: ");
    StrReverse4(str);
    printf("\n");

    scanf("%d", &temp);

}


char* StrReverse(char* str)
{
    char *temp, *ptr;
    int len, i;

    temp=str;
    for(len=0; *temp !='\0';temp++, len++);
    
    ptr=malloc(sizeof(char)*(len+1));
    
    for(i=len-1; i>=0; i--)
        ptr[len-i-1]=str[i];
    
    ptr[len]='\0';
    return ptr;
}

char* StrReverse1(char* str)
{
    char *temp, *ptr;
    int len, i;

    temp=str;
    for(len=0; *temp !='\0';temp++, len++);
    
    ptr=malloc(sizeof(char)*(len+1));
    
    for(i=len-1; i>=0; i--)
        *(ptr+len-i-1)=*(str+i);
    
    *(ptr+len)='\0';
    return ptr;
}

char* StrReverse2(char* str)
{
    int i, j, len;
    char temp;
    char *ptr=NULL;
    i=j=len=temp=0;

    len=strlen(str);
    ptr=malloc(sizeof(char)*(len+1));
    ptr=strcpy(ptr,str);
    for (i=0, j=len-1; i<=j; i++, j--)
    {
        temp=ptr[i];
        ptr[i]=ptr[j];
        ptr[j]=temp;
    }
    return ptr;
}

void StrReverse3(char* str)
{
    int i, j, len;
    char temp;
    i=j=len=temp=0;

    len=strlen(str);
    for (i=0, j=len-1; i<=j; i++, j--)
    {
        temp=str[i];
        str[i]=str[j];
        str[j]=temp;
    }
}



/*A coooooooooool way of reversing a string by recursion. I found it at this web address
http://www.geocities.com/cyberkabila/datastructure/datastructuresright_reversestring.htm
*/

void StrReverse4(char *str)
{
    if(*str)
    {
        StrReverse4(str+1);
        putchar(*str);
    }
}

If you can provide me the solution with the XOR operator, I can study it. I shall be ever grateful.

Thanks!

Sathyaish Chakravarthy
Wednesday, July 21, 2004

I got the answer here.

http://www.codeguru.com/forum/showthread.php?p=982919&posted=1#post982919

But that's again an element-by-element XORing. I guess, there possibly wouldn't be a way to do it in a single sweep, would there?

Here's Guysl's solutions:

/*
Here on Joel's Tech Interviews forum, a guy suggested that he could reverse a string in one pass in C with the exclusive OR (XOR) operator

  http://discuss.fogcreek.com/techinterview/default.asp?cmd=show&ixPost=2077&ixReplies=3

I wondered and posted to all possible places like Code Guru, VB Forums, Comp.Lang.C UseNet forums
and got a reply from Guysl on Code Guru.
  http://www.codeguru.com/forum/showthread.php?p=982919&posted=1#post982919

*/

char* rev(char* str)
{
  int end= strlen(str)-1;
  int start = 0;

  while( start<end )
  {
    str[start] ^= str[end];
    str[end] ^=  str[start];
    str[start]^= str[end];

    ++start;
    --end;
  }

  return str;
}

Sathyaish Chakravarthy
Wednesday, July 21, 2004

Hi Colin,

I recieved your email, in which you said

================================

    Hello, here is the solution I use:

Suppose we want to swap whats in A with whats in B.
Let A = x and B = y.

So,
A = A XOR B
  then A = x XOR y
            B = y
B = A XOR B
  then A = x XOR y
            B = (x XOR y) XOR y
                = x XOR (y XOR y)
                = x
A = A XOR B
  then A = (x XOR y) XOR x
              = (y XOR x) XOR x
              = y XOR (x XOR x)
              = y

now B = x and A = y

There, the values have swapped with no other variables used.
Neet huh?

Anyways, If you want to post this in the forum your are referring to,
please feel free to.

================================

Thanks for the solution. I actually posted the question on several forums and recieved the same solution from here as well:

http://www.codeguru.com/forum/showthread.php?t=303185


The only problem I see with this solution is that:

(1) This is still an element-by-element reversal, as against a one pass reversal.

(2) This won't do any good with the median element, when the address of both the elements, A and B, is the same.

Thanks for the solution.

Sathyaish Chakravarthy
Wednesday, July 21, 2004

A 'pointers only' solution, FWIW:

char *rev( char *s)
{
  char c, *p, *q;
  if (s!=null && *s!=0) // No empty strings, please!
  {
    q = s;
    while (*(++q)) ; // points q at '0' terminator;
    for (p=s; p < --q; p++)  // ignores middle character when strlen is odd
    {
      c = *p;
      *p = *q;
      *q = c;
    }
  }
  return s;
}

This isn't as cute as the XOR approach and it costs an extra 'char' of stack space, but it saves a newbie maintainer from unnecessary mental gymnastics.

As was the XOR approach, this scheme is essentially 'one pass' because each element is indexed at most once. (After the pseudo 'strlen' line, of course)

Chuck Boyer
Thursday, August 12, 2004

Hmm!

Sathyaish Chakravarthy
Monday, August 16, 2004

In practice, for most compilers on Intel hardware the code

int tmp;
tmp = *b;
*b = *a;
*a = tmp;

will compile into a single XCHG instruction. However, most compilers will not figure out the equivalent

b ^= a;
a ^= b;
b ^= a;

Ham Fisted
Saturday, August 21, 2004

*  Recent Topics

*  Fog Creek Home
