- > See also [Go slices on go.dev](https://go.dev/blog/slices-intro)
- Go slices are weird. It may looks and feels like Rust slices at first, but Go simplistic nature hides something from us.
- # Go arrays
	- Go slices are built on top of Go arrays. So let's do arrays first
	- Go arrays are statically allocated, and so array length is integral part of Go array types:
	  ```go
	  a := [2]int{10, 10}       // [10, 10]
	  b := [3]int{10, 20}       // [10, 20, 0]
	  c := [10]int{}            // [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	  d := [...]int{7, 5, 3, 1} // d's type is [4]int
	  ```
	  Here, `a` and `b` are of different types, and for `b` the third element is automatically initialized to zero value for us. `c` is also an array of int of length 10, whose elements are all initialized to 0.
	- Think about arrays as a sort of struct but with indexed rather than named fields: a fixed-size composite value.
	- Unlike in C, Go array variables are values and **NOT some pointers to the first element**.
		- ```go
		  package main
		  import "fmt"
		  
		  func main() {
		  	a := [3]int{10, 20, 30}
		  	fmt.Println(a) // [10,20,30]
		    
		  	changeWhole(a) // a copy of a is sent to changeWhole
		  	fmt.Println(a) // [10,20,30]
		    
		  	changeFirst(a) // a copy of a is sent to changeFirst
		  	fmt.Println(a) // [10,20,30]
		  }
		  func changeWhole(a [3]int) {
		  	a = [3]int{0, 0, 0}
		  }
		  func changeFirst(a [3]int) {
		  	a[0] = -1
		  }
		  ```
- # Slice declaration/definition
	- A slice literal is like Go array literal, except the fact that the length is omitted from type definition:
	  ```go
	  a := [3]int{10, 20, 30}
	  b := []int{10, 20, 30}
	  ```
	- Or using `make([]T, len, cap)`:
	  ```go
	  c := make([]int, 5, 5)
	  ```
	  Go will allocate a new array of capacity 5 and length 5, returning a slice that uses that new array
	- We can also *slicing* existing arrays and slices using half-open range:
	  ```go
	  b := []byte{'g', 'o', 'l', 'a', 'n', 'g'}
	  
	  b[1:4] == []byte{'o', 'l', 'a'} // true: sharing the same storage as b// b[:2] == []byte{'g', 'o'}
	  b[2:] == []byte{'l', 'a', 'n', 'g'}
	  b[:] == b
	  
	  a := [3]int{100, 200, 300}
	  x := a[:] // slice x refers to the a's storage
	  ```
- # Slice structure
	- Go slice structure can be simplified to this small struct:
	  ```go
	  type goSlice[T any] struct {
	    elem *T
	    length    int
	    capacity  int
	  }
	  ```
	- Length is the number of elements referred to by the slice
	- Capacity is the *storage size of the underlying array, beginning at the element referred to by the slice pointer*
	  ```go
	  a := [10]int{10, 20, 30}
	  b := a[1:4]
	  
	  fmt.Println("len(a)", len(a)) // len(a) 10
	  fmt.Println("len(b)", len(b)) // len(b) 3
	  fmt.Println("cap(a)", cap(a)) // cap(a) 10
	  fmt.Println("cap(b)", cap(b)) // cap(b) 9
	  ```
		- Therefore, this call to `make`:
		  ```go
		  x := make([]int, 5)
		  ```
		  returns this (approximation) slice:
		  ```json
		  {
		      "elem": "0xSomePointer",
		    	"len": 5,
		    	"cap": 5,
		  }
		  ```
- # Slicing internals
	- Slicing does not copy elements to new storage for the new slice.
	- Slicing creates a new value pointing to the original array
	- Therefore *modifying slice elements also modifies the elements in the original arrays*:
	  ```go
	  a := [10]int{10, 20, 30}
	  b := a[1:4]
	  b[0] = 1000
	  
	  fmt.Println(b[0]) // 1000
	  fmt.Println(a[1]) // 1000
	  ```
	- We can shrink and grow our slice:
	  ```go
	  s := make([]int, 5) // [0, 0, 0, 0, 0]
	  fmt.Println(s, "len(s)", len(s)) // 5
	  fmt.Println(s, "cap(s)", cap(s)) // 5
	  
	  s[2] = 200 // [0, 0, 200, 0, 0]
	  fmt.Println(s, "len(s)", len(s)) // 5
	  fmt.Println(s, "cap(s)", cap(s)) // 5
	  
	  // Shrink
	  s = s[2:4] // [200, 0]
	  fmt.Println(s, "len(s)", len(s)) // 2
	  fmt.Println(s, "cap(s)", cap(s)) // 3
	  
	  // We can also grow back our slice!
	  s = s[:cap(s)] // [200, 0, 0]
	  fmt.Println(s, "len(s)", len(s)) // 3
	  fmt.Println(s, "cap(s)", cap(s)) // 3
	  ```
	  > If we try to grow a slice past its capacity, Go'll throw a runtime panic.
	  > Like in other languages, to grow *dynamic arrays* beyond their capacity, we must allocate a new > array with x2 the capacity and loop through the old array to copy its elements to the new arrays
- # `copy`
	- `copy` copies up to the largest number possible (`len(dst)` or `len(src)`, whichever is smaller):
	  ```go
	  s := []int{10, 20, 30, 40} // len=4
	  d := []int{-1, -2}         // len=2
	  
	  n := copy(d, s)     // Copy 2 elems starting from s[0]
	  fmt.Println("n", n) // 2
	  
	  fmt.Println("s", s) // [10, 20, 30, 40]
	  fmt.Println("d", d) // [10, 20]
	  
	  n = copy(d, s[1:])  // Copy 2 elems starting from s[1]
	  fmt.Println("n", n) // 2
	  
	  fmt.Println("s", s) // [10, 20, 30, 40]
	  fmt.Println("d", d) // [20, 30]
	  ```
	- We can use `copy` to *grow* our slice, i.e. copying slice values:
	  ```go
	  t := make([]byte, len(s), (cap(s)+1)*2)
	  _ = copy(t, s)
	  s = t
	  ```
	  Like with this:
	  ```go
	  func AppendByte(slice []byte, data ...byte) []byte {
	      m := len(slice)
	      n := m + len(data)
	      if n > cap(slice) { // if necessary, reallocate
	          // allocate double what's needed, for future growth.
	          newSlice := make([]byte, (n+1)*2)
	          copy(newSlice, slice)
	          slice = newSlice
	      }
	      slice = slice[0:n]
	      copy(slice[m:n], data)
	      return slice
	  }
	  ```
- # `append`
	- `append(s []T, x ...T)`  returns a new slice with elements from `s` appended with `x`
	- The return value depends on external factors, mainly capacity
	- If `cap(s) >= len(s)+len(t)`, then *the old storage array* will be used:
	  ```go
	  a := [10]int{}
	  s1 := a[:3]
	  s2 := a[:3]
	  
	  fmt.Printf("%p vs %p\n", s1, s2)
	  fmt.Println("s1", "len", len(s1), "cap", cap(s1), s1)
	  fmt.Println("s2", "len", len(s2), "cap", cap(s2), s2)
	  fmt.Println("a", "len", len(a), "cap", cap(a), a)
	  /*
	  0x1400001c0a0 vs 0x1400001c0a0
	  s1 len 3 cap 10 [0 0 0]
	  s2 len 3 cap 10 [0 0 0]
	  a len 10 cap 10 [0 0 0 0 0 0 0 0 0 0]
	  */
	  
	  s1 = append(s1, 8)
	  fmt.Printf("%p vs %p\n", s1, s2)
	  fmt.Println("s1", "len", len(s1), "cap", cap(s1), s1)
	  fmt.Println("s2", "len", len(s2), "cap", cap(s2), s2)
	  fmt.Println("a", "len", len(a), "cap", cap(a), a)
	  /*
	  0x1400001c0a0 vs 0x1400001c0a0
	  s1 len 4 cap 10 [0 0 0 8]
	  s2 len 3 cap 10 [0 0 0]
	  a len 10 cap 10 [0 0 0 8 0 0 0 0 0 0]
	  */
	  
	  // Test that we still use the same backing array:
	  s1[0] = -1
	  fmt.Printf("%p vs %p\n", s1, s2)
	  fmt.Println("s1", "len", len(s1), "cap", cap(s1), s1)
	  fmt.Println("s2", "len", len(s2), "cap", cap(s2), s2)
	  fmt.Println("a", "len", len(a), "cap", cap(a), a)
	  /*
	  0x1400001c0a0 vs 0x1400001c0a0
	  s1 len 4 cap 10 [-1 0 0 8]
	  s2 len 3 cap 10 [-1 0 0]
	  a len 10 cap 10 [-1 0 0 8 0 0 0 0 0 0]
	  */
	  ```
	- If `cap(s) < len(s)+len(t)`, then *a new array with 2x the capacity will be allocated* and populated with elements from `s` and `t`:
	  ```go
	  a := [10]int{}
	  s1 := a[:]
	  s2 := a[:]
	  
	  fmt.Printf("%p vs %p\n", s1, s2)
	  fmt.Println("s1", "len", len(s1), "cap", cap(s1), s1)
	  fmt.Println("s2", "len", len(s2), "cap", cap(s2), s2)
	  fmt.Println("a", "len", len(a), "cap", cap(a), a)
	  /*
	  0x14000122000 vs 0x14000122000
	  s1 len 10 cap 10 [0 0 0 0 0 0 0 0 0 0]
	  s2 len 10 cap 10 [0 0 0 0 0 0 0 0 0 0]
	  a len 10 cap 10 [0 0 0 0 0 0 0 0 0 0]
	  */
	  
	  s1 = append(s1, 8)
	  fmt.Printf("%p vs %p\n", s1, s2)
	  fmt.Println("s1", "len", len(s1), "cap", cap(s1), s1)
	  fmt.Println("s2", "len", len(s2), "cap", cap(s2), s2)
	  fmt.Println("a", "len", len(a), "cap", cap(a), a)
	  /*
	  0x14000132000 vs 0x14000122000
	  s1 len 11 cap 20 [0 0 0 0 0 0 0 0 0 0 8]
	  s2 len 10 cap 10 [0 0 0 0 0 0 0 0 0 0]
	  a len 10 cap 10 [0 0 0 0 0 0 0 0 0 0]
	  */
	  
	  // Test that we still use the same backing array:
	  s1[0] = -1
	  fmt.Printf("%p vs %p\n", s1, s2)
	  fmt.Println("s1", "len", len(s1), "cap", cap(s1), s1)
	  fmt.Println("s2", "len", len(s2), "cap", cap(s2), s2)
	  fmt.Println("a", "len", len(a), "cap", cap(a), a)
	  /*
	  0x14000132000 vs 0x14000122000
	  s1 len 11 cap 20 [-1 0 0 0 0 0 0 0 0 0 8]
	  s2 len 10 cap 10 [0 0 0 0 0 0 0 0 0 0]
	  a len 10 cap 10 [0 0 0 0 0 0 0 0 0 0]
	  */
	  ```