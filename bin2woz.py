import sys
import os

#  This script takes a compiled 6502 binary file and creates a text
#  file containing the Wozmon commands to load the program into
#  memory.

filename = None
address = int("F480", 16)
argaddr = None
try:
    filename = sys.argv[1]
    if len(sys.argv) > 2:
        argaddr = sys.argv[2].upper()
        address = int(argaddr, 16)
    outfile = os.path.basename(filename)
    outfile = os.path.splitext(outfile)[0]+'.woz'
    fh = open(filename, "rb")
    data = fh.read()
    hexarr = ["%02x" % b for b in data]
    fh.close()
    i = address
    lines = []
    for h in hexarr:
        addr = "%04x" % i
        strout = "%s:%s\r" % (addr.upper(), h.upper())
        lines.append(strout)
        i += 1
    fh = open(outfile, "w")
    fh.writelines(lines)
    fh.close()
except IndexError as e:
    print("USAGE: %s FILE [START ADDRESS]" % sys.argv[0])
except FileNotFoundError as e:
    print("%s not found." % filename)
except ValueError as e:
    print("%s is not a valid address." % argaddr)
