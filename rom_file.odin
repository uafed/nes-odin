package main

import "core:os"

Nes_Header :: struct {
	magic:        [4]u8,
	program_size: u8,
	chr_size:     u8,
	flags:        [5]u8,
	padding:      [5]u8,
}

Nes_Rom :: struct {
	header:       Nes_Header,
	program_data: []u8,
}

Nes_Parse_Error :: enum {
	None = 0,
	Invalid_Header,
	Invalid_Payload,
}

Error :: union #shared_nil {
	os.Error,
	Nes_Parse_Error,
}

read_rom_file :: proc(path: string) -> (Nes_Rom, Error) {
	data, err := os.read_entire_file(path, context.allocator)
	defer delete(data, context.allocator)

	if err != os.General_Error.None {
		return {}, err
	}

	if len(data) < 16 {
		return {}, Nes_Parse_Error.Invalid_Header
	}

	rom := Nes_Rom {
		header = Nes_Header{},
	}

	_ = copy(rom.header.magic[:], data[0:4])

	rom.header.program_size = data[4]
	rom.header.chr_size = data[5]

	_ = copy(rom.header.flags[:], data[6:10])
	_ = copy(rom.header.padding[:], data[11:15])

	if len(data) - 16 < int(rom.header.program_size) {
		return {}, Nes_Parse_Error.Invalid_Payload
	}

	total_size := u32(rom.header.program_size) * 16 * 1024

	prg_data, prg_err := make([]u8, total_size, context.allocator)
	_ = copy(prg_data[:], data[16:])

	rom.program_data = prg_data

	if prg_err != .None {
		return {}, err
	}
	return rom, err
}
