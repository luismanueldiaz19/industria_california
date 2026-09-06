# 📘 Principios de Ingeniería de Software

## 1. Introducción
La Ingeniería de Software es la disciplina que aplica principios científicos, matemáticos y prácticos al desarrollo de sistemas de software, garantizando calidad, eficiencia y mantenibilidad.

---

## 2. Principios Fundamentales

### 🔹 2.1 Modularidad
- Dividir el sistema en componentes independientes y reutilizables.
- Facilita el mantenimiento y la escalabilidad.

### 🔹 2.2 Abstracción
- Ocultar detalles internos y mostrar solo lo esencial.
- Permite enfocarse en el “qué” más que en el “cómo”.

### 🔹 2.3 Encapsulamiento
- Proteger los datos y operaciones internas de un módulo.
- Garantiza seguridad y reduce errores por acceso indebido.

### 🔹 2.4 Separación de Responsabilidades
- Cada módulo debe tener una función clara y única.
- Evita duplicidad y confusión en el código.

### 🔹 2.5 Reutilización
- Diseñar componentes genéricos y parametrizables.
- Reduce costos y tiempo de desarrollo.

### 🔹 2.6 Robustez
- Manejo adecuado de errores y excepciones.
- El sistema debe recuperarse ante fallos sin comprometer la integridad.

### 🔹 2.7 Escalabilidad
- El software debe crecer sin perder rendimiento.
- Considerar tanto escalabilidad vertical (más recursos) como horizontal (más nodos).

### 🔹 2.8 Validación y Verificación
- **Verificación:** ¿Estamos construyendo el sistema correctamente?
- **Validación:** ¿Estamos construyendo el sistema correcto?

### 🔹 2.9 Documentación Clara
- Mantener manuales, diagramas y guías actualizadas.
- Facilita la colaboración y el mantenimiento futuro.

---

## 3. Ciclo de Vida del Software
1. **Requerimientos** → Definición clara de necesidades.
2. **Diseño** → Arquitectura modular y escalable.
3. **Implementación** → Codificación siguiendo estándares.
4. **Pruebas** → Validación funcional y de rendimiento.
5. **Despliegue** → Entrega controlada y segura.
6. **Mantenimiento** → Corrección, mejoras y evolución.

---

## 4. Buenas Prácticas
- Uso de **control de versiones** (Git).
- Aplicación de **pruebas unitarias e integrales**.
- Integración continua y despliegue automatizado (CI/CD).
- Monitoreo y métricas para detectar problemas tempranos.
- Feedback visual y validaciones robustas en la UI.

---

## 5. Conclusión
Aplicar estos principios asegura que el software sea **confiable, escalable y mantenible**, reduciendo riesgos y costos en cualquier proyecto.

---

## 6. Referencias
- Sommerville, I. *Software Engineering*.
- Pressman, R. *Software Engineering: A Practitioner’s Approach*.
- IEEE Standards for Software Engineering.



# Principios de Ingeniería de Software

Documento de referencia general, aplicable a cualquier proyecto de software independientemente del lenguaje, framework o dominio.

---

## 1. Principios Fundamentales de Diseño

### 1.1 KISS (Keep It Simple, Stupid)
La simplicidad debe ser un objetivo activo. Ante dos soluciones que resuelven el mismo problema, se prefiere la más simple de entender, mantener y probar.

### 1.2 DRY (Don't Repeat Yourself)
Cada pieza de conocimiento o lógica debe tener una única representación autorizada en el sistema. La duplicación de código genera puntos de fallo múltiples ante cambios futuros.

### 1.3 YAGNI (You Aren't Gonna Need It)
No se debe implementar funcionalidad especulativa "por si acaso se necesita después". Se construye lo que el requisito actual exige, no lo que podría exigir en el futuro.

### 1.4 Separación de Responsabilidades (Separation of Concerns)
Cada módulo, clase o función debe encargarse de un aspecto bien delimitado del problema. Esto reduce el acoplamiento y facilita el razonamiento sobre el sistema.

### 1.5 Principio de Menor Sorpresa (Least Astonishment)
El comportamiento de un componente debe coincidir con lo que un desarrollador razonable esperaría de su nombre, firma y contexto. Evitar efectos secundarios ocultos o nombres engañosos.

---

## 2. Principios SOLID (Diseño Orientado a Objetos)

| Principio | Descripción |
|---|---|
| **S** — Single Responsibility | Una clase debe tener una única razón para cambiar. |
| **O** — Open/Closed | El código debe estar abierto a extensión, cerrado a modificación. |
| **L** — Liskov Substitution | Las subclases deben poder sustituir a sus clases base sin alterar la corrección del programa. |
| **I** — Interface Segregation | Es preferible tener varias interfaces específicas antes que una interfaz general con métodos que no todos los clientes usan. |
| **D** — Dependency Inversion | Los módulos de alto nivel no deben depender de módulos de bajo nivel; ambos deben depender de abstracciones. |

Estos principios aplican con matices también fuera de la POO pura (por ejemplo, en diseño de módulos funcionales o servicios).

---

## 3. Arquitectura y Estructura

- **Alta cohesión, bajo acoplamiento**: los elementos relacionados deben agruparse juntos; los módulos independientes deben poder cambiar sin afectarse mutuamente.
- **Diseño por capas o límites claros**: separar lógica de negocio, acceso a datos y presentación (o sus equivalentes según la arquitectura elegida: hexagonal, limpia, por capas, microservicios, etc.).
- **Contratos explícitos**: las interfaces entre componentes (APIs, funciones públicas, esquemas de datos) deben estar bien definidas y documentadas.
- **Composición sobre herencia**: preferir construir comportamiento combinando piezas pequeñas antes que mediante jerarquías de herencia profundas.
- **Diseño evolutivo**: la arquitectura debe poder adaptarse a nuevos requisitos sin reescrituras masivas; se decide lo mínimo necesario ahora y se documentan los puntos de extensión.

