- Memory stores data for an [[Process]]'s immediate use and could be volatile or persistent
- Memory is backed by multiple types of hardware, e.g. CPU registers, RAM, disks, etc.
- # [[Physical memory]]
	- Physical memory maps to real memory location on a hardware
		- e.g. the offset `0x50` of a RAM stick
	- In the past, [processes]([[Process]]) were given physical memory by the the OS to manage
	- This created so many problems and risks, so most modern OSs use virtual memory instead
- # [[Virtual memory]]
	- > Virtual memory is usually accomplished with the help of [Memory Management Unit (MMU)](https://en.wikipedia.org/wiki/Memory_management_unit), which is integrated into the CPU today.
	  >
	  > Emulators and VMs might also use MMU on the host to increase performance
	- Virtual memory is that is mapped to virtual location, e.g. some virtual offset `0xba3`, which gets mapped to [[Physical memory]] (e.g. address `0x77` of your RAM)
	- Modern OSs have sole access to physical memory and maintains the address spaces, and allocates a chunk of that to individual [processes]([[Process]])
	- ## Styles and flavors
		- ### Single virtual address space
			- The whole computer is running with a single **virtual** address space, shared by processes
			- Used by weird system such as [IBM i](https://en.wikipedia.org/wiki/IBM_i), and also on older OSs (e.g. OS/VS1, OS2/VS2 SVS)
		- ### Dedicated address space per process
			- Each process is assigned its own address space
			- De facto standard for a modern OS
	- For running [processes]([[Process]]), the allocated virtual memory is called the *Main Storage*
	- It provides ideal abstractions over the actual memory hardware for the running programs
		- > The programs also benefits from OS memory management, e.g. swap on disk, without having to actually program it.
		- Memory isolation
			- Processes only have exclusive access to its own memory
			- Memory addresses become more private to the processes, as leaked addresses only maps to that running process virtual memoryme
		- No memory fragmentation
			- Non-contiguous chunks of memory, probably from different hardware, can be easily mapped to virtual addresses inside a one big contiguous virtual memory
		- No memory hierarchy
			- The hierarchy is something like `Registers > CPU caches > RAM, Disks`, and is different from protection hierarchy i.e. rings 0-3
		- With dedicated address space, no [relocation](https://en.wikipedia.org/wiki/Relocation_(computing)) is needed
			- In position-dependent code, relocation is locating program code or data in memory with relative addressing
			- Relocation is usually done by the linker at link time, and can also be done at load time by relocating the loader
		- Sharing memory between processes that used the same libraries
		- ASLR (address space layout randomization) further obfuscates the addresses
- # [[Memory management]]
	- How programs and processes manage memory
	- Management is primarily request, allocate, and free
		- Usually we only explicitly request/allocate memory for large objects (i.e. the heap allocation)
	- ## Manual memory management
		- Programmers manage their program's memory
		- Error-prone and potentially unsafe due to memory safety violations
		- This is accomplished explicitly by `malloc` and `free` for requesting/freeing memory from heap
			- You can also request for memory on the stack with `alloca` which gets automatically freed
		- ### Memory pool (fixed size block allocation)
			- A large fixed-size allocation
			- Implemented using *fixed-size* [free list (freelist)](https://en.wikipedia.org/wiki/Free_list) of *fixed-size* blocks of the memory #freelist
				- A free list is a linked list of unallocated locations
				- For example, our pool be backed by a linked list of length 3, with each element mapping to a 4k block of unallocated memory:
				  ```
				  | block=1, size=4k | block=2, size=4k | block=3, size=4k |
				  ```
		- ### Buddy blocks (buddy system allocation)
			- > See also: https://en.wikipedia.org/wiki/Buddy_memory_allocation
			- Like with memory pool, but with multiple pools of varying block sizes instead
			- Unlike memory pools, buddy block aims to minimize memory waste per allocations, i.e. fit a large object into a fittingly large blocks
			- Unlike memory pool, buddy block pools are dynamic and may shrink or grow after initialization
			- Each pool's block size is fixed to a certain number, e.g. powers of 2 or other convenient size
				- The power of 2 stuff is crucial, because it allows halving and quick computation
				- The buddies are also aligned on memory address boundaries
				- Every block K in this system has an integer order, starting with lower bound L (usually 0) until upper bound U
					- Order $K$ must satisfy $2^{L} \leq 2^{K} \leq 2^{U}$
					- The size of block of order $n$ is proportional to $2^{n}$
			- #### Algorithm
				- > There're many flavors of buddy algorithm, so we'll focus on the simplest and most widespread: subdividing into 2 smaller blocks
				- The first thing buddy algo does is determining smallest possible size
					- Usually this is via the system's own lower bound limit to save us from overhead of determining "should I try smaller"
						- If this limit is set, then it'll probably be used as the size of our new block
						- Usually set low:
							- Good: less waste per block, i.e. improving [internal fragmentation](https://en.wikipedia.org/wiki/Fragmentation_(computing)#Internal_fragmentation)
						- Without this limit, the algo will start out with the largest available memory, and splits it down into halves until it finds the smallest possible block size to service the request
				- This smallest value is used to represent order-0. Higher order blocks are expressed as power-of-2 of this minimum value
					- Assume the smallest possible block is 64K in size
					- The upper order limit is 4
					- The largest possible allocatable block, $2^{4} \times 64 = 1028$ in size.
			- #### Example 1
				- https://en.wikipedia.org/wiki/Buddy_memory_allocation#Algorithm
			- #### Example 2
				- Note that names such as `A1` or `D` refers to a unique block.
				- As they progressively increase in size from `A` through `D`, so do the number of 64K blocks inside each of them
				- | Block | Size | Buddy pair | Notes |
				  | A1 | 64K | A2 | Min value |
				  | A2 | 64K | A1 | Buddy of A1 |
				  | B | 128K | A1 + A2 | |
				  | C | 256K | A1 + A2 + B | |
				  | D | 512K | A1 + A2 + B + C | |
				- | Step | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K |
				  | --: | --: | --: | --: | --: | --: | --: | --: | --: | --: | --: | --: | --: | --: | --: | --: |
				  | -1: Free |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
				  | 0: Split | A1 | A2 | B | B | C | C | C | C | D | D | D | D | D | D | D | D |
				  | 1: Alloc(W, 32K) | W=32 | - | B | B | C | C | C | C | D | D | D | D | D | D | D | D |
				  | 2: Alloc (X, 64K) | W=32 | - | X=64 | - | C | C | C | C | D | D | D | D | D | D | D | D |
				- We've used up 3 blocks `A1`, `A2`, and `B` to store `W` and `X`.
				- The remaining "free" blocks are `C`, `D`, and `E`
				- Now, if we're to insert Y of size 60K, we have a problem: the next available block `C` is a bit too large (256K) for 60K data
				- So instead of putting Y into `C`, we'll split `C` into 2 blocks of size 64: `C1` and `C2`
				- | Step | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K |
				  | --: | --: | --: | --: | --: | --: | --: | --: | --: | --: | --: | --: | --: | --: | --: | --: |
				  | -1: Free |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
				  | 0: Split | A1 | A2 | B | B | C | C | C | C | D | D | D | D | D | D | D | D |
				  | 1: Alloc(W, 32K) | W=32 | - | B | B | C | C | C | C | D | D | D | D | D | D | D | D |
				  | 2: Alloc (X, 64K) | W=32 | - | X=64 | - | C | C | C | C | D | D | D | D | D | D | D | D |
				  | 3: Split C | W=32 | - | X=64 | - | C1 | C1 | C2 | C2 | D | D | D | D | D | D | D | D |
				  | 4: Alloc (Y, 60K)  | W=32 | - | X=64 | - | Y=60 | - | C2 | C2 | D | D | D | D | D | D | D | D |
				- Note that A1's 32K and C1's 4K free space is what we call internal fragmentation
				- Now, if we want to insert Z (150K), we'll have to split `D`:
				- | Step | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K | 64K |
				  | --: | --: | --: | --: | --: | --: | --: | --: | --: | --: | --: | --: | --: | --: | --: | --: |
				  | -1: Free |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
				  | 0: Split | A1 | A2 | B | B | C | C | C | C | D | D | D | D | D | D | D | D |
				  | 1: Alloc(W, 32K) | W=32 | - | B | B | C | C | C | C | D | D | D | D | D | D | D | D |
				  | 2: Alloc (X, 64K) | W=32 | - | X=64 | - | C | C | C | C | D | D | D | D | D | D | D | D |
				  | 3: Split C | W=32 | - | X=64 | - | C1 | C1 | C2 | C2 | D | D | D | D | D | D | D | D |
				  | 4: Alloc (Y, 60K)  | W=32 | - | X=64 | - | Y=60 | - | C2 | C2 | D | D | D | D | D | D | D | D |
				  | 5: Split D  | W=32 | - | X=64 | - | Y=60 | - | C2 | C2 | D1 | D1 | D1 | D1 | D2 | D2 | D2 | D2 |
				  | 6: Alloc (Y, 150K) | W=32 | - | X=64 | - | Y=60 | - | C2 | C2 | Z=64 | Z=64 | Z=22 | - | D2 | D2 | D2 | D2 |
		- ### Slab allocation
			- This approach pre-allocates memory chunks just big enough to fit certain type of objects
			- These chunks are called *cache*
			- The allocator can just keep tracks of free cache slots
			- Constructing an object -> uses a free cache slot
			- Destructing the object -> frees the cache slot
			- No memory fragmentation
		- ### Stack allocation
			- `alloca` allocates memory from within the current process's function stack frames
				- Because it allocates on the process's or thread's stack, it's probably in the caches
			- This memory gets cleaned up when the current function returns
			- `alloca` is limited to small size allocations
	- ## Automatic memory management
		- The runtime manages memory (i.e. no need for programmers to manage memory), like with Go runtime
		- ### Call stack variable
			- In most languages, even [[C]], the call stack variables are automatically deallocated
			- Can be considered zero-costs
		- ### [[Garbage collection]] (GC)
			- Very popular way to manage memory. Used in many languages
			- Have overhead costs
			- Potential "GC pause" problems