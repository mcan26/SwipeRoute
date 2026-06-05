import os
import re

def main():
    with open('lib/main.dart', 'r') as f:
        lines = f.readlines()

    header_end = 0
    for i, line in enumerate(lines):
        if line.startswith('// -----------------------------------------------------------------------------'):
            header_end = i
            break

    headers = lines[:header_end]
    # Add exports or adjustments to headers if needed

    sections = {}
    current_section = None
    current_lines = []
    
    for line in lines[header_end:]:
        match = re.match(r'// (.*) SCREEN$', line.strip())
        if match:
            if current_section:
                sections[current_section] = current_lines
            current_section = match.group(1).strip().replace(' ', '_').lower()
            current_lines = [line]
        elif line.strip() == '// SETTINGS BOTTOM SHEET':
            if current_section:
                sections[current_section] = current_lines
            current_section = 'settings_bottom_sheet'
            current_lines = [line]
        else:
            if current_section:
                current_lines.append(line)

    if current_section:
        sections[current_section] = current_lines

    if not os.path.exists('lib/screens'):
        os.makedirs('lib/screens')

    imports_to_add = "".join([line for line in headers if line.startswith('import ')])
    imports_to_add += "\nimport '../main.dart'; // For globals like isSupabaseInitialized\n"
    imports_to_add += "import '../config/supabase_config.dart';\n"
    imports_to_add += "import '../models/local_places.dart';\n\n"

    for sec, sec_lines in sections.items():
        if sec in ['main_scaffold', 'swiper']:
            # Maybe keep these in swiper_screen or leave them?
            pass
        
        filename = f"lib/screens/{sec}_screen.dart" if not sec.endswith('sheet') and not sec.endswith('screen') else f"lib/screens/{sec}.dart"
        if sec == 'settings_bottom_sheet':
             filename = "lib/screens/settings_bottom_sheet.dart"
        
        with open(filename, 'w') as f:
            f.write(imports_to_add)
            f.writelines(sec_lines)
            
    print(f"Extracted: {list(sections.keys())}")

if __name__ == '__main__':
    main()
