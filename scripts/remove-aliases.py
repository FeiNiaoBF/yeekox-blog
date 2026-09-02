"""批量删除文章 frontmatter 中的 aliases 块（用户决策：旧链接不再需要）"""
import re
from pathlib import Path

REPO = Path(r'D:\Creative_Studio\WorkSpace\Project\yeekox-blog')
count = 0

for fp in (REPO / 'content' / 'posts').rglob('*.md'):
    text = fp.read_text(encoding='utf-8')
    if 'aliases:' not in text[:800]:
        continue
    # 删除 aliases: 块（aliases: 开头，连续的 "  - " 行）
    new_text = re.sub(r'aliases:\n(?:  - .+\n)+', '', text, count=1)
    if new_text != text:
        fp.write_text(new_text, encoding='utf-8')
        count += 1

print(f'清理 aliases 的文件数: {count}')
# 验证：全站不应再有 aliases
left = [str(f.relative_to(REPO)) for f in (REPO / 'content').rglob('*.md') if 'aliases:' in f.read_text(encoding='utf-8')[:800]]
print(f'残留: {len(left)}')
for f in left[:5]:
    print(' ', f)
