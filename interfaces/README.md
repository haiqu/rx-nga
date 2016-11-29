# Interface Layers for RETRO 12

Retro has two basic parts: an image file providing the basic language and an interface layer providing a user interface and platform specific I/O functionality. The subdirectories here contain implementations of interface layers for some common systems.

See the individual subdirectories for notes on building them.

## POSIX (Linux / macOS)

The posix/ directory contains:

- interactive listener
- block editor

These require an OS with termios and ioctl's for terminal control. I've tested it on:

- Linux (ARM, x86, x86-64)
- macOS

The block editor is still considered experimental and shouldn't be relied on for long term use at this point.

## WINDOWS

The win32/ directory contains:

- interactive listener

This is tested on Windows 7, built under mingw-gcc.

## iOS

This is a snapshot of an older version of the code used in iOS app. It provides an editor centric environment.
