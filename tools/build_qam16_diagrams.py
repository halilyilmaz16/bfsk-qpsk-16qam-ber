"""Regenerate eight English 16-QAM and shared constellation diagrams.

Usage:
    python tools/build_qam16_diagrams.py --source-zip PATH/TO/bfsk-qpsk-16qam-ber-main.zip

The upstream SVG files are the geometry and palette templates. Their hashes
pin the supplied source version; only exact text-node translations are applied.
Edit this mapping and regenerate rather than editing the generated SVG files.
No archive members are extracted. Only the eight listed SVG files under
docs/qam16 and docs/genel are written.
"""

from __future__ import annotations

import argparse
import hashlib
import html
from pathlib import Path
import re
import xml.etree.ElementTree as ET
from zipfile import ZipFile


ROOT = Path(__file__).resolve().parents[1]
ARCHIVE_PREFIX = "bfsk-qpsk-16qam-ber-main/docs/"
TEMPLATE_SHA256 = {
    "qam16/qam16_alici.svg": "a691a028b565cf83531867c39d6cfd2817c7229be33d9dabdfe5b3ccc748d4ad",
    "qam16/qam16_alici_dark.svg": "0249fc790fcf73b47dbe1ab3fc858b0c0e72db5955447b07b48001f6b992b84a",
    "qam16/qam16_sistem.svg": "b22148e6ef3679797eb8dd6d97f820dd45d353a4da5672eec8bcc48d991830b5",
    "qam16/qam16_sistem_dark.svg": "ed1a02bf1b38050e58b93c90b0386230d0143c4c2ee7bbbb8b4a04d9ba8d95bd",
    "qam16/qam16_verici.svg": "438ac18b07c9ffe7446bf4c76a81147690ad4db170eaddac776dc2ddcd768c6f",
    "qam16/qam16_verici_dark.svg": "5eeabfee95dfa33027cf209e157e7bb9f934a74be6ef0e5e88adc04bea4f252d",
    "genel/constellations_gray.svg": "86ca87f21fe6dbbb32b8a6823ed22ef1c5b33a12289828be87eb977b76afbc6d",
    "genel/constellations_gray_dark.svg": "90fc6aeeb222db419cbd321fc6f0286eba8b80c25786dea99c933225826ee518",
}
TRANSLATIONS = {
    "16-QAM uçtan uca sistem: verici, AWGN kanal, korelasyon alıcısı":
        "16-QAM end-to-end system: transmitter, AWGN channel, correlation receiver",
    "16-QAM vericisi": "16-QAM transmitter",
    "16-QAM alıcısı": "16-QAM receiver",
    "1  Verici": "1  Transmitter",
    "2  Kanal (AWGN)": "2  Channel (AWGN)",
    "3  Alıcı (korelatör)": "3  Receiver (correlator)",
    "bitler": "bits",
    "b₁b₂ → I seviyesi": "b₁b₂ → I level",
    "b₃b₄ → Q seviyesi": "b₃b₄ → Q level",
    "→ kanal": "→ channel",
    "4-PAM dilim": "4-PAM slicer",
    "4-PAM dilim → b₁b₂": "4-PAM slicer → b₁b₂",
    "4-PAM dilim → b₃b₄": "4-PAM slicer → b₃b₄",
    "x = √10·zI; eşik −2, 0, +2": "x = √10·zI; cuts −2, 0, +2",
    "x = √10·zQ; eşik −2, 0, +2": "x = √10·zQ; cuts −2, 0, +2",
    "bits ile karşılaştır": "compare bits",
    "kodda: real(r)": "code: real(r)",
    "kodda: imag(r)": "code: imag(r)",
    "Verici:  k = 4 bit/sembol, Ts = 4Tb.  G (Gray 4-PAM): 00 → −3, 01 → −1, 11 → +1, 10 → +3":
        "Transmitter: k = 4 bits/symbol, Ts = 4Tb.  G (Gray 4-PAM): 00 → −3, 01 → −1, 11 → +1, 10 → +3",
    "Alıcı:  zI = aI + nI, zQ = aQ + nQ  (korelatörler QPSK ile aynı)":
        "Receiver: zI = aI + nI, zQ = aQ + nQ  (same correlators as QPSK)",
    "Karar:  her eksende en yakın seviye.  1. bit = (x > 0),  2. bit = (|x| < 2)":
        "Decision: nearest level on each axis.  1st bit = (x > 0),  2nd bit = (|x| < 2)",
    "Es = 1 (÷√10, ham ortalama enerji 5 + 5 = 10),  Eb = Es/4":
        "Es = 1 (÷√10, raw mean energy 5 + 5 = 10),  Eb = Es/4",
    "Teori: Pb = ¼·[3Q(u) + 2Q(3u) − Q(5u)],  u = √(4Eb/5N0)      kodda: qam16_adim_adim.m":
        "Theory: Pb = ¼·[3Q(u) + 2Q(3u) − Q(5u)],  u = √(4Eb/5N0)      code: qam16_adim_adim.m",
    "Ham ortalama enerji 5 + 5 = 10 → ÷√10 → Es = 1, Eb = Es/4":
        "Raw mean energy 5 + 5 = 10 → ÷√10 → Es = 1, Eb = Es/4",
    "Örnek: 1011 → (3 + j)/√10.   Kodda (temel bant): s = aI + j·aQ  (qam16_mod)":
        "Example: 1011 → (3 + j)/√10.  Baseband code: s = aI + j·aQ  (qam16_mod)",
    "Eşikler −2, 0, +2:   1. bit = (x > 0),   2. bit = (|x| < 2)   kodda: pam4_slice":
        "Cuts −2, 0, +2:  1st bit = (x > 0),  2nd bit = (|x| < 2)  code: pam4_slice",
    "Her eksende en yakın seviye = ML karar (AWGN, eşit olasılıklı semboller)":
        "Nearest level on each axis = ML decision (AWGN, equiprobable symbols)",
    "QPSK ve 16-QAM Gray kodlu yıldız diyagramları":
        "QPSK and 16-QAM Gray-coded constellations",
    "QPSK dört nokta, 16-QAM on altı nokta; Gray etiketleri, örnek dizi 1011 0011 için semboller turuncu.":
        "QPSK has four points and 16-QAM has sixteen, with Gray labels. Orange symbols show the example sequence 1011 0011.",
    "b1 → I işareti, b2 → Q işareti": "b1 → I sign, b2 → Q sign",
    "satır: b3b4": "row: b3b4",
    "sütun: b1b2 (I = −3, −1, +1, +3)": "column: b1b2 (I = −3, −1, +1, +3)",
    "örnek dizideki semboller (10 11 00 11 / 1011 0011)":
        "Example symbols (10 11 00 11 / 1011 0011)",
}
TEXT_NODE = re.compile(r"(<(?:title|desc|text|tspan)\b[^>]*>)([^<]*)(</(?:title|desc|text|tspan)>)")


