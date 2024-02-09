# Documento de Diseño: Normalización de Datos del Calendario de Eventos de Premios de Fórmula 1

## Título y Personas

- **Título:** Normalización de Datos del Calendario de Eventos de Premios de Fórmula 1
- **Fuente de Datos:** Archivo .ICS
- **Stack Tecnológico:** Python
- **Autor:** Codelaby
- **Fecha Límite:** Miércoles, 14 de Febrero 2024
- **Revisores:** Codelaby
- **Última Actualización:** Jueves, 9 de Febrero del 2024

## Resumen

El objetivo de este documento es diseñar e implementar un proceso de normalización de datos para el calendario de eventos de premios de Fórmula 1. Se utilizará un archivo .ICS como fuente de datos, y se empleará Python para la extracción y normalización de los campos, incluyendo la ubicación del país y la zona horaria a partir de la información de geolocalización.

## Contexto

El proceso de normalización de datos es fundamental para garantizar la coherencia y la calidad de los datos en el calendario de eventos de premios de Fórmula 1. La extracción precisa de la información, así como la identificación de la ubicación y la zona horaria de cada evento, son aspectos clave para su correcta representación y utilización.

## Metas y No Metas

**Metas:**

- Extraer datos clave de los eventos del calendario, incluyendo la ubicación y la fecha.
- Normalizar la información de geolocalización para obtener el país y la zona horaria correspondientes.
- Preparar los datos para su posterior procesamiento y análisis.

**No Metas:**

- Realizar cambios significativos en la estructura o funcionalidad del calendario de eventos que no estén relacionados con la normalización de datos.
- Extender el proceso de normalización a otras fuentes de datos o tipos de eventos en esta iteración.

## Solución Propuesta

Se propone utilizar Python para procesar el archivo .ICS y extraer los campos relevantes de cada evento. Se emplearán bibliotecas como `icalendar`, `pytz`, `tzfpy` y `geopy` para gestionar la información de geolocalización y zona horaria. Se diseñará un proceso de normalización que identifique la ubicación del país y la zona horaria a partir de las coordenadas geográficas proporcionadas en el archivo .ICS.

## Recursos de Soporte

La fuente de datos utilizada para la extracción de eventos relacionados con la Fórmula 1 es el sitio web https://f1calendar.com/es/generate. Este sitio proporciona un servicio para generar calendarios personalizados de eventos de Fórmula 1, ofreciendo información detallada sobre las fechas, horarios y ubicaciones de cada carrera, clasificación y sesión de práctica. Utilizamos este servicio para obtener un archivo en formato .ICS que contiene los datos de los eventos, los cuales posteriormente procesamos y normalizamos utilizando Python y las bibliotecas adecuadas para su posterior análisis y uso en nuestras aplicaciones o sistemas.

Para facilitar la implementación del proceso de normalización de datos, se proporcionarán los siguientes recursos:

