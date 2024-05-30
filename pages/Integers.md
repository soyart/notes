## [[Unsigned integers]]
	- The simplest integers are unsigned integers. Because it is unsigned, all the bits can be used to store the numeric value for that int.
		- ```
		  # unsigned
		  0001 = 1
		  1001 = 9
		  ```
	- ### Overflows
		- Unsigned ints overflows will *wrap around*, leaving only smaller-value bits on the right side
			- If we have a 4-bit int with value $15_{10}$, and then add $1_{10}$ to it:
			  ```
			        1111 = 15
			  +      001 = +1
			  =    10000     << it's 16 in 5-bit
			  wrap  0000 = 0 << but just 0 in 4-bit
			  ```
		- In `n`-sized binary number, the wrap around is the modulo of the $2^N$
			- For example, adding $8_{10}$ to $14_{10}$ produces $22_{10}$
			- But in 4-bit system, 22 is out of range, and will be wrapped to $$22\mod {2^4} = 6$$
			- ```
			       1110 = 14
			  +    1000 = 8
			  =   10110 = 22
			  wrap 0110 = 6
			  ```
- ## [[Signed integers]]
	- There are 4 methods for representing signed ints
	- ### Signed magnitude
	  id:: 66535f02-198f-4a35-9ae9-3a69721729ad
		- A single bit is sacrificed for storing signs, usually the left-most bit (a *sign bit*). The other bits are called *magnitude bits*.
		- Signed magnitude implementation is hard
			- Quirks like `+0` and `-0`
			- Addition and subtraction feels weird
				- > TLDR; don't use signed magnitude for additions and subtractions
				- Adding values of the same magnitude but different signs:
				  ```
				  7+(-7)    = 0
				       0111 = +7
				  +    1111 = -7
				      10110 = ???
				  
				  5+(-2)    = +3
				       0101 = +5
				  +    1010 = -2
				       1111 = ???
				  ```
				- Another example is binary subtraction which will cancel each other's bits out to `0`:
				  ```
				  -9-(-9) =  0
				     11001 = -9
				  -  11001 = -9
				     00001 = +0 // looks ok
				     
				  -9-(-7) = -2
				     1100 = -9
				     1111 = -7
				     ????      // looks weird
				  ```
			- Comparisons require checking the signed bit
			- For 8-bit, signed-magnitude range starts from $-127$ instead of $-128$ as with [[2's complement]] method
		- This means that, if 4-bit uints have range of $[0, 15]$, then 4-bit ints range will be $[-7, +6]$
		  ```
		  bits   unsigned  signed
		  0000   +0        +0  
		  1000   +8        -0         
		  1111   +15       -7
		  ```
		- Most of the times, `1` maps to minus and `0` to plus sign.
		  ```
		  # signed
		  0001 = +1
		  1001 = -1
		  ```
	- ### [[1's and 2's complement]]
		- A *1's complement* is a bitwise `NOT` applied to an unsigned int
			- > 1's complement can also be obtained from signed-magnitude values by applying `NOT` only to the magnitude bits.
			- So If we have 8-bit $1_{10}$:
			  ```
			  00000001 = 1
			  ```
			  Then we can apply NOT and get $-1_{10}$:
			  ```
			       00000001 = +1
			  NOT  11111110 = -1
			  
			      00101011 = +43 // unsigned
			  NOT
			      11010100 = -43 // signed, 1's complement
			  ```
		- 1's complement is still has some problems, like with [signed magnitude](((66535f02-198f-4a35-9ae9-3a69721729ad))):
			- 1's complement also has `+0` and `-0`
			- The range is also identical, both SM and 1C has range of $[-127, +127]$
			- And addition and subtraction still feel weird:
			  id:: 6653654e-7012-4a62-9d3d-4b22287207f1
			  ```
			      binary    decimal
			     11111110     −1
			  +  00000010     +2
			  ───────────     ──
			   1 00000000      0   ← Not the correct answer
			            1     +1   ← Add carry
			  ───────────     ──
			     00000001      1   ← Correct answer
			  ```
		- *2's complement* is similar to [adding a carry in 1's to make it work](((6653654e-7012-4a62-9d3d-4b22287207f1))). So 2's complement is just 1's complement plus the one bit from carry-over
		- With 2's, the sign bit has power, i.e. in a 4-bit number: **the sign bit, if set to 1, is** $-8_{10}$
		- We can say that 2's complement is $NOT(i)+1$, of the positive number plus one
			- > When doing 2's complements, **always ignore overflows!**
			- For example, here we have $7_{10}$:
			- ```
			        0111 = +7
			  1's   1000
			  +1       1
			  2's   1001 = -7 (signed 2's)
			        ^ -8
			           ^ +1
			           = -8+1 = -7
			  
			        01100 = +12  
			  1's   10011
			  +1        1
			  2's   10100 = -12 (signed 2's)
			  ```
		- ### Using 2's complement for subtraction
			- We can perform normal (non 2's) subtraction of ${39_{10}-25_{10}}$:
			  ```
			     0100111 = +39
			  -  0011001 = +25
			     0001110 = +14
			  ```
			- However, simple subtraction feels weird when the result is negative, e.g. with ${43_{10}-71_{10}}$:
			  ```
			     00101011 = +43
			  -  01000111 = +71
			   (-1)100100
			     ^ can't borrow!
			     and that bit will have to be written as -1,
			     which looks weird in binary
			  ```
			- To simplify subtraction, we can think of it as *plus the 2's complement*, that is, $43_{10}-71_{10}$ can be written as $43_{10}+(-71_{10})$:
			  ```
			  Prepare 2's:
			       01000111 = +71
			  1's  10111000
			  2's  10111001
			  
			     00101011 = +43
			  +  10111001 = -71 (2's)
			     11100100 = -28
			  ```