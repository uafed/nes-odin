#+feature dynamic-literals

package main

import "core:fmt"
import "core:mem"
import "core:os"
import "vendor:sdl2"

NATIVE_SCREEN_WIDTH :: 256
NATIVE_SCREEN_HEIGHT :: 240
WINDOW_SCALE :: 4

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
	assert(sdl2.Init(sdl2.INIT_VIDEO) == 0, sdl2.GetErrorString())
	defer sdl2.Quit()

	window := sdl2.CreateWindow(
		title = "NES Emulator",
		x = sdl2.WINDOWPOS_CENTERED,
		y = sdl2.WINDOWPOS_CENTERED,
		w = NATIVE_SCREEN_WIDTH * WINDOW_SCALE,
		h = NATIVE_SCREEN_HEIGHT * WINDOW_SCALE,
		flags = sdl2.WINDOW_SHOWN,
	)
	assert(window != nil, sdl2.GetErrorString())
	defer sdl2.DestroyWindow(window)

	if len(os.args) != 2 {
		fmt.fprintf(os.stderr, "Usage: nes-odin <path to rom file>\n")
		return
	}

	path := os.args[1]
	rom, err := read_rom_file(path = path)
	defer delete(rom.program_data, context.allocator)

	if err != .None {
		fmt.fprintf(os.stderr, "[Error]: Could not read \"%s\" (error: %s)\n", path, err)
		return
	}

	fmt.fprintf(os.stdout, "magic: \"%s\"\n", rom.header.magic)
	fmt.fprintf(os.stdout, "program_size (header): %d\n", u32(rom.header.program_size) * 16 * 1024)
	fmt.fprintf(os.stdout, "program_data (actual): %d\n", len(rom.program_data))

	state := CpuState{}
	state.accumulator = 0
	state.x_index = 0
	state.y_index = 0
	state.stack_ptr = 0xfd
	state.status = {.InterruptDisable}
	state.program_counter = 0xfffc
	state.internal_memory = state.memory[0:2048]

	for {
		event: sdl2.Event

		for sdl2.PollEvent(&event) {
			#partial switch event.type {
			case .QUIT:
				return
			case .KEYDOWN:
				if event.key.keysym.scancode == sdl2.SCANCODE_ESCAPE {
					return
				}
			}
		}

		// fetch & decode instructions
		instruction := fetch_and_decode_instruction(&state)
		if instruction == nil {
			fmt.fprintf(os.stderr, "Unrecognized instruction:", instruction)
		}

		switch instr in instruction {
		case AddWithCarry:
			switch mode in instr {
			case Immediate:
			case ZeroPageDirect:
			case ZeroPageIndexed:
			case AbsoluteDirect:
			case AbsoluteIndexed:
			}
		}
	}
}

fetch_next_byte :: proc(state: ^CpuState) -> u8 {
	value := state.memory[state.program_counter]
	state.program_counter += 1
	return value
}

fetch_next_u16 :: proc(state: ^CpuState) -> u16 {
	high := state.memory[state.program_counter]
	state.program_counter += 1
	low := state.memory[state.program_counter]
	state.program_counter += 1
	return (u16(high) << 8) | u16(low)
}


fetch_and_decode_instruction :: proc(state: ^CpuState) -> Instruction {
	opcode := fetch_next_byte(state)
	switch opcode {
	// Add width carry
	case 0x69:
		return AddWithCarry(Immediate{operand = fetch_next_byte(state)})
	case 0x65:
		return AddWithCarry(ZeroPageDirect{operand = fetch_next_byte(state)})
	case 0x75:
		return AddWithCarry(ZeroPageIndexed{operand = fetch_next_byte(state), index = .X})
	case 0x6D:
		return AddWithCarry(AbsoluteDirect{address = fetch_next_u16(state)})
	case 0x7D:
		return AddWithCarry(AbsoluteIndexed{operand = fetch_next_byte(state), index = .X})
	case 0x79:
		return AddWithCarry(AbsoluteIndexed{operand = fetch_next_byte(state), index = .Y})
	case 0x61:
		return AddWithCarry(IndirectIndexed{operand = fetch_next_byte(state), index = .X})
	case 0x71:
		return AddWithCarry(IndirectIndexed{operand = fetch_next_byte(state), index = .Y})
	}
	return nil
}
