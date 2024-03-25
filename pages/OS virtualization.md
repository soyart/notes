# Operating systems
	- OS runs and manages other program and hardware resources
	- Before software OS, there used to be a human operator who loaded and operated the computer
	- Early OS was tied to its hardware, and usually came in the form of a machine-specific standard library (i.e. providing functions for I/O and display)
	- Main jobs for modern OSes are
		- Initializing memory and other objects for other programs
		- Manage hardware
		- Manage loading and running of programs
- # Time-sharing operating systems
	- Before TSOS, the computer could only run 1 program at a time
		- i.e. the computer loads a program into memory, and proceeds to execute it until the program exits.
	- TS allows the CPU to *virtually* executes more than 1 program at a time.
		- This works by isolating each running program into a *process*, and then make the CPU switches execution between these processes.
	- Robust TS systems have 2 main parts: *mechanisms* and *policies*
		- **Mechanisms** are low-level machinery that control TS
			- e.g. **context switching**
		- **Policies** sit on top of mechanisms, and determine how to perform the mechanisms.
			- Policies are high-level intelligence the OS uses to determine how to do TS with a particular *mechanism*.
			- Policies usually use current or historical data, like `given the current system state, and that programs A has been hogging CPU for x minutes, what program should run if the current system is optimizing for memory`
			- e.g. if our underlying mechanism is *context switching*, then we can implement a *scheduler* policy to determine when and how to switch contexts.
		- You can think of *mechanisms as how* questions, and *policies as which* questions
		- Mechanisms and policies are best designed separated
	- ## Processes
		- A process is the representation of a running program as seen by the OS
		- ## From programs to processes
			- OS loads *executable program bytes* from disk to memory
			  logseq.order-list-type:: number
			- OS allocates some memory, run-time stack, to setup the program for running
			  logseq.order-list-type:: number
			- OS may initializes the stack with some variables, e.g. in C programs where the OS typically injects `argc` and `argv` to the `main` function
			  logseq.order-list-type:: number
			- OS may allocates more memory as *heap* for the program. The program can request this via `malloc()` and return it to the OS using `free()`
			  logseq.order-list-type:: number
			- OS then sets up I/O for the program. In UNIX, each process gets 3 file descriptors (`stdin`, `stdout`, `stderr`)
			  logseq.order-list-type:: number
			- OS then starts the program execution via its entrypoint (usually `main` function)
			  logseq.order-list-type:: number
		- ## Process API
			- Most OSes provide the following APIs
			- ### Create
				- Creates a process, e.g. invoking a program
			- ### Destroy
				- Destroys a running process forcefully
			- ### Wait
				- Controls how programs wait (stop running)
			- ### Status [Optional]
				- Gets the process current status
		- ## Machine state
			- #### Address space
				- Is what a program can see or update at the time of its running
				- Is represented inside a process data structure
				- Everything here about the program is memory
					- Data is of course in memory
					- Instructions (machine code) are also just bytes in memory*
			- #### Registers
				- References what CPU registers are being used by the running programs
				- Special registers are instruction pointer *IP* (aka program counter *PC*)
					- IP points to next instruction the program will execute
		- ## Process states (simplified)
			- {{renderer code_diagram,graphviz}}
				- ```graphviz
				  digraph D {
				  	rankdir=LR
				  	Running -> Blocked [label="io_initiate"]
				      Blocked -> Ready [label="io_finish"]
				  	Running -> Ready [label="descheduled"]
				   	Ready -> Running [label="scheduled"]
				  }
				  ```
			- There are 3 states each process can be in
				- Running (the process is running on the CPU)
				  logseq.order-list-type:: number
				- Ready (the process is ready to run, but not running)
				  logseq.order-list-type:: number
				- Blocked (the process is not ready to run until something finishes, e.g. a process might be waiting for disk I/O to finish before it's Ready again)
				  logseq.order-list-type:: number
			- Let's see how these state transitions happen
				- Example 1: there are 2 processes, `Process0` and `Process1`. Both don't do I/O, so they are run back-to-back
					- | Process0 | Process1 |         Notes |
					  |:---------|:--------:|--------------:|
					  | Running  |  Ready   | P0 is running |
					  | Running  |  Ready   |   P0 finishes |
					  | -        | Running  |     P1 starts |
					  | -        | Running  |   P1 finishes |
					  | -        |    -     |     Both done |
					- Example 2: there are 2 processes, but this time `Process0` has to do some I/O
						- | Process0 | Process1 |                Notes |
						  |:---------|:--------:|---------------------:|
						  | Running  |  Ready   |              P0 runs |
						  | Running  |  Ready   |                      |
						  | Running  |  Ready   |      P0 initiates IO |
						  | Blocked  | Running  |              P1 runs |
						  | Blocked  | Running  |                      |
						  | Blocked  | Running  |   IO finishes for P0 |
						  | Ready    | Running  |                      |
						  | Ready    | Running  |          P1 finishes |
						  | Running  |    -     | P0 continues running |
						  | Running  |    -     |                      |
						  | Running  |    -     |          P0 finishes |
						  | -        |    -     |          P0 finishes |
		- ## Process struct
			- An OS needs to keep track of processes, and each state needs a uniform representation for the OS, whether it's a web browser, or a DNS server.
			- ```c
			  // the registers xv6 will save and restore
			  // to stop and subsequently restart a process
			  struct context {
			    int eip;
			    int esp;
			    int ebx;
			    int ecx;
			    int edx;
			    int esi;
			    int edi;
			    int ebp;
			  };
			  // the different states a process can be in
			  enum proc_state { UNUSED, EMBRYO, SLEEPING,
			                    RUNNABLE, RUNNING, ZOMBIE };
			  // the information xv6 tracks about each process
			  // including its register context and state
			  struct proc {
			    char *mem;                  // Start of process memory
			    uint sz;                    // Size of process memory
			    char *kstack;               // Bottom of kernel stack
			                                // for this process
			    enum proc_state state;      // Process state
			    int pid;                    // Process ID
			    struct proc *parent;        // Parent process
			    void *chan;                 // If !zero, sleeping on chan
			    int killed;                 // If !zero, has been killed
			    struct file *ofile[NOFILE]; // Open files
			    struct inode *cwd;          // Current directory
			    struct context context;     // Switch here to run process
			    struct trapframe *tf;       // Trap frame for the
			                                // current interrupt
			  };
			  ```
			- When a running process is stopped, the OS copies the values of its registers to this structure some where in memory
			- When that stopped process is brought back to run, the OS restores the values from the structure back to the actual CPU registers
			- Because multiple programs run on the OS, it has to keep some lists of these processes too