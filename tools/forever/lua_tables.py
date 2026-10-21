"""Minimal reader for the Lua table literals in RecipeRadar's Database files.

Supports exactly what those generated files use: nested tables with ["key"] = value entries,
array entries, strings, numbers, booleans, nil and -- comments.
"""
import re

_NUMBER = re.compile(r"-?\d+(\.\d+)?([eE][+-]?\d+)?")
_IDENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
_ESCAPES = {"n": "\n", "t": "\t", "r": "\r", "\\": "\\", '"': '"', "'": "'"}


class LuaTableReader:
    def __init__(self, text, pos=0):
        self.s = text
        self.i = pos

    def _skip(self):
        s, n = self.s, len(self.s)
        while self.i < n:
            if s[self.i] in " \t\r\n":
                self.i += 1
            elif s.startswith("--", self.i):
                end = s.find("\n", self.i)
                self.i = n if end < 0 else end + 1
            else:
                break

    def _expect(self, ch):
        self._skip()
        if self.s[self.i] != ch:
            raise ValueError(f"expected {ch!r} at {self.i}, found {self.s[self.i:self.i + 20]!r}")
        self.i += 1

    def _string(self):
        quote = self.s[self.i]
        self.i += 1
        out = []
        while self.s[self.i] != quote:
            ch = self.s[self.i]
            if ch == "\\":
                self.i += 1
                nxt = self.s[self.i]
                if nxt.isdigit():
                    digits = re.match(r"\d{1,3}", self.s[self.i:]).group(0)
                    out.append(chr(int(digits)))
                    self.i += len(digits) - 1
                else:
                    out.append(_ESCAPES.get(nxt, nxt))
            else:
                out.append(ch)
            self.i += 1
        self.i += 1
        return "".join(out)

    def value(self):
        self._skip()
        c = self.s[self.i]
        if c == "{":
            return self._table()
        if c in "\"'":
            return self._string()
        for word, val in (("true", True), ("false", False), ("nil", None)):
            if self.s.startswith(word, self.i):
                self.i += len(word)
                return val
        m = _NUMBER.match(self.s, self.i)
        if not m:
            raise ValueError(f"unexpected value at {self.i}: {self.s[self.i:self.i + 20]!r}")
        self.i = m.end()
        text = m.group(0)
        return float(text) if ("." in text or "e" in text.lower()) else int(text)

    def _table(self):
        self.i += 1
        mapping, array = {}, []
        while True:
            self._skip()
            c = self.s[self.i]
            if c == "}":
                self.i += 1
                break
            if c == "[":
                self.i += 1
                key = self.value()
                self._expect("]")
                self._expect("=")
                mapping[key] = self.value()
            else:
                ident = _IDENT.match(self.s, self.i)
                after = ident and self.s[ident.end():].lstrip()[:1] == "=" and not self.s[ident.end():].lstrip()[:2] == "=="
                if ident and after and ident.group(0) not in ("true", "false", "nil"):
                    self.i = ident.end()
                    self._expect("=")
                    mapping[ident.group(0)] = self.value()
                else:
                    array.append(self.value())
            self._skip()
            if self.s[self.i] in ",;":
                self.i += 1
        if mapping and array:
            raise ValueError("mixed table not supported")
        return mapping if mapping else array


def read_assignment(text, pattern):
    """Yields (regex match, parsed value) for every `<pattern> = { ... }` in text."""
    for m in re.finditer(pattern + r"\s*=\s*(?=\{)", text):
        yield m, LuaTableReader(text, m.end()).value()
