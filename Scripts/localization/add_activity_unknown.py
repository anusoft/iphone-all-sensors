import re

new_keys = {
    "activity.unknown": {"en": "Unknown", "th": "ไม่ทราบ", "zh": "未知", "ja": "不明", "ko": "알 수 없음", "es": "Desconocido", "fr": "Inconnu", "de": "Unbekannt", "pt": "Desconhecido", "ar": "غير معروف", "it": "Sconosciuto", "ru": "Неизвестно"},
    "label.x": {"en": "X", "th": "X", "zh": "X", "ja": "X", "ko": "X", "es": "X", "fr": "X", "de": "X", "pt": "X", "ar": "X", "it": "X", "ru": "X"},
    "label.y": {"en": "Y", "th": "Y", "zh": "Y", "ja": "Y", "ko": "Y", "es": "Y", "fr": "Y", "de": "Y", "pt": "Y", "ar": "Y", "it": "Y", "ru": "Y"},
    "label.z": {"en": "Z", "th": "Z", "zh": "Z", "ja": "Z", "ko": "Z", "es": "Z", "fr": "Z", "de": "Z", "pt": "Z", "ar": "Z", "it": "Z", "ru": "Z"},
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
        for key, translations in new_keys.items():
            if f'"{key}"' in existing:
                continue
            value = translations[lang_code]
            new_entries.append(f'\n        "{key}": "{value}",')
        if new_entries:
            new_dict = prefix + existing + ''.join(new_entries) + suffix
            content = content[:match.start()] + new_dict + content[match.end():]
            print(f'Added {len(new_entries)} keys to {lang_name}')

with open(filepath, 'w') as f:
    f.write(content)
print('Done')
