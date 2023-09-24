# Design Doc: Sistema para Almacenar Code Snippets

## Resumen

El objetivo de este proyecto es diseñar y desarrollar un sistema para almacenar code snippets (fragmentos de código) que permita a los usuarios guardar, organizar y consultar snippets de diferentes lenguajes de programación. El sistema utilizará Supabase como backend para el almacenamiento de datos. El sistema contendrá información sobre el lenguaje de programación, la categoría, el título, el código en sí y la fecha de publicación de cada code snippet. Este documento proporciona una descripción detallada de cómo se construirá este sistema.

## Objetivos del Proyecto

### 1. Almacenamiento de Code Snippets

El sistema debe permitir a los usuarios almacenar code snippets, incluyendo la siguiente información:

- **Lenguaje de Programación**: El lenguaje de programación al que pertenece el snippet.
- **Categoría**: Una categorización que ayuda a organizar y buscar snippets relacionados.
- **Título**: Un título descriptivo para el snippet.
- **Trozo de Código**: El código en sí mismo.
- **Fecha de Publicación**: La fecha en que se creó o se guardó el snippet.

### 2. Consulta y Búsqueda de Snippets

Los usuarios deben poder realizar consultas y búsquedas eficientes en el sistema para encontrar snippets relevantes según el lenguaje, la categoría, el título u otras palabras clave.

## Arquitectura Técnica

### Backend: Supabase

Utilizaremos Supabase como nuestro backend para el almacenamiento de datos. Supabase es una plataforma que proporciona una base de datos PostgreSQL, junto con API REST y WebSockets para interactuar con la base de datos.

### Estructura de la Base de Datos

Definiremos la estructura de la base de datos en Supabase de la siguiente manera:

- **Tabla Snippets**:
  - `id`: Identificador único del snippet (generado automáticamente).
  - `language`: Campo de texto que almacena el lenguaje de programación.
  - `category`: Campo de texto que almacena la categoría del snippet.
  - `title`: Campo de texto que almacena el título del snippet.
  - `code`: Campo de texto largo que almacena el código del snippet.
  - `published_date`: Campo de fecha y hora que almacena la fecha de publicación.

### API y Endpoints

Configuraremos los siguientes endpoints en la API de Supabase:

- **Crear Snippet**: Permite a los usuarios crear y almacenar nuevos snippets.
- **Recuperar Snippet por ID**: Permite a los usuarios recuperar un snippet específico por su ID.
- **Consultar Snippets**: Permite a los usuarios realizar consultas para buscar snippets según diferentes criterios, como lenguaje, categoría, título, etc.
- **Actualizar Snippet**: Permite a los usuarios actualizar la información de un snippet existente.
- **Eliminar Snippet**: Permite a los usuarios eliminar un snippet existente.

## Flujo de Trabajo del Usuario

1. Un usuario se registra o inicia sesión en la plataforma.
2. El usuario navega a la sección de "Snippets" o "Code Snippets".
3. El usuario puede crear un nuevo snippet proporcionando el lenguaje, la categoría, el título y el código.
4. El usuario puede buscar snippets existentes según sus necesidades.
5. El usuario puede ver los detalles de un snippet, editarlos o eliminarlos según sea necesario.

## Pruebas y Monitoreo

Se realizarán pruebas exhaustivas para garantizar el funcionamiento correcto del sistema, incluyendo pruebas de integración, pruebas de unidad y pruebas de rendimiento. Se configurarán mecanismos de monitoreo para detectar cualquier problema en tiempo real.

## Conclusiones

Este sistema permitirá a los desarrolladores almacenar y gestionar sus code snippets de manera eficiente, lo que facilitará la reutilización de código y mejorará la productividad en el desarrollo de software. La elección de Supabase como backend proporciona una solución escalable y de alto rendimiento para el almacenamiento de datos. El sistema se diseñará de manera que sea fácil de usar y proporcione una experiencia fluida para los usuarios.
