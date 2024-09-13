# Bit-Field in Operand Code

Operand bit-field is;

[Dst[8:0]][Src1[8:0]][Src2[8:0]][Src3[8:0]][Win0[6:0]][Win1[6:0]][Win2[6:0]][Win3[6:0]][Slice[6:0]]

Total 71-bit.
**Note**: Win0 is used for Destination (Dst/dst) operand.


### Register Index

- Number of Register Files: 2 units
- Register File: 64 entries
**NOTE: 2 Register File Spaces**


Total 9-bit field for each operand.

- Valid: 1-bit
- Slicing: 1-bit
- Operand: 7-bit Src/Dst[6:0]
    - [6] Register File Space Indicator
        0 Even Register File
        1 Odd Register File
    - [5:0] Register Index

### Operands

One destination operand (Dst/dst) and three source operands (Src/src) are supported.

### Slicing

Slicing supports contiguous register access, maximum size is 64 (size of register file). Actual access length is the vallue plus one. All operands support the slicing, and share the value.

- Valid: 1-bit
- Slicce Length: 6-bit; Slice[5:0]

### Windowing

Windowing supports a scope in register file under contiguous accesses represented by slice length. Actual scope size is the value plus one. All source operands support the windowing, each source has its own window, but destination operand does not support.

- Valid: 1-bit
- Window Size [5:0]; Win[5:0]


## Constant

Depending on ConstSel Field (see isa_opcode.md). The ConstSel indicates one of source-1, 2, and 3 can be constant. The bit field (sub-total 15-bit) indicated by ConstSel is used for constructing constant (immediate) value. Instruction Length (96-bit), Operation Code (9-bit), Operand Field (71-bit), remains 16-bit (Const Field), plus the 16-bit, makes 32-bit constant (immediate) value.

- 32-bit Integer/Float Constant Construction: [Src[8:0]][Win[6:0]][Const[15:0]]
- Maxium 23-bit Data Memory Constant Construction: [Win[6:0]][Const[15:0]]