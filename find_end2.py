with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

# Find end of function
end_line = None
for i, line in enumerate(lines[366:], start=366):
    if line.strip() == "}" and i > 410:
        end_line = i
        break

print(f"Function ends at line {end_line}")
for i, line in enumerate(lines[410:end_line+2], start=410):
    print(f"{i}: {line.rstrip()}")
