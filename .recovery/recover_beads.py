import json
import os
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
LOG = Path(os.path.expanduser('~/.gemini/antigravity-ide/brain/8b388e11-9fd8-4af6-9ba1-fff8fa1ea4ce/.system_generated/logs/transcript_full.jsonl'))
rows = [json.loads(line) for line in LOG.read_text(encoding='utf-8').splitlines()]
def norm(s):
    return s.replace('\r', '')
base = next(r for r in rows if r['step_index'] == 9)
lines = [m.group(2) for m in re.finditer(r'^(\d+): (.*)$', norm(base['content']), re.M)]
assert len(lines) == 574
text = '\n'.join(lines) + '\n'
audits = []
for row in rows:
    step = row['step_index']
    if step <= 9 or step >= 1350:
        continue
    content = norm(row.get('content', ''))
    if row['type'] == 'CODE_ACTION' and 'beads_screen.dart' in content.split('[diff_block_start]')[0] and '[diff_block_start]' in content:
        diff = content.split('[diff_block_start]', 1)[1].split('[diff_block_end]', 1)[0].strip('\n')
        current = text.splitlines()
        offset = 0
        chunks = re.split(r'(?m)^@@ ', diff)[1:]
        for chunk in chunks:
            header, body = chunk.split('\n', 1)
            m = re.match(r'-(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@', header)
            assert m, (step, header)
            old, new = [], []
            for line in body.splitlines():
                if line.startswith((' ', '-')): old.append(line[1:])
                if line.startswith((' ', '+')): new.append(line[1:])
            pos = int(m[1]) - 1 + offset
            if current[pos:pos+len(old)] != old:
                matches = [i for i in range(len(current)-len(old)+1) if current[i:i+len(old)] == old]
                assert len(matches) == 1, ('diff mismatch', step, pos, matches, current[pos:pos+3], old[:3])
                pos = matches[0]
            current[pos:pos+len(old)] = new
            offset += len(new) - len(old)
        text = '\n'.join(current) + '\n'
        audits.append(f'{step}: applied recorded diff')
    for tool in row.get('tool_calls', []):
        if tool['name'] != 'run_command': continue
        cmd = norm(tool['args'].get('CommandLine', ''))
        if 'beads_screen.dart' not in cmd or not any(x in cmd for x in ['Set-Content', 'Add-Content']): continue
        # Interpret only known string operations; never execute historical commands.
        if step == 388: continue  # This only wrote a separate temporary file.
        if step == 396:
            cur = text.splitlines(); text = '\n'.join(cur[:715] + cur[962:]) + '\n'
        else:
            strings = dict((m[1], m[3]) for m in re.finditer(r'\$(\w+) = @([\"\x27])\n(.*?)\n\2@', cmd, re.S))
            trim = re.search(r'\$lines\[0\.\.(\d+)\]', cmd)
            if trim: text = '\n'.join(text.splitlines()[:int(trim[1])+1]) + '\n\n'
            if '$oldBlock' in cmd:
                old = strings['oldBlock']; new = strings.get('newBlock', '')
                text = text.replace(old, new)
            for m in re.finditer(r'\$content\.Replace\("([^"\n]*)", "([^"\n]*)"\)', cmd):
                a,b = (v.replace('`r`n','\n').replace('`n','\n') for v in m.groups())
                text = text.replace(a,b)
            if '$widgets' in strings: raise AssertionError('unexpected variable')
            if 'widgets' in strings: text = text.removesuffix('\n') + strings['widgets'] + '\n'
            if 'appendContent' in strings:
                text += strings['appendContent']
                if 'Add-Content' in cmd: text += '\n'
        audits.append(f'{step}: replayed inspected string operation')
    if row['type'] == 'VIEW_FILE' and 'screens/beads_screen.dart' in content:
        seen = [(int(m[1]),m[2]) for m in re.finditer(r'^(\d+): (.*)$', content, re.M)]
        cur = text.splitlines()
        for n,s in seen:
            if n == len(cur) + 1 and s == '' and text.endswith('\n'): continue
            assert n <= len(cur) and cur[n-1] == s, ('view mismatch',step,n,cur[n-1] if n<=len(cur) else '<EOF>',s)
        audits.append(f'{step}: matched {len(seen)} historical source lines')
    ROOT.joinpath('candidate.dart.txt').write_bytes(text.replace('\n','\r\n').encode('utf-8'))
    ROOT.joinpath('recovery-audit.txt').write_text('\n'.join(audits),encoding='utf-8')
print('Recovered', len(text.splitlines()), 'lines;', len(text.encode('utf-8')), 'UTF-8 bytes with LF')
