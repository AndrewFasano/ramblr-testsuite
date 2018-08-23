# randprog
Reassembablable disassembly test framework

1. Generate valid C source code with Csmith
2. Compile it for ARM
3. Use Ramblr to generate assembly
4. Assemble Ramblr output
5. Compare original and rewritten checksums

### Install
Get and install Csmith in the randprog directory
`git clone https://github.com/csmith-project/csmith.git`

Build Csmith
`cd cmith`

`./configure` or `CC=arm-linux-gnueabi-gcc ./configure --host=arm-linux-gnueabi`

```
make
cp runtime/csmith /usr/local/bin
```

### Usage
Run with `./test.sh [seed]`

If no seed is provided, a random seed will be used.
