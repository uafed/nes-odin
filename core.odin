package main

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
	memory:          [64 * 1024]u8,
	internal_memory: []u8,
}

Index :: enum {
	X,
	Y,
}

ZeroPageDirect :: struct {
	operand: u8,
}

ZeroPageIndexed :: struct {
	operand: u8,
	index:   Index,
}

Accumulator :: struct {}

AbsoluteDirect :: struct {
	address: u16,
}

AbsoluteIndexed :: struct {
	operand: u8,
	index:   Index,
}

IndirectIndexed :: struct {
	operand: u8,
	index:   Index,
}


Immediate :: struct {
	operand: u8,
}

AddWithCarry :: union {
	Immediate,
	ZeroPageDirect,
	ZeroPageIndexed,
	AbsoluteDirect,
	AbsoluteIndexed,
	IndirectIndexed,
}

Instruction :: union {
	AddWithCarry,
}
