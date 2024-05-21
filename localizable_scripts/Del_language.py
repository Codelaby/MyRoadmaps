import os
import json

# Path to the JSON file
file_path = 'origin/Localizable.xcstrings'

# Carpeta de salida para los JSON eliminados
output_folder = 'deleted'

# Crear la carpeta si no existe
os.makedirs(output_folder, exist_ok=True)

# Abrir y cargar el contenido del archivo JSON
with open(file_path, 'r', encoding='utf-8') as file:
    data = json.load(file)

# Eliminar las entradas en español
for key, value in data['strings'].items():
    if 'es' in value.get('localizations', {}):
        del value['localizations']['es']

# Crear el nombre de archivo de salida
output_file_name = os.path.join(output_folder, os.path.basename(file_path))

# Escribir el nuevo JSON en el archivo de salida
with open(output_file_name, 'w', encoding='utf-8') as output_file:
    json.dump(data, output_file, indent=2, ensure_ascii=False)

print(f"Deleted JSON file has been created: {output_file_name}")