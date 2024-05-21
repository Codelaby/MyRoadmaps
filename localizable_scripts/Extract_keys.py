import json

filterStartKey = 'paywall_'
output_file_path = 'paywall_strings.json'

# Plantilla
template = {
    "sourceLanguage": "en",
    "strings": {},  # Aquí se reemplazará con los datos filtrados
    "version": "1.0"
}

# Path to the JSON file
file_path = 'origin/Localizable.xcstrings'

# Open and load the content of the JSON file
with open(file_path, 'r', encoding='utf-8') as file:
    data = json.load(file)

# Filtrar las claves que empiezan con 'pref_'
filtered_data = {key: value for key, value in data['strings'].items() if key.startswith(filterStartKey)}

# Actualizar la plantilla con los datos filtrados
template['strings'] = filtered_data


# Escribir el nuevo JSON en el archivo de salida
with open(output_file_path, 'w', encoding='utf-8') as output_file:
    json.dump(template, output_file, indent=2, ensure_ascii=False)


print(f"Output JSON file has been created: {output_file_path}")