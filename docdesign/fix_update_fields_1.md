# Documento de Diseño - Ampliación de la Tabla de Code Snippets

## Resumen

Este documento describe la ampliación de la tabla de "Code Snippets" (fragmentos de código) para incluir nuevos campos que mejorarán la utilidad y la organización de los snippets. Los nuevos campos incluyen `media`, `src_link` y `score`. Estos campos permitirán a los usuarios adjuntar enlaces a videos demostrativos, enlaces a repositorios de código y asignar una puntuación de prioridad a los snippets.

## Nuevos Campos

### 1. `media` (Texto)

- **Descripción:** Este campo permitirá a los usuarios adjuntar enlaces a medios, como videos demostrativos o tutoriales relacionados con el code snippet.
- **Tipo de Datos:** Texto
- **Ejemplo:** Enlace a un video de YouTube que muestra cómo utilizar el code snippet.

### 2. `src_link` (Texto)

- **Descripción:** Este campo permitirá a los usuarios adjuntar enlaces a repositorios de código fuente donde se encuentre el código relacionado con el code snippet. Esto facilitará el acceso al código fuente completo.
- **Tipo de Datos:** Texto
- **Ejemplo:** Enlace a un repositorio de GitHub que contiene el código del code snippet.

### 3. `score` (Entero)

- **Descripción:** Este campo permitirá a los usuarios asignar una puntuación o valor de prioridad a los snippets. Esto puede ayudar a los usuarios a destacar o clasificar los snippets más importantes o útiles.
- **Tipo de Datos:** Entero
- **Ejemplo:** Puntuación de 5 para un snippet especialmente útil.

## Actualización de la Tabla

Para incorporar estos nuevos campos en la tabla de "Code Snippets", se realizarán las siguientes modificaciones:

```sql
ALTER TABLE code_snippets
ADD COLUMN media TEXT NULL,
ADD COLUMN src_link TEXT NULL,
ADD COLUMN score BIGINT NULL DEFAULT '0'::bigint;
```

## Funcionalidad Adicional

### Consulta y Filtros

Los usuarios podrán realizar consultas y filtrar snippets basados en estos nuevos campos. Por ejemplo, podrán buscar snippets que tengan enlaces de medios adjuntos o aquellos que tengan una puntuación alta.

### Visualización Mejorada

La incorporación de enlaces a medios y repositorios de código permitirá a los usuarios obtener una visión más completa y comprensible de cada snippet. Esto facilitará la evaluación y el uso de los snippets.

## Conclusiones

La ampliación de la tabla de "Code Snippets" con los campos `media`, `src_link` y `score` mejorará significativamente la utilidad de la plataforma al permitir a los usuarios adjuntar enlaces a recursos relacionados y clasificar la importancia de los snippets. Estos cambios proporcionarán una experiencia más completa y versátil para los usuarios, lo que contribuirá a la eficacia y el valor de la plataforma.
