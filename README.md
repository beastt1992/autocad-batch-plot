# BPDF — AutoCAD Batch Plot Tool

**Batch export all title block frames to individual PDFs with one command.**

Built by an architect, for architects. No more plotting one sheet at a time.

---

## Demo

```
Command: BPDF
Block Name <A$C44896E9B>:        ← Enter to reuse last setting
PDF Prefix <Project-Name>:
Output Folder <C:\Desktop>:
Plot Style: monochrome-2.ctb
Paper Size: ISO_A3_(420.00_x_297.00_MM)
Scale: 1:100

Found 26 frames → Plotting...
  [1/26] Done
  [2/26] Done
  ...
  [26/26] Done ✓
```

26 sheets exported in under 1 minute.

---

## Features

- ✅ Auto-detects all title block frames by Block name
- ✅ Sorts output top-to-bottom, left-to-right
- ✅ Dynamically loads plot styles and paper sizes from your machine
- ✅ Remembers last settings — just press Enter to reuse
- ✅ Confirmation screen before plotting
- ✅ Compatible with AutoCAD 2014 and above

---

## Installation

1. Download `batch-pdf.lsp`
2. In AutoCAD, type `APPLOAD`
3. Click **Startup Suite → Contents → Add**
4. Select `batch-pdf.lsp` → OK

The command `BPDF` will be available every time AutoCAD starts.

---

## Usage

**Step 1 — Find your title block name**

Click on a title block frame → type `LIST` → look for `Block name:`

**Step 2 — Run the command**

```
BPDF
```

**Step 3 — Answer the prompts**

| Prompt | Example |
|--------|---------|
| Block Name | `A$C44896E9B` |
| PDF Prefix | `Project-Name` |
| Output Folder | `C:\Users\User\Desktop\Output` (Enter = Desktop) |
| Plot Style | Select number from list |
| Paper Size | Select number from list |
| Scale | `100` for 1:100, Enter = Fit to paper |

---

## Requirements

- AutoCAD 2014 or above
- Windows 10 / 11
- `DWG To PDF.pc3` plotter (included with AutoCAD by default)

---

## About

Made by an architect in Taiwan who got tired of plotting sheets one by one.

If this saved you time, consider buying me a coffee ☕

[![GitHub Sponsors](https://img.shields.io/badge/Sponsor-GitHub-pink?logo=github)](https://github.com/sponsors/beastt1992)

---

## License

MIT — free to use, modify, and share.
