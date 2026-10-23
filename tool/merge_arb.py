#!/usr/bin/env python3
"""Junta as traduções por área (lib/l10n/parts/<area>_pt.arb e <area>_en.arb) em
lib/l10n/app_pt.arb e lib/l10n/app_en.arb e regenera o código (flutter gen-l10n).

Cada área escreve só nos seus ficheiros, por isso não há conflitos entre áreas.
As chaves têm de ser únicas em todas as áreas, e português e inglês têm de ter as mesmas chaves.

Uso: python3 tool/merge_arb.py          (junta e gera)
     python3 tool/merge_arb.py --no-gen (só junta)
"""
import collections
import glob
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PARTS = os.path.join(ROOT, 'lib', 'l10n', 'parts')
OUT = os.path.join(ROOT, 'lib', 'l10n')


def load(lang):
    merged = collections.OrderedDict()
    merged['@@locale'] = lang
    owner = {}
    for path in sorted(glob.glob(os.path.join(PARTS, f'*_{lang}.arb'))):
        with open(path, encoding='utf-8') as f:
            data = json.load(f, object_pairs_hook=collections.OrderedDict)
        for key, value in data.items():
            if key == '@@locale':
                continue
            if key in merged:
                sys.exit(f'Chave repetida "{key}": {owner[key]} e {os.path.basename(path)}')
            merged[key] = value
            owner[key] = os.path.basename(path)
    return merged


def main():
    pt, en = load('pt'), load('en')
    texts = lambda d: {k for k in d if not k.startswith('@')}
    only_pt, only_en = texts(pt) - texts(en), texts(en) - texts(pt)
    if only_pt or only_en:
        sys.exit(f'Faltam traduções. Só em português: {sorted(only_pt)}; só em inglês: {sorted(only_en)}')
    for lang, data in (('pt', pt), ('en', en)):
        with open(os.path.join(OUT, f'app_{lang}.arb'), 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write('\n')
    print(f'{len(texts(pt))} textos juntos.')
    if '--no-gen' not in sys.argv:
        subprocess.run(['flutter', 'gen-l10n'], cwd=ROOT, check=True)


if __name__ == '__main__':
    main()
