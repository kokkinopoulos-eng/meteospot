with open("C:/meteospot/lib/screens/chat_screen.dart", "r", encoding="utf-8") as f:
    content = f.read()

# Find beach related content
import re
matches = [(m.start(), content[max(0,m.start()-20):m.start()+50]) for m in re.finditer(r'beach|Beach|παραλ', content)]
for pos, ctx in matches[:10]:
    line_num = content[:pos].count('\n')
    print(f"Line {line_num}: {ctx.strip()}")
