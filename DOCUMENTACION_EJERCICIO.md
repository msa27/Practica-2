# Documentación del ejercicio — Práctica 2

Documentación corta de requisitos y archivos implementados. Detalle didáctico en `APRENDIZAJE.md`; verificación en `PLAN.md`.

---

## 1. Resumen del enunciado

La práctica pide una aplicación web **ASP.NET MVC 5** para una clínica veterinaria que gestione **clientes** y **mascotas** en la base de datos `Practica2`. Debe existir una página de bienvenida y un menú con tres opciones: registro de clientes, registro de mascotas y consulta de mascotas.

El registro de clientes captura cédula, nombre y correo; la cédula no puede repetirse. El registro de mascotas asocia cada animal a un cliente activo y limita a **máximo 2 mascotas de la misma especie por cliente**. Todos los campos de los formularios son obligatorios.

La consulta lista mascotas con cédula y nombre del cliente, nombre de la mascota, especie y peso. Las reglas de negocio se implementan en los **controladores** con LINQ y `SaveChanges()`; la validación de campos obligatorios, en el **cliente** con jQuery Validate.

**Base de datos:** solo el script del profesor (`Database script.txt`) con tablas `Clientes` y `Mascotas`. No se modifica el esquema ni se añaden tablas/SPs extra.

---

## 2. Script SQL

### `Database script.txt` (único script requerido)

| Elemento | Descripción |
|----------|-------------|
| BD `Practica2` | Base de datos del ejercicio |
| `Clientes` | `IdCliente` (PK, identity), `Cedula`, `Nombre`, `Correo`, `Estado` (bit) |
| `Mascotas` | `IdMascota` (PK, identity), `Nombre`, `Especie`, `Raza`, `Peso` (decimal 8,2), `IdCliente` (FK) |
| `FK_Mascotas_Clientes` | Relación 1:N Clientes → Mascotas |

---

## 3. Archivos del proyecto `Practica2.Web`

### Controllers

| Controlador | Acción | Qué hace |
|-------------|--------|----------|
| `HomeController` | `Index` (GET) | Página de bienvenida |
| `ClientesController` | `Registrar` (GET) | Formulario vacío (`ClienteModel`) |
| | `Registrar` (POST) | LINQ: verifica cédula única, inserta con `Estado=true`, `SaveChanges()`; si falla muestra mensaje; si OK redirige a Home |
| `MascotasController` | `Registrar` (GET) | Formulario con dropdown de clientes activos |
| | `Registrar` (POST) | LINQ: valida cliente activo y máx. 2 especie; inserta mascota; si falla recarga dropdown; si OK redirige a `Consultar` |
| | `Consultar` (GET) | LINQ JOIN Clientes/Mascotas → lista `ConsultaMascotaModel` |
| | `ObtenerClientesActivos` | LINQ: clientes con `Estado==true` para el dropdown |

Todos los controladores capturan excepciones, registran con `UtilitarioService` (Trace) y devuelven `Error.cshtml`.

### Models (ViewModels)

| Archivo | Campos / uso |
|---------|--------------|
| `ClienteModel` | `Cedula`, `Nombre`, `Correo` — formulario registro cliente |
| `MascotaModel` | `Nombre`, `Especie`, `Raza`, `Peso`, `IdCliente`, `Clientes` (dropdown) |
| `ConsultaMascotaModel` | `CedulaCliente`, `NombreCliente`, `NombreMascota`, `Especie`, `Peso` — fila de consulta |

### `EF/` (Entity Framework 6, Database First)

| Archivo | Contenido |
|---------|-----------|
| `Model1.edmx` (+ `.csdl`, `.ssdl`, `.msl`) | Modelo EDMX contra BD `Practica2` — solo `Clientes` y `Mascotas` |
| `Model1.Context.cs` | `Practica2Entities`: `DbSet<Clientes>`, `DbSet<Mascotas>` |
| `Clientes.cs`, `Mascotas.cs` | Entidades de tablas |

### Views

| Vista | Propósito |
|-------|-----------|
| `Shared/_Layout.cshtml` | Layout Mazer: bienvenida, menú lateral (3 opciones), `@RenderBody` |
| `Shared/Error.cshtml` | Mensaje genérico de error técnico |
| `Home/Index.cshtml` | Texto de bienvenida e instrucciones |
| `Clientes/Registrar.cshtml` | Formulario cédula/nombre/correo + `registrar-cliente.js` |
| `Mascotas/Registrar.cshtml` | Dropdown cliente + campos mascota + `registrar-mascota.js` |
| `Mascotas/Consultar.cshtml` | Tabla con las 5 columnas del enunciado |

### `Scripts/`

| Archivo | Validación jQuery |
|---------|-------------------|
| `registrar-cliente.js` | `Cedula`, `Nombre`, `Correo` obligatorios; correo con formato email |
| `registrar-mascota.js` | `IdCliente`, `Nombre`, `Especie`, `Raza`, `Peso` obligatorios; peso numérico ≥ 0.01 |

### `Servicios/`

| Archivo | Propósito |
|---------|-----------|
| `UtilitarioService.cs` | `RegistrarErrorBitacora` → `System.Diagnostics.Trace` (sin tabla en BD) |

### Configuración

| Archivo | Rol |
|---------|-----|
| `App_Start/RouteConfig.cs` | Ruta por defecto `{controller}/{action}/{id}` → `Home/Index` |
| `App_Start/BundleConfig.cs` | Bundles jQuery, jQuery Validate, CSS |
| `App_Start/FilterConfig.cs` | Filtro global `HandleErrorAttribute` |
| `Global.asax.cs` | Arranque MVC + UTF-8 en respuestas |
| `Web.config` | Cadena `Practica2Entities` (localhost), EF6, cultura `es-ES`, validación unobtrusive |

---

## 4. Reglas de negocio — dónde se implementan

| Regla | Capa | Detalle |
|-------|------|---------|
| Campos obligatorios | Cliente (JS) | `registrar-cliente.js`, `registrar-mascota.js` |
| Cédula única | Controlador | LINQ `FirstOrDefault` por cédula antes de insertar |
| Cliente activo al registrar mascota | Controlador | LINQ verifica `Estado == true` |
| Máx. 2 mascotas misma especie/cliente | Controlador | LINQ `Count()` por `IdCliente` + `Especie` |
| Solo clientes activos en dropdown | Controlador | `MascotasController.ObtenerClientesActivos` (LINQ) |
| Mensaje si regla falla | Controlador | `ViewBag.Mensaje` genérico |
| Errores de excepción | Servicio | `UtilitarioService` → `Trace.TraceError` |
| Consulta de mascotas | Controlador | LINQ JOIN ordenado por nombre cliente/mascota |
| Cliente nuevo con `Estado=1` | Controlador | Insert con `Estado = true` |

---

## 5. Entrega

Incluir: `Practica2.Web.sln`, carpeta `Practica2.Web/`, `Database script.txt`. Excluir `bin/`, `obj/`, `.vs/`.
