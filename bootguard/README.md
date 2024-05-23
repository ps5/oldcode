# Bootguard 2.0

Detects modified MBR bootloader and restores original copy.
Effectively protects against old bootloader viruses.

This was written in 1993-1994 for protecting IBM PCs running MSDOS against boot sector viruses.
Infected boot sector would be overwritten with a clean bootloader automatically upon a reboot.
