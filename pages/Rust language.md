alias:: Rust

- This is me returning to Rust after 2 years, only the important is noted down
- # Types
	- ## Scalar
		- ### Integer
			- Comparison table
			  | Length | Signed | Unsigned |
			  | ---- | ---- | ---- |
			  | 8-bit | `i8` | `u8` |
			  | 16-bit | `i16` | `u16` |
			  | 32-bit | `i32` | `u32` |
			  | 64-bit | `i64` | `u64` |
			  | 128-bit | `i128` | `u128` |
			  | Architecture-dependent | `isize` | `usize` |
			- Signed integers in Rust are represented using [[2's complement]]
			- Default int type without annotation is `i32`
			- Use `isize` or `usize` to index an array
			- Integer literals
			  | Number literals | Example |
			  | ---- | ---- | ---- |
			  | Decimal | `98_222` |
			  | Hex | `0xff` |
			  | Octal | `0o77` |
			  | Binary | `0b1111_0000` |
			  | Byte (`u8` only) | `b'A'` |
			- Overflow behavior
				- > Remember that Rust builds have 2 mode: debug and release
				- Let's say we have a `u8` and want to assign value outside of its 8-bit range, `256`
					- In Debug mode, Rust adds custom code that panics at runtime when overflow
					- In Release mode, Rust wraps arounds that `u8` so 256 becomes 0 and 257 becomes 1
				- The `wrapping_*` method family can help with dealing with potential overflows, e.g. `wrapping_add`
		- ### Floating point
			- Rust provides 2 types: `f32` and `f64`
			- The default type is `f64` which is mostly as fast as `f32` but offers better precision
		- ### Boolean
			- A `bool` takes 8-bit space in Rust
		- ### Character
			- A `char` is 32 bit and takes 4 bytes in Rust
			- Represents a Unicode scalar value
			- Use single quote to define `char`:
			  ```rust
			  fn main() {
			      let c = 'z';
			      let z: char = 'ℤ'; // with explicit type annotation
			      let heart_eyed_cat = '😻';
			  }
			  ```
	- ## Compound
		- Compound types group some values together under a single variable
		- ### Tuple
			- Tuples are simplest way to combine types in Rust
			- ```rust
			  let t: (f32, usize, char) = (1.0, 2, 'z');
			  println!("1st element: {}", t.0); // 1.0
			  println!("3rd element: {}", t.2); // 'z'
			  ```
			- Data is represented as defined, in this case, the memory for variable `t` looks like this:
			  ```
			  |--f32--|--usize--|--char--|
			     32b      64b      32b
			  ```
			- A special tuple, called "unit" because it does not contain any data, is defined as `()` and expressed as `(())`
		- ### Array
			- An array is a fixed-length collection of values of the same type T: `[T; length]`
			- Length is part of the type
				- The compiler can helps us detect type (which includes length!):
				  ```rust
				  let a = [1, 2, 3, 4, 5]; // a is of type [i32; 5]
				  let b = [1usize, 2, 3, 4, 5]; // a is of type [usize; 5]
				  ```
			- We can index to access element of the array:
			  ```rust
			  let c = [10, 20, 30, 40, 50]; // a is of type [i32; 5]
			  println!("{}", c[3]); // 40
			  ```
			- When indexing Rust checks the size of the array before actually accessing. If the index is invalid, Rust panics.
	- ## Functions
		- Rust functions are first-class
		- Rust is expression-based language, so we prefer expression as return
			- We prefer this:
			  ```rust
			  fn percent(value: f64, full: f64) -> f64 {
			  	value/full*100
			  }
			  ```
			  over
			  ```rust
			  fn percent(value: f64, full: f64) -> f64 {
			  	return value/full*100;
			  }
			  ```
- # Control flow
	- ### `if`
		- Basic `if`, like with Go
		- Cool features is that we can use `if` + `let` with expression to construct a statement that assign conditional value:
		  ```rust
		  let salary = if is_female(&employee) {
		   	2000
		  } else {
		   	3000
		  };
		  ```
		  Note that `2000` and `3000` must be the same type
	- ### `loop`
		- `loop` provides infinite loop, e.g. this one which will keep printing `"again!"`:
		  ```rust
		  loop {
		  	println!("again!");
		  }
		  ```
		- `continue` and `break` can be used inside a `loop`, like how they work in Go `for` loops
		- `break <value>` can be used to return a value from `loop`!:
		  ```rust
		  let mut counter = 0;
		  let result = loop {
		  	counter += 1;
		  	if counter == 10 {
		  		break counter * 2;
		  	}
		  };
		  println!("The result is {result}"); // 20
		  ```
		- Use "loop labels" to name loops:
		  ```rust
		  let mut count = 0;
		  'counting_up: loop { // Loop label = 'counting_up
		  	println!("count = {count}");
		  	let mut remaining = 10;
		  	loop {
		  		println!("remaining = {remaining}");
		  		if remaining == 9 {
		  			break; // Break nearest loop, on L5
		  		}
		        	if count == 2 {
		          	break 'counting_up; // Break loop on L2
		  		}
		          remaining -= 1;
		  	}
		  	count += 1;
		  }
		  println!("End count = {count}");
		  ```
	- ### `while`
		- `while` executes its code block only when its condition evaluates to `true`
		- ```rust
		  let mut number = 3;
		  while number != 0 {
		  	println!("{number}!");
		  	number -= 1;
		  }
		  println!("LIFTOFF!!!");
		  ```
	- `for`
		- `for` is special in Rust: it's used to loop over a *collection* or *iterator*
		- Let's just use `for` to iterate over Rust array:
		  ```rust
		  let arr: [char; 3] = ['x', 'y', 'z'];
		  for c in arr {
		  	println!("c: {}", c);
		  }
		  ```
		- `Range` is provided so you can enumerate like this:
		  ```rust
		  for n in (1..3) {
		  	println!("c: {}", c);
		  }
		  // 1
		  // 2
		  // 3
		  ```
		- Or `for` loop over a `rev` iterator:
		  ```rust
		  for n in (1..3).rev() {
		  	println!("n: {}", n);
		  }
		  // 3
		  // 2
		  // 1
		  ```
- # Ownership
	- #Memory
	- Ownership is how Rust models memory management
	- Rust has no GC, and so programmers must manage the program's memory by themselves
	- Ownership helps Rust programmers manage memory *at compile time*, enforced by `rustc`