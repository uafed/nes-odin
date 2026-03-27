#+feature dynamic-literals

package main

import "core:fmt"
import "core:mem"
import "core:os"

main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("\n=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			} else {
				fmt.println("\n=== No leaks found === ")
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	if len(os.args) != 2 {
		fmt.fprintf(os.stderr, "Usage: nes-odin <path to rom file>\n")
		return
	}

	path := os.args[1]
	rom, err := read_rom_file(path = path)
	defer delete(rom.program_data)

	if err != .None {
		fmt.fprintf(os.stderr, "[Error]: Could not read \"%s\" (error: %s)\n", path, err)
		return
	}

	fmt.fprintf(os.stdout, "magic: \"%s\"\n", rom.header.magic)
	fmt.fprintf(os.stdout, "program_size: %d\n", u32(rom.header.program_size) * 16 * 1024)
	fmt.fprintf(os.stdout, "program_data: %d\n", rom.program_data[:])

	// Loop where we fetch-decode-execute instructions
}
