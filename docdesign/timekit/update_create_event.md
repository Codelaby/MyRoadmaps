# Mejoras en la Creación de Eventos en Timekit

**Título y Personas**
 - Título: Mejoras en la Creación de Eventos en Timekit
 - App: Timekit
 - Plataforma: SwiftUI
 - Autor: Codelaby
 - Fecha limite: por determinar
 - Revisores: Codelaby
 - Última Actualización: Lunes, 12 Febrero del 2024

## Resumen
El propósito de este documento es diseñar e implementar mejoras en la funcionalidad de creación de eventos en la aplicación Timekit. Estas mejoras permitirán a los usuarios adjuntar enlaces a eventos y seleccionar colores de una paleta predefinida. Además, se migrará la asignación de colores predeterminados basados en el nombre y la fecha del evento.

## Contexto
La inclusión de la capacidad de adjuntar enlaces y seleccionar colores en la creación de eventos enriquecerá la experiencia del usuario al brindarles más opciones y personalización al crear eventos en Timekit.

## Metas y No Metas
**Metas:**
- Permitir a los usuarios adjuntar enlaces a eventos.
- Implementar un selector de color basado en una paleta predefinida.
- Migrar la asignación de colores predeterminados basados en el nombre y la fecha del evento.
- Validar la estructura del enlace introducido por el usuario.
- Desactivar el botón de guardado hasta que el enlace sea válido o no esté vacío.

**No Metas:**
- Implementar cambios significativos en otras áreas de la aplicación no relacionadas con la creación de eventos.

## Solución Propuesta
- Incluir una caja de texto en la pantalla de creación de eventos para que los usuarios puedan introducir enlaces.
- Implementar una validación de la estructura del enlace introducido para asegurar su validez.
- Desactivar el botón de guardado si el enlace está vacío o no es válido.
- Agregar un selector de color tipo menú con una paleta predefinida para que los usuarios puedan elegir el color del evento.
- Migrar la lógica de asignación de colores predeterminados basados en el nombre y la fecha del evento.

## Recursos de soporte
Se proporcionará un tutorial detallado sobre cómo implementar la validación de enlaces y el selector de color en SwiftUI.
Documentación sobre las mejores prácticas para la migración de datos en aplicaciones iOS.

**Tutorial en Video:**
[Selector de colores compacto en SwiftUI](https://swiftuisnippets.wordpress.com/2023/10/26/selector-de-colores-compacto-en-swiftui/)
[Generación de Colores a Partir de Texto en SwiftUI](https://swiftuisnippets.wordpress.com/2024/01/23/generacion-de-colores-a-partir-de-texto-en-swiftui/)

## Flujo de Trabajo
- ⬜ Diseñar la interfaz de usuario para incluir una caja de texto para enlaces y un selector de color.
- ⬜ Implementar la lógica de validación de enlaces y desactivar el botón de guardado según sea necesario.
- ⬜ Integrar el selector de color con una paleta predefinida.
- ⬜ Migrar la lógica de asignación de colores predeterminados.
- ⬜ Realizar pruebas exhaustivas para asegurar el correcto funcionamiento de las nuevas funcionalidades.

## Implementación Técnica
- Utilizar validación de patrones de expresiones regulares para verificar la estructura del enlace introducido por el usuario.
- Implementar un picker de color con una lista de colores predefinidos.
- Utilizar la lógica de migración de datos para asignar colores predeterminados basados en el nombre y la fecha del evento.
```swift
import SwifUI
 
extension Color {
    static func textToColor(_ text: String) -> Color {
        guard !text.isEmpty else {
            return .clear
        }
         
        let materialColors: [Color] = [
            Color(hex: 0xF44336), Color(hex: 0xE91E63), Color(hex: 0x9C27B0),
            Color(hex: 0x673AB7), Color(hex: 0x3F51B5), Color(hex: 0x2196F3),
            Color(hex: 0x03A9F4), Color(hex: 0x00BCD4), Color(hex: 0x009688),
            Color(hex: 0x4CAF50), Color(hex: 0x8BC34A), Color(hex: 0xCDDC39),
            Color(hex: 0xFFEB3B), Color(hex: 0xFFC107), Color(hex: 0xFF9800),
            Color(hex: 0xFF5722), Color(hex: 0x795548), Color(hex: 0x9E9E9E),
            Color(hex: 0x607D8B)
        ]
     
        let sum = text.lowercased().reduce(0) { $0 + Int($1.asciiValue ?? 0) }
        let index = sum % materialColors.count
        return materialColors[index]
    }
 
    init(hex: UInt32, alpha: Double = 1.0) {
        let red = Double((hex & 0xFF0000) >> 16) / 255.0
        let green = Double((hex & 0x00FF00) >> 8) / 255.0
        let blue = Double(hex & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }
}
//Su uso
let youcolor = Color.textToColor("Hola mundo")
```

## Pruebas y Monitoreo
- ⬜ Realizar pruebas exhaustivas en diferentes dispositivos para asegurar la funcionalidad y validez de los enlaces introducidos.
- ⬜ Verificar que el selector de color funcione correctamente y que los colores seleccionados se reflejen correctamente en la interfaz de usuario.
- ⬜ Monitorizar la retroalimentación de los usuarios para identificar posibles problemas y realizar ajustes según sea necesario.

## Impacto en Otros Equipos
- Comunicar las nuevas funcionalidades a los equipos de soporte y atención al cliente para que estén preparados para manejar consultas relacionadas.
- No se espera un impacto significativo en otros equipos, ya que la implementación se centra en la mejora de la funcionalidad de creación de eventos.

## Preguntas Pendientes
- ¿Cómo gestionaremos futuras actualizaciones y añadidos de funcionalidades en la creación de eventos?

## Detalles de Planificación y Cronograma
- ✅ Diseñar la estructura de archivos de strings localizados: Por determinar
- ⬜ Diseño de la interfaz de usuario y lógica de validación: Por determinar
- ⬜ Implementación de la funcionalidad de enlaces y selector de color: Por determinar
- ⬜ Pruebas exhaustivas y ajustes finales: Por determinar
- ⬜ Lanzamiento y monitorización inicial: Por determinar
