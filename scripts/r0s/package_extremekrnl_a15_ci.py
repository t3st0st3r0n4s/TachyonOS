#!/usr/bin/env python3
"""Verify the original ExtremeKRNL recovery ZIP; rename for its exact KSU tag.

No ROM rebuild, donor-image substitution, AVB re-signing or updater changes.
The upstream A15 three-image recovery updater is already used by TachyonOS.
"""
import argparse
import hashlib
import os
from pathlib import Path
import re
import shutil
import sys
import zipfile

PARTS = ("boot", "vendor_boot", "dtbo")
UPDATER = ("META-INF/com/google/android/update-binary",
           "META-INF/com/google/android/updater-script")
MEMBERS = set(UPDATER) | {"files/" + name + ".img" for name in PARTS}
VERSION = re.compile(r"v[0-9]+\.[0-9]+\.[0-9]+")
NATIVE = re.compile(
    r"(ExtremeKRNL-[A-Za-z0-9_.+-]+)_r0s_UNOFFICIAL_KSU_"
    r"(\d{2}-\d{2}-\d{4}_\d{2}-\d{2}-\d{2})\.zip"
)


def need(condition, message):
    if not condition:
        raise ValueError(message)


def sha256_file(path):
    with path.open("rb") as stream:
        digest = hashlib.sha256()
        for chunk in iter(lambda: stream.read(1048576), b""):
            digest.update(chunk)
        return digest.hexdigest()


def output_name(native, tag):
    need(VERSION.fullmatch(tag) is not None, "KernelSU tag must be stable semver")
    match = NATIVE.fullmatch(native)
    need(match is not None, "unexpected upstream recovery ZIP filename")
    return match[1] + "_r0s_KSUNext-" + tag + "_" + match[2] + ".zip"


def verify_native(native, source):
    with zipfile.ZipFile(native) as archive:
        names = [info.filename for info in archive.infolist() if not info.is_dir()]
        need(len(names) == 5 and set(names) == MEMBERS,
             "unexpected recovery ZIP contents; original five-file layout required")
        need(archive.testzip() is None, "recovery ZIP CRC failure")
        for item in UPDATER:
            need(archive.read(item) == (source / "build" / Path(item).name).read_bytes(),
                 "upstream recovery installer differs: " + item)
        for part in PARTS:
            filename = "files/" + part + ".img"
            expected = sha256_file(source / "build/out/r0s" / (part + ".img"))
            need(hashlib.sha256(archive.read(filename)).hexdigest() == expected,
                 "recovery ZIP image differs from compiled output: " + part)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=("self-test", "package"))
    parser.add_argument("--kernel-src", type=Path)
    parser.add_argument("--ksu-tag")
    parser.add_argument("--output-dir", type=Path)
    args = parser.parse_args()
    if args.mode == "self-test":
        sample = "ExtremeKRNL-Nexus-2200-v1_r0s_UNOFFICIAL_KSU_15-10-2026_09-01-02.zip"
        expected = "ExtremeKRNL-Nexus-2200-v1_r0s_KSUNext-v3.4.2_15-10-2026_09-01-02.zip"
        need(output_name(sample, "v3.4.2") == expected, "filename conversion drift")
        need(len(MEMBERS) == 5, "updater member contract changed")
        print("A15 original ExtremeKRNL ZIP packaging fixture PASS")
        return

    source = args.kernel_src
    tag = args.ksu_tag
    destination = args.output_dir
    need(source is not None and destination is not None and tag,
         "kernel source, release tag and output directory required")
    candidates = sorted((source / "build/out/r0s").glob("*_r0s_UNOFFICIAL_KSU_*.zip"))
    need(len(candidates) == 1, "expected one completed upstream KSU recovery ZIP")
    native = candidates[0]
    target = destination / output_name(native.name, tag)
    need(not target.exists(), "recovery ZIP destination exists")
    verify_native(native, source)
    destination.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(native, target)  # Do not repack or alter proven updater bytes.
    need(sha256_file(target) == sha256_file(native), "copied recovery ZIP differs")
    print("TACHYON A15 ORIGINAL EXTREMEKRNL RECOVERY ZIP HOST VERIFY PASS")
    print("ZIP: " + str(target))
    print("SHA256: " + sha256_file(target))
    print("BOARD QUALIFICATION: DEFERRED for newly selected KernelSU version")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, zipfile.BadZipFile) as exc:
        print("TACHYON A15 KERNEL ZIP BLOCKED: " + str(exc), file=sys.stderr)
        sys.exit(2)