- Documentación de las bibliotecas utilizadas en el proceso, incluyendo ejemplos y guías de uso.
- Ejemplos de código para la extracción y normalización de datos a partir de archivos .ICS. [Documentación de iCalendar](https://icalendar.readthedocs.io/en/latest/)
- Tutoriales y referencias adicionales sobre el manejo de datos de geolocalización y zona horaria en Python. [Documentación de tzfpy](https://pypi.org/project/tzfpy/) y [Documentación de geopy](https://geopy.readthedocs.io/en/stable/)

Estos recursos proporcionarán información detallada y ejemplos prácticos para ayudar a los desarrolladores en la implementación del proceso de normalización de datos del calendario de eventos de premios de Fórmula 1.

## Flujo de Trabajo

1. Procesamiento del archivo .ICS para extraer los eventos del calendario.
2. Extracción de los campos relevantes de cada evento, incluyendo la información de geolocalización.
3. Normalización de los datos de geolocalización para obtener el país y la zona horaria correspondientes.
4. Preparación de los datos normalizados para su almacenamiento o análisis posterior.

## Implementación Técnica

La implementación técnica se basará en el uso de Python y las bibliotecas mencionadas anteriormente para llevar a cabo el proceso de normalización de datos. Se diseñarán funciones y clases específicas para la extracción, procesamiento y normalización de la información contenida en el archivo .ICS.

Aquí está el bloque actualizado para la implementación técnica, incluyendo las funciones que has proporcionado:

```python
# Implementación Técnica

# Función para procesar el archivo .ICS y extraer eventos
def procesar_archivo_ics(archivo):
    eventos = []
    
    with open(archivo, 'rb') as f:
        calendario = icalendar.Calendar.from_ical(f.read())
        
        for componente in calendario.walk():
            if componente.name == "VEVENT":
                evento = {
                    "UID": componente.get("UID"),
                    "SUMMARY": componente.get("SUMMARY"),
                    "DTSTART": componente.get("DTSTART").dt,
                    "DTEND": componente.get("DTEND").dt,
                    "LOCATION": componente.get("LOCATION"),
                    "CATEGORIES": componente.get("CATEGORIES"),
                    "GEO": componente.get("GEO"),
                    "SEQUENCE": componente.get("SEQUENCE"),
                    "STATUS": componente.get("STATUS"),
                    "SEQUENCE": componente.get("SEQUENCE")
                }
                eventos.append(evento)
                
    return eventos

# Función para obtener la zona horaria a partir de coordenadas geográficas
def obtener_timezone(latitude, longitude):
    timezone_str = get_tz(latitude, longitude)
    return timezone_str

# Función para convertir una fecha y hora a la zona horaria local especificada
def convertir_a_zona_horaria_local(dt, tzName):
    zona_horaria_utc = pytz.utc
    zona_horaria_local = pytz.timezone(tzName) 
    return dt.replace(tzinfo=zona_horaria_utc).astimezone(zona_horaria_local)

# Función para obtener el país y su código ISO a partir de coordenadas geográficas
def obtener_pais_iso(latitude, longitude):
    geolocalizador = Nominatim(user_agent="my_geocoder")
    location = geolocalizador.reverse((latitude, longitude), exactly_one=True)
    if location:
        return location.raw["address"]["country"], location.raw["address"]["country_code"]
    return None, None

# Función para remover acentos de un texto
def remover_acentos(texto):
    texto_normalizado = ''.join((c for c in unicodedata.normalize('NFD', texto) if unicodedata.category(c) != 'Mn'))
    return texto_normalizado

# Función para generar un slug a partir de un texto
def slugify(texto):
    texto_sin_acentos = remover_acentos(texto)
    slug = re.sub(r'[^a-zA-Z0-9]+', '-', texto_sin_acentos)
    slug = re.sub(r'-+', '-', slug)
    slug = slug.lower()
    slug = slug.strip('-')
    return slug

# Función para generar un slug a partir de un texto entre paréntesis
def make_slug(texto):
    patron = re.compile(r'\(([^)]+)\)')
    coincidencias = patron.findall(texto)
    if coincidencias:
        c = coincidencias[-1]
        return slugify(c)
    else:
        return None
```

Este bloque de código contiene las funciones necesarias para procesar el archivo .ICS, así como otras utilidades para la normalización de datos, como la obtención de la zona horaria, el país y su código ISO, y la generación de slugs. Estas funciones serán fundamentales para el proceso de normalización de los datos del calendario de eventos de premios de Fórmula 1.

Aquí tienes el párrafo y la implementación de la extracción de datos para comprobar la precisión y la integridad de los datos normalizados:

---

**Extracción y Comprobación de Datos**

Se utiliza el archivo "f1_calendar_2024.ics" como fuente de datos para extraer eventos relacionados con los premios de Fórmula 1. Cada evento se procesa individualmente para normalizar la información y se comprueba su precisión mediante la transformación de la hora UTC a la zona horaria local del evento. Además, se verifica que el país obtenido a partir de las coordenadas geográficas coincida con el circuito correspondiente al evento.

```python
archivo_ics = "f1_calendar_2024.ics"
eventos = procesar_archivo_ics(archivo_ics)

for evento in eventos:

    # Extracción de coordenadas geográficas
    p0, p1 = map(float, reversed(evento["GEO"].to_ical().split(";")))

    # Obtención de la zona horaria
    timezone = obtener_timezone(p0, p1)

    # Obtención del país y su código ISO
    pais, iso_code = obtener_pais_iso(p1, p0)

    # Conversión de fechas y horas a la zona horaria local
    dtstart_local = convertir_a_zona_horaria_local(evento["DTSTART"])
    dtend_local = convertir_a_zona_horaria_local(evento["DTEND"])

    # Transformación de fechas y horas a formato string
    dtstart_str = evento["DTSTART"].strftime("%Y%m%dT%H%M%SZ")
    dtend_str = evento["DTEND"].strftime("%Y%m%dT%H%M%SZ")

    # Conversión de fechas y horas al track time (zona horaria del evento)
    dtstart_track_time = convertir_tracktime(evento["DTSTART"], timezone)
    dtend_track_time = convertir_tracktime(evento["DTEND"], timezone)

    # Extracción de referencia, tipo de evento y número de pista
    ref = evento["UID"].split("#")[-1]
    event_type = ref.split("_")[-1]
    track_num = int(re.search(r'GP(\d+)', ref).group(1)) + 1

    # Generación de slug a partir del resumen del evento
    slug = make_slug(evento["SUMMARY"])

    # Impresión de los datos normalizados para comprobación
    print("UID:", evento["UID"])
    print("REF", ref)
    print("SLUG", slug)
    print("TYPE", event_type)
    print("TRACK_NUM", track_num)
    print("SEQUENCE", evento["SEQUENCE"])
    print("country iso:", iso_code)
    print("SUMMARY:", evento["SUMMARY"])
    print("GEO:", evento["GEO"].to_ical())
    print("LATITUDE", p1)
    print("LONGITUDE", p0)
    print("TIMEZONE:", timezone)
    print("DTSTART (UTC):", dtstart_str)
    print("DTEND (UTC):", dtend_str)
    print("DTSTART (tz):", dtstart_track_time)
    print("DTEND (tz):", dtend_track_time)
    print("DTSTART (local):", dtstart_local)
    print("DTEND (local):", dtend_local)
    print("LOCATION:", evento["LOCATION"])
    print("CATEGORIES:", evento["CATEGORIES"].to_ical().decode('utf-8'))
    print("STATUS", evento["STATUS"])
    print()
```

Este bloque de código permite extraer y normalizar los datos de los eventos del calendario de Fórmula 1, asegurando su precisión y coherencia con los datos oficiales. Cada aspecto del evento se verifica y se convierte a la zona horaria local del evento para su correcta representación. Además, se realizan comprobaciones adicionales para garantizar la integridad de los datos normalizados.

## Pruebas y Monitoreo

Se llevarán a cabo pruebas exhaustivas para verificar la precisión y la integridad de los datos normalizados. Los datos normalizados serán comparados con los datos proporcionados oficialmente en el sitio web de la Fórmula 1 (https://www.formula1.com/en/racing/2024.html) para garantizar su exactitud. Estas pruebas incluirán:

1. Verificación de Fechas y Horas:
   - Las fechas y horas de todos los eventos se compararán con la hora local del evento, transformando la hora UTC de cada evento a la zona horaria de la competición.
   
2. Validación del ISO Code del País:
   - Se verificará que el ISO code del país obtenido a partir de las coordenadas geográficas concuerde con el circuito correspondiente al evento.

3. Extracción de Referencia y Tipo de Competición:
   - Se comprobará que la extracción de la referencia a partir del UID de la fuente de datos sea correcta y que se pueda determinar el tipo de competición (libres, clasificación, carrera, etc.).
   - Se realizarán pruebas para validar la numeración de eventos y asegurar su coherencia.

Se monitorearán los resultados de las pruebas para identificar posibles problemas o áreas de mejora en el proceso de normalización. Cualquier discrepancia entre los datos normalizados y los datos oficiales será investigada y corregida según sea necesario para garantizar la precisión de la información proporcionada.

## Impacto en Otros Equipos

Se comunicará el lanzamiento del proceso de normalización de datos a los equipos relevantes, como el equipo de desarrollo y los responsables de la gestión de eventos. Se proporcionará apoyo y asistencia adicional según sea necesario para garantizar una correcta integración y utilización de los datos normalizados.

## Preguntas Pendientes

1. ¿Cómo gestionaremos las actualizaciones y añadidos de traducciones en futuras iteraciones?
2. ¿Qué herramientas utilizaremos para coordinar el trabajo entre el equipo de desarrollo y los traductores, así como para gestionar las traducciones de manera eficiente?

## Detalles de Planificación y Cronograma

- **Análisis de Requisitos y Diseño de la Solución:** Jueves, 8 de Febrero del 2024
   - Identificar los campos relevantes a extraer del archivo .ICS.
   - Diseñar la estructura de datos para almacenar la información normalizada.
- **Implementación del Proceso de Normalización:** Viernes, 9 de Febrero del 2024
   - Desarrollar funciones para procesar el archivo .ICS y extraer los datos necesarios.
   - Implementar la lógica de normalización para obtener la ubicación del país y la zona horaria.
- **Pruebas Unitarias y de Integración:** Lunes, 12 de Febrero del 2024
   - Realizar pruebas para verificar la precisión y la integridad de los datos normalizados.
   - Integrar el proceso de normalización con otros componentes del sistema, si es necesario.
- **Ajustes y Optimizaciones:** Martes, 13 de Febrero del 2024
   - Realizar ajustes basados en los resultados de las pruebas y el feedback recibido.
   - Optimizar el rendimiento del proceso de normalización, si es posible.
- **Documentación y Entrega:** Miércoles, 14 de Febrero del 2024
   - Documentar el proceso de normalización y sus componentes.
   - Preparar la entrega del código y la documentación al equipo de desarrollo.



