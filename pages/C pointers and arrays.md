- In C, pointers and arrays are very related
- Anything that you can do with array subscripts can also be done with pointers
- # C pointers
	- The declaration
	  ```c
	  int i, *p, to_int(f double);
	  ```
	  Tells us that, expressions `i`, `*p`, and `to_int(6.6)` will yield an `int`
	- Like with other languages, C uses `*` for dereferencing data, and `&` to take address from variables
	- > C pointers can only point to objects in memory, such as variables and arrays. We cannot take address from expressions, constants, or `register` variables
	- Because C can only return 1 variables, pointers are used by functions to change data from the caller, like with `scanf`-like function `getint` from K&R:
	  ```c
	  int getint(int *p);
	  ```
	  This function returns an int as status indicator, while the data we want from it gets put into `*p`
- # C arrays
	- The declaration
	  ```c
	  int a[10];
	  ```
	  defines an array  named `a` of size 10
	- C array name *is* the pointer to the 0th element
	- Note that array names are not variable, so we can't reassign `a`
	- Like with other language, we can access elements with array subscript:
	  ```c
	  int i = a[10];   // Copy element at index 8 from a to i
	  int *p = &a[0]; // p now points to the first element of a
	  printf("%d\n", *(p+2)); // prints a[2]
	  ```
	- The array approach is internally identical to pointer approach, with the pointers having the benefit of being reassignable
		- C pointers and arrays are very interchangeable such that they share syntax:
		- If `a` is an array name, then `&a[i]` and `a+i` are also identical
		- If `a` is an array name, then `a[i]` and `*(a+i)` are identical
		- If `p` is a pointer to the start of an array, then `p[i]` and `*(p+i)` are identical
	- We can also slice an array by using a pointer that points to non-0 index, i.e. if we have this function `strlen` which expects a pointer to chars (or an array of chars):
	  ```c
	  int strlen(char *s) {
	    	char *p = s; // p points to s[0]
	    	while (*p != '\0') {
	        p++;
	      }
	    
	    	return p-s; // characters read
	  };
	  
	  int main(void) {
	   	int a[10];
	  	strlen(&a[8]); // strlen will see s as a char array of size 2 [a[8], a[9]]
	                     // i.e. s is &a[8]
	  }
	  ```
- # Pointer arithmetic
	- C pointers can be used in arithmetic operations, much like an `int`
	- C guarantees that 0 (`NULL` pointer) will never point to any data
		- `NULL` is defined in `stdio.h`
	- Pointer arithmetic can be used for array access:
	  
	  > This is true for array of all element types
	  
	  ```c
	  int a[10], *p;
	  for (int i = 0; i < 10; i++) {
	    a[i] = (i+1) * 100;
	  }
	  
	  p = &a[0];
	  printf("%d\n", *p);     // 100 (a[0])
	  printf("%d\n", *(p+1)); // 200 (a[1])
	  ```
	- However, pointers and non-0 ints are not interchangeable, except for 0. C allows pointer assignment of 0, and comparison with 0
	- ## Example: basic salloc
		- We'll implement basic memory management
		- Unlike `malloc`, memory will be statically initialized to a char array `char *sbuf`
		- `sbuf` states are tracked via `sbufp`, which points to the *next free location*
		- We will allocate memory with `char *salloc(int)`
		- And we'll free memory with `int sfree(char *p)`