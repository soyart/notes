- #OS #Assembly #Rust
- This will be based on the following blog series
	- [2018+] https://os.phil-opp.com/
	- [2026] https://blog.desigeek.com/post/2026/02/building-microkernel-part0-why-build-an-os/
- # Part 1
	- This part will deal with booting up our [freestanding Rust binary](https://os.phil-opp.com/freestanding-rust-binary/) (our minimum *kernel*) from qemu
		- The configuration for our VM would look like this:
		  ```shell
		  qemu-system-aarch64 \
		    -machine virt,gic-version=2 \
		    -cpu cortex-a53 \
		    -m 256M \
		    -nographic \ # No need for GUI and graphics
		    -serial mon:stdio \ # Because we'll use visual serial, connected to host stdio
		    -kernel dist/virt/os-aarch64-virt.elf # Our kernel ELF
		  ```
			- We chose GICv2 because it's simpler and perfect for single-core
		- `#![no_std]` tells our compiler to omit Rust `std`
			- Meaning we have to say goodbye to `println!`
			- Even if we try this:
			  ```rust
			  // main.rs
			  #![no_std]
			  fn main() {}
			  ```
			  It would still fails to compile:
			  ```
			  cargo build
			  error: `#[panic_handler]` function required, but not found
			  error: language item required, but not found: `eh_personality`
			  ```
				- Missing *function* `#[panic_handler]`
					- This language item defines *what function to call* when a panic happens
					- We can add a dummy panic handler with:
					  ```rust
					  // Somewhere in main.rs
					  use core::panic::PanicInfo;
					  
					  /// This function is called on panic.
					  #[panic_handler]
					  fn panic(_info: &PanicInfo) -> ! {
					      loop {}
					  }
					  ```
				- Missing *language item* `eh_personality`
					- Items are stuff like the trait `Copy`, which defines which types have [*copy semantics*](https://doc.rust-lang.org/nightly/core/marker/trait.Copy.html), i.e. types whose values can be duplicated simply by copying bits.
						- If we look at its [implementation](https://github.com/rust-lang/rust/blob/485397e49a02a3b7ff77c17e4a3f16c653925cb3/src/libcore/marker.rs#L296-L299), we'll see `#[lang = "copy"]` that defines the language item `copy`
					- `eh_personality` specifies how to ["unwind" stacks](https://www.bogotobogo.com/cplusplus/stackunwinding.php) during panics
					- This is too complicated for our project, so we can just "not" unwind in both debug mode and release mode by specifying the following directives in `Cargo.toml`:
					  ```toml
					  # Cargo.toml
					  [profile.dev]
					  panic = "abort"
					  
					  [profile.release]
					  panic = "abort"
					  ```
				- If we resolve the previous 2 problems, we still get compile error:
				  ```
				  cargo build
				  error: requires `start` lang_item
				  ```
					- Missing *language item* `start`
						- Normal Rust entry point chain
							- When writing a normal Rust program, we might think that `main` is the first entry point the OS goes to when executing our program
							- In reality, `main` runs inside a Rust's "runtime".
							- So the Rust runtime must start first
							- In normal Rust binary with `std`, the binary is linked with the OS's standard library, which is usually C
								- This means our Rust program is run inside an OS-dependent C runtime
							- We call this C runtime `crt0` (C Runtime 0), and the entrypoint for crt0 is usually `_start`
							- `crt0` then invokes the [entry point of the Rust runtime](https://github.com/rust-lang/rust/blob/bb4d1491466d8239a7a5fd68bd605e3276e97afb/src/libstd/rt.rs#L32-L73), which is marked by the `start` language item.
								- Rust runtime is minimal, compared to Go runtime
								- In Go, the Go runtime manages heap memory and goroutines
								- In Rust, the runtime handles overflows, panics, function arguments, etc.
							- Rust `start` calls Rust `main`
							- {{renderer code_diagram,mermaid}}
								- ```mermaid
								  graph TD
								      A[Linux Kernel: execve] -->|Loads ELF Binary| B[Dynamic Linker: ld-linux.so]
								      B -->|Maps Dependencies| C[C Runtime: _start / crt0.o]
								      C -->|Initialize Stack & Args| D[Rust Runtime: lang_start]
								      D -->|Setup Guard Pages & Panics| E[Rust main function]
								      E -->|Your Code Logic| F[Return Value / Exit]
								      F -->|Cleanup| G[libc: exit]
								      G -->|Syscall| H[Kernel: Process Termination]
								  
								      subgraph OS Space
								      A
								      H
								      end
								  
								      subgraph Entry Point
								      B
								      C
								      end
								  
								      subgraph Rust Standard Library
								      D
								      E
								      end
								  ```
					- Implementing the `start` language item wouldn’t help, since it would still require `crt0` that we exclude via `!#[no_std]`
					- Instead, we must overwrite `crt0`'s `_start` directly
						- ```rust
						  #![no_std]
						  #![no_main]
						  
						  use core::panic::PanicInfo;
						  /// This function is called on panic.
						  #[panic_handler]
						  fn panic(_info: &PanicInfo) -> ! {
						      loop {}
						  }
						  #[unsafe(no_mangle)]
						  pub extern "C" fn _start() -> ! {
						      loop {}
						  }
						  ```
						- `#[unsafe(no_mangle)]` forces compiler to output verbatim function name, instead of random shit like deadbeef__start
						- `extern "C"` forces compiler to make this function follow C calling convention
						- `-> !` tells our compiler that this `_start` function is a diverging function, i.e. that it never returns
				- So, even though we fixed `start` language item, we'd still get linker error
					- [Rust target triple](https://clang.llvm.org/docs/CrossCompilation.html#target-triple)
						- ```
						  x86_64-unknown-linux-gnu
						  ```
							- Architecture: `x86_64`
							- Vendor `unknown`
							- OS `linux`
							- ABI `gnu`
					- Because we're writing our own OS (and nothing runs under our kernel), we need a our target triple to omit OS with `none`, such as `thumbv7em-none-eabihf`
					- If we run the `cargo build` command with No-OS target triple, it should not complain about linker errors:
					  ```shell
					  rustup target add thumbv7em-none-eabihf # Add target
					  cargo build --target thumbv7em-none-eabihf
					  ```
					- Note that we're not using this target `thumbv7em-none-eabihf`, we'll use [custom target triple](https://doc.rust-lang.org/rustc/targets/custom.html) instead
	- Qemu will boot into ARM EL2 and might handover in EL2 or EL1, so our kernel should be able to drop from EL2 to EL1
	- ## Primer: #ELF
		- > An ELF file is like a shipping manifest. It says: “here’s a chunk of 
		  executable code, load it at this address. Here’s read-only data, put it 
		  over here. Here’s uninitialized data (BSS), allocate this much space and
		   zero it. Oh, and the program starts executing at this address.”
		  >
		  > https://blog.desigeek.com/post/2026/02/building-microkernel-part1-foundations-boot/
		- ELF is a *file format* for executables, object code, shared libraries, device drivers, etc
		- Historically, it was specified in Unix SVR4 ABI
		- By design, it's cross-platform supports different endianness
		- When we *build* our Rust microkernel, both `cargo` and our linker of choice produces binary output in ELF
		- Qemu knows how to loads ELF
		- ELF Sections for our kernel:
			- **`.text.boot`**: The very first code that runs (our assembly entry point)
			- **`.text`**: The rest of our compiled Rust code
			- **`.rodata`**: Read-only data (string constants, lookup tables)
			- **`.data`**: Initialized mutable data (statics with non-zero initial values)
			- **`.bss`**: [Uninitialized data (statics that start at zero](https://en.wikipedia.org/wiki/.bss), just a size, no actual bytes in the binary)
	- ## Primer: ARM #Assembly
		- > Note: we'll focus on AArch64
		- ### Registers
			- #### ARM general-purpose registers
				- ARM provides 31 general-purpose registers, each 64-bit wide in AArch64
					- `x0` - `x30` and `w0` - `w30`
						- `x29` and `x30` are a little special (See below)
					- These register names are prefixed with `x{n}`, hence we have `x0` through `x30`
					- On AArch64, we have `w{n}`, 32-bit wide and each corresponds to bottom 32 bits of `x{n}`. For example, `w7` is the bottom 32 bits on `x7`
				- `x29`: Frame pointer (like `rbp` on x86)
				- `x30`: Link register, holds the return address after a `bl` (branch-with-link) call
				- `xsr`: zero register, behaves like `/dev/null` but for registers
				- `sp`: our *banked* stack pointer
					- Banked means that `sp` is actually pointing to >1 physical registers, depending on the processor's states, such as current EL
					- This is to prevent EL1 crash from corrupting EL0 stacks
					- And it might even be faster - when exception happens, the processor can just switch to the right register when entering a new EL without having to move/load stuff
			- #### ARM system registers
				- Unlike x86 family, these **system registers** cannot be manipulated with normal instructions such as `mov` or `add`
				- We must manipulate them with special instructions, such as `msr` (move-system-from-register?) and `mrs` (move-register-from-system)
					- **`mrs x0, CurrentEL`**: Move value from `CurrentEL` into `x0`
					- `msr spsr_el2, x0`: Move value from `x0` into `spsr_el2`
		- ### Labels and directives
			- Assembly uses numbered local labels such as `1:`, `2:`, or `40:`
			- `1b` search backward from current line to label `1:`
			- `6f` search forward from current line for label `6:`
		- ### Common instructions
			- | Instruction | What it does |
			  | ---- | ---- | ---- |
			  | `isb` | Instruction synchronization barrier (flush pipeline) |
			  | `eret` | Exception return (drop to lower exception level) |
			  | `wfe` | Wait for event (low-power sleep) |
			  | `ldr x0, =label` | Load the address of `label` into `x0` |
			  | `mov sp, x0` | Copy `x0` into the stack pointer |
			  | `str xzr, [x1], #8` | Store zero to the address in `x1`, then add 8 to `x1` |
			  | `cmp x1, x2` | Compare `x1` and `x2` (sets condition flags) |
			  | `b.ge 2f` | Branch forward to label `2:` if the comparison was greater-than-or-equal |
			  | `b.ne label` | Branch to `label` if not equal |
			  | `bl rust_main` | Branch with link: save return address in `x30`, jump to `rust_main` |
			  | `bic x0, x0, #(1 << 10)` | Bit clear: clear bit 10 in `x0` |
			  | `orr x0, x0, #(3 << 20)` | Bitwise OR: set bits 20 and 21 in `x0` |
			  | `lsr x1, x1, #2` | Logical shift right by 2 bits |
			  | `and x1, x1, #3` | Bitwise AND with 3 (keep only bits 0 and 1) |
			  | `adr x0, label` | Load the PC-relative address of `label` into `x0` |
	- ## Primer: ARM exception levels
	  id:: 69dd1ab5-0f03-4b46-bb0e-c4076bb0b9b0
		- ARM has 4 exception levels (ELs)
			- | EL | Name | Who runs here | What they can do |
			  | ---- | ---- | ---- |
			  | EL0 | Application | User programs | Normal instructions only. Can’t touch hardware. |
			  | EL1 | Kernel | Operating systems | Configure MMU, handle interrupts, access all memory |
			  | EL2 | Hypervisor | Virtual machine monitors | Virtualize EL1 guests, trap privileged operations |
			  | EL3 | Secure Monitor | TrustZone firmware | Switch between secure and non-secure worlds |
		- Main idea for "dropping" or "escalating" EL
			- In ARM, we can't simply "jump to EL1" when exception occurs, because we have no such instructions
			- We must think of this as a **"return" operation** instead (`eret`, exception return?), i.e. where does ELx return to, and what the states should be, when it decides to drop/escalate
			- ### Example: dropping from EL2 to EL1
				- Before we  drop to EL1, we must ensure that EL1 has valid stack to use immediately after the entry
				- This is done by populating relevant registers. Note that lower levels cannot set higher level's registers
					- `spsr_el2` is target states for **returning from EL2 (`eret`)**
						- This will be stored to `PSTATE`
						- Target modes to return to for EL2
						  id:: 69dd22e3-8912-41a0-aab4-cb3c495d52a9
							- | Target Mode  | `spsr_el2` Value (Mode Bits) | Description |
							  | **EL1h** | `0b0101` (0x5) | Return to EL1 using **sp_el1** |
							  | **EL1t** | `0b0100` (0x4) | Return to EL1 using **sp_el0** |
							  | **EL0** | `0b0000` (0x0) | Return to EL0 (Always uses **sp_el0**)  |
						- For example, if we want to enter EL1 in *handler* mode (EL1h), we can do:
						  ```asm
						    // Configure EL2 to return to EL1h.
						    mov x0, #(0b0101) // EL1h
						    msr spsr_el2, x0
						  ```
					- `elr_el2` target instruction address for **returning from EL2**
					- `cptr_el2` Architectural Feature Trap Register for EL2
						- Like a file permission flag, where each feature is mapped to a bit range within the register
						- Controls whether EL2 intercepts attempts by lower ELs to use "features" like the *Floating Point unit* or *SIMD (NEON)* instructions
						- We must configure this value before we enter EL1, to prevent EL2 trapping some of our Rust-translated instructions and crashing the CPU
					- `sp_el1` stack pointer for EL1, which must be ready to use immediately after `eret`
					  id:: 69dd1d52-5030-461a-8404-b8a0c0d856ce
						- `sp_el1` will be used as stack for EL1 if we're using EL1h mode
						- In EL1t (thread) mode, EL1 stack pointer would be `sp_el0`: See ((69dd22e3-8912-41a0-aab4-cb3c495d52a9))
		- Vector table
			- Fixed-layout block of code
			- Think of it as "emergency phonebook" for a particular EL
			- When some exception happens, the CPU does not know where to jump to
			- The CPU uses this to determine where to jump to when it's in a particular EL
	- ## Basic boot process for qemu AAarch64
		- Qemu hands control to our "kernel"
		- We set stack pointer, and zero the BSS
			- This is done in a "loop", one word at a time
		- If we're not in EL1 already, drop from EL2 to EL1
			- Configure EL2 to "return" to EL1 (for the switch)
			- Configure EL2 to not crash EL1 on some instructions (e.g. floating point)
			- Initialize stuff for EL1 and "return" from EL2 to EL1
		- `boot.S`
			- Here's our assembly `boot.S` that prepares the system for our Rust microkernel
				- ```asm
				  .section .text.boot
				  .global _start
				  _start:
				    // Set stack
				    ldr x0, =__stack_top
				    mov sp, x0
				  
				    // Zero BSS: [__bss_start, __bss_end)
				    ldr x1, =__bss_start
				    ldr x2, =__bss_end
				  1:
				    cmp x1, x2
				    b.ge 2f
				    str xzr, [x1], #8
				    b 1b
				  2:
				    // If we entered at EL2 (typical for QEMU virt), drop to EL1 so the kernel runs
				    // in a simpler environment (EL1 + GICv2 + CNTP timer).
				    mrs x1, CurrentEL
				    lsr x1, x1, #2
				    and x1, x1, #3
				    cmp x1, #2
				    b.ne el1_start
				  
				    // Set up an EL1 stack pointer.
				    ldr x0, =__stack_top
				    msr sp_el1, x0
				  
				    // Configure EL2 to return to EL1h.
				    mov x0, #(0b0101)         // EL1h
				    msr spsr_el2, x0
				    adr x0, el1_start
				    msr elr_el2, x0
				  
				    // Enable FP/ASIMD access at EL1 and ensure EL2 doesn't trap it.
				    mrs x0, cptr_el2
				    bic x0, x0, #(1 << 10)    // TFP = 0 (don't trap FP/ASIMD)
				    msr cptr_el2, x0
				    isb
				    eret
				  
				  el1_start:
				    // Install a minimal exception vector table for the *current* exception level.
				    // QEMU `virt` typically enters at EL2, so we must set VBAR_EL2 (not just VBAR_EL1).
				    adr x0, vectors
				    msr vbar_el1, x0
				    isb
				  
				    // Enable FP/ASIMD for Rust/LLVM.
				    // Rust/LLVM may use NEON registers for struct copies/memcpy even in early bring-up.
				    // If FP is disabled, this traps with EC=0x07 (FP/ASIMD access trap).
				    mrs x0, cpacr_el1
				    orr x0, x0, #(3 << 20)   // FPEN = 0b11
				    msr cpacr_el1, x0
				    isb
				  
				    bl rust_main
				  3:
				    wfe
				    b 3b
				  ```
			- The EL2-EL1 drop can be referenced here: ((69dd1ab5-0f03-4b46-bb0e-c4076bb0b9b0))
			- On L57, we are entering into Rust with `bl rust_main` (branch-with-link)
				- *Branch-with-link* saves the return address in ARM *link register*, `x30`
				- This means that, if `rust_main` ever returns, we'll come right back to where we are
				- `rust_main` is our Rust "entrypoint", instead of the usual `fn main()`
					- ```rust
					  #![no_std]
					  #![no_main]
					  
					  #[unsafe(no_mangle)]
					  pub extern "C" fn rust_main() -> ! {
					    todo!()
					  }
					  ```
					- Unlike normal programs, whose main returns to the OS, we're writing the OS, so there's no one to return to!
					- So our "main" must never return. This is a *hardware-level promise*, and it helps Rust optimize our binary by skipping the extra cleanup instructions
					- It also helps us guard against accidental return at compile time by the Rust compiler
				- The assembly L57:L60 guards against our Rust ever returning:
				- ```asm
				    bl rust_main
				  3:
				    wfe // Low-power mode, so our hardware won't overcook during crash
				    b 3b // Sometimes called *hardware dead-end*
				  ```
				- This is pessimistic, typical of assembly programmers
				- If our Rust code has a bug, or cosmic ray happens and our Rust pops a return address, and our CPU returns to the line after our `bl rust_main` line, the execution would be caught in this loop.
		- `main.rs`
			- Here's our Rust entrypoint
				- ```rust
				  #![no_std]
				  #![no_main]
				  
				  use core::panic::PanicInfo;
				  use hal::log::Logger;
				  
				  core::arch::global_asm!(include_str!("boot.S"));
				  
				  // QEMU `virt` PL011 UART base.
				  const UART0_BASE: usize = 0x0900_0000;
				  
				  struct UartLogger;
				  
				  impl UartLogger {
				      #[inline(always)]
				      fn mmio_write(offset: usize, val: u32) {
				          unsafe { core::ptr::write_volatile((UART0_BASE + offset) as *mut u32, val) }
				      }
				  
				      #[inline(always)]
				      fn mmio_read(offset: usize) -> u32 {
				          unsafe { core::ptr::read_volatile((UART0_BASE + offset) as *const u32) }
				      }
				  
				      fn putc(c: u8) {
				          // FR (0x18) bit5 = TXFF (transmit FIFO full)
				          while (Self::mmio_read(0x18) & (1 << 5)) != 0 {}
				          Self::mmio_write(0x00, c as u32);
				      }
				  
				      pub(crate) fn puts(s: &str) {
				          for &b in s.as_bytes() {
				              if b == b'\n' {
				                  Self::putc(b'\r');
				              }
				              Self::putc(b);
				          }
				      }
				  }
				  
				  impl hal::log::Logger for UartLogger {
				      fn log(&self, s: &str) {
				          UartLogger::puts(s);
				      }
				  }
				  
				  mod timer;
				  mod preempt;
				  mod mem;
				  
				  #[unsafe(no_mangle)]
				  pub extern "C" fn rust_main() -> ! {
				      let logger = UartLogger;
				      logger.log("rustOS: aarch64 QEMU virt boot OK\n");
				  
				      #[cfg(feature = "demo-ipc")]
				      {
				          logger.log("rustOS: IPC + cooperative scheduling demo\n");
				          kernel::kmain(&logger)
				      }
				  
				      #[cfg(feature = "demo-timer")]
				      {
				          logger.log("rustOS: timer interrupts demo\n");
				          timer::init();
				          logger.log("rustOS: timer started, entering idle loop\n");
				          loop {
				              hal::arch::halt();
				          }
				      }
				  
				      #[cfg(feature = "demo-preempt")]
				      {
				          logger.log("rustOS: preemptive multitasking demo\n");
				          preempt::init();
				          extern "C" {
				              fn start_first(ctx: *const preempt::Context) -> !;
				          }
				          unsafe { start_first(preempt::first_context()) }
				      }
				  
				      #[cfg(feature = "demo-memory")]
				      {
				          logger.log("rustOS: memory management demo (frames + page tables)\n");
				          mem::demo();
				          loop {
				              hal::arch::halt();
				          }
				      }
				  
				      #[cfg(not(any(feature = "demo-ipc", feature = "demo-timer",
				                     feature = "demo-preempt", feature = "demo-memory")))]
				      {
				          logger.log("rustOS: no demo selected, halting\n");
				          loop {
				              hal::arch::halt();
				          }
				      }
				  }
				  
				  #[panic_handler]
				  fn panic(_info: &PanicInfo) -> ! {
				      UartLogger::puts("rustOS: PANIC\n");
				      loop {
				          hal::arch::halt();
				      }
				  }
				  ```