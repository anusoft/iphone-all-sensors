import re

new_key = {
    "label.radioTechnology": {"en": "Radio Technology", "th": "เทคโนโลยีวิทยุ", "zh": "无线技术", "ja": "無線技術", "ko": "무선 기술", "es": "Tecnología de Radio", "fr": "Technologie Radio", "de": "Funktechnologie", "pt": "Tecnologia de Rádio", "ar": "تقنية الراديو", "it": "Tecnologia Radio", "ru": "Радиотехнология"},
}

filepath = '/Users/mac/Projects/poc/iphone-all-sensors/iPhoneSensors/iPhoneSensors/Services/LocalizationManager.swift'
with open(filepath, 'r') as f:
    content = f.read()

lang_map = {
    'english': 'en', 'thai': 'th', 'chinese': 'zh', 'japanese': 'ja', 'korean': 'ko',
    'spanish': 'es', 'french': 'fr', 'german': 'de', 'portuguese': 'pt',
    'arabic': 'ar', 'italian': 'it', 'russian': 'ru',
}

for lang_name, lang_code in lang_map.items():
    pattern = rf'(static let {lang_name}: \[String: String\] = \[)(.*?)(\n    \])'
    match = re.search(pattern, content, re.DOTALL)
    if match:
        prefix = match.group(1)
        existing = match.group(2)
        suffix = match.group(3)
        new_entries = []
        for key, translations in new_key.items():
            if f'"{key}"' in existing:
                continue
            value = translations[lang_code]
            new_entries.append(f'\n        "{key}": "{value}",')
        if new_entries:
            new_dict = prefix + existing + ''.join(new_entries) + suffix
            content = content[:match.start()] + new_dict + content[match.end():]
            print(f'Added key to {lang_name}')

with open(filepath, 'w') as f:
    f.write(content)
print('Done')
