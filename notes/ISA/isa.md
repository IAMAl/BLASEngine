# Bit-Field in Operation Code

## 1. Unit Selector [2:0]
### [2]
- 0		Scalar Unit
- 1		Vector Unit

### [1:0]
- 00		Arithmetic Unit
- 01		Conditional (Scalar: Jump/Branch (PAC) Unit, Vector: Mask Unit)
- 10		Logic/Shift/Rotate Units
- 11		Load/Store Unit


## 2. Arithmetic Unit [1:0]
### Scalar Unit
- 00		Adder
    - OpCode [1:0]
	    - 00		Unsiged Addition
	    - 01		Unsigned Subtruction
	    - 10		Signed Addition
	    - 11		Signed Addition
- 01		Multiplier
    - OpCode [1:0]
	    - 00		Unsigned Multiplication
	    - 01		Signed Multiplication
	    - 1x		Reserved
- 10		Divider
	- OpCode [1:0]
		- 00		Unsigned Division
		- 01		Signed Division
		- 10		Unsigned Modulo
		- 11		Float32 Division
- 11		Convert
	- OpCode [1:0]
	    - 00		Int32 to Float32
	    - 01		Move
	    - 10		Bit-Reverse
	    - 11		Reserved
### Vector Unit
- 00		Adder
	- OpCode [1:0]
	    - 00		Addition
	    - 01		Subtraction
        - 1x		Reserved
- 01		Multiplier
	- OpCode [1:0]
	    - 00		Multiplication
	    - 01		Reserved
	    - 1x		Reserved
- 10		Specials
	- OpCode [1:0]
	    - 00		Power of Any
	    - 01		Exponential
	    - 10		Logarithm of Two
	    - 11		Reserved
- 11		Convert
	- OpCode [1:0]
	    - 00		Float32 to Int32
	    - 01		Move
	    - 1x		Reserved

## 3. Conditional	[1:0]
### Scalar Unit
- 00		Compare
	- OpCode [1:0]
	    - 00		Equal
	    - 01		Greater than
	    - 10		Lesser than or Equal
	    - 11		Not Equal
- 01		Jump
	- OpCode [1:0]
	    - 00		Relative Jump width Source
	    - 01		Relative Jump width Constant
	    - 1x		Reserved
- 10		Branch
	- OpCode [1:0]
	    - 00		Relative Branch width Source
	    - 01		Relative Branch width Constant
	    - 1x		Reserved
- 11		Reserved

### Vector Unit
- 00		Compare
	- OpCode [1:0]
	    - 00		Equal
	    - 01		Greater than
	    - 10		Lesser than or Equal
	    - 11		Not Equal
- 01		Reserved
- 10		Reserved
- 11		Mask Handle
    - Opcode [1:0]
	    - 00 Set Mask All One
		- 01 Enable Masked Operation
		- 10 Disable Masked Operation
		- 11 Set Mask by Comparing


## 4. Logic/Shift/Rotate [1:0]
### Scalar Unit
- 00		Logic
	- OpCode [1:0]
	    - 00		NOT
	    - 01		AND
	    - 10		OR
	    - 11		XOR
- 01		Shift
	- OpCode [1:0]
	    - 00		Logic Left-Shift
	    - 01		Arithmetic Left-Shift
	    - 10		Logic Right-Shift
	    - 11		Arithmetic Right-Shift
- 10		Rotate
    - OpCode [1:0]
	    - 00		Left-Rotate
	    - 01		Reserved
	    - 10		Right-Rotate
	    - 11		Reserved
- 11		Reserved

### Vector Unit
- xx		Reserved


## 5. Load/Store [1:0]
### Scalar Unit
- 00		Load with Sign-Extension to 4-Byte for Even Unit
    - OpCode	[1:0]
	    - 00		Byte Load
	    - 01		Short Load
	    - 10		Word Load
	    - 11		Reserved
- 01		Load with Sign-Extension to 4-Byte for Odd Unit
	- OpCode	[1:0]
	    - 00		Byte Load
	    - 01		Short Load
	    - 10		Word Load
	    - 11		Reserved
- 10		Store for Even Unit
    - OpCode	[1:0]
	    - 00		Byte Store
	    - 01		Short Store
	    - 10		Word Store
	    - 11		Reserved
- 11		Store for Odd Unit
	- OpCode	[1:0]
	    - 00		Byte Store
	    - 01		Short Store
	    - 10		Word Store
	    - 11		Reserved

### Vector Unit
- 00		Normal Word-Load for Even Unit
	- OpCode	[1:0]
	    - 0x		Reserved
	    - 10		Word Load
	    - 11		Reserved
- 01		Normal Word-Load for Odd Unit
	- OpCode	[1:0]
	    - 0x		Reserved
	    - 10		Word Load
	    - 11		Reserved
- 10		Normal Word Store for Even Unit
    - OpCode	[1:0]
	    - 0x		Reserved
	    - 10		Word Store
	    - 11		Reserved
- 11		Normal Word Store for Odd Unit
    - OpCode	[1:0]
	    - 0x		Reserved
	    - 10		Word Store
	    - 11		Reserved
