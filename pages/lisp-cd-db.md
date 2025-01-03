# A practical example: a simple CD database
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
	- Now that we're able to create and add to the database, let's try to pretty-print it with [`FORMAT`](((67338345-c2f7-4369-896a-0f2999062607)))
	  ```lisp
	  (defun dump-db ()
	    (dolist (cd *db*)
	      (format t "~{~a:~10t~a~%~}~%" cd)))
	  ```
		- We can also use `FORMAT`'s `~{...~}` directive to loop over `*db*` all by itself by nesting `~{...~}`:
		  ```lisp
		  (defun dump-db ()
		    (format t "~{~{~a:~10t~a~%~}~%~}" *db*))
		  ```
	- We also want to allow users to add new CD to the database via console prompt:
	  ```lisp
	  ; Reads string from stdin, with a prompt
	  (defun prompt-read (prompt)
	    (format *query-io* "~a: " prompt) ; Note how there's no ~%, so the input stays in the same line
	    (force-output *query-io*) ; The call to FORCE-OUTPUT is necessary in some implementations to ensure that Lisp doesn't wait for a newline before it prints the prompt.
	    (read-line *query-io*)) ; This last expr returns the line as string
	  
	  ; Wraps prompt-read with PARSE-INTEGER, and defaults to 0 if PARSE-INTEGER returns nil
	  (defun read-int (prompt)
	    (or (parse-integer (prompt-read prompt) :junk-allowed t) 0)) ; if parse-integer returns nil (i.e. invalid numeric strings), 0 will be used
	  
	  (defun prompt-for-cd ()
	    (make-cd
	     (prompt-read "Title")
	     (prompt-read "Artist")
	     (read-int "Rating")
	     (y-or-n-p "Ripped"))) ; For booleans, we'll use Common Lisp Y-OR-N-P, which works like yn.sh
	  ```
	- We also want users to be able to add >1 CDs to the database:
	  ```lisp
	  (defun prompt-for-cds ()
	    (format t "Let's add CDs!~%")
	    (loop
	      (add-record (prompt-new-cd))
	      (if (not (y-or-n-p "Add more?")) (return))
	    )
	  )
	  
	  (prompt-for-cds)
	  
	  #|
	  Let's add CDs!
	  Title: t1
	  Artist: a1
	  Rating: 1
	  Ripped (y/n) y
	  Another? (y/n) y
	  Title: t2
	  Artist: a2
	  Rating: 2
	  Ripped (y/n) n
	  Another? (y/n) y
	  Title: t3
	  Artist: a3
	  Rating: 3
	  Ripped (y/n) y
	  Another? (y/n) n
	  TITLE:    t3
	  ARTIST:   a3
	  RATING:   3
	  RIPPED:   T
	  
	  TITLE:    t2
	  ARTIST:   a2
	  RATING:   2
	  RIPPED:   NIL
	  
	  TITLE:    t1
	  ARTIST:   a1
	  RATING:   1
	  RIPPED:   T
	  |#
	  ```
	- ### Database resistence
		- We'll persist db data to files - i.e. save to files and load from files
		- We'll have to be able to open files, "encode/marshal" the database into bytes and write to opened files.
		- We would probably want to be able to load the bytes back from files into Lisp in-memory representation of our db
		- Saving db to a file is straightforward:
		  ```lisp
		  (defun save-db (filename)
		  	(with-open-file
		  		(out filename
		  			:direction :output ; open write
		  			:if-exists :supersede ; overwrite if exists
		  		)
		  		(format t "Saving db to ~a~%" filename)
		  		(with-standard-io-syntax (print *db* out))
		  		(format t "Saved db to ~a~%" filename)
		  	)
		  )
		  ```
		- Note that `PRINT` marshals the data structure into bytes that Common Lisp can decode later, and `WITH-STANDARD-IO-SYNTAX` resets all symbols that affect how `PRINT` works to default values
		- Loading db from a file is also straightforward:
		  ```lisp
		  (defun load-db (filename)
		  	(with-open-file
		  		(in filename)
		  		(format t "Loading db from ~a~%" filename)
		  		; SETF is used as standard assignment operator,
		  		; in this case it sets *db* to whatever `(read in)` evaluates to
		  		(with-standard-io-syntax (setf *db* (read in)))
		  		(format t "Loaded db from ~a~%" filename)
		  	)
		  )
		  ```
		- See full example of persistence
			- Full code in `cd.lisp`:
				- ```lisp
				  (defvar *db* nil) 
				  
				  (defun make-cd (title artist rating ripped)
				    (list :title title :artist artist :rating rating :ripped ripped))
				  
				  (defun add-record (cd)
				    (push cd *db*))
				  
				  (defun prompt-read (prompt)
				    (format *query-io* "~a: " prompt) ; Note how there's no ~%, so the input stays in the same line
				    (force-output *query-io*) ; The call to FORCE-OUTPUT is necessary in some implementations to ensure that Lisp doesn't wait for a newline before it prints the prompt.
				    (read-line *query-io*)) ; This last expr returns the line as string
				  
				  (defun read-int (prompt)
				    (or (parse-integer (prompt-read prompt) :junk-allowed t) 0)) ; if parse-integer returns nil (i.e. invalid numeric strings), 0 will be used
				  
				  (defun read-bool (prompt)
				    (y-or-n-p prompt)) ; y-or-n-p will prompt for user until y|Y or n|N is entered
				  
				  (defun prompt-for-cd ()
				    (make-cd
				     (prompt-read "Title")
				     (prompt-read "Artist")
				     (read-int "Rating")
				     (y-or-n-p "Ripped")
				    )
				  )
				  
				  (defun prompt-for-cds ()
				    (format t "Let's add CDs!~%")
				    (loop
				      (add-record (prompt-for-cd))
				      (if (not (y-or-n-p "Another?")) (return))
				    )
				  )
				  
				  (defun dump-db ()
				    ; Prints 2 elements from a plist delimited by \n
				    (format t "~{~{~a:~10t~a~%~}~%~}" *db*))
				  
				  (defun save-db (filename)
				  	(with-open-file
				  		(out filename
				  			:direction :output ; open write
				  			:if-exists :supersede ; overwrite if exists
				  		)
				  		(format t "Saving db to ~a~%" filename)
				  		(with-standard-io-syntax (print *db* out))
				  		(format t "Saved db to ~a~%" filename)
				  	)
				  )
				  
				  (defun load-db (filename)
				  	(with-open-file
				  		(in filename)
				  		(format t "Loading db from ~a~%" filename)
				  		; SETF is used as standard assignment operator,
				  		; in this case it sets *db* to whatever `(read in)` evaluates to
				  		(with-standard-io-syntax (setf *db* (read in)))
				  		(format t "Loaded db from ~a~%" filename)
				  	)
				  )
				  
				  (prompt-for-cds)
				  
				  (format t "~%Preview db~%")
				  (dump-db)
				  (format t "~%Saving db~%")
				  (save-db "cd.db")
				  
				  (format t "~%Add new cd after db saved~%")
				  (add-record (make-cd "late_title" "late_artist" 0 t))
				  (dump-db)
				  
				  (load-db "cd.db")
				  (dump-db)
				  ```
			- stdout running `cd.lisp`:
				- ```
				  Let's add CDs!
				  Title: the dark side of the moon
				  Artist: pink floyd
				  Rating: 5
				  Ripped (y/n) y
				  Another? (y/n) y
				  Title: the wall
				  Artist: pink floyd
				  Rating: 4
				  Ripped (y/n) y
				  Another? (y/n) y
				  Title: blood on the tracks
				  Artist: bob dylan
				  Rating: 5
				  Ripped (y/n) n
				  Another? (y/n) y
				  Title: blond on blond
				  Artist: bob dylan
				  Rating: 5
				  Ripped (y/n) n
				  Another? (y/n) n
				  
				  Preview db
				  TITLE:    blond on blond
				  ARTIST:   bob dylan
				  RATING:   5
				  RIPPED:   NIL
				  
				  TITLE:    blood on the tracks
				  ARTIST:   bob dylan
				  RATING:   5
				  RIPPED:   NIL
				  
				  TITLE:    the wall
				  ARTIST:   pink floyd
				  RATING:   4
				  RIPPED:   T
				  
				  TITLE:    the dark side of the moon
				  ARTIST:   pink floyd
				  RATING:   5
				  RIPPED:   T
				  
				  
				  Saving db
				  Saving db to cd.db
				  Saved db to cd.db
				  
				  Add new cd after db saved
				  TITLE:    late_title
				  ARTIST:   late_artist
				  RATING:   0
				  RIPPED:   T
				  
				  TITLE:    blond on blond
				  ARTIST:   bob dylan
				  RATING:   5
				  RIPPED:   NIL
				  
				  TITLE:    blood on the tracks
				  ARTIST:   bob dylan
				  RATING:   5
				  RIPPED:   NIL
				  
				  TITLE:    the wall
				  ARTIST:   pink floyd
				  RATING:   4
				  RIPPED:   T
				  
				  TITLE:    the dark side of the moon
				  ARTIST:   pink floyd
				  RATING:   5
				  RIPPED:   T
				  
				  Loading db from cd.db
				  Loaded db from cd.db
				  TITLE:    blond on blond
				  ARTIST:   bob dylan
				  RATING:   5
				  RIPPED:   NIL
				  
				  TITLE:    blood on the tracks
				  ARTIST:   bob dylan
				  RATING:   5
				  RIPPED:   NIL
				  
				  TITLE:    the wall
				  ARTIST:   pink floyd
				  RATING:   4
				  RIPPED:   T
				  
				  TITLE:    the dark side of the moon
				  ARTIST:   pink floyd
				  RATING:   5
				  RIPPED:   T
				  ```
			- And this is how data formatted with `PRINT` written to `cd.db` looks like:
			  > Note: CD with title `late_title` is not saved to disk because it was pushed to db after db was persisted. After `load-db`, the global variable `*db*` gets overwritten by data from the file
			  
			  ```
			  ((:|TITLE| "blond on blond" :|ARTIST| "bob dylan" :|RATING| 5. :|RIPPED| |COMMON-LISP|::|NIL|) (:|TITLE| "blood on the tracks" :|ARTIST| "bob dylan" :|RATING| 5. :|RIPPED| |COMMON-LISP|::|NIL|) (:|TITLE| "the wall" :|ARTIST| "pink floyd" :|RATING| 4. :|RIPPED| |COMMON-LISP|::|T|) (:|TITLE| "the dark side of the moon" :|ARTIST| "pink floyd" :|RATING| 5. :|RIPPED| |COMMON-LISP|::|T|)) 
			  ```
	- ### Basic queries with `REMOVE-IF-NOT`
		- Filtering can be done with [`REMOVE-IF-NOT` macro](((6748a839-342e-496e-925e-9ff3fca233f7)))
			- For example, filtering out only entries with particular artist:
			  ```lisp
			  (remove-if-not
			    #'(lambda (cd) (equal (getf cd :artist) "Bab Dylon")) *db*)
			  ```
			  Or ripped tracks:
			  ```lisp
			  (remove-if-not
			    #'(lambda (cd) (equal (getf cd :ripped) T)) *db*)
			  ```
		- We can just simply write multiple select functions, like `select-by-artist`, `select-by-title`, and so on:
		  ```lisp
		  (defun select-by-artist (artist)
		    (remove-if-not
		     #'(lambda (cd) (equal (getf cd :artist) artist))
		     *db*))
		  ```
			- ```lisp
			  (load-db "cd.db")
			  (format t "Dumping db after loading~%")
			  (dump-db)
			  (format t "bob dylan cds: ~a~%" (select-by-artist "bob dylan"))
			  ```
			- ```
			  Loading db from cd.db
			  Loaded db from cd.db
			  Dumping db after loading
			  TITLE:    blond on blond
			  ARTIST:   bob dylan
			  RATING:   5
			  RIPPED:   NIL
			  
			  TITLE:    blood on the tracks
			  ARTIST:   bob dylan
			  RATING:   5
			  RIPPED:   NIL
			  
			  TITLE:    the wall
			  ARTIST:   pink floyd
			  RATING:   4
			  RIPPED:   T
			  
			  TITLE:    the dark side of the moon
			  ARTIST:   pink floyd
			  RATING:   5
			  RIPPED:   T
			  
			  bob dylan cds: ((TITLE blond on blond ARTIST bob dylan RATING 5 RIPPED NIL) (TITLE blood on the tracks ARTIST bob dylan RATING 5 RIPPED NIL))
			  ```
		- But that observe that only the anonymous function would need to change for each selector. So we are better off with a solution that lets us supply the lambda function instead of writing one by hand:
		  ```lisp
		  (defun selector-fn (fn)
		    (remove-if-not fn *db*)
		  )
		  
		  (defun select-by-artist-2 (artist)
		    (selector-fn #'(lambda (cd) (equal (getf cd :artist) artist))))
		  ```
		- We can even give the get-by-artist logic a name that we can reuse:
		  ```lisp
		  (defun selector-fn (fn)
		    (remove-if-not fn *db*)
		  )
		  
		  (defun selector-artist (artist)
		    (lambda (cd) (equal (getf cd :artist) artist))
		  )
		  
		  ; Not a good idea, but still possible
		  (defun get-bob-dylan () (selector-fn (selector-artist "bob dylan")))
		  ```
			- ```lisp
			  (defun selector-fn (fn)
			    (remove-if-not fn *db*)
			  )
			  
			  (defun selector-artist (artist)
			    (lambda (cd) (equal (getf cd :artist) artist))
			  )
			  
			  ; Not a good idea, but still possible
			  (defun get-bob-dylan () (selector-fn (selector-artist "bob dylan")))
			  
			  (load-db "cd.db")
			  (format t "Dumping db after loading~%")
			  (dump-db)
			  (format t "bob dylan cds: ~a~%" (selector-fn (lambda (cd) (equal (getf cd :artist) "bob dylan"))))
			  (format t "bob dylan cds: ~a~%" (selector-fn (selector-artist "bob dylan")))
			  (format t "bob dylan cds: ~a~%" (get-bob-dylan))
			  
			  ```
			- ```
			  Loading db from cd.db
			  Loaded db from cd.db
			  Dumping db after loading
			  TITLE:    blond on blond
			  ARTIST:   bob dylan
			  RATING:   5
			  RIPPED:   NIL
			  
			  TITLE:    blood on the tracks
			  ARTIST:   bob dylan
			  RATING:   5
			  RIPPED:   NIL
			  
			  TITLE:    the wall
			  ARTIST:   pink floyd
			  RATING:   4
			  RIPPED:   T
			  
			  TITLE:    the dark side of the moon
			  ARTIST:   pink floyd
			  RATING:   5
			  RIPPED:   T
			  
			  bob dylan cds: ((TITLE blond on blond ARTIST bob dylan RATING 5 RIPPED NIL) (TITLE blood on the tracks ARTIST bob dylan RATING 5 RIPPED NIL))
			  bob dylan cds: ((TITLE blond on blond ARTIST bob dylan RATING 5 RIPPED NIL) (TITLE blood on the tracks ARTIST bob dylan RATING 5 RIPPED NIL))
			  bob dylan cds: ((TITLE blond on blond ARTIST bob dylan RATING 5 RIPPED NIL) (TITLE blood on the tracks ARTIST bob dylan RATING 5 RIPPED NIL))
			  ```
	- ### Queries that look like SQL
		- Using [keyword parameters](((674b5477-dbed-449a-bfb1-0c654ce9914d))), we can design the query API to be more SQL-like like this
		  ```lisp
		  (select (where :artist "bob dylan"))
		  (select (where :rating 10 :ripped nil))
		  ```