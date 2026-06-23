# Documentación del ejercicio — Práctica 2

Documentación corta de requisitos y archivos implementados. Detalle didáctico en `APRENDIZAJE.md`; verificación en `PLAN.md`.

---

## 1. Resumen del enunciado

La práctica pide una aplicación web **ASP.NET MVC 5** para una clínica veterinaria que gestione **clientes** y **mascotas** en la base de datos `Practica2`. Debe existir una página de bienvenida y un menú con tres opciones: registro de clientes, registro de mascotas y consulta de mascotas.

El registro de clientes captura cédula, nombre y correo; la cédula no puede repetirse. El registro de mascotas asocia cada animal a un cliente activo y limita a **máximo 2 mascotas de la misma especie por cliente**. Todos los campos de los formularios son obligatorios.

La consulta lista mascotas con cédula y nombre del cliente, nombre de la mascota, especie y peso. Las reglas de negocio se implementan en **stored procedures**; la validación de campos obligatorios, en el **cliente** con jQuery Validate.

---

## 2. Scripts SQL (orden de ejecución)

La base de datos se prepara con **dos scripts separados**. El script del profesor define únicamente las tablas del enunciado; los procedimientos almacenados y la bitácora son **adiciones** que no alteran ese esquema.

| Script | Rol | ¿Modifica `Clientes`/`Mascotas`? |
|--------|-----|----------------------------------|
| **1.** `Database script.txt` | Tablas del profesor (`Practica2`, `Clientes`, `Mascotas`, FK). **Intocable** — no añadir columnas, renombrar ni cambiar DDL. | Crea las tablas (script original) |
| **2.** `Practica2_StoredProcedures.sql` | SPs de negocio + tabla auxiliar `tbError` (opcional, patrón KN). Solo `CREATE PROCEDURE` y objetos nuevos. | **No** — no hace `ALTER`/`DROP` de tablas del profesor |

```text
sqlcmd -S localhost -E -i "Database script.txt"
sqlcmd -S localhost -E -i "Practica2_StoredProcedures.sql"
```

### Script 1 — `Database script.txt` (profesor, intocable)

| Elemento | Descripción |
|----------|-------------|
| BD `Practica2` | Base de datos del ejercicio |
| `Clientes` | `IdCliente` (PK, identity), `Cedula`, `Nombre`, `Correo`, `Estado` (bit) |
| `Mascotas` | `IdMascota` (PK, identity), `Nombre`, `Especie`, `Raza`, `Peso` (decimal 8,2), `IdCliente` (FK) |
| `FK_Mascotas_Clientes` | Relación 1:N Clientes → Mascotas |

### Script 2 — `Practica2_StoredProcedures.sql` (adiciones, no modifica tablas del profesor)

| Objeto | Propósito |
|--------|-----------|
| `tbError` | Bitácora: `Consecutivo`, `Fecha`, `Mensaje`, `Lugar`, `Usuario` |
| `spRegistrarError` | Inserta un error en `tbError` |
| `spRegistrarCliente` | Inserta cliente (`Estado=1`). `@Resultado`: `1` OK, `-1` cédula duplicada, `0` fallo |
| `spRegistrarMascota` | Inserta mascota. `@Resultado`: `1` OK, `-1` cliente inexistente/inactivo, `-2` límite especie, `0` fallo |
| `spConsultarMascotas` | JOIN Clientes/Mascotas; devuelve cédula, nombre cliente, nombre mascota, especie, peso |

---

## 3. Archivos del proyecto `Practica2.Web`

### Controllers

| Controlador | Acción | Qué hace |
|-------------|--------|----------|
| `HomeController` | `Index` (GET) | Página de bienvenida |
| `ClientesController` | `Registrar` (GET) | Formulario vacío (`ClienteModel`) |
| | `Registrar` (POST) | Llama `spRegistrarCliente`; si `Resultado≠1` muestra mensaje; si OK redirige a Home |
| `MascotasController` | `Registrar` (GET) | Formulario con dropdown de clientes activos |
| | `Registrar` (POST) | Llama `spRegistrarMascota`; si falla recarga dropdown; si OK redirige a `Consultar` |
| | `Consultar` (GET) | Ejecuta `spConsultarMascotas` → lista `ConsultaMascotaModel` |
| | `ObtenerClientesActivos` | LINQ: clientes con `Estado==true` para el dropdown |

Todos los controladores capturan excepciones, registran en bitácora (`UtilitarioService`) y devuelven `Error.cshtml`.

### Models (ViewModels)

| Archivo | Campos / uso |
|---------|--------------|
| `ClienteModel` | `Cedula`, `Nombre`, `Correo` — formulario registro cliente |
| `MascotaModel` | `Nombre`, `Especie`, `Raza`, `Peso`, `IdCliente`, `Clientes` (dropdown) |
| `ConsultaMascotaModel` | `CedulaCliente`, `NombreCliente`, `NombreMascota`, `Especie`, `Peso` — fila de consulta |

### `EF/` (Entity Framework 6, Database First)

| Archivo | Contenido |
|---------|-----------|
| `Model1.edmx` (+ `.csdl`, `.ssdl`, `.msl`) | Modelo EDMX contra BD `Practica2` |
| `Model1.Context.cs` | `Practica2Entities`: `DbSet` + métodos de los 4 SPs |
| `Clientes.cs`, `Mascotas.cs` | Entidades de tablas |
| `tbError.cs` | Entidad bitácora |
| `spConsultarMascotas_Result.cs` | Tipo de retorno del SP de consulta |

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
| `UtilitarioService.cs` | `RegistrarErrorBitacora` → `spRegistrarError` (no propaga fallo de bitácora) |

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
| Cédula única | SP | `spRegistrarCliente` → `Resultado = -1` |
| Cliente activo al registrar mascota | SP | `spRegistrarMascota` verifica `Estado = 1` → `-1` |
| Máx. 2 mascotas misma especie/cliente | SP | `spRegistrarMascota` → `-2` |
| Solo clientes activos en dropdown | Controlador | `MascotasController.ObtenerClientesActivos` (LINQ) |
| Mensaje si SP falla | Controlador | `ViewBag.Mensaje` genérico; no distingue código `-1`/`-2` |
| Errores de excepción | Servicio + SP | `UtilitarioService` → `spRegistrarError` |
| Consulta de mascotas | SP | `spConsultarMascotas` (JOIN ordenado por nombre cliente/mascota) |
| Cliente nuevo con `Estado=1` | SP | `spRegistrarCliente` inserta con `Estado = 1` |

---

## 5. Entrega

Incluir: `Practica2.Web.sln`, carpeta `Practica2.Web/`, `Database script.txt`, `Practica2_StoredProcedures.sql`. Excluir `bin/`, `obj/`, `.vs/`.
