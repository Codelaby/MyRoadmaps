# Documentación Técnica - Tabla de Code Snippets

## Resumen

Esta documentación técnica describe la estructura y la funcionalidad de la tabla de "Code Snippets" (fragmentos de código) en el sistema. Los code snippets son piezas de código relacionadas con la programación que se almacenan en la base de datos. Esta tabla estará disponible solo para lectura pública, mientras que la escritura y la gestión de datos se llevarán a cabo por parte del administrador a través de Supabase.

## Estructura de la Tabla

### Campos de la Tabla

1. `id` (UUID): Identificador único generado automáticamente para cada code snippet utilizando la función `uuid_generate_v4()`. Este campo sirve como clave primaria.

2. `category` (Texto): La categoría a la que pertenece el code snippet.

3. `label` (Array de Texto): Un array de texto que permite asociar múltiples etiquetas (tags) al code snippet.

4. `title` (Texto): Un título descriptivo para el code snippet.

5. `description` (Texto): Una descripción detallada del code snippet.

6. `code_lang` (Texto): El lenguaje de programación al que pertenece el code snippet.

7. `code` (Texto Largo): El código fuente real del snippet.

8. `author` (Texto): El autor del code snippet.

9. `created_at` (Fecha y Hora): La fecha y hora en que se creó el code snippet.

### Restricciones y Notas

- El campo `id` es único y se genera automáticamente mediante la función `uuid_generate_v4()`.
- La tabla de code snippets estará disponible solo para lectura pública. La escritura y la gestión de datos se realizarán a través del backend y la interfaz de administración de Supabase.

## Funcionalidad de la Tabla

La tabla de code snippets almacena información detallada sobre snippets de código relacionados con la programación. Los campos clave de esta tabla permiten la organización y búsqueda eficiente de code snippets. A continuación, se describe la funcionalidad clave:

### Consulta de Code Snippets

Los usuarios pueden realizar consultas para recuperar code snippets basados en varios criterios, como el lenguaje de programación, la categoría, el título, las etiquetas y la fecha de creación.

Ejemplo de consulta SQL para recuperar todos los snippets de un lenguaje específico:

```sql
SELECT * FROM code_snippets WHERE code_lang = 'Python';
```

### Búsqueda por Etiquetas

Los usuarios pueden buscar code snippets utilizando etiquetas específicas. Esto permite una búsqueda más precisa y la recuperación de snippets relacionados con temas específicos.

Ejemplo de consulta SQL para buscar snippets con etiquetas relacionadas con "algoritmos":

```sql
SELECT * FROM code_snippets WHERE 'algoritmos' = ANY (label);
```

## Conclusiones

La tabla de "Code Snippets" proporciona una estructura organizada para almacenar y recuperar snippets de código relacionados con la programación. Esta tabla estará disponible solo para lectura pública, y la escritura y la gestión de datos serán responsabilidad del administrador a través de Supabase. Los campos y las consultas mencionados anteriormente permiten a los usuarios buscar y acceder fácilmente a snippets de interés según diferentes criterios. La inclusión de etiquetas en un array proporciona una forma flexible de categorizar y buscar snippets relacionados.
