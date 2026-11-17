"""Build the requested short explanation and gallery from measured results."""
from __future__ import annotations

import csv
import shutil
import sys
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph
from reportlab.lib.utils import ImageReader

ROOT = Path(__file__).resolve().parents[1]
RESULTS = ROOT / "results" / "qam16"
OUT = ROOT / "teslim" / "16QAM_Summary_and_Figures.pdf"
LEGACY_OUT = ROOT / "teslim" / "16QAM_Ozet_ve_Gorseller.pdf"
PR = "https://github.com/halilyilmaz16/bfsk-qpsk-16qam-ber/pull/11"
W, H = landscape(A4)
M = 36
BLUE = colors.HexColor("#0072bd")
INK = colors.HexColor("#202020")
MUTED = colors.HexColor("#606060")
RULE = colors.HexColor("#d9d9d9")


def build() -> Path:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    pdfmetrics.registerFont(TTFont("Segoe", "C:/Windows/Fonts/segoeui.ttf"))
    pdfmetrics.registerFont(TTFont("SegoeBold", "C:/Windows/Fonts/segoeuib.ttf"))
    pdfmetrics.registerFontFamily("Segoe", normal="Segoe", bold="SegoeBold")
    c = canvas.Canvas(str(OUT), pagesize=(W, H), pageCompression=1)
    c.setTitle("16-QAM - Summary and figures")
    c.setAuthor("Emir Dündar")
    c.setCreator("16-QAM project material")
    style = ParagraphStyle("body", fontName="Segoe", fontSize=10.5,
                           leading=15, textColor=INK, alignment=TA_LEFT)
    caption_style = ParagraphStyle("caption", parent=style, fontSize=10, leading=14)

    def paragraph(text: str, x: float, y: float, width: float,
                  selected=style) -> float:
        p = Paragraph(text, selected)
        _, height = p.wrap(width, H)
        p.drawOn(c, x, y-height)
        return y-height

    def text(value: str, x: float, y: float, size=10.5, bold=False, color=INK):
        c.setFont("SegoeBold" if bold else "Segoe", size)
        c.setFillColor(color)
        c.drawString(x, y, value)

    def header(number: int, title: str, subtitle: str):
        c.bookmarkPage(f"page{number}")
        c.addOutlineEntry(title, f"page{number}", level=0)
        text("EE451  /  EMIR DÜNDAR", M, H-28, size=9, bold=True, color=BLUE)
        text(title, M, H-58, size=22, bold=True)
        text(subtitle, M, H-78, size=10, color=MUTED)
        c.setStrokeColor(RULE)
        c.line(M, H-90, W-M, H-90)
        text("16-QAM  |  17 November 2026", M, 19, size=8.5, color=MUTED)
        c.setFont("Segoe", 8.5)
        c.drawRightString(W-M, 19, f"{number} / 6")

    header(1, "16-QAM: Project Summary", "Four bits per symbol, encoded as one amplitude-phase constellation point.")
    left_x, col_w = M, 365
    right_x, right_w = M+col_w+34, W-2*M-col_w-34
    y = H-119
    blocks = [
        ("1  Map four bits to one point",
         "The first two bits select I; the last two select Q. Each axis uses -3, -1, +1, +3, giving 4 x 4 = 16 points. The Gray sequence along either axis is 00, 01, 11, 10."),
        ("2  Generate the real carrier waveform",
         "The I and Q values weight cosine and negative-sine carriers. Their sum has the selected amplitude and phase. Example: <b>1011</b> = <b>(3+j)/sqrt(10)</b>; amplitude 1, phase approximately 18.4 degrees."),
        ("3  Add noise and detect the bits",
         "The AWGN channel adds Gaussian noise. Two coherent correlators recover I and Q. The receiver selects the nearest level on each axis, then recovers four bits. The unscaled thresholds are -2, 0, +2."),
        ("4  Count errors and compare with theory",
         "BER = erroneous bits / transmitted bits. The interface compares 0, 6 and 12 dB, showing BER/SER, received constellation points, I/Q distributions, bit errors and the real waveform."),
    ]
    for title, body in blocks:
        text(title, left_x, y, size=11.5, bold=True)
        y = paragraph(body, left_x, y-12, col_w)-20

    y = H-119
    text("Run the single-file version", right_x, y, size=13, bold=True, color=BLUE)
    y = paragraph("Open <b>qam16_standalone.m</b> in MATLAB and click <b>Run</b>, or enter <b>qam16_standalone</b> in the Command Window. Then click the interface's <b>Run</b> button. No other project files or Communications Toolbox are required.", right_x, y-16, right_w)-22
    text("Measured results", right_x, y, size=13, bold=True, color=BLUE)
    y -= 20
    rows = list(csv.DictReader((RESULTS/"qam16_ber.csv").open(encoding="utf-8")))
    selected_rows = [r for r in rows if r["EbN0_dB"] in ("0", "6", "12")]
    widths = [48, 92, 98, right_w-238]
    headers = ["Eb/N0", "Bit errors", "Measured BER", "Theory"]
    x = right_x
    for label, width in zip(headers, widths):
        text(label, x, y, size=9, bold=True)
        x += width
    c.setStrokeColor(RULE)
    c.line(right_x, y-7, right_x+right_w, y-7)
    y -= 26
    for row in selected_rows:
        values = [row["EbN0_dB"]+" dB", f'{int(row["BitErrors"]):,}',
                  f'{float(row["BER_Passband"]):.7f}', f'{float(row["BER_Theory"]):.7f}']
        x = right_x
        for value, width in zip(values, widths):
            text(value, x, y, size=9.5)
            x += width
        y -= 24
    y = paragraph("The table uses <b>2,000,000 bits</b> at each point of the 0:2:14 dB sweep. Interface screenshots show the default <b>40,000-bit</b> demonstration.", right_x, y-4, right_w, caption_style)-19
    y = paragraph("<b>Limit:</b> Only 3 errors occurred at 14 dB, so that estimate has limited precision. Observing zero errors does not establish zero BER. These are ideally synchronized simulations, not ESP32 hardware measurements.", right_x, y, right_w, caption_style)-20
    c.setFillColor(BLUE)
    c.setFont("SegoeBold", 10)
    c.drawString(right_x, y, "GitHub: Emir Dündar's 16-QAM contribution - PR #11")
    c.linkURL(PR, (right_x, y-3, right_x+right_w, y+12), relative=0)
    c.showPage()

    pages = [
        (2, "Experiment Interface", "40,000 bits; three Eb/N0 levels; BER, received constellation and bit-error strip.",
         "qam16_gui.png", "Set the parameters on the left and click Run. Use Which experiment? to select 0, 6 or 12 dB. Red points represent incorrectly detected symbols."),
        (3, "BER: Theory and Simulation", "2,000,000 bits per noise level; an independent complex-baseband check is also shown.",
         "qam16_ber.png", "Increasing Eb/N0 reduces noise and lowers BER. At 12 dB, 279 bit errors were observed. The square at 14 dB marks limited precision because only 3 errors occurred."),
        (4, "Received 16-QAM Constellations", "Compare 0, 6 and 12 dB: the noise cloud becomes tighter as Eb/N0 increases.",
         "qam16_constellations.png", "Blue: correctly detected symbols. Red: symbol errors. Circles mark ideal points. As noise decreases, received samples cluster more tightly around the 16 centers."),
        (5, "Real Carrier Waveform", "Top: I/Q levels. Middle: transmitted signal. Bottom: noisy channel output.",
         "qam16_waveform.png", "I and Q may change at every symbol boundary, changing the analog waveform's amplitude and phase. The receiver correlates with cosine and negative sine to recover these levels."),
        (6, "I/Q and Waveform Tab", "Inspect the received level distributions together with the first four waveform symbols.",
         "qam16_gui_iq.png", "Dashed lines mark decision thresholds; orange markers show ideal unscaled levels. At higher Eb/N0, the histograms become concentrated around four distinct levels."),
    ]
    for number, title, subtitle, filename, caption in pages:
        header(number, title, subtitle)
        image = ImageReader(str(RESULTS/filename))
        iw, ih = image.getSize()
        box_x, box_y = M, 80
        box_w, box_h = W-2*M, H-184
        scale = min(box_w/iw, box_h/ih)
        dw, dh = iw*scale, ih*scale
        c.drawImage(image, box_x+(box_w-dw)/2, box_y+(box_h-dh)/2,
                    width=dw, height=dh, mask="auto")
        paragraph(caption, M, 61, W-2*M, caption_style)
        c.showPage()
    c.save()
    # Keep earlier file links useful while presenting the English filename.
    shutil.copyfile(OUT, LEGACY_OUT)
    return OUT


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    print(build())