def translate_svg(template: bytes) -> tuple[str, set[str]]:
    """Keep all SVG markup unchanged, including coordinates and colors."""
    used = set()

    def replace(match: re.Match[str]) -> str:
        original = html.unescape(match[2])
        if original not in TRANSLATIONS:
            return match[0]
        used.add(original)
        translated = html.escape(TRANSLATIONS[original], quote=False)
        return f"{match[1]}{translated}{match[3]}"

    translated = TEXT_NODE.sub(replace, template.decode("utf-8"))
    ET.fromstring(translated)
    return translated, used


def approximate_width(text: str, font_size: float) -> float:
    """Estimate Helvetica text width without requiring a rendering package."""
    narrow = "ilI1|.,:;'![]()₀₁₂₃₄"
    wide = "mwMW@"
    total = 0.0
    for char in text:
        if char.isspace():
            total += 0.28
        elif char in narrow:
            total += 0.28
        elif char in wide:
            total += 0.83
        elif char.isupper():
            total += 0.67
        else:
            total += 0.56
    return total * font_size


def width_warnings(svg: str) -> list[str]:
    """Flag estimated horizontal overflow in a box or at the canvas edge.

    This is a quick check, not a substitute for visual inspection in a renderer.
    """
    document = ET.fromstring(svg)
    canvas_width = float(document.get("width"))
    boxes = []
    for node in document.iter():
        if node.tag.rsplit("}", 1)[-1] != "rect" or node.get("fill") == "none":
            continue
        x, y = float(node.get("x", 0)), float(node.get("y", 0))
        w, h = float(node.get("width")), float(node.get("height"))
        if w < canvas_width:
            boxes.append((x, y, w, h))
    warnings = []
    for node in document.iter():
        if node.tag.rsplit("}", 1)[-1] != "text":
            continue
        text = "".join(node.itertext())
        x, y = float(node.get("x", 0)), float(node.get("y", 0))
        width = approximate_width(text, float(node.get("font-size", 12)))
        anchor = node.get("text-anchor", "start")
        left = x - (width / 2 if anchor == "middle" else width if anchor == "end" else 0)
        right = left + width
        containing = [box for box in boxes
                      if box[0] <= x <= box[0] + box[2] and box[1] <= y <= box[1] + box[3]]
        if containing:
            box = min(containing, key=lambda item: item[2] * item[3])
            limit_left, limit_right = box[0] + 4, box[0] + box[2] - 4
        else:
            limit_left, limit_right = 4, canvas_width - 4
        if left < limit_left or right > limit_right:
            warnings.append(f"y={y:g}: {text!r} (estimated {width:.1f}px)")
    return warnings


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-zip", type=Path, required=True, help="Original upstream source archive")
    args = parser.parse_args()
    outputs = {}
    used = set()
    with ZipFile(args.source_zip) as archive:
        for name, expected_hash in TEMPLATE_SHA256.items():
            template = archive.read(ARCHIVE_PREFIX + name)
            if hashlib.sha256(template).hexdigest() != expected_hash:
                raise ValueError(f"Unexpected upstream SVG template: {name}")
            svg, translated_labels = translate_svg(template)
            outputs[name] = svg
            used.update(translated_labels)
    if used != set(TRANSLATIONS):
        raise ValueError(f"Translation labels missing from templates: {sorted(set(TRANSLATIONS) - used)}")
    output_directory = ROOT / "docs"
    for name, svg in outputs.items():
        (output_directory / name).write_bytes(svg.encode("utf-8"))
        warnings = width_warnings(svg)
        print(f"Generated {name}: {len(warnings)} estimated width warning(s)")
        for warning in warnings:
            print(f"  {warning}")


if __name__ == "__main__":
    main()
