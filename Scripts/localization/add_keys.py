import re

new_keys = {
    "label.trueHeading": {"en": "True Heading", "th": "ทิศทางจริง", "zh": "真航向", "ja": "真方位", "ko": "진북 방향", "es": "Rumbo Verdadero", "fr": "Cap Vrai", "de": "Wahrer Kurs", "pt": "Direção Verdadeira", "ar": "الاتجاه الحقيقي", "it": "Rotta Vera", "ru": "Истинный Курс"},
    "label.magneticHeading": {"en": "Magnetic Heading", "th": "ทิศทางแม่เหล็ก", "zh": "磁航向", "ja": "磁方位", "ko": "자북 방향", "es": "Rumbo Magnético", "fr": "Cap Magnétique", "de": "Magnetischer Kurs", "pt": "Direção Magnética", "ar": "الاتجاه المغناطيسي", "it": "Rotta Magnetica", "ru": "Магнитный Курс"},
    "label.headingAccuracy": {"en": "Heading Accuracy", "th": "ความแม่นยำของทิศทาง", "zh": "航向精度", "ja": "方位精度", "ko": "방향 정확도", "es": "Precisión de Rumbo", "fr": "Précision du Cap", "de": "Kursgenauigkeit", "pt": "Precisão da Direção", "ar": "دقة الاتجاه", "it": "Precisione Rotta", "ru": "Точность Курса"},
    "label.roll": {"en": "Roll", "th": "ม้วน", "zh": "横滚", "ja": "ロール", "ko": "롤", "es": "Alabeo", "fr": "Roulis", "de": "Rollen", "pt": "Rolagem", "ar": "الدحرجة", "it": "Rollio", "ru": "Крен"},
    "label.pitch": {"en": "Pitch", "th": "เอียง", "zh": "俯仰", "ja": "ピッチ", "ko": "피치", "es": "Cabeceo", "fr": "Tangage", "de": "Nicken", "pt": "Arfagem", "ar": "الانحدار", "it": "Beccheggio", "ru": "Тангаж"},
    "label.yaw": {"en": "Yaw", "th": "หมุน", "zh": "偏航", "ja": "ヨー", "ko": "요", "es": "Guinada", "fr": "Lacet", "de": "Gieren", "pt": "Guinada", "ar": "الانعراج", "it": "Imbardata", "ru": "Рыскание"},
    "button.done": {"en": "Done", "th": "เสร็จสิ้น", "zh": "完成", "ja": "完了", "ko": "완료", "es": "Listo", "fr": "Terminé", "de": "Fertig", "pt": "Concluído", "ar": "تم", "it": "Fatto", "ru": "Готово"},
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
