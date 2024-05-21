import json
import os

# Rutas de los archivos de salida
data_file_paths = [
    'templates/action_strings.json',
    'templates/about_strings.json',
    'templates/pref_strings.json',
    'templates/delete_default_data_strings.json',
    'origin/Localizable.xcstrings'
    ]

# Ruta del archivo de destino fusionado
merged_file_path = 'merged/Localizable.xcstrings'

# Crear un diccionario vacío para almacenar los datos fusionados
merged_data = {"sourceLanguage": "en", "strings": {}, "version": "1.0"}

# Iterar sobre cada ruta de archivo en la lista
for data_file_path in data_file_paths:
    # Abrir y cargar solo la sección "strings" del archivo de salida actual
    with open(data_file_path, 'r', encoding='utf-8') as output_file:
        output_data = json.load(output_file)['strings']

    # Fusionar los datos del archivo actual con los datos fusionados
    merged_data['strings'].update(output_data)

# Crear directorio si no existe
os.makedirs(os.path.dirname(merged_file_path), exist_ok=True)

# Escribir los datos combinados en el archivo fusionado
with open(merged_file_path, 'w', encoding='utf-8') as merged_file:
    json.dump(merged_data, merged_file, indent=2, ensure_ascii=False)

print(f"Merged JSON has been created at: {merged_file_path}")