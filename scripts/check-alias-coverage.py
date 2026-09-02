"""核对：旧 /blog/ slug 是否全部被 aliases 覆盖"""
import re
import subprocess
from pathlib import Path

REPO = Path(r'D:\Creative_Studio\WorkSpace\Project\yeekox-blog')

def git(*a):
    return subprocess.run(['git', '-C', str(REPO), *a], capture_output=True, text=True).stdout

old_files = git('ls-tree', '-r', '--name-only', 'cfc29f6', 'content/blog/').splitlines()

# 旧 slug → 语言集合
old_map = {}
for rel in old_files:
    p = rel[len('content/blog/'):]
    m = re.match(r'(.+)/index\.(zh-cn|en|ja)\.md$', p) or re.match(r'(.+)\.(zh-cn|en|ja)\.md$', p)
    if not m:
        continue
    slug, lang = m.group(1), m.group(2)
    if slug.endswith('_index'):
        continue
    old_map.setdefault(slug, set()).add(lang)

# 6s081 系列已手写 aliases（旧 note_class → 新 6s081），单独处理
REORG = {  # 旧 note_class slug → 新 6s081 slug
    'note_class/mit6.s081_0': '6s081/01-xv6-source',
}

print(f'旧文章 slug 总数: {len(old_map)}')
covered, missing = [], []
for slug, langs in sorted(old_map.items()):
    # 直接同名目录？
    new_dir = REPO / 'content' / 'posts' / slug
    if new_dir.exists():
        # 检查每个语言文件是否有 /blog/<slug>/ alias
        ok = True
        for lang in langs:
            fp = new_dir / f'index.{lang}.md'
            if not fp.exists():
                continue
            text = fp.read_text(encoding='utf-8')[:600]
            if f'/blog/{slug}/' not in text:
                ok = False
                missing.append(f'{fp.name}: 缺 /blog/{slug}/')
        if ok:
            covered.append(slug)
        continue
    # 已重组到 6s081 的？
    low = slug.lower()
    if low in REORG:
        covered.append(f'{slug} (→{REORG[low]})')
        continue
    # 大小写不同的目录？
    cand = [d.name for d in (REPO / 'content' / 'posts').iterdir() if d.is_dir() and d.name.lower() == low.split('/')[-1]]
    if cand:
        covered.append(f'{slug} ({cand[0]} 大小写)')
        continue
    missing.append(f'{slug}: 无对应新目录')

print(f'已覆盖: {len(covered)}')
print(f'缺失: {len(missing)}')
for m in missing:
    print('  MISS', m)
