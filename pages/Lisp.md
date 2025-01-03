- > See also
  Lisp PoC CD database page [[lisp-cd-db]] 
  [Practical Common Lisp book](https://gigamonkeys.com/book)
  [lisp-lang.org/learn](https://lisp-lang.org/learn)
- > Lisp here will be Common Lisp
- Lisp is a programming with long history, and even longer list of dialects (Common Lisp, Clojure, Scheme, etc). Each dialect also has its own implementations
- Lisp also pioneered many features of high-level programming languages, like garbage collection, recursion, dynamic typing
- In Lisp family, the underlying building blocks are implemented as linked lists, each node called a con:
  ```
  [CAR (data), CDR (next)-]->[CAR, CDR]->[CAR, CDR]
  ```
- # Lisp introduction
	- Lisp stands for *list processing*, so most of Lisp is just lists. And this makes it perfect for AI
	- Lisp expressions are declared inside a pair of parenthesis, like:
	  ```lisp
	  (+ 5 4)
	  ```
		- The expression above is a Lisp list with 3 elements
		- `+`, an operator
		- `5`, number 5
		- `4`, number 4
		- Normally, the first element is a *Lisp operator*, of which there are 3 kinds: **functions**, **macros**, and **special operators**
	- Lists can also be nested:
	  ```lisp
	  (+ 5 4 (+ 100 200)) ; evaluates to 309
	  ```
	- Lisp is case-insensitive, so function `FORMAT` can be written as `format`
	- GNU CLISP, an implementation of Common Lisp, ships with REPL
	  > See also: [this chapter for clisp REPL](https://gigamonkeys.com/book/lather-rinse-repeat-a-tour-of-the-repl)
	- A Lisp expression always evaluates to a result
		- For example, `DEFVAR` returns the name of the new variable created
		- Even `FORMAT` returns a value - `NIL`.
		- If we try to evaluate `(format t "Hello, world!")`, we'll see 2 lines of outputs:
		  ```
		  [1]> (format t "Hello, world!")
		  Hello, world!
		  NIL
		  [2]>
		  ```
			- The 1st line is the output of format, which is string `Hello, world!`
			- The 2nd line is the return value of the expression, which is `NIL`
	- ## Lisp operators
		- Lisp has 3 kinds of operators, **functions**, **macros**, and **special operators**
		- The operators are the first
	- ## Lisp functions
		- Functions are defined with `DEFUN`:
		  ```lisp
		  ; Definition
		  ;; defun takes 3 parts of arguments:
		  ;; 1st argument/element is the name of the function being defined
		  ;; 2nd argument/element is the argument list of the function being defined
		  ;; The rest is the body of the function being defined
		  (defun hello_world () (format t "Hello, world!~%"))
		  
		  ; Call
		  (hello_world) ; prints Hello, world!\n
		  
		  ; Hyphen in function name is also legal
		  ;; This format with line breaks is preferred for defun
		  (defun hello-mars ()
		   	(format t "Hello, Mars!~%"))
		  (hello-mars) ; prints Hello, Mars!\n
		  
		  ; camelCase is also used in Lisp circles,
		  ; but Lisp names are case insensitive
		  (defun helloJupiter () (format t "Hello, Jupiter!~%"))
		  (hellojupiter)
		  (helloJupiter)
		  (HELLOJUPITER)
		  ```
		- Functions can be shadowed:
		  ```lisp
		  (defun helloJupiter () (format t "Hello, Jupiter!~%"))
		  (HELLOJUPITER) ; prints Hello, Jupiter!\n
		  
		  (defun helloJupiter () (format t "Hi, Jupiter!~%"))
		  (HELLOJUPITER) ; prints Hi, Jupiter!\n
		  ```
		- `DEFUN` returns the name of the function being defined, so in REPL it looks like this (Note the last `NIL` from the return value of `HENLO`):
		  ```
		  [1]> (defun henlo () (format t "Henlo there~%"))
		  HENO
		  [2]> (henlo)
		  Henlo there
		  NIL
		  [3]>
		  ```
		- Argument list is specified as the 2nd argument to `DEFUN`:
		  ```lisp
		  (defun greet (name) (
		  	format t "Welcome, ~A~%" name))
		  
		  (greet "Prem") ;; Welcome, Prem
		  
		  (defun myadd (a b) (
		   	+ a b))
		  
		  (print (myadd 10 20)) ;; 30
		  ```
		- Functions can also contain more than 1 top-level expression. The final return value will be from the function's last expression:
		  ```lisp
		  (defun foofn (n)
		    (format t "n is ~a~%" n)
		    (format t "n+1 is ~a~%" (+ n 1))
		    (defvar n_plus_ten (+ n 10))
		    (format t "n+10 is ~a~%" n_plus_ten) ; Last expr is FORMAT which returns nil
		  )
		  
		  (foofn 20)
		  
		  ; n_plus_ten is also available to code outside foofn after call to foofn
		  (format t "n_plus_ten is ~a~%" n_plus_ten)
		  ```
		- ### Keyword parameters
		  id:: 674b5477-dbed-449a-bfb1-0c654ce9914d
			- Basic Lisp functions work like in any other languages (matching params on the order of function call argument):
			  ```lisp
			  (defun foo (a b c) (list a b c))
			  (foo 10 20 30) ; (10 20 30)
			  (foo 10 20)    ; Error! Missing argument
			  ```
			- However, we can do something like named parameters in Python, with default values `NIL`:
			  ```lisp
			  (defun foo (&key a b c) (list a b c))
			  (foo :a 10 :c 30 :b 20) ; (10 20 30)
			  (foo :a 10 :c 30)       ; (10 NIL 30)
			  (foo)                   ; (NIL NIL NIL)
			  (foo :a 10 :x 30 :b 20) ; Error! Unexpected keyword/value pair for :x
			  ```
			- Or we can give them non-`NIL` default values:
			  ```lisp
			  (defun foo (&key a (b 2) (c 3)) (list a b c))
			  (foo :a 10 :c 30 :b 20) ; (10 20 30)
			  (foo :a 10 :b 20)       ; (10 20 3)
			  (foo :a 10)             ; (10 2 3)
			  ```
			- We can also check if a particular parameter was given with a *supplied-p* parameter:
			  ```lisp
			  (defun foo (&key a (b 2 b-p) (c 3 c-p)) (list a b b-p c c-p))
			  ```
			  Here, `c-p` will be `T` if `c` is given, and `NIL` if omitted:
			  ```lisp
			  (foo :a 10 :c 30 :b 20) ; (10 20 T 30 T)
			  (foo :a 10 :b 20)       ; (10 20 T 3 NIL)
			  (foo :a 10)             ; (10 2 NIL 3 NIL)
			  ```
			  We are free to name the *supplied-p* parameter:
			  ```lisp
			  (defun foo (&key (a 1 x-p) (b 2 b-p) (c 3 c-p)) (list a x-p b b-p c c-p))
			  (foo :a 10 :c 30 :b 20) ; (10 T 20 T 30 T)
			  (foo :b 20)             ; (1 NIL 20 T 3 NIL)
			  ```
	- ## Lisp variables and symbols
		- ### Declaration and definition
			- Global variables are defined with `DEFVAR` and is globally scoped
				- The convention is that global variable names are surrounded by asterisk `*`
				- `DEFVAR` returns the name of the global variable:
				  ```
				  [1]> (defvar *l* (list 10 20 30))
				  *L*
				  ```
			- Local, lexically scoped variables with `LET`
				- ```lisp
				  (let ((msg "some msg"))
				  	(print msg)
				  )
				  
				  (print msg) ; *** - EVAL: variable MSG has no value
				  ```
		- ### Assignment
			- `SETF` is the standard assignment function in Common Lisp
				- `SETF` returns the value assigned to the symbol:
				  ```
				  [1]> (setf l (list 10 20 30))
				  (10 20 30)
				  ```
	- ## Lisp lists
		- ### Simple lists with `LIST`
			- We can define a new simple list
			  ```
			  [1]> (list 1 2 3 "foo" 4)
			  (1 2 3 "foo" 4)
			  ```
				- ```
				  [1]> (defvar *mylist* (list 10 20 30))
				  *MYLIST*
				  [2]> *mylist*
				  (10 20 30)
				  ```
			- `(a b c)` vs `'(a b c)` vs  `(list a b c)`
				- `(a b c)` is a normal Lisp expression, where `a` is expected to be an operator and `b` `c` its arguments
				- `'(a b c)` is a bit weird: the `'` *quotes* the arguments and preserve them as written (i.e. not evaluating)
					- The expression `'(10 20 30)` is like `(list 10 20 30)`
					- The expression `'(foo bar zip)` creates a list containing the 3 symbols, meanwhile `(list foo bar zip)`
				- `(list a b c)` creates a new list with values from symbol `a`, `b`, and `c`
			- We can add elements to `LIST` with macro `PUSH`:
			  ```lisp
			  (defvar mylist (list 1 2 3))
			  (push 500 mylist)
			  (format t "~A~%" mylist) ;; (500 1 2 3)
			  (push 600 mylist)
			  (format t "~A~%" mylist) ;; (600 500 1 2 3)
			  ```
			- We can filter using `REMOVE-IF-NOT`:
			  id:: 6748a839-342e-496e-925e-9ff3fca233f7
				- `REMOVE-IF-NOT` predicate can be any function accepting a single argument returning anything but `NIL` as true
				- > `REMOVE-IF-NOT` creates a *new list* with only elements that matched the predicate
				  
				  ```lisp
				  (setf l (list 101 202 303 404)) ; Original list
				  (format t "List: ~a~%" l)
				  (format t "Filtered: ~a~%" (remove-if-not #'evenp l))
				  (format t "Filtered: ~a~%" (remove-if-not #'evenp (list 1 2 3 4 5)))
				  (format t "Filtered: ~a~%" (remove-if-not #'evenp '(1 2 3 4 5)))
				  
				  ;
				  ;List: (101 202 303 404)
				  ;Filtered: (202 404)
				  ;Filtered: (2 4)
				  ;Filtered: (2 4)
				  ;
				  ```
				- In the above example, `EVENP` is the predicate
				- The funny syntax `'#FOO` is just Lisp's way of telling the language to use a function named `FOO` instead of a variable
				- Anonymous functions can also be passed as predicate:
				  ```lisp
				  (setf l (list 101 202 303 404)) ; Original list
				  (format t "List: ~a~%" l)
				  (format t "Filtered: ~a~%"
				  	(remove-if-not #'(lambda (x) (= 0 (mod x 2))) l)
				  )
				  
				  ; In this case, the predicate is:
				  ; (lambda (x) (= 0 (mod x 2)))
				  ```
		- ### Property lists, i.e. plist, with `LIST`
			- A plist seems like simple list, except that its elements alternate between *key* and *value*. The keys are prepended with colon `:`
			- ```
			  [1]> (list :a 10 :b 20 :c 30)
			  (:A 10 :B 20 :C 30)
			  ```
			- Because the operator used to create lists and plists are the same (`LIST`), we can say that it's the content that designates whether a list is simple or plist
			- One advantage plists have over simple lists is how we can access their properties with function `GETF`:
			  ```lisp
			  (defvar *myplist* (LIST :a 10 :b 20 :c 30))
			  (format t "My plist is: ~A~%" *myplist*)
			  (format t "Property :a is: ~A~%" (GETF *myplist* :a))
			  (format t "Property :b is: ~A~%" (GETF *myplist* :b))
			  (format t "Property :c is: ~A~%" (GETF *myplist* :c))
			  
			  #|| Output
			  My plist is: (A 10 B 20 C 30)
			  Property :a is: 10
			  Property :b is: 20
			  Property :c is: 30
			  ||#
			  ```
			  Note that `GETF` will not work if you enclose the field within quotes:
			  ```lisp
			  (defvar *myplist* (LIST :a 10 :b 20 :c 30))
			  (format t "My plist is: ~A~%" *myplist*)
			  (format t "NoBug: Property :a is: ~A~%" (GETF *myplist* :a))
			  (format t "Bug:   Property :a is: ~A~%" (GETF *myplist* ":a"))
			  
			  #|| Output
			  My plist is: (A 10 B 20 C 30)
			  NoBug: Property :a is: 10
			  Bug:   Property :a is: NIL
			  ||#
			  ```
		- Iterating over lists with `DOLIST`
			- `DOLIST` iterates over a list, binding each element to a new variable available inside its scope
			- ```lisp
			  (defvar mylist (list 10 20 30))
			  (dolist (elem mylist)
			    (format t "elem is ~A~%" elem))
			  
			  (defun println (l)
			    (dolist (elem l)
			      (format t "elem is ~A~%" elem)))
			  
			  (println (list 500 400 300))
			  ```
	- ## Importing Lisp code
		- `LOAD` works like sourcing in shell scripts
		- We have a file `vars.lisp` here
		  ```lisp
		  ; vars.lisp
		  ;; Defines a global variable varfoo
		  (defvar *varfoo* "VarFoo")
		  ```
		- And also a file `foo.lisp`, which loads `vars.lisp`
		  ```lisp
		  ; foo.lisp
		  ;; Use varfoo defined in vars.lisp
		  (print *varfoo*)
		  ```
		- We can also load pre-compiled files (example in clisp REPL):
		  ```
		  [1]> (load (compile-file "vars.lisp"))
		  ;; Compiling file /Users/prem.p/git/llisp/vars.lisp ...
		  ;; Wrote file /Users/prem.p/learn-lisp/vars.fas
		  0 errors, 0 warnings
		  ;; Loading file /Users/prem.p/learn-lisp/vars.fas ...
		  ;; Loaded file /Users/prem.p/learn-lisp/vars.fas
		  #P"/Users/prem.p/git/llisp/vars.fas"
		  [2]> (format t "~a~%" *varfoo*)
		  VarFoo
		  NIL
		  ```
		  `vars.fas` is the compiled version of `vars.lisp`, where `.fas` denotes FASL (fast-load file)
	- ## `FORMAT`
	  id:: 67338345-c2f7-4369-896a-0f2999062607
		- `FORMAT` can be used to format strings and print to stdout, like Go `fmt.Fprintf`
		- We can use `t` to tell `FORMAT` to write its output to terminal/stdout
		- #### Format directives
			- `~a` or *aesthetic*, consumes 1 variable, and outputs it in human-readable format.
				- For string, double quotes will be omitted
				- For symbol `:foo`, the colon is omitted and outputed as `FOO`
				- ```lisp
				  (defvar cd (list :track "idiot wind" :artist "bob dylan" :rating 69))
				  (format t "~a~%" cd) ;; "(TRACK idiot wind ARTIST bob dylan RATING 69)\n"
				  ```
			- `~t` or *tabulating*, makes sure there's enough whitespaces before the next directive
				- `~10t` means that the following directive will be formatted at the 10th column of the line
				- ```lisp
				  (defvar cd (list :track "idiot wind" :artist "bob dylan" :rating 69))
				  (format t ">>~10t~a~%" cd) ;; ">>        (TRACK idiot wind ARTIST bob dylan RATING 69)\n"
				  ```
			- `~{...~}` will cause `FORMAT` to loop through its arguments
				- For example, `~{~a ~a~%~}` means that `FORMAT` will consume 2 symbols, with a newline at the end of each iteration:
				  ```lisp
				  (defvar myvar (list :field1 "one" :field2 "two" :field3 "three"))
				  #| Output:
				  FIELD1: one
				  FIELD2: two
				  FIELD3: three
				  |#
				  
				  (defvar song (list :track "idiot wind" :artist "bob dylan" :rating 69))
				  (format t "~{~a:~10t~a~%~}~%" song)
				  #| Output:
				  TRACK:    idiot wind
				  ARTIST:   bob dylan
				  RATING:   69
				  |#
				  
				  (format t "~{[~a] [~a]~}~%" (list 10 20)) 
				  ;; "[10] [20]\n"
				  
				  (format t "Values: ~{a:~a b:~a~}~%" (list 10 (list 100 200))) ;; 
				  ;; "Values: a:10 b:(100 200)\n"
				  ```
				- If the data being format is missing some variable, `~{...~}` throws an error:
				  ```lisp
				  (defvar myvar (list :field1 "one" :field2 "two" :field3 "three"))
				  (format t "~{~a:~10t~a~%~}~%" myvar) ; ok
				  
				  (defvar myvar (list :field1 "one" :field2 "two" :field3 "three" :fieldmissingdata))
				  (format t "~{~a:~10t~a~%~}~%" myvar)
				  #|
				  FIELD1: one
				  FIELD2: two
				  FIELD3: three
				  FIELDMISSINGDATA:
				  *** - There are not enough arguments left for this format directive.
				        Current point in control string:
				          "~{~a: ~a~%~}~%"
				                 |
				  |#
				  ```
		- ### Using `FORMAT` as input prompt
			- ```lisp
			  (defun prompt-read (prompt)
			    (format *query-io* "~a: " prompt) ; Note how there's no ~%, so the input stays in the same line
			    (force-output *query-io*) ; The call to FORCE-OUTPUT is necessary in some implementations to ensure that Lisp doesn't wait for a newline before it prints the prompt.
			    (read-line *query-io*)) ; This last expr returns the line as string
			  
			  (format t "Input is: ~a~%" (prompt-read "Enter some input"))
			  #|
			  Enter some input: eiei
			  Input is: eiei
			  |#
			  ```
			- Builtin `READ-LINE` returns string, so to cast it to other type, we must wrap it inside some parser function, such as builtin `PARSE-INTEGER`:
			  ```lisp
			  (defun prompt-read (prompt)
			    (format *query-io* "~a: " prompt) ; Note how there's no ~%, so the input stays in the same line
			    (force-output *query-io*) ; The call to FORCE-OUTPUT is necessary in some implementations to ensure that Lisp doesn't wait for a newline before it prints the prompt.
			    (read-line *query-io*)) ; This last expr returns the line as string
			  
			  (defun read-int 
			    (parse-integer (prompt-read "Enter some int")))
			  
			  (format t "Int is: ~a~%" (read-int "Enter some int"))
			  #|
			  Enter some int: 40
			  Int is: 40
			  |#
			  ```
				- If the data entered is not int, then error will be thrown:
				  ```
				  Enter some int: s
				  *** - PARSE-INTEGER: substring "s" does not have integer syntax at position 0
				  ```
				- To relax this, `PARSE-INTEGER` allows a keyword `:junk-allowed` to make it more lenient and return `NIL` instead:
				  ```lisp
				  (defun read-int (prompt)
				    (parse-integer (prompt-read prompt) :junk-allowed t))
				  
				  (format t "Int is: ~a~%" (read-int "Enter some int"))
				  #|
				  Enter some int: s
				  Int is: NIL
				  |#
				  ```
				- To use default value (e.g. 0) in case of `NIL` input, we can use `OR` macro:
				  ```lisp
				  (defun read-int (prompt)
				    (or (parse-integer (prompt-read prompt) :junk-allowed t) ))
				  
				  (format t "Int is: ~a~%" (read-int "Enter some int"))
				  #|
				  Enter some int: s
				  Int is: 0
				  |# 
				  ```
				- For boolean input values, we can use Common Lisp's `y-or-n-p` to keep prompting user until they enter either `y` or `n` (i.e. yes and no), returning `T` for true and `NIL` for false:
				  ```lisp
				  (format t "isGay: ~a~%" (y-or-n-p "U gay [y/n]: "))
				  #|
				  U gay [y/n]:  (y/n) 4
				  Please answer with y or n : 2
				  Please answer with y or n : 1
				  Please answer with y or n : s
				  Please answer with y or n : y
				  isGay: T
				  |#
				  ```