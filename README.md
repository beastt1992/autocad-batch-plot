# BPDF — AutoCAD Batch Plot Tool

**Batch export all title block frames to individual PDFs with one command.**

Built by an architect, for architects. No more plotting one sheet at a time.

---

## What it does

- Click on a title block frame → automatically detects the Block name
- Option to plot just that 1 frame, or all frames with the same name
- Sorts output top-to-bottom, left-to-right
- Lets you choose plot style, paper size, and scale
- Remembers your last settings — just press Enter to reuse
- Confirmation screen before plotting
- Compatible with AutoCAD 2014 and above (auto-detects version differences)

---

## Demo

```
Command: BPDF

Click on a title block frame (or press Enter to type block name):
→ [click on frame]

Block detected: A$C44896E9B
Plot [1=This frame only / A=All frames with this name] <A>: A

PDF Prefix <frame>:
Output Folder <C:\Desktop>:
Plot Style: (select from list)
Paper Size: (select from list)
Scale: 100  ← 1:100

Found 26 frames → Plotting...
  [1/26] Done
  [2/26] Done
  ...
  [26/26] Done ✓
```

26 sheets exported in under 1 minute.

---

## Installation

1. Download `batch-pdf.lsp`
2. In AutoCAD, type `APPLOAD`
3. Click **Startup Suite → Contents → Add**
4. Select `batch-pdf.lsp` → OK

The command `BPDF` will be available every time AutoCAD starts.

---

## Usage

**Step 1 — Run the command**
```
BPDF
```

**Step 2 — Select your title block**

Click directly on a title block frame in Model Space.
The tool will automatically read the Block name.

Or press Enter to type the Block name manually.
(Tip: click a frame → type `LIST` to find the Block name)

**Step 3 — Choose scope**

```
Plot [1=This frame only / A=All frames with this name] <A>:
```

**Step 4 — Answer the prompts**

| Prompt | Example |
|--------|---------|
| PDF Prefix | `Project-2024` |
| Output Folder | Enter = Desktop |
| Plot Style | Select number from list |
| Paper Size | Select number from list |
| Scale | `100` for 1:100, Enter = Fit |

**Step 5 — Confirm and plot**

Review the summary → OK → `Y` → done!

---

## Requirements

- AutoCAD 2014 or above
- Windows 10 / 11
- `DWG To PDF.pc3` plotter (included with AutoCAD by default)

---

## Changelog

**v1.2** - Click to select title block, option to plot 1 frame or all frames
**v1.1** - Auto-detect AC_WINDOW value, fixed RefreshPlotDeviceInfo order
**v1.0** - Initial release

---

## Why BPDF?

AutoCAD's built-in Batch Plot works at the Layout level.
BPDF works in **Model Space** — common workflow in Taiwan and Asia where all drawings are arranged in one Model Space with individual title block frames.

Similar tools exist in Chinese-language communities (e.g. 秋楓 BatchPlot) but are closed-source and Chinese only. BPDF is open source and works globally.

---

## About

Made by an architect in Taiwan who got tired of plotting sheets one by one.

If this saved you time, consider buying me a coffee ☕

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/beastt1992)
---

## License

MIT — free to use, modify, and share.
