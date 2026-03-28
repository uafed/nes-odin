#+feature dynamic-literals

package main

import "core:fmt"
import "core:mem"
import "core:os"
import "vendor:sdl2"

Flags :: enum {
	Carry            = 0,
	Zero             = 1,
	InterruptDisable = 2,
	Decimal          = 3,
	Overflow         = 6,
	Negative         = 7,
}

CpuState :: struct {
	accumulator:     u8,
	x_index:         u8,
	y_index:         u8,
	stack_ptr:       u16,
	status:          bit_set[Flags;u8],
	program_counter: u16,
	memory:          [2048]u8,
}

ZeroPageDirect :: struct {
	oper: u8,
}

Index :: enum {
	X,
	Y,
}

ZeroPageIndexed :: struct {
	operand: u8,
	index:   Index,
}

ZeroPage :: union {
	ZeroPageDirect,
	ZeroPageIndexed,
}

Accumulator :: struct {}

AbsoluteDirect :: struct {
	address: u16,
}

AbsoluteIndexed :: struct {
	index: Index,
}

Absolute :: union {
	AbsoluteIndexed,
}

Immediate :: struct {
	operand: u8,
}

AddressingMode :: union {
	ZeroPage,
	Absolute,
	Immediate,
	Accumulator,
}

Opcode :: enum {
	ADC,
}

Instruction :: struct {
	opcode: Opcode,
	input:  AddressingMode,
}

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
	fmt.fprintf(os.stdout, "program_size: %d\n", u32(rom.header.program_size) * 16 * 1024)
	fmt.fprintf(os.stdout, "program_data: %d\n", rom.program_data[:])

	state := CpuState{}

	_ = state.memory[state.program_counter]
	_ = Instruction {
		opcode = .ADC,
		input  = ZeroPage(ZeroPageDirect{}),
	}

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
	}

}
