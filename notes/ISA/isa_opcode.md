# Bit-Field in Operation Code

Operation COde's bit-field is;

[Unit Sel[2:0]][Func Sel[1:0]][OpCode[1:0]][ConstFlag[1:0]]

Total 9-bit.

## 1. Unit Selector [2:0]

Unit Sel (Unit Selector) bit-field selects scalar unit or vector unit and its execution unit cluster.

### [2] Scalar/Vector Unit Select
- 0		Scalar Unit
- 1		Vector Unit

### [1:0] Execution Cluster Select
- 00		Arithmetic Unit
- 01		Conditional (Scalar: Jump/Branch (PAC) Unit, Vector: Mask Unit)
- 10		Logic/Shift/Rotate Units
- 11		Load/Store Unit

Section 2nd to 5th shows encode for every execution cluster. BLASEngine's unique point is scalar unit and vector unit have same instruction bit-field assignment and every field has same roles.

## 2. Arithmetic Unit [1:0]
### Scalar Unit
- 00		Adder
    - OpCode [1:0]
	    - 00		Unsiged Addition
	    - 01		Unsigned Subtruction
	    - 10		Signed Addition
	    - 11		Signed Subtruction
- 01		Multiplier
    - OpCode [1:0]
	    - 00		Unsigned Multiplication
	    - 01		Signed Multiplication
	    - 10		Add-Multiply
	    - 11		Multiply-Add
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
	    - 10		Output Scalar Data
	    - 11		Bit-Reverse
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
	    - 10		Add-Multiply
	    - 11		Multiply-Add
- 10		Reserved
- 11		Convert
	- OpCode [1:0]
	    - 00		Float32 to Int32
	    - 01		Move
		- 10		Input Scalar Data
	    - 11		Reserved

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
	    - 00		Relative Jump width Constant
	    - 01		Relative Jump width Source
	    - 1x		Reserved
- 10		Branch
	- OpCode [1:0]
	    - 00		Relative Branch width Constant
	    - 01		Relative Branch width Source
	    - 1x		Reserved
- 11		Vector Unit Handle
	- Opcode [1:0]
		- 00 Enable All Lanes
		- 01 Reserved
		- 10 Write Lane-Enable Register
		- 11 Read Lane Status Register

### Vector Unit
- 00		Compare
	- OpCode [1:0]
	    - 00		Equal
	    - 01		Greater than
	    - 10		Lesser than or Equal
	    - 11		Not Equal
- 01		Set Mask
	- Opcode [1:0]
	    - 00 Set Mask All One
		- 01 Reserved
		- 1x Reserved
- 10		Mask Handle
    - Opcode [1:0]
		- 00 Enable Masked Operation
		- 01 Disable Masked Operation
		- 10 Reserved
		- 11 Set Mask by True of Follower Comparing
- 11		Selector
	- Opcode [1:0]
		- 00 max()
		- 01 min()
		- 1x Reserved


## 4. Logic/Shift/Rotate [1:0]
### Scalar Unit
- 00		Shift
	- OpCode [1:0]
	    - 00		Logic Left-Shift
	    - 01		Arithmetic Left-Shift
	    - 10		Logic Right-Shift
	    - 11		Arithmetic Right-Shift
- 01		Rotate
    - OpCode [1:0]
	    - 00		Left-Rotate
	    - 01		Reserved
	    - 10		Right-Rotate
	    - 11		Reserved
- 10		Logic
	- OpCode [1:0]
	    - 00		NOT
	    - 01		AND
	    - 10		OR
	    - 11		XOR
- 11		Reserved

### Vector Unit
- 00 Power and Logarithm
	- OpCode [1:0]
	    - 00		Exponential
	    - 01		Power of Any
	    - 10		Logarithm of Two
	    - 11		Reserved
- 10 Reserved
- 1x		Reserved


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

## 6. Constant Operation Flag ConstSel[1:0]

- 00 No Constant
- 01 Source-1 Constant (Access-Length in case of Ld/St)
- 10 Source-2 Constant (Stride Factor in case of Ld/St)
- 11 Source-3 Constant (Base Address in case of Ld/St)