---

## 4. Calidad del Código

- **Nombrado significativo**: variables, funciones y clases deben describir su propósito sin necesidad de comentarios adicionales.
- **Funciones pequeñas y con un solo propósito**: si una función necesita ser explicada en varias frases, probablemente debe dividirse.
- **Evitar código muerto**: eliminar código no utilizado en lugar de comentarlo o dejarlo "por si acaso".
- **Manejo explícito de errores**: los errores deben capturarse, tratarse o propagarse de forma intencional, nunca ignorarse silenciosamente.
- **Comentarios con propósito**: explican el *por qué*, no el *qué* (el código ya dice el qué). Se evita comentar código evidente.
- **Consistencia de estilo**: seguir una guía de estilo única en todo el proyecto, idealmente reforzada con linters y formateadores automáticos.

---

## 5. Pruebas y Verificación

- **Pirámide de pruebas**: base amplia de pruebas unitarias rápidas, capa intermedia de pruebas de integración, y una capa reducida de pruebas end-to-end.
- **Pruebas como documentación viva**: un buen conjunto de pruebas describe el comportamiento esperado del sistema.
- **Tests deterministas y aislados**: no deben depender del orden de ejecución ni de estado compartido entre ellos.
- **Cobertura con criterio**: la métrica de cobertura es una guía, no un objetivo en sí mismo; importa más probar los caminos críticos y los casos límite.
- **Fallar rápido (Fail Fast)**: detectar errores lo antes posible, tanto en tiempo de compilación/análisis estático como en ejecución.

---

## 6. Control de Versiones y Colaboración

- **Commits atómicos y descriptivos**: cada commit representa un cambio lógico coherente, con un mensaje claro sobre el qué y el por qué.
- **Ramas de corta duración**: minimizar el tiempo de vida de las ramas de feature para reducir conflictos de integración.
- **Revisión de código (Code Review)**: todo cambio relevante debe ser revisado por otra persona antes de integrarse; el objetivo es mejorar calidad y compartir contexto, no solo detectar errores.
- **Integración continua**: los cambios se integran frecuentemente a la rama principal, validados por builds y pruebas automatizadas.

---

## 7. Mantenibilidad y Deuda Técnica

- **Deuda técnica visible y gestionada**: se documenta y prioriza conscientemente, no se acumula de forma implícita.
- **Refactorización continua**: mejorar la estructura interna del código sin alterar su comportamiento externo, como práctica habitual y no como proyecto aislado.
- **Documentación mínima viable pero suficiente**: el sistema debe poder entenderse sin depender exclusivamente del conocimiento tácito de quien lo escribió.
- **Principio de las ventanas rotas**: no dejar código de mala calidad "porque ya estaba así"; cada cambio es una oportunidad de dejar el código un poco mejor (regla del boy scout).

---

## 8. Seguridad y Robustez

- **Principio de menor privilegio**: cada componente o usuario debe tener solo los permisos estrictamente necesarios para su función.
- **Validación de entradas**: nunca confiar en datos externos (usuario, red, archivos) sin validarlos o sanearlos.
- **Defensa en profundidad**: no depender de una única capa de seguridad; combinar múltiples controles.
- **Manejo seguro de secretos**: credenciales y claves nunca se incluyen en el código fuente ni en el control de versiones.
- **Diseño resiliente a fallos**: anticipar fallos de red, dependencias externas y recursos, con mecanismos de reintento, *circuit breakers* o *fallbacks* según el contexto.

---

## 9. Rendimiento y Escalabilidad

- **No optimizar prematuramente**: primero se busca corrección y claridad; se optimiza cuando hay evidencia (mediciones) de que es necesario.
- **Medir antes de optimizar**: usar perfilado y métricas reales en lugar de suposiciones.
- **Diseñar para escalar según necesidad real**: la escalabilidad se incorpora cuando el crecimiento esperado lo justifica, no de forma especulativa.

---

## 10. Proceso y Trabajo en Equipo

- **Requisitos claros antes de codificar**: entender el problema y los criterios de aceptación reduce retrabajo.
- **Iteración incremental**: entregar en incrementos pequeños y funcionales permite retroalimentación temprana y reduce riesgo.
- **Comunicación sobre suposiciones**: toda decisión de diseño no trivial se documenta y comunica al equipo.
- **Automatización de tareas repetitivas**: builds, despliegues, pruebas y formateo deben automatizarse siempre que sea posible.
- **Aprendizaje continuo**: retrospectivas y revisión de incidentes (post-mortems) como mecanismo de mejora, no de culpa.

---

## Resumen ejecutivo

| Área | Principio clave |
|---|---|
| Diseño | Simplicidad, no duplicación, no sobre-ingeniería |
| Arquitectura | Bajo acoplamiento, alta cohesión, contratos claros |
| Código | Legible, con errores manejados explícitamente |
| Pruebas | Rápidas, aisladas, enfocadas en comportamiento crítico |
| Colaboración | Commits pequeños, revisión de código, integración continua |
| Mantenimiento | Deuda técnica visible, refactorización constante |
| Seguridad | Menor privilegio, validación de entradas, defensa en profundidad |
| Rendimiento | Medir antes de optimizar |
| Proceso | Iteración incremental, comunicación explícita |

Estos principios no son reglas absolutas: son heurísticas que deben aplicarse con criterio según el contexto, tamaño y objetivos de cada proyecto.
