#!/usr/bin/env python3
"""Acrescenta o ramo =0 a todos os plurais ICU dos ficheiros em lib/l10n/parts.

Em português o 0 conta como singular (a regra "one" cobre 0 e 1), por isso `=1{1 conta} other{...}`
mostraria "1 conta" para zero. O ramo =0 copia o ramo "other" (que usa {count}, e dá "0 contas").
Idempotente: corre quantas vezes quiseres.
"""
import collections
import glob
import json
import re

PLURAL = re.compile(r'\{(\w+), plural,')


def match_close(s, start):
    depth = 0
    for i in range(start, len(s)):
        if s[i] == '{':
            depth += 1
        elif s[i] == '}':
            depth -= 1
            if depth == 0:
                return i
    raise ValueError('chaveta por fechar: ' + s)


def branches(body):
    """Ramos de um plural: lista de (seletor, conteúdo, início, fim)."""
    out, i = [], 0
    while i < len(body):
        m = re.compile(r'\s*(=\d+|zero|one|two|few|many|other)\{').match(body, i)
        if not m:
            break
        open_idx = m.end() - 1
        close = match_close(body, open_idx)
        out.append((m.group(1), body[open_idx + 1:close]))
        i = close + 1
    return out


def fix(s):
    changed = True
    while changed:
        changed = False
        for m in PLURAL.finditer(s):
            start = m.start()
            end = match_close(s, start)
            inner_start = m.end()
            inner = s[inner_start:end]
            bs = branches(inner)
            if bs and not any(b[0] in ('=0', 'zero') for b in bs):
                other = next((c for sel, c in bs if sel == 'other'), None)
                if other is None:
                    continue
                s = s[:inner_start] + ' =0{' + other + '}' + s[inner_start:]
                changed = True
                break
    return s


total = 0
for path in sorted(glob.glob('lib/l10n/parts/*.arb')):
    with open(path, encoding='utf-8') as f:
        data = json.load(f, object_pairs_hook=collections.OrderedDict)
    n = 0
    for k, v in list(data.items()):
        if k.startswith('@') or not isinstance(v, str):
            continue
        new = fix(v)
        if new != v:
            data[k] = new
            n += 1
    if n:
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write('\n')
        print(f'{path}: {n}')
        total += n
print('plurais corrigidos:', total)
