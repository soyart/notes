tags:: Programming, Language
alias:: Golang, Go language

- Go is a compiled, statically typed programming languages with [[garbage collector]]
- # Go runtime
	- Go runtime provides *memory allocator*, *garbage collector*, *scheduler*, *system monitor*, and a lot of stuff to help us Go programmers stay sane and write code that run efficiently
	- The runtime is included in every Go binary
	- ## Hands-on: no-op program in C vs Go
		- We'll write 2 versions of the same program: the program does nothing, not even printing hello world. The first one in [[C]] :
		  ```c
		  // nothing.c
		  int main() {
		    return 0;
		  }
		  ```
		  And another in Go:
		  ```go
		  // nothing.go
		  package main
		  func main() {}
		  ```
		- If we now compile and run the binaries, we can observe these facts:
		  ```sh
		  $ gcc -o nothing_c nothing.c
		  $ go build -o nothing_go nothing.go
		  
		  $ ls -lh nothing_c nothing_go
		  -rwxrwxr-x  1 user  user   16K Feb  7 12:05 nothing_c
		  -rwxrwxr-x  1 user  user  1.5M Feb  7 12:05 nothing_go
		  
		  $ time ./nothing_c
		  real    0m0.001s
		  
		  $ time ./nothing_go
		  real    0m0.002s
		  ```
		- We see that the Go binary is about 1.5MB bigger than the C program, and it took twice as long to run
		- This is because while our program might do nothing (in `main`), Go programs sets up the runtime first before entering `main`
		- This means that `main` is not the [[ELF]] entry point!
		  id:: 6a0b2748-59b4-462f-8280-f5c6e7dbd504
		  ```sh
		  $ readelf -h nothing_go | grep "Entry point"
		  Entry point address:               0x467280
		  $ go tool nm nothing_go | grep 467280
		  467280 T _rt0_amd64_linux
		  ```
			- So the real entry point on this particular machine is **`_rt0_amd64_linux`**
			- `_rt0_amd64_linux` is an [assembly function in `src/runtime/_rt0_amd64_linux`](https://github.com/golang/go/blob/go1.25.3/src/runtime/rt0_linux_amd64.s)
				- There're more than 1 "runtime entry point" in Go
				- Each supported architecture-platform gets its own entry point
					- e.g. `_rt0_arm64_linux` and `_rt0_386_linux`
			- All platform-specific entry points do the same thing: **they grab CLI args and jump to `_rt0_go`**
			- `_rt0_go` is the real deal here: it's a big function that Go uses to perform *bootstrapping*
	- ## Go runtime memory management
		- ### `mspan` and `mheap` (Central Global Pool)
			- > Note: Before Go 1.14, `mheap` constructs `mspan` from memory pages *right away*. Now the construction is on-demand
			- `mheap` only manages page allocations (`mheap.pages`)
				- Instead of managing objects, `mheap` simply manages raw memory pages
				- When the OS gives Go memory arenas, `mheap` maps them to continuous grid of 8KB pages
				- `mheap` allocates on-demand. For example, if an allocation request comes in:
					- `mheap` looks up free N contiguous blocks of available OS pages
					- If found, `mheap` updates its radix tree (to mark allocation)
					- `mheap` constructs new `mspan`s (very small metadata) and return it to the requester
					- `mheap` then leaves the `mspan` to `mcentral` or `stackpool`/`stackLarge`
			- `mheap` and `stackpool/stackLarge`, and `mcentral`
		- ### `stackpool`, and `stackLarge` (Go stack)
			- The Go runtime keeps **pools of pre-allocated stack segments**, *organized by size*, so that creating a new goroutine is fast
				- The Go stack pool uses a form of [[Fixed size block allocation]] (based heavily on the **TCMalloc (Thread-Caching Malloc)**):
				  ```
				  [Go Allocator Model: Fixed-Size Classes]
				  Memory -> Sliced into strict power-of-two categories:
				            [ 2 KB ] -> Managed by stackpool[0]
				            [ 4 KB ] -> Managed by stackpool[1]
				            [ 8 KB ] -> Managed by stackpool[2]
				            [16 KB ] -> Managed by stackpool[3]
				            [32 KB+] -> Managed by stackLarge (Via Page Allocator)
				  ```
					- **Predefined Classes:** Go does not dynamically split or merge blocks on the fly to fulfill arbitrary sizes. Instead, it rounds every stack request up to the nearest predefined size class
					- **No Dynamic Merging:** When a 2KB stack is freed, the runtime does not look at the neighboring 2KB block to instantly merge them into a 4KB block (which is what [[Buddy Block allocation]] does). Go simply returns the 2KB chunk to the 2KB free pool slot
			- `stackpool` allows goroutines to be cheaply made, as new goroutines can just grab memory from this pool
				- ```
				  ┌────────────────────────────────────────────────────────┐
				  │  1. USER / GOROUTINE LAYER                             │
				  │     • A goroutine (g) executes a function.             │
				  │     • It requires local variables on its stack.        │
				  │     • Points to a slice of memory (g.stack.lo/hi).     │
				  └───────────────────────────┬────────────────────────────┘
				                              │ (Needs 2KB Stack Segment)
				                              ▼
				  ┌────────────────────────────────────────────────────────┐
				  │  2. RUNTIME POOL LAYER (stackpool / stackLarge)        │
				  │     • Organizes memory by fixed size-classes.          │
				  │     • stackpool handles small stacks (<32KB).          │
				  │     • Holds arrays of available mspans.                │
				  └───────────────────────────┬────────────────────────────┘
				                              │ (Grabs/Assigns an available mspan)
				                              ▼
				  ┌──────────────────────────────────────────────────────────┐
				  │  3. MEMORY SPAN LAYER (mspan)                            │
				  │     • The manager of a chunk of memory pages.            │
				  │     • Slices its pages into uniform segments (e.g., 2KB) │
				  │     • Tracks free/busy slots via its internal bitmask.   │
				  └───────────────────────────┬──────────────────────────────┘
				                              │ (Manages Virtual Address Ranges)
				                              ▼
				  ┌────────────────────────────────────────────────────────┐
				  │  4. VIRTUAL MEMORY LAYER (OS Pages)                    │
				  │     • Contiguous blocks of addresses mapped by the OS. │
				  │     • Go runtime maps these via mmap / VirtualAlloc.   │
				  │     • Consumes address space, but not necessarily RAM. │
				  └───────────────────────────┬────────────────────────────┘
				                              │ (First write triggers Page Fault)
				                              ▼
				  ┌────────────────────────────────────────────────────────┐
				  │  5. PHYSICAL RAM LAYER (Hardware Page Frames)          │
				  │     • Actual electronic transistors on the RAM stick.  │
				  │     • Wired to the Virtual Page by the OS kernel.      │
				  │     • Holds the actual binary data of your variables.  │
				  └────────────────────────────────────────────────────────┘
				  ```
		- ### `mcentral` (Go heap)
			- Go does not map your `make([]T, 100)` to a `malloc` call per se
			- Instead, Go allocates big chunks up-front, then reuse the chunk(s) as the program runs
			- The *allocator* manages all of this
			- If we want 58 bytes of data, the allocator gives you a 64B block
			- The allocator organizes memory by size, up to 68 classes from 8B to 32KB
				- If the data is >=32KB in size, Go allocates directly from the heap
		- ### Everything altogether
			- We know that each contiguous chunk of OS memory gets wrapped inside `mspan`
			- And these `mspan` are all tracked and managed inside a *Central Global Pool*, segregated by size
			- Flowchart
				- {{renderer code_diagram,mermaid}}
					- ```mermaid
					  graph TD
					      %% Nodes Definition
					      OS["🌐 Operating System<br>(Virtual Memory Pages)"]
					      
					      subgraph mheap_struct["mheap (The Global Giant)"]
					          pages["mheap.pages<br>(Page Allocator)"]
					          central_arr["mheap.central [size_class]<br>(Array of mcentral)"]
					          stack_global["Global Stack Pools<br>(stackpool / stackLarge)"]
					      end
					  
					      mcentral["mcentral<br>(Global Heap Pool per Size)"]
					      mspan["mspan<br>(Contiguous Pages / Objects)"]
					  
					      subgraph mcache_struct["mcache (Local Cache per P)"]
					          alloc["mcache.alloc [size_class]<br>(Active mspans)"]
					          stackcache["mcache.stackcache [order]<br>(Local Stack Cache)"]
					      end
					  
					      P["P (Logical Processor)"]
					      G["G (Goroutine Execution)"]
					  
					      %% Memory Flow Connections
					      OS -->|sysAlloc / mmap| pages
					      pages -->|Creates| mspan
					      mspan -->|Tracked by| central_arr
					      central_arr --> mcentral
					      
					      %% Heap Branch
					      mcentral -->|Refills / Sweeps| alloc
					      
					      %% Stack Branch
					      pages -->|Allocates Stack Chunks| stack_global
					      stack_global -->|Refills| stackcache
					      
					      %% Delivery to P and G
					      alloc -->|Lock-free Heap Alloc| P
					      stackcache -->|Lock-free Stack Alloc| P
					      P -->|Executes & Uses Memory| G
					  
					      %% Styling
					      style OS fill:#1f2937,stroke:#374151,stroke-width:2px,color:#fff
					      style mheap_struct fill:#111827,stroke:#4b5563,stroke-width:2px,color:#fff
					      style mcache_struct fill:#111827,stroke:#4b5563,stroke-width:2px,color:#fff
					      style P fill:#0369a1,stroke:#0284c7,stroke-width:2px,color:#fff
					      style G fill:#0d9488,stroke:#14b8a6,stroke-width:2px,color:#fff
					  
					  ```
			- {{renderer code_diagram,mermaid}}
				- ```mermaid
				  flowchart TD
				      %% Custom Styles
				      classDef os fill:#f5f5f5,stroke:#333,stroke-width:2px;
				      classDef span fill:#fffde7,stroke:#fbc02d,stroke-width:2px;
				      classDef global fill:#e1f5fe,stroke:#0288d1,stroke-width:2px;
				      classDef local fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px;
				      classDef execution fill:#fff3e0,stroke:#ef6c00,stroke-width:2px;
				  
				      %% 1. Operating System Layer
				      subgraph OS_Layer [1. OPERATING SYSTEM LAYER]
				          OS["Virtual Address Space <br> (Raw unmapped address pages via mmap)"]
				      end
				      class OS_Layer os;
				  
				      %% 2. Memory Span Layer
				      subgraph Span_Layer [2. MEMORY SPAN LAYER]
				          mspan["mspan Container <br> (Wraps OS virtual pages)"]
				          subgraph Slots [Slices pages into Uniform Slots]
				              direction LR
				              s1["Slot (2KB)"] --- s2["Slot (2KB)"] --- s3["Slot (2KB)"] --- s4["Slot (2KB)"]
				          end
				      end
				      class Span_Layer span;
				  
				      %% 3. Central Global Pool Layer
				      subgraph Global_Layer [3. CENTRAL GLOBAL POOL LAYER - REQUIRES LOCKS]
				          subgraph stackpool [GLOBAL STACK POOL: stackpool]
				              direction TB
				              bin2["2KB List"] --> sp_m1["mspan"] --> sp_m2["mspan"]
				              bin4["4KB List"] --> sp_m3["mspan"]
				          end
				          
				          subgraph mcentral [GLOBAL HEAP POOL: mcentral]
				              direction TB
				              c1["Size Class 1"] --> mc_m1["mspan"] --> mc_m2["mspan"]
				              c2["Size Class 2"] --> mc_m3["mspan"]
				          end
				      end
				      class Global_Layer global;
				  
				      %% 4. Per-P Local Cache Layer
				      subgraph Local_Layer [4. PER-PROCESSOR P LOCAL CACHE LAYER - LOCK-FREE]
				          subgraph P_Cache [Processor P Cache]
				              direction LR
				              p_stack["p.stackcache <br> (Private 2KB/4KB slots stash)"]
				              mcache["mcache <br> (Private heap object slots)"]
				          end
				      end
				      class Local_Layer local;
				  
				      %% 5. Execution Layer
				      subgraph Execution_Layer [5. EXECUTION LAYER]
				          G["Goroutine (g) <br> (Executes your Go code)"]
				      end
				      class Execution_Layer execution;
				  
				      %% Flow Pipelines
				      OS -->|sysAlloc| mspan
				      mspan -->|Initialize| Slots
				      Slots -->|Sorted into size bins| Global_Layer
				      
				      %% Fast Path Links
				      p_stack ==>|FAST PATH: Instant Stack Allocation| G
				      mcache ==>|FAST PATH: Instant Heap Allocation| G
				  
				      %% Slow Path Links
				      sp_m1 -.->|SLOW PATH: Locked Refill when empty| p_stack
				      mc_m1 -.->|SLOW PATH: Locked Refill when empty| mcache
				  
				      %% Link Styling
				      linkStyle 4,5 stroke:#2e7d32,stroke-width:3px;
				      linkStyle 6,7 stroke:#c62828,stroke-width:2px,stroke-dasharray: 4 4;
				  
				  ```
		- ### Goroutine isolation
			- The allocator uses *local memory cache* to manage memory for [different Ps (processor, like a CPU core)](https://go.dev/src/runtime/HACKING#gs-ms-ps)
				- > In older, simpler allocator, there's a single global central list of free memory blocks. The global list must be MUTEX protected, meaning there's lock and unlock operations.
				  >
				  > Go authors hated this and decided that the memory cache must be lock-free
				- Go allocator instead creates a *P* for each CPU core (or thread if it's hyperthreaded)
					- Think of a P as a resource bucket or a "local workspace" for a CPU thread:
					  ```
					  ┌────────────────────────────────────────────────────────┐
					  │                      PROCESSOR (P)                     │
					  │  (Only ONE thread executes inside this P at a time)    │
					  ├────────────────────────────────────────────────────────┤
					  │ 1. RUN QUEUE                                           │
					  │    [ Goroutine 1 ] ──► [ Goroutine 2 ] ──► ...         │
					  ├────────────────────────────────────────────────────────┤
					  │ 2. PRIVATE HEAP STASH (mcache)                         │
					  │    • Array of small mspans assigned exclusively to P.  │
					  │    • Used when a goroutine runs `alloc()` / `new()`.   │
					  ├────────────────────────────────────────────────────────┤
					  │ 3. PRIVATE STACK STASH (stackcache)                    │
					  │    • Array of free stack segments (2KB, 4KB, 8KB, 16KB)│
					  │    • Used when a new goroutine is spawned or grows.    │
					  └────────────────────────────────────────────────────────┘
					  ```
					- In each P, the allocator hooks 2 private local memory objects called `stackcache` (for the stackpool) `mcache` (for heap) directly into each P:
					  ```
					                    ┌───────────────────────────────┐
					                    │      CENTRAL GLOBAL POOL      │
					                    │   (Shared - Requires Locks)   │
					                    └───────────────┬───────────────┘
					                                    │
					                   ┌────────────────┴────────────────┐
					                   │ Refills only when empty (Locked)│
					                   ▼                                 ▼
					          ┌─────────────────┐               ┌─────────────────┐
					          │   P1 (Core 1)   │               │   P2 (Core 2)   │
					          ├─────────────────┤               ├─────────────────┤
					          │ Local Cache     │               │ Local Cache     │
					          │ [2KB][4KB][8KB] │               │ [2KB][4KB][8KB] │
					          └────────┬────────┘               └────────┬────────┘
					                   │ (Lock-Free)                     │ (Lock-Free)
					                   ▼                                 ▼
					           Goroutine A                       Goroutine B
					  ```
					- This P now has its own private stack memory (`stackcache`), and heap memory `mcache`
					- `stackcache` and `mcache` are only private to P, and the goroutines running on P are share these 2 memory objects
					- > Note: At any given time, exactly 1 goroutine is running on a P
					  > This means that there's **NO concurrent access** to P (like context switching)
					- Context switching helps isolate each goroutine's memory
						- To prevent goroutine G2 messing up with goroutine G1, Go sanitizes and untangles the memory all G1's memory out of the P, before putting G2 on P. G1 will only ever see a its memory, not G2's memory, and vice versa:
						  ```
						  [ Timeline of a Single P ] ──────────────────────────────────────────────►
						  
						     G1 Running               Context Switch              G2 Running
						  ┌───────────────────────┐ ┌────────────────────────┐ ┌───────────────────────┐
						  │ Modifies P's mcache   │ │ Scheduler saves G1     │ │ Inherits P's mcache   │
						  │ (Sequential - Safe)   │ │ & restores G2 registers│ │ (Sequential - Safe)   │
						  └───────────────────────┘ └────────────────────────┘ └───────────────────────┘
						  ```
						- {{renderer code_diagram,mermaid}}
							- ```mermaid
							  sequenceDiagram
							      autonumber
							      participant G1 as Goroutine A (G1)
							      participant P as Processor (P) Cache Pool
							      participant R as Go Runtime Scheduler
							      participant G2 as Goroutine B (G2)
							  
							      Note over G1, P: PHASE 1: G1 Executing Custom Code
							      G1->>P: Requests 2KB Stack Segment
							      P-->>G1: Hands over Slot #1 (Marked as OCCUPIED in pool tracking)
							      Note over G1: G1 runs, writing data exclusively<br/>to its assigned Slot #1 addresses
							  
							      Note over G1, R: PHASE 2: Context Switch Initiated (G1 Blocks)
							      R->>G1: Halts G1 instruction stream execution
							      R->>G1: Saves current CPU Stack Pointer (SP) into g1.sched.sp
							      Note over R: P's Cache is frozen. Slot #1 remains tightly locked to G1 metadata
							  
							      R->>G2: Selects G2 from the runnable local queue
							      Note over R: ASSEMBLY FLIP: Runtime overwrites physical CPU SP register<br/>to point to G2's separate stack address range
							  
							      Note over R, G2: PHASE 3: G2 Resumes Execution
							      R->>G2: Restores G2 registers and fires execution stream
							      Note over G2: CPU writes to G2 stack addresses.<br/>G1's Slot #1 space is physically unreachable.
							      G2->>P: Requests new memory allocation
							      Note over P: Pool scan reads allocation map,<br/>bypasses occupied Slot #1
							      P-->>G2: Hands over a fresh, vacant Slot #2
							  ```
		- > Extra: Before Go 1.14, `mheap` manages `mspan`s directly
			- The runtime requests some memory from the OS.
			  logseq.order-list-type:: number
				- The OS allocates a chunk of virtual memory addresses for the runtime
				  logseq.order-list-type:: number
			- For each contiguous chunk of OS memory, Go wraps it with a `mspan`
			  logseq.order-list-type:: number
			- All available `mspan`s are tracked in the Global Central Pool
			  logseq.order-list-type:: number
			- ```
			  ┌────────────────────────────────────────────────────────┐
			  │  1. OPERATING SYSTEM (OS) LAYER                        │
			  │     • Manages raw virtual address spaces.              │
			  │     • Allocates blocks of addresses via mmap.          │
			  │     • Maps virtual addresses to physical RAM on-demand.│
			  └───────────────────────────┬────────────────────────────┘
			                              │ (Hands over a raw virtual memory block)
			                              ▼
			  ┌────────────────────────────────────────────────────────┐
			  │  2. MEMORY SPAN LAYER (mspan)                          │
			  │     • Acts as the container/manager for the block.     │
			  │     • Slices the virtual memory into uniform segments. │
			  │     • Tracks which segments are active or free.        │
			  └───────────────────────────┬────────────────────────────┘
			                              │ (Stored and indexed by segment size)
			                              ▼
			  ┌────────────────────────────────────────────────────────┐
			  │  3. Global Central Pool (mheap)                        │
			  │     • The central warehouse for all available mspans.  │
			  │     • Categorizes mspans into fixed size-class arrays. │
			  └────────────────────────────────────────────────────────┘
			  ```
	- ## Bootstrapping
		- Bootstrapping is what happens between the OS starting our [[ELF]] binary and `func main`
			- Inside the binary, [the entry point will be some `_rt0_<arch>_<platform>` assembly](((6a0b2748-59b4-462f-8280-f5c6e7dbd504)))
		- Those platform-specific assembly will jump to `_rt0_go`
		- `_rt0_go` initializes 2 objects: `g0` and `m0`
		  logseq.order-list-type:: number
		  id:: 6a0b294c-194f-42fe-9c77-dac8aa08181e
			- > We need these 2 objects because our code runs on goroutines, which in turn, run on OS threads. This is why we need one of each before we enter our code
			- `g0` the first goroutine
				- `g0` is special in that it won't run our code
				- `g0` is strictly for the runtime's housekeeping
			- `m0` the first thread
			  id:: 6a0b2972-17b4-4dbf-8858-eaaee1ac472e
		- `_rt0_go` then initializes *Thread-Local Storage* (TLS)
		  logseq.order-list-type:: number
			- > Important: **If TLS fails, Go aborts further execution**
			- TLS is OS mechanism that allows threads to have their own private data storage
			- Different threads can read the same TLS slot and get out a different value!
				- e.g. Two threads may read from the same `slot no. 5` TLS slot, but that *number 5* is actually mapped to different physical memory
			- Go uses TLS to store pointer to the goroutine that thread is supposed to run
			- With this, the runtime can always answer *what goroutine am I supposed to run right now?*
		- `_rt0_go` then inspects the CPU
		  logseq.order-list-type:: number
			- This is to enable some hardware optimizations
		- `_rt0_go` then inspects if the binary has `CGO` support, and if it does, it also initializes the C runtime
		  logseq.order-list-type:: number
		- `_rt0_go` then:
		  logseq.order-list-type:: number
			- `check()` check compiler assumptions
			- `args()` saves the command-line arguments
			- `osinit()` detects the number of CPUs (which becomes the default `GOMAXPROCS`)
			- `schedinit()`— the scheduler comes to life
		- ## `schedinit()`
			- `schedinit()` (in [`src/runtime/proc.go`](https://github.com/golang/go/blob/go1.25.3/src/runtime/proc.go)) is Go scheduler initialization function.
			- > See more about scheduler, and the 3 resource types: *G*s, *M*s, and *P*s: https://go.dev/src/runtime/HACKING#scheduler-structures
			- ### Stop the world
			  logseq.order-list-type:: number
				- In Go, this means *pausing* all goroutines (i.e. *marking* them as *stopped*)
				- During the stop, the runtime can safely does its thing
				- In `schedinit()` case, there're no goroutines running yet, so the world has never started per se, but `schedinit()` still explicitly marks them as stopped nonetheless
					- This is to ensure all the subsystems behave nicely and simple enough to understand
			- ### `stackinit` (Go stack pool initialization)
			  logseq.order-list-type:: number
				- Goroutines must run on a stack, (the stack becomes stack memory of the goroutine)
				- Goroutines start with 2KB stacks that grow dynamically
				- When a goroutine finishes and its stack is freed, the stack goes back into the pool
			- ### `mallocinit` (Go memory allocator initialization)
			  logseq.order-list-type:: number
				- Go needs more than just stacks. It also needs a heap to store any data that escapes the stack, such as maps and slices
			- ### `cpuinit`
			  logseq.order-list-type:: number
				- Explore CPU for extensions not described by assembly code
			- ### `alginit`
			  logseq.order-list-type:: number
				- Select a map key hashing algorithm
				- If `cpuinit` says AES is available on the CPU, Go will use that
				- Otherwise Go falls back to software implementation
			- ### `modulesinit`
			  logseq.order-list-type:: number
				- Builds table of *all* Go module packages, with data:
					- Type definitions
					  logseq.order-list-type:: number
					- Function pointers
					  logseq.order-list-type:: number
					- GC bitmaps
					  logseq.order-list-type:: number
			- ### `typelinksinit` and `itabsinit`
			  logseq.order-list-type:: number
				- Initialize interface dispatch table, for interfaces
			- ### `mcommoninit` (m-common-init)
			  logseq.order-list-type:: number
				- Finishes preparing `m0` \(((6a0b294c-194f-42fe-9c77-dac8aa08181e)))
				- Registers `m0` to global list of all threads
			- ### `goargs` and `goenvs`
			  logseq.order-list-type:: number
				- `goargs` converts C-style `argv` to Go string slices (eventually accessed via `os.Args`)
				- `goenvs` is like `goargs`, but work with environment variables
			- ### `secure`
			  logseq.order-list-type:: number
				- Security checks
			- ### `checkfds`
			  logseq.order-list-type:: number
				- Checking file descriptors to make sure stdin, stdout, and stderr are available
				  logseq.order-list-type:: number
			- ### `gcinit`
			  logseq.order-list-type:: number
				- Initialize Go **mark-and-sweep** garbage collector
				  logseq.order-list-type:: number
			- ### Initialize new **`$GOMAXPROCS` P**s
			  logseq.order-list-type:: number
			- ### Start the world
			  logseq.order-list-type:: number