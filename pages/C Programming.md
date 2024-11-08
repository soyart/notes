- > Note: the notes are tested on macOS clang on M3 Pro
- # C types
	- > The standard (as per K&R) only specifies a few types
	- `int` (see also [[Integers]])
		- The standard does not guarantee size of `int`, but most implementations follow the machine's word size.
		- 2 size modifiers `short` and `long` applies to `int`
			- We can omit `int` when used with these 2 modifiers, i.e. `short int i = 7;` statement is identical to `short i = 7;`
			- On modern 64-bit architectures, `short` is 16-bit, `int` 32-bit, and `long` is 64-bit
		- 2 [sign](((66535f02-198f-4a35-9ae9-3a69721729ad))) modifiers `signed` and `unsigned` are also available for `int`, and plain `int` is always `signed int`.
		- The standard only specifies the following rules:
			- `int` must be at least 16-bit
			- `long` must be at least 32-bit
			- `short` <= `int` <= `long`
		- If we want to set/mask bits in a portable way, we can take advantage of [C type conversion](((6659e12f-ed51-4b62-ac5a-f34008127a90)))
			- For example, if we want to set in `x` the leftmost 6 bits to zero, we can do:
			  ```c
			  x & ~077 // 077  is: 000111111
			           // ~077 is: 111000000
			           // So the code always sets the 6 leftmost bits to 0, regardless of x's length
			  ```
			- Using `~077` is great, because we don't have to assume length of `x`
			- Since `077` is a constant, C will (at compile time) promote it to whatever `x` is according to its conversion rule
			- It would then apply the `~` operator, which flips all bits in the promoted value
	- `char`
		- > The standard library provides `ctypes.h` for working with C characters. It defines functions such as `isdigit`, `isspace`, `isupper`, `tolower`, etc.
		- `char` is a type meant for holding a character, usually 1 byte in size
		- `char` can be operated with arithmetics with other ints
		- The standard defines 3 separate types for `char`, namely `unsigned char`, `signed char`, and `char`.
		  id:: 6658bc6b-ee7c-4d11-8c97-15b80f0c8220
			- On gcc, `char` is by default signed. This allows us to use non-ASCII values to encode something else, like (stdio EOF) `-1` which is i32 on Apple M3.
			- To find out whether a plain `char` is signed or unsigned in an implementation, use `limits.h`:
			  ```c
			  #include <limits.h>
			  #include <stdio.h>
			  
			  int main(void)
			  {
			      printf("CHAR_MIN %d\n", CHAR_MIN);
			      printf("CHAR_MAX %d\n", CHAR_MAX);
			      printf("CHAR_BIT %d\n", CHAR_BIT);
			  
			      printf("SCHAR_MIN %d\n", SCHAR_MIN);
			      printf("SCHAR_MAX %d\n", SCHAR_MAX);
			  }
			  ```
			  
			  LLVM and gcc output (Apple M3):
			  ```
			  CHAR_MIN -128
			  CHAR_MAX 127
			  CHAR_BIT 8
			  SCHAR_MIN -128
			  SCHAR_MAX 127
			  ```
		- Because `char` can be signed or unsigned, and implementations differ across machines, conversion from `char` to integers might produce negative integers (even if all printable characters are positive)
			- On some machines, if a `char`'s leftmost bit is set to `1`, then converting it to integers might produce negative values
			- On other machines, a `char` is first promoted to integers by padding zeroes to the left (sign extension), and thus only producing positive value
		- This is why we might see small variables assigned to `unsigned char` - it's equivalent to a byte, or `u8` in Rust and `uint8` in Go
	- `float`
		- Single-precision floating point data type, usually 32-bit
	- `double` (double-precision floating point)
		- Double-precision floating point type.
		- Modifier `long` can be applied to produce a `long double`, which offers greater precision than a `double`, but the standard only requires `long double` to be *at least* as precise as `double`
	- ## Size (width) of C types
	  id:: 6658bded-c248-4077-b601-29a3225ccb23
		- On Apple M3 (arm64) using clang, here's the sizes of each types:
		  ```c
		  #include <stdio.h>
		  #include <stdlib.h>
		  
		  long countw(void);
		  
		  int main(void)
		  {
		      printf("size of short int in bytes: %ld\n", sizeof(short int));
		      printf("size of int in bytes: %ld\n", sizeof(int));
		      printf("size of long int in bytes: %ld\n", sizeof(long int));
		      printf("size of char in bytes: %ld\n", sizeof(char));
		      printf("size of float in bytes: %ld\n", sizeof(float));
		      printf("size of double in bytes: %ld\n", sizeof(double));
		      printf("size of long double in bytes: %ld\n", sizeof(long double));
		  }
		  ```
		  LLVM output on Apple M3:
		  ```
		  size of short int in bytes: 2
		  size of int in bytes: 4
		  size of long int in bytes: 8
		  size of char in bytes: 1
		  size of float in bytes: 4
		  size of double in bytes: 8
		  size of long double in bytes: 8
		  value of EOF -1
		  size of EOF in bytes: 4
		  ```
	- ## Type conversion
	  id:: 6659e12f-ed51-4b62-ac5a-f34008127a90
		- Floating point <-> integer conversions are rounded
		- `float` <-> `double` is implementation-dependent
		- ### No `unsigned` involved
			- Promotion from *narrower* types to *wider* types
				- > Exception: `float` are not automatically promoted to `double` to minimize memory
				- `char` is a small integer, so it can be promoted to integer types and participate in arithmetics as integers
					- We know that [`char` can be signed or unsigned](((6658bc6b-ee7c-4d11-8c97-15b80f0c8220))), so the conversion from `char` to integer types are quite tricky and machine-specific
				- In `float` and `int` arithmetics like `f+i`, the integer is promoted to `float` and the arithmetics are done on `float`
			- Lossy conversion may be allowed, but some warnings will be made
			- Nonsense conversion, like using a floating point as array index, is outright illegal
		- ### With `unsigned`
			- Generally *unsigned integer types of identical width are considered to be wider* than their signed counterparts
			- Behaviors are machine-dependent, due to the fact that it depends on integer types on the hardware
			- > Assume `int` is 16-bit and `long` is 32-bit.
			- `-1L < 1U`
				- Signed long `-1L` ints are wider than unsigned int `1U`.
				- `1U` is promoted to *signed long* `1L`
				- So this expression actually tested `-1L < 1L`
			- `-1L > 1UL`
				- `-1L` will be promoted to `unsigned long`
				- So `-1L` will have a `1` as its leftmost bit (from its previously signed bit, which, after conversion, is treated as a magnitude bit)
		- ### In assignments
			- When conversion is needed in assignments, the righthand side of the assignment is converted to the lefthand side and may cause data loss and overflows
			- #### Integers
				- When converting wider integers to narrower ones by dropping higher-order bit
				- In this snippet, `c` value is unchanged (lossless) because `int` is wider than `char`:
				  ```c
				  char c = 'a';
				  int i;
				  
				  i = c;
				  c = i;
				  ```
				- Reversing the order of assignments might lose data:
				  ```c
				  #include <stdio.h>
				  
				  int main(void)
				  {
				      int i = 300;
				      char c = 0;
				  
				      printf("i init %3d %o\t%x\n", i, i, i);
				      printf("c init %3d %o\t%x\n", c, c, c);
				  
				      c = i;
				      i = c;
				  
				      printf("i done %3d %o\t%x\n", i, i, i);
				      printf("c done %3d %o\t%x\n", c, c, c);
				  }
				  
				  ```
				  ```
				  i init 300 454	12c
				  c init  0  0	 0
				  i done 44 54	2c
				  c done 44 54	2c
				  ```
				- Or overflows:
				  ```
				  i init 256 400	100
				  c init   0 0	0
				  i done   0 0	0
				  c done   0 0	0
				  ```
				  ```
				  i init 255 377	ff
				  c init   0           0         0
				  i done  -1 37777777777	ffffffff
				  c done  -1 37777777777	ffffffff
				  ```
		- Explicit conversions have the following form:
		  ```
		  (type_name) expr
		  ```
		  So, if we have `double sqrt(double);` definition, and a `float`, then  we can call `sqrt` with:
		  ```c
		  // Like 'sqrt(float64(f))' in Go
		  // The value of f is converted to a double,
		  // and sent to sqrt. f itself did not change.
		  sqrt((double) f)
		  ```
		  Note that we might not have to do this if we have function prototype for `sqrt`, since function prototypes will coerce C to convert argument values to proper types as defined in the function's prototype.
- # [[C declarations and definitions]]
  id:: 6675b7f5-0dff-411f-84ee-f5a247849ac5
	- **Declaration** announces property of a name
	- **Definition** also sets aside the storage.
	- ## External variables
		- > **There must be only 1 definition of an external variable throughout the files being compiled**. Other files will have to use `extern` to access it
		- If these 2 lines **are outside of a function**:
		  ```c
		  int sp; // If external, is initialized to 0
		  double s[16]; // This sets aside storage of 16 double, and fill it with 0.00
		  ```**
		  Then they define `sp` and `s`
			- > Note: for local variables, use before definition will get garbage value:
			  
			  ```c
			  #include <stdio.h>
			  
			  int i = 'i';
			  int ext;
			  double f;
			  
			  int main(void)
			  {
			      int local;
			      extern int j;
			  
			      printf("i: %c\n", i);
			      printf("j: %c\n", j);
			  
			      printf("f: %f\n", f);
			      printf("ext: %d\n", ext);
			      printf("local: %d\n", local);
			  }
			  
			  int j = 'j';
			  ```
			  ```
			  i: i
			  j: j
			  f: 0.000000
			  ext: 0
			  local: 1
			  ```
		- However, this:
		  ```c
		  extern int sp;
		  extern double s[];
		  ```
		  **only declares the properties of `sp` and `s` to the rest of the source file**.  The last line only declares that `s` will be an array of `double`, whose size is determined/defined elsewhere
		- #### Visibility
			- Functions can see external variables if their declarations appear before the function definition.
			- In this example, `main` does not see `c`, but `f` does:
			  ```c
			  char f();
			  
			  int main(void)
			  {
			      int i = f();
			    	int c_int = c; // Compile error! no such variable c!
			  }
			  
			  char c = 'c';
			  char f()
			  {
			      return c;
			  }
			  
			  ```
			- Even if we put declaration of `char c;` in `main`, that `c` is not the same as external variable c:
			  ```c
			  #include <stdio.h>
			  
			  char f();
			  
			  int main(void)
			  {
			      char c;
			      int i = f();
			  
			      printf("main.c: %d\n", c);
			      printf("main.i: %d\n", i);
			      printf("i == c: %s\n", i == c ? "true" : "false");
			  }
			  
			  char c = 'c';
			  
			  char f()
			  {
			      return c;
			  }
			  ```
			  ```
			  main.c: 0
			  main.i: 99
			  i == c: false
			  ```
			- #### Basic scope rules
				- > Due to complexity of compiling C programs (i.e. may be compiled separately), there're many questions regarding scopes of external variables
				- The *scope* of a *name* is the part of the program from which the name can be referenced
				- Scopes of an local variable, like automatic variables and function parameters, are local to the function
				- Scopes of external a variable last from the line at which it's [declared](((6675b7f5-0dff-411f-84ee-f5a247849ac5))), *down until the end of the file being compiled*. In the snippet below, only functions `push` and `getsp` can see external variables`sp` and `v`:
				  ```c
				  #define MAXSP 100
				  int main() {}
				  
				  int sp = 0;
				  double v[MAXSP]
				  
				  void push(double v) {}
				  double getsp() { return sp; }
				  ```
		- #### `extern` declarations
			- [Declarations with `extern`](((6675b7f5-0dff-411f-84ee-f5a247849ac5))) can be used to refer to variables before their definition, or if it's [defined](((6675b7f5-0dff-411f-84ee-f5a247849ac5))) in a different file
			- This allows `main` to see `j`
			  ```c
			  #include <stdio.h>
			  int i = 'i';
			  int main(void)
			  {
			      extern int j;
			      printf("i: %c\n", i); // 'c'
			      printf("j: %c\n", j); // 'j'
			  }
			  
			  int j = 'j';
			  ```
			- Here, we have 2 functions `pop` and `push` that work on external variables `sp` and `s`. They are spread across 2 files:
			  ```c
			  // file1.c
			  // Here, sp and s from file2.c are available to all functions
			  extern int sp;
			  extern double s[];
			  
			  void push(double f) {}
			  double pop(void) {..}
			  ```
			  ```c
			  // file2.c
			  #define MAXSZ 10
			  int sp = 0;
			  double s[MAXSZ]
			  ```
	- ## `static` variables
		- [Static variables](((6675c6a9-2d38-4502-9429-575ff7ada745))) are scoped only in the file they are declared, avoiding name conflicts
	- ## Register variables
		- `register` keyword can be applied to declarations to suggest the C compiler that this variable will be heavily used.
		- Compilers may ignore `register` keyword
		- Register declarations *can only be applied to automatic variables* (i.e. non-external)
		- *Getting address of register variables is impossible*, even if the variables are not placed on real registers
	- ## Block structures
		- > Automatic variables declared inside a block is initialized each time the execution reaches this block
		- Variable declarations can follow any left curly brace that introduces compound statements
		- Here, the scope of `i` is the `true` branch of the `if` statement. This `i` is not related to any other i declared outside of this `if (true)` block:
		  ```c
		  if (n > 0) {
		  	int i; // new i
		    	for (i = 0; i < n; i++) {
		        // ...
		      }
		  }
		  ```
		  Or we can say that this block declaration *hides `i`* from the outside code
		- Formal function parameters *also hides* their names from outside code:
		  ```c
		  int x;
		  int y;
		  
		  void f(double x) {
		    double y;
		    // ...
		  }
		  ```
		  Like all sane languages, here, in function `f`, `x` refers to the function argument which is a `double`, while outside of `x` they refer to the external integer `x`
	- ## Initializations
		- Initializations are expressions that give names some values
			- Expressions could be constant, or variable
		- If there's no explicit initialization, then
			- Automatic and register variables get garbage initial values
			- External and static variables get zero initial values, much like Go default values
		- We can initialize *scalar* variables right during definitions:
		  > For external and static variables, the initializer must be constant expression
		  
		  ```c
		  int x = 1; // constant expr: int 1
		  char squote = '\''; // also constant expr: char '\'
		  long day = 60 * 60 * 24; // also constant expr: int constant * int constant * int constant
		  ```
		- For external variables, initializations are done once, before the programs start
		- For automatic variables, initializations are done every time execution enters the block scope, including in recursive functions
		- ### Initializing arrays
			- > There's no way to initialize an array in the middle without providing preceding values
			- We can also initialize arrays with this syntax:
			  ```c
			  int days[] = {31, 28, 26}; // initialize days with length 3 containing the 3 ints
			  int months[4] = {10, 20, 30, 40}; // initialize months with length 4 containing the 4 ints
			  ```
			  Omitting the length in initialization makes the compiler counts the length from the assignment value and initializing the array to that length
			- Under-filled arrays will have zeroes initialized to their vacant spaces:
			  ```c
			  int arr[4] = {10, 20, 30}; // [10, 20, 30, 0]
			  ```
			- Character arrays have some special syntactic sugar: the initializer can be string literals:
			  ```c
			  char pattern1[] = "foo";
			  char pattern2[] = {'f', 'o', 'o'}; // equivalent
			  ```
- # C functions
	- > All C functions are *external* (like external variables) and can be recursive
	- ## Caveat
		- If more than 1 functions are called in an expression, the order of these calls is undefined
		- So in this snippet:
		  ```c
		  int i = 8;
		  int result = foo(&i) + bar(&i)
		  ```
		  We have no way of knowing if `foo` or `bar` is going to be called first, and risk bugs when both functions modify the same value.
		- To ensure order of execution, use a temporary variable:
		  ```c
		  int i = 8;
		  int result = foo(&i);
		  result = bar(&i);
		  ```
	- ## Parameters
		- If we have this declaration:
		  ```c
		  int f();
		  ```
		  The declaration *does not* say that `f` takes no arguments. **Instead, when omitted, parameters are not type-checked at all when we call it somewhere else**.
		- To declare that `f` takes absolutely no argument, you'll have to explicitly declare void parameter:
		  ```c
		  int f(void);
		  ```
		- By explicitly typing out the parameter types, the compiler should be able to see if some expression calls `f` with variables of invalid types, i.e. for `void` the compiler guarantees that it'll produce an error if `f` is called with any argument
	- ## Return values
		- **Default return type is int**, unless explicitly stated.
			- If the function definition does not explicitly state that a function returns nothing (e.g. `void f();`), then its return value is inferred to be `int`
			- We can omit the `return` statement:
			  ```c
			  int f(void);
			  int f(void) {};
			  ```
			  Here, the return value from calling `f` is some garbage unless we explicitly returns a value:
			  ```c
			  int f(void);
			  int f(void) { return 9; };
			  ```
		- Values in the expression following `return` are implicitly converted to the function's return type
			- ```c
			  int f(unsigned char c);
			  int f(unsigned char c) {
			      return c;
			  }
			  ```
			  Here, the return value of calling `f` is `unsigned char c` converted to signed `int` (only the value, note that `c` itself is unchanged).
			  Or we can explicitly convert it:
			  ```c
			  int f(unsigned char c);
			  int f(unsigned char c) {
			      return (int) c;
			  }
			  ```
		- We can declare functions along with variables in 1 statement, for example the statement
		  ```c
		  double sum, atof(char s[]);
		  ```
		  declares 2 names: `double sum` and `double atof(char s[])`. This means that we can do something like:
		  ```c
		  sum += atof("21.8")
		  ```
- # Multi-file C programs
	- > See also: [[C declarations and definitions]]
	- Let's say our `main.c` program uses functions defined in `1.c` and `2.c`, then, if we run:
	  ```sh
	  cc 'main.c' '1.c' '2.c'
	  ```
	  The C compiler will produce 3 *object code* files: `main.o`, `1.o`, and `2.o`, and then it would load them all into a single executable `a.out`
	- ## [[C headers]]
		- C headers come in handy when we have to work with multiple files
		- ### Example
			- we will be refactoring this basic stack machine calculator in `main.c` into several separated files:
			- #### Original program, in 1 file:
				- ```c
				  #include <ctype.h>
				  #include <stdio.h>
				  #include <stdlib.h>
				  
				  #define NUMBER '0'
				  #define MAXOPS 100
				  #define SZ_STACK 5
				  #define SZ_BUF 100
				  
				  int getop(char[]);
				  void push(double);
				  double pop(void);
				  
				  int main(void)
				  {
				      int type;
				      double top; // Top of stack - to ensure order of function calls in pop() / pop()
				      char s[MAXOPS];
				  
				      while ((type = getop(s)) != EOF) {
				          switch (type) {
				          case NUMBER:
				              push(atof(s));
				              continue;
				  
				          case '+':
				              push(pop() + pop());
				              continue;
				  
				          case '*':
				              push(pop() * pop());
				              continue;
				  
				          case '-':
				              top = pop();
				              push(pop() - top);
				              continue;
				  
				          case '/':
				              top = pop();
				              push(pop() - top);
				              continue;
				  
				          case '\n':
				              printf("\t%.8g\n", pop());
				              return 0;
				          }
				      }
				  }
				  
				  void test_stack(void)
				  {
				      int n = SZ_STACK + 2;
				  
				      for (int i = 0; i < n; i++) {
				          push((double)i);
				      }
				      for (int i = 0; i < n; i++) {
				          double f = pop();
				      }
				  }
				  
				  int sp = 0; // Stack pointer
				  double stack[SZ_STACK];
				  
				  void push(double f)
				  {
				      if (sp >= SZ_STACK) {
				          return;
				      }
				  
				      stack[sp++] = f;
				  }
				  
				  double pop(void)
				  {
				      if (sp < 1) {
				          return 0.0;
				      }
				  
				      // sp is like count/len: a len of 1 means that the value is in array[0]
				      return stack[--sp];
				  }
				  
				  int getch(void);
				  void ungetch(int);
				  
				  int getop(char s[])
				  {
				      int i, c;
				  
				      // Skip whitespaces
				      while ((s[0] = c = getch()) == ' ' || c == '\t')
				          ;
				  
				      // Terminate s (construct a valid string)
				      s[1] = '\0';
				  
				      // Return operator
				      if (!isdigit(c) && c != '.') {
				          return c;
				      }
				  
				      // Reset s and collect integer part
				      i = 0;
				      if (isdigit(c)) {
				          while (isdigit((s[++i] = c = getch())))
				              ;
				      }
				  
				      // Collect fractional part
				      if (c == '.') {
				          while (isdigit((s[++i] = c = getch())))
				              ;
				      }
				  
				      s[i] = '\0';
				  
				      if (c != EOF) {
				          ungetch(c);
				      }
				  
				      return NUMBER;
				  }
				  
				  char buf[SZ_BUF];
				  int bufp = 0;
				  
				  int getch(void)
				  {
				      if (bufp > 0) {
				          return buf[--bufp];
				      }
				  
				      char c = getchar();
				      return c;
				  }
				  
				  void ungetch(int c)
				  {
				      if (bufp >= SZ_BUF) {
				          return;
				      }
				    
				      buf[bufp++] = c;
				  }
				  ```
			- We want separate them into multiple files, to mock real use cases where these functions would probably come from different libraries
				- `main.c` will has the main function
				- `stack.c` will provide stack machines (`pop`, `push`, and their variables)
				- `getop.c` will provide part for getting the next `double` or calculator operator char
			- With so many files involved, we'd probably want to centralize definitions and declarations
			- We'll centralize as much as we could, in one place, so that our program evolves more cleanly
			- To do that, let's create a C header file for that, `calc.h`
			- #### Resulting program
			  id:: 6675c375-477f-4243-8b3d-f1c986cfcfb5
				- The header `calc.h` defines external names for all other files:
				  ```c
				  // calc.h
				  
				  #define NUMBER '0'
				  void push(double);
				  double pop(void);
				  int getop(char []);
				  int getch(void);
				  void ungetch(int);
				  ```
				- `main.c` instead defines only stuff it needs:
				  ```c
				  // main.c
				  #include <stdio.h>
				  #include <stdlib.h>
				  #include "calc.h" // << our header!
				  
				  #define MAXOP 100
				  
				  int main(void) { .. }
				  ```
				- `getop.c` are similar to `main.c`:
				  ```c
				  // getop.c
				  #include <stdio.h>
				  #include <ctype.h>
				  #include "calc.h" // << our header!
				  
				  // Recall that if not explicitly set to concrete types or void,
				  // function return type is inferred to be int
				  getop() {}
				  ```
				- `stack.c` defines its own internal external variables:
				  ```c
				  // stack.c
				  // main.c
				  #include <stdio.h>
				  #include "calc.h" // << our header!
				  
				  #define SZ_STACK 5
				  
				  int sp = 0;
				  int s[SZ_BUF];
				  ```
				- `getch.c` also looks more simpler:
				  ```c
				  #include <stdio.h>
				  
				  #define SZ_BUF 100
				  
				  char buf[SZ_BUF];
				  int bufp = 0;
				  
				  int getch(void) {..}
				  void ungetch(int c) {..}
				  ```
	- ## Static variables
	  id:: 6675c6a9-2d38-4502-9429-575ff7ada745
		- Applying [`static` on external variable declarations]([[C declarations and definitions]]) limits the scope of the variable to the rest of the source file only
		- For example, if we change `stack.c` to:
		  ```c
		  static char buf[SZ_BUF];
		  static int bufp = 0'
		  ```
		  Then those names will not conflict with other identical names from other files
		- We can also apply `static` declarations on functions as well, which will cause the static functions to be invisible outside of the file
- # [[C preprocessors]]
	- C implementations provide their preprocessor
	- C preprocessors evaluates the source files *before* actual compilation
	- ## C macro substitution
		- `#define`
			- `#define` macros are used to do text substitution, and are usually in the form:
			  ```c
			  #define TEXT1 this is the replacement text
			  #define TEXT2 this is \
			  the replacement \
			  text
			  ```
			- To make `#define` substitute multi-line text, append `\` at the end of the line
			- `#define` can also mimic function calls, like Rust macros:
			  ```c
			  #define max(a, b) ((a > b) ? a : b);
			  ```
			  > Note: we call names `a` and `b` as *macro parameters*
				- Now, `int i = max(1, 2)` is going to be in-lined to `int i = ((1 > 2) ? 1 : 2)`
				- This is commonly done, to reduce costs of actual function call stacks
				- Be careful with the expression to give to macros, expressions with side effects may lead to bugs, like with: `max(++i, ++j)`
			- ### String substitutions in `#define` with `#`
				- ```c
				  // The define parameter '2+1' will be enclosed in double quotes
				  // in place of #expr
				  #define dprint(expr) printf(#expr " = %g\n", expr);
				  
				  // Double ## can be used for actual concatenation
				  // If the parameter in the replacement are adjacent to ##,
				  // then their values will be substituted, and the 4 bytes ` "" `
				  // will be removed
				  #define paste(front, back) front ## back
				  
				  int x = 1;
				  int y = x+2;
				  
				  int main(void) {
				    dprint(2+1); // printf("2+1" "= %g\n", 2+1)
				                 //=printf("2+1 = %g\n", 2+1)
				    dprint(x/y); // printf("x/y" "= %g\n", x/y)
				                 //=printf("x/y = %g\n", x/y)
				    
				    char name[] = "foobar";
				    paste(name, 1) // Produces name1
				  }
				  ```
		- `#undef`
			- `#undef` can be used to un-define names:
			- ```c
			  #include <stdio.h>
			  #unset getchar
			  
			  // All occurences of getchar will use this declaration
			  // instead of the ones in stdio.h
			  unsigned char getchar(void);
			  ```
		- `#include`
			- `#include` adds a directive for the preprocessor to include source files, with 2 standard forms:
			  ```c
			  #include "filename"
			  #include <filename>
			  ```
			- If the filename is enclosed in quotes, then the preprocessor would try to find it in the same directory
			- If the filename is enclosed in the pair `<>`, then the it's up to the implementation to decide how to search for the file
		- `#if` and other conditionals
			- C preprocessor can also handle conditionals, by testing non-0 expression against `#if`. There're also `#elif`, `#else`
			- So we can actually implement conditional definitions:
			  ```c
			  #if SYSTEM == SYSV
			  	#define FOOHEADER "sysv.h"
			  #elif SYSTEM == BSD
			  	#define FOOHEADER "bsd.h"
			  #else
			  	#define FOOHEADER "generic.h"
			  #endif
			  ```
			- We can also implement conditional inclusions:
			  ```c
			  #if !defined(BAR)
			  	#include <bar.h>
			  #endif
			  ```
			  > Note: the expression `defined(foo)` returns 1 if `foo` is defined
			- Or we can use the shorthand syntax with `#ifdef` and `#ifndef`:
			  ```c
			  #ifndef(BAR)
			  	#include <bar.h>
			  #endif
			  ```
- # [[C pointers and arrays]]