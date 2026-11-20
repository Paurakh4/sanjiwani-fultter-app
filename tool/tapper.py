#!/usr/bin/env python3
"""Tap UI elements on the connected Android device by matching text/desc/content-id.

Avoids hand-computed coordinates: dumps the uiautomator hierarchy, finds the node,
taps its centre. Usage:
  tapper.py text "Demo login"
  tapper.py desc "Sign in"
  tapper.py id LoginScreen
  tapper.py xy 540 2264
  tapper.py shot /tmp/shot.png
  tapper.py dump            # print visible texts + bounds
"""
import re
import subprocess
import sys
import xml.etree.ElementTree as ET


def adb(*args: str) -> str:
    return subprocess.run(
        ("adb", *args), check=True, capture_output=True, text=True
    ).stdout


def nodes():
    adb("shell", "uiautomator", "dump", "/sdcard/u.xml")
    raw = adb("exec-out", "cat", "/sdcard/u.xml")
    start = raw.find("<?xml")
    raw = raw[start:] if start >= 0 else raw
    root = ET.fromstring(raw[: raw.rfind(">") + 1])
    out = []
    for el in root.iter():
        if el.tag != "node":
            continue
        out.append(
            {
                "text": el.get("text", ""),
                "desc": el.get("content-desc", ""),
                "id": el.get("resource-id", ""),
                "cls": el.get("class", ""),
                "bounds": el.get("bounds", ""),
            }
        )
    return out


def centre(bounds: str):
    nums = [int(v) for pair in re.findall(r"\[(-?\d+),(-?\d+)\]", bounds) for v in pair]
    if len(nums) != 4:
        raise SystemExit(f"unparsed bounds {bounds!r}")
    x1, y1, x2, y2 = nums
    return (x1 + x2) // 2, (y1 + y2) // 2


def tap(x: int, y: int) -> None:
    adb("shell", "input", "tap", str(x), str(y))
    print(f"tap {x},{y}")


def main() -> None:
    mode = sys.argv[1] if len(sys.argv) > 1 else "dump"
    if mode == "shot":
        path = sys.argv[2] if len(sys.argv) > 2 else "/tmp/shot.png"
        with open(path, "wb") as fh:
            fh.write(
                subprocess.run(
                    ("adb", "exec-out", "screencap", "-p"),
                    check=True,
                    capture_output=True,
                ).stdout
            )
        print(path)
        return
    if mode == "xy":
        tap(int(sys.argv[2]), int(sys.argv[3]))
        return
    if mode == "dump":
        for n in nodes():
            if n["text"] or n["desc"]:
                print(f"{n['cls'].split('.')[-1]:14} {n['bounds']:26} "
                      f"text={n['text']!r} desc={n['desc']!r}")
        return
    key = {"text": "text", "desc": "desc", "id": "id"}[mode]
    want = sys.argv[2].lower()
    for n in nodes():
        if want in n[key].lower():
            tap(*centre(n["bounds"]))
            return
    sys.exit(f"no node with {key}~{sys.argv[2]!r}")


if __name__ == "__main__":
    main()
