- > See also
  [Practical Common Lisp book](https://gigamonkeys.com/book)
  [lisp-lang.org/learn](https://lisp-lang.org/learn)
- > Lisp here will be Common Lisp
- Lisp is a programming with long history, and even longer list of dialects (Common Lisp, Scheme, etc.)
- # Lisp introduction
	- Lisp stands for *list processing*, so most of Lisp is just lists. And this makes it perfect for AI
	- Lists in Lisp are declared inside a pair of parenthesis, like:
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
	- ## Data structures
		- Simple lists with `LIST`
			- We can implement a track with a four-item list
			  ```
			  [1]> (list 1 2 3 4)
			  (1 2 3 4)
			  ```
				- ```
				  [1]> (defvar *mylist* (list 10 20 30))
				  *MYLIST*
				  [2]> *mylist*
				  (10 20 30)
				  ```
			- We can add elements to `LIST` with macro `PUSH`:
			  ```lisp
			  (defvar mylist (list 1 2 3))
			  (push 500 mylist)
			  (FORMAT t "~A~%" mylist) ;; (500 1 2 3)
			  (push 600 mylist)
			  (FORMAT t "~A~%" mylist) ;; (600 500 1 2 3)
			  ```
		- Property lists, i.e. plist, with `LIST`
			- A plist seems like simple list, except that its elements alternate between *key* and *value*. The keys are prepended with colon `:`
			- ```
			  [1]> (list :a 10 :b 20 :c 30)
			  (:A 10 :B 20 :C 30)
			  ```
			- Because the operator used to create lists and plists are the same (`LIST`), we can say that it's the content that designates whether a list is simple or plist
			- One advantage plists have over simple lists is how we can access their properties with function `GETF`:
			  ```lisp
			  (DEFVAR *myplist* (LIST :a 10 :b 20 :c 30))
			  (FORMAT t "My plist is: ~A~%" *myplist*)
			  (FORMAT t "Property :a is: ~A~%" (GETF *myplist* :a))
			  (FORMAT t "Property :b is: ~A~%" (GETF *myplist* :b))
			  (FORMAT t "Property :c is: ~A~%" (GETF *myplist* :c))
			  
			  #|| Output
			  My plist is: (A 10 B 20 C 30)
			  Property :a is: 10
			  Property :b is: 20
			  Property :c is: 30
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
- # A practical example: a simple CD database
	- > See also: https://gigamonkeys.com/book/practical-a-simple-database
	- We want to rip a CD and track the ripping progress with some simple database
	- This means we'll want to use plist to store a CD
	- We can write a function `make-cd(title artist rating ripped)`, which will return a plist containing the disc information
	  ```lisp
	  (defun make-cd (title artist rating ripped)
	    (list :title title :artist artist :rating rating :ripped ripped))
	  ```
	- Because we're building a db, a single record is not enough. We need structures to hold multiple CDs. We can use a global variable `*db*` as storage objects:
	  ```lisp
	  (defvar *db* nil) ;; Declare a global variable and set its initial value to nil
	  ```
	- And we can `PUSH` entry to global variable `*db*` with our own function:
	  ```lisp
	  (defun add-record (cd)
	    (push cd *db*))
	  ```
		- `add-record` returns the value of the list expression, which is `PUSH cd *db*`. We know that `PUSH` itself returns the new value of the variable it modified
		- Now, let's try our functions by adding some albums using REPL:
		  ```
		  [1]> (defun make-cd (title artist rating ripped)
		    (list :title title :artist artist :rating rating :ripped ripped))
		  MAKE-CD
		  [2]> (defvar *db* nil)
		  *DB*
		  [3]> (defun add-record (cd) (
		                      push cd *db*))
		  ADD-RECORD
		  [4]> (add-record (make-cd "Album1" "Artist1" 5 t))
		  ((:TITLE "Album1" :ARTIST "Artist1" :RATING 5 :RIPPED T))
		  [5]> (add-record (make-cd "Album2" "Artist1" 4 t))
		  ((:TITLE "Album2" :ARTIST "Artist1" :RATING 4 :RIPPED T)
		   (:TITLE "Album1" :ARTIST "Artist1" :RATING 5 :RIPPED T))
		  [6]> (add-record (make-cd "Album3" "Artist2" 4 t))
		  ((:TITLE "Album3" :ARTIST "Artist2" :RATING 4 :RIPPED T)
		   (:TITLE "Album2" :ARTIST "Artist1" :RATING 4 :RIPPED T)
		   (:TITLE "Album1" :ARTIST "Artist1" :RATING 5 :RIPPED T))
		  ```
	- Now that we're able to create and add to the database, let's try to pretty-print it using `DOLIST`:
	  ```lisp
	  (defun dump-db ()
	    (dolist (cd *db*)
	      (format t "~{~a:~10t~a~%~}~%" cd)))
	  ```
		- `~a` directive means "aesthetic". It'll consume 1 variable, and outputs it in human-readable format. For strings, double quotes will be omitted, for symbol `:foo`, the colon is omitted and outputed as `FOO`
		- `~t` is for tabulating, `~10t` means that the following directive will be formatted at the 10th column of the line
		- `~{....~}` will cause `FORMAT` to loop through its arguments, for example, `~{~a ~a~%~}` means that `FORMAT` will consume 2 symbols, with a newline at the end of each iteration:
		  ```lisp
		  (format t "~{[~a] [~a]~}~%" (list 10 20)) 
		  (format t "Values: ~{a:~a b:~a~}~%" (list 10 (list 100 200))) ;; 
		  ;; "[10] [20]\n"
		  ;; "Values: a:10 b:(100 200)\n"
		  ```