#!/usr/bin/env python

import patcherex
from patcherex.backends.detourbackend import DetourBackend
from patcherex.backends.reassembler_backend import ReassemblerBackend
from patcherex.patches import *
import sys
import subprocess
import os

archs = {
        "mips": "mipsel-linux-gnu-gcc-5  -Xassembler --relax-branch -Xassembler -call_nonpic {in_file} -o {outfile}",
        "x86": "gcc -m32 -f dwarf -g {in_file} -o {outfile}",
        "x86_64": "gcc -f dwarf -g {in_file} -o {outfile}",
        "armel32":"python arm_fixup.py {in_file} && arm-linux-gnueabi-gcc -Xassembler --gstabs+ -masm-syntax-unified -ffunction-sections -mcpu=cortex-a8 -g {in_file} -o {outfile}",
        }

runs = { "armel32":"qemu-arm-static -L /usr/arm-linux-gnueabi {outfile}"
        }
if len(sys.argv) < 3:
    print("Usage: {} [binary] [architecture] [autorun]\n\tValid architectures: {}".format(sys.argv[0], ", ".join(archs.keys())))
    sys.exit(1)

name = sys.argv[1]
arch = sys.argv[2]
autorun = True if len(sys.argv) == 4 else False
backend = ReassemblerBackend(name)
patches = []

out_file="a.out"
out_asm = "/tmp/{}_mod".format(name.replace("/","_"))
# and then we save the file
backend._binary.remove_unnecessary_stuff() #Seriously?
try:
    backend.save(out_asm)
except Exception as e:
    s = str(e)
    if "/tmp/" in s:
        fname = "/tmp/"+s.split("/tmp/")[1].split(" ")[0]
        print("Builtin RAMBLR assembler failed. Asm file at {}".format(fname))
    else:
        raise

if arch in archs.keys():
    print("\nTrying to autobuild for {}".format(arch))
    try:
        dir_path = os.path.dirname(os.path.realpath(__file__))
        print(subprocess.check_output(archs[arch].format(in_file=fname, outfile=out_file), shell=True, cwd=dir_path))
        print("Autobuild success! Saved to {}".format(out_file))
        #os.remove(out_asm)
        if autorun and arch in runs:
            print("Running {}\n".format(out_file) + "="*10)
            print(subprocess.check_output(runs[arch].format(outfile=out_file), shell=True))
            print("="*10+"\n")


    except subprocess.CalledProcessError as e:
        print("Autobuild failed: ran {}".format(archs[arch].format(in_file=fname, outfile=out_file)))

else:
    print("No support for auto-building {}, manually build {}".format(arch, fname))

print(fname)
