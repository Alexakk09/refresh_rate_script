# Automatic Refresh Rate Switcher

A small PowerShell utility for Windows laptops that automatically changes the display refresh rate when switching between **AC power and battery power**.

## What It Does

- When the charger is **plugged in**, it switches the display to the configured refresh rate.
- When the charger is **unplugged**, it switches the display to another configured refresh rate.
- This makes it easy to use a higher refresh rate while plugged in and a lower refresh rate on battery to reduce power consumption.

## Files

- `refresh-rate.ps1` — Handles the refresh-rate change.
- `setup.ps1` — Sets up the required configuration/tasks.
- `switch.ps1` — Handles switching between the configured refresh rates.

## Requirements

- Windows
- PowerShell
- A laptop/display supporting the configured refresh rates

## Usage

Run the setup script:

```powershell
.\setup.ps1
