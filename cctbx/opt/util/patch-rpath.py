#!/usr/bin/env python
# -*- coding: utf-8 -*-


import os
import sys
import glob
import subprocess



RUNPATH_TOKEN = "(RUNPATH)"
RPATH_TOKEN   = "(RPATH)"



def read_elf(file_name):
    out = os.popen(f"readelf -d {file_name}").read()

    elf_data = dict()
    elf_data["has_runpath"] = RUNPATH_TOKEN in out
    elf_data["has_rpath"]   = RPATH_TOKEN in out
    elf_data["lines"]       = out.split("\n")
    return elf_data



paren = lambda s: s[s.find("[")+1:s.find("]")]



def get_elf_path(token, lines):
    fi_token = filter(lambda line: token in line, lines)
    matches  = list(fi_token)
    if len(matches) == 1:
        return paren(matches[0])
    else:
        raise RuntimeError(f"Got {len(matches)} matches, expected 1: {matches}")



TRANS_MAP = {"-":r"\-", "]":r"\]", "\\":r"\\", "^":r"\^", "$":r"\$", "*":r"\*"}
escaped = lambda a: a.translate(str.maketrans(TRANS_MAP))



def set_elf_path(rpath, file_name, log="patchelf.log"):

    rpath_escaped = escaped(rpath)

    with open(log, "a") as f:
        f.write(f"=>Patching {file_name}: RPATH -> RUNPATH")
        f.write(f"* Running patch for {rpath}\n")


    cmd = f"patchelf --remove-rpath {file_name}"

    with open(log, "a") as f: f.write(f" 1. {cmd}\n")

    status = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if status.returncode != 0 :
        error_message = f"{cmd} didn't work: {status.stderr}"
        with open(log, "a") as f: f.write(f"    ERROR: {error_message}\n\n")
        # raise RuntimeError(error_message)
        print(error_message)

    cmd = f"patchelf --set-rpath \"{rpath_escaped}\" {file_name}"

    with open(log, "a") as f: f.write(f" 2. {cmd}\n")

    status = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if status.returncode != 0 :
        error_message = f"{cmd} didn't work: {status.stderr}"
        with open(log, "a") as f: f.write(f"    ERROR: {error_message}\n\n")
        # raise RuntimeError(error_message)
        print(error_message)

    with open(log, "a") as f: f.write("\n")




if __name__ == "__main__":
    target_dir = sys.argv[1]

    print(f"Patching RPATH to RUNPATH for all shared objects in {target_dir}")

    for root, dirs, files in os.walk(target_dir):
        for file_name in glob.glob(os.path.join(root, "*.so")):
            elf = read_elf(file_name)
            if elf["has_rpath"]:
                print(f"Patching {file_name}: RPATH -> RUNPATH")
                rpath = get_elf_path(RPATH_TOKEN, elf["lines"])
                set_elf_path(rpath, file_name)
            else:
                print(f"Not patching {file_name}: no RPATH")
