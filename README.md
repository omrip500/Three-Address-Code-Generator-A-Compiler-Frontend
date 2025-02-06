# Three Address Code Generator – A Compiler Frontend

## Overview
This project is a **compiler frontend** that translates a simple programming language into **Three Address Code (TAC)** using **Flex** and **Bison**. It supports expressions, control structures, type handling, and input/output operations.

## Features
- **Lexical Analysis**: Tokenizes the input source code.
- **Syntax Analysis**: Parses the tokenized input and verifies grammar rules.
- **Type System**: Supports `int` and `double` types with automatic type conversion.
- **Control Flow**:
  - `if` and `while` statements
  - **Custom `repeat` statement** (new feature added)
- **Input & Output Statements**:
  - `READ(var)`: Reads a value from input into a variable.
  - `WRITE(expression)`: Prints an expression to output.
- **Error Handling**:
  - Detects undeclared variables.
  - Prevents redeclaration of variables.
  - Ensures type compatibility in expressions and assignments.

## Compilation & Execution
### **Requirements**
- `flex`
- `bison`
- `gcc`

### **Build Instructions**
```bash
make
```

### **Running the Generator**
```bash
./gen ./examples/input_file.txt
```

### **Example Code**
#### **Input (example.txt)**
```c
a  = (b+c)*(d+f);

while (a < b+c)
    a = a + y;

if (w+z<b+c)
     a = a+y;
else
     z = y;
```
#### **Generated Three Address Code (output.tac)**
```assembly
    t1 = b + c
    t2 = d + f
    t3 = t1 * t2
    a = t3
    
L_1:
    t4 = b + c
    ifFalse a < t4 goto L_2
    t5 = a + y
    a = t5
    goto L_1
L_2:
    
    t6 = w + z
    t7 = b + c
    ifFalse t6 < t7 goto L_4
    t8 = a + y
    a = t8
    goto L_3
L_4:
    z = y
L_3:
    
```

## File Structure
```
|-- tac_generator/
    |-- src/
        |-- gen.y (Bison grammar)
        |-- gen.lex (Flex scanner)
        |-- symboltable.c (Symbol table implementation)
        |-- symboltable.h (Symbol table header)
        |-- main.c (Entry point for the generator)
    |-- examples/
        |-- input_example.txt
        |-- output_example.tac
    |-- Makefile
    |-- README.md
```

## Future Improvements
- Add support for functions.
- Implement an optimization phase.
- Extend type system with `char` and `string` support.

