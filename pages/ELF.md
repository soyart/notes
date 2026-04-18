- > See also: https://en.wikipedia.org/wiki/Executable_and_Linkable_Format
- ELF is a *file format* for executables, object code, shared libraries, device drivers, etc
	- Historically, it was specified in Unix SVR4 ABI
	- Its DOS-Windows equivalent is `.EXE`
- By design, it's cross-platform supports different endianness
- # ELF structure
	- > An ELF file is like a shipping manifest. It says: “here’s a chunk of 
	  executable code, load it at this address. Here’s read-only data, put it 
	  over here. Here’s uninitialized data (BSS), allocate this much space and
	   zero it. Oh, and the program starts executing at this address.”
	  >
	  > https://blog.desigeek.com/post/2026/02/building-microkernel-part1-foundations-boot/
	- Each ELF has "sections" to it
		- ![File:Elf-layout--en.svg](https://upload.wikimedia.org/wikipedia/commons/thumb/7/77/Elf-layout--en.svg/1920px-Elf-layout--en.svg.png)
	- ### ELF Header
	  id:: 69e3ab7b-1f5e-4942-80c6-31f91ee1997a
		- > ELF information
		- `e_ident` (32-bit of data)
			- `EI_VERSION`
				- ELF version
			- `EI_DATA`
				- Endianness
			- `EI_ABIVERSION`
				- Define OS ABI
			- `EI_CLASS`
				- Define bit size
		- `e_version`
			- Define ELF version
		- `e_machine`
			- Define ISA
		- `e_entry`
			- Entry point offset within this ELF
		- `e_ehsize`
			- Size of this ELF Header
		- `e_phoff`
			- Offset to ((69e3ab64-c87c-4fe1-a9c2-b420bcf08a59)) within this ELF
		- `e_shoff`
			- Offset to ((69e3ad5e-da21-4ca9-a4c0-374ae594bf23)) within this ELF
		- Fields that control ((69e3ab64-c87c-4fe1-a9c2-b420bcf08a59)) and ((69e3ad5e-da21-4ca9-a4c0-374ae594bf23))
			- PHT
				- `e_phentsize`
				- `e_phnum`
			- SHT
				- `e_shentsize`
				- `e_shnum`
	- ### Program Header Table (PHT)
	  id:: 69e3ab64-c87c-4fe1-a9c2-b420bcf08a59
		- > PHT defines execution blueprint, i.e. "how to create a *process image* (how memory should look like for executing this process)"
		  >
		  > This means that non-executable ELF files (e.g. a shared object `.o` files) are missing PHT.
		  >
		  > Another thing is PHT is always fixed-size (56 bytes for 64-bit PHT) for parsing speed. When there's no information, the region still takes the same space but zeroed instead
		- Define multiple memory segments in the table as entries
		- Each PHT entry (a segment) is defined with:
			- > Segments do not have names and are identified from their types only
			- `p_type`
				- Segment type for this entry
				- Type examples
					- `PT_LOAD`
						- The segment is just to be loaded/copied to memory
						- Usually we have 2 `PT_LOAD` segments:
							- *Code* segment (R-E), usually points to `.text` section
							- *Data* segment (RW-), usually points to `.data` section
							- Alternatively, read-only data segment, usually points to `.rodata`
					- `PT_INTERP`
						- Path to program interpreter, usually the system's dynamic linker
						- Only 1 such segment per ELF file
						- Example would be `/lib64/ld-linux-x86_64.so.2` or `/lib/ld-linux-aarch64.so.1` on Linux
							- For a static C binary, this segment type is not needed
					- `PT_DYNAMIC`
						- List of all shared libraries (dynamic linking), or the `.so` files
			- `p_offset`
				- Offset within start of this ELF file to this segment
			- `p_vaddr`
				- Address in [[Virtual memory]] to load this segment to
			- `p_paddr`
				- Address in [[Physical memory]] to load this segment to
			- `p_filesz` and `p_memsz`
				- Size on file and in memory
			- `p_flags`
				- Feature flags such as permissions (R/W/X)
			- `p_align`
				- Enabling alignment for this segment
				- Disable alignment with `0` and `1`
				- Otherwise, give it a power of 2 value
				- Usually we use system's page size (e.g. 4096B or 2MB)
				- The OS loader uses this to ensure that `p_vaddr` (memory address) and `p_offset` (file offset) are congruent modulo the page size. This allows the  kernel to map file pages directly into memory pages without data shifting.
	- ### Section Header Table (SHT)
	  id:: 69e3ad5e-da21-4ca9-a4c0-374ae594bf23
		- ### Note: Segments vs sections
			- > [ELF sections and segments](https://neetx.github.io/posts/ELF-headers-sections-and-segments/)
			- Segments are useful at run time, when the OS is loading the program, **but segments are useless at _link time_**
			- **Sections are also region of memory, usually smaller, and are used only at _link time_**
			- A PHT segment is a region of memory, which implicitly contains some SHT sections
				- **Link-time**: The linker groups all data sections with R permission to a single PHT segment of type `PT_LOAD` with read-only permissions.
				- **Runtime**: This big `PT_LOAD` segment is loaded by the OS at runtime, according to PHT
			- Segments are used at higher-level because it's larger and more crude
			- Segments are also the smallest unit the OS loads into memory
		- SHT defines other zero or more *memory sections* within the file
		- SHT is mostly fixed-size (`Elf32_Shdr` or `Elf64_Shdr`)
		- SHT refers to a section called `.shstrtab` for section names
			- > Note: Section names are **not** enforced by the ELF format itself, but they are heavily dictated by **convention and compiler behavior**.
			- The location of this `.shstrtab` section can be found in our ((69e3ab7b-1f5e-4942-80c6-31f91ee1997a)), field `e_shstrndx`
			- For example, if our SHT has 3 sections `.text`, `.data`, `.shstrtab`, our `.shstrtab` would look like this:
			  ```
			  .text\0.data\0.shstrtab\0
			  ```
		- Each section defines:
			- `sh_name` (index, not a string!)
				- Zero-based index within `.shstrtab`
				- Example
					- Let's say we have just 4 sections in this ELF: `.text`, `.rodata`, `.bss`, `.iterp`
					- Then our `.shstrtab` would look like this:
					  ```
					   .text\0.rodata\0.bss\0.iterp
					  ```
					- So, our actual `.rodata` section will have `sh_name` equal to `1`
			- `sh_type`
				- `SHT_PROGBITS` for *program bits*, i.e. code and data
				- `SHT_SYMTAB` for symbol table
			- `sh_flag`
				- Permissions and feature flags
			- `sh_offset`
				- Offset to this section within the ELF file
			- `sh_addr`
				- The [[Virtual memory]] address where this section's first byte should reside if it appears in a memory image.
			- `sh_size`
				- The section size
			- `sh_addralign`
				- Required alignment of this section. Lower level than segment's `p_align`