import sys
import os

filename = None
try:
    filename = sys.argv[1]
    outfile = os.path.basename(filename)
    outfile = os.path.splitext(outfile)[0]+'.woz'
    fh = open(filename, "rb")
    data = fh.read()
    hexarr = ["%02x" % b for b in data]
    fh.close()
    i = 62592  # F480
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
    print("USAGE: %s <filename.bin>" % sys.argv[0])
except FileNotFoundError as e:
    print("%s not found." % filename)
