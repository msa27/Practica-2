# Plan de implementación — Práctica 2

> **Proyecto:** `Practica2.Web` (ASP.NET MVC 5)  
> **Base de datos:** `Practica2` en SQL Server (`localhost`)  
> **Repositorio:** https://github.com/msa27/Practica-2.git  
> **Estado base:** commit `56041d3+` — aplicación funcional implementada  
> **Auditoría (jun 2026):** el código en `Practica2.Web/` coincide con las fases 0–6. La documentación describe código existente, no diseños pendientes. Ver `APRENDIZAJE.md` sección 0 para el inventario archivo por archivo.

---

## 1. Objetivo de la práctica

Desarrollar una aplicación web con **ASP.NET MVC 5** que permita a una clínica veterinaria:

1. **Registrar clientes** con cédula, nombre y correo (cédula única).
2. **Registrar mascotas** asociadas a un cliente activo (máximo 2 mascotas de la misma especie por cliente).
3. **Consultar mascotas** mostrando cédula y nombre del cliente, nombre de la mascota, especie y peso.

La interfaz debe incluir una página de bienvenida y un menú lateral con las tres opciones anteriores. Los campos obligatorios se validan en el **cliente** con jQuery Validate; en el **servidor** se aplican las **reglas de negocio** en los controladores (no hay `[Required]`/`ModelState` para campos vacíos).

---

## 2. Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                     Navegador (Browser)                     │
│  Bootstrap 5 + jQuery Validate + Scripts/*.js               │
└──────────────────────────┬──────────────────────────────────┘
                           │ HTTP (GET/POST)
┌──────────────────────────▼──────────────────────────────────┐
│              Capa de presentación (Views/)                  │
│  Razor (.cshtml) — formularios, tablas, layout Mazer        │
└──────────────────────────┬──────────────────────────────────┘
                           │ Model / ViewBag
┌──────────────────────────▼──────────────────────────────────┐
│           Capa de control (Controllers/)                    │
│  HomeController, ClientesController, MascotasController     │
│  Reglas de negocio en SPs + LINQ (dropdown) + manejo de errores │
└──────────────────────────┬──────────────────────────────────┘
                           │ ViewModels (Models/)
┌──────────────────────────▼──────────────────────────────────┐
│           Capa de acceso a datos (EF/)                      │
│  Entity Framework 6 Database First — Model1.edmx,            │
│  Practica2Entities, SPs importados, DbSet<Clientes/Mascotas> │
└──────────────────────────┬──────────────────────────────────┘
                           │ ADO.NET / T-SQL
┌──────────────────────────▼──────────────────────────────────┐
│              SQL Server — BD Practica2                      │
│  Tablas: Clientes (1) ──< Mascotas (N), tbError            │
│  SPs: spRegistrarCliente, spRegistrarMascota,                │
│       spConsultarMascotas, spRegistrarError                 │
└─────────────────────────────────────────────────────────────┘
```

| Componente | Tecnología | Ubicación |
|------------|------------|-----------|
| Framework web | ASP.NET MVC 5, .NET 4.8 | `Practica2.Web/` |
| ORM | Entity Framework 6 (Database First / EDMX `Model1.edmx`) | `Practica2.Web/EF/` |
| ViewModels | Clases POCO en español | `Practica2.Web/Models/` |
| Validación cliente | jQuery Validation 1.19.5 | `Practica2.Web/Scripts/` |
| Estilos | Bootstrap 5 + CSS Mazer | `Views/Shared/_Layout.cshtml`, `Content/site.css` |
| Bitácora errores | `UtilitarioService` → `spRegistrarError` / `tbError` | `Practica2.Web/Servicios/` |
| Conexión BD | `Practica2Entities` en `Web.config` | Integrated Security → `localhost` |

---

## 3. Fases de implementación

### Fase 0 — Preparación del entorno ✅

| Paso | Descripción | Verificación |
|------|-------------|--------------|
| 0.1 | Ejecutar `Database script.sql` y `Practica2_StoredProcedures.sql` | BD `Practica2` + SPs + `tbError` |
| 0.2 | Crear solución `Practica2.Web.sln` y proyecto MVC 5 | Proyecto compila |
| 0.3 | Configurar cadena de conexión en `Web.config` | `Practica2Entities` apunta a `localhost` |
| 0.4 | Restaurar paquetes NuGet (EF6, MVC, jQuery, etc.) | Carpeta `packages/` presente |

### Fase 1 — Modelo de datos y EF (EDMX) ✅

| Paso | Descripción | Archivos |
|------|-------------|----------|
| 1.1 | Modelo Database First desde BD `Practica2` | `EF/Model1.edmx`, entidades generadas |
| 1.2 | Importar SPs al EDMX | `spRegistrarCliente`, `spRegistrarMascota`, `spConsultarMascotas`, `spRegistrarError` |
| 1.3 | Crear ViewModels separados de entidades EF | `Models/ClienteModel.cs`, `MascotaModel.cs`, `ConsultaMascotaModel.cs` |

### Fase 2 — Layout y navegación ✅

| Paso | Descripción | Archivos |
|------|-------------|----------|
| 2.1 | Layout con sidebar y mensaje de bienvenida | `Views/Shared/_Layout.cshtml` |
| 2.2 | Página de inicio | `Views/Home/Index.cshtml`, `HomeController.cs` |
| 2.3 | Menú: Registro Clientes, Registro Mascotas, Consulta Mascotas | Enlaces en `_Layout.cshtml` |

### Fase 3 — Registro de clientes ✅

| Paso | Descripción | Regla de negocio |
|------|-------------|------------------|
| 3.1 | Vista GET con formulario vacío | — |
| 3.2 | Vista POST: `spRegistrarCliente` (cédula única en SP) | `@Resultado = 1` éxito, `-1` cédula duplicada |
| 3.3 | Validación jQuery (campos obligatorios, email) | `Scripts/registrar-cliente.js` |
| 3.4 | Mensaje de error vía `ViewBag.Mensaje` si falla | Texto: *"La información no se ha podido registrar"* |
| 3.5 | Redirección a Home tras éxito | `RedirectToAction("Index", "Home")` |

### Fase 4 — Registro de mascotas ✅

| Paso | Descripción | Regla de negocio |
|------|-------------|------------------|
| 4.1 | Dropdown de clientes activos (`Estado == true`) | Solo clientes activos |
| 4.2 | `spRegistrarMascota` valida cliente activo | Rechazar si inactivo o inexistente (`@Resultado = -2`) |
| 4.3 | `spRegistrarMascota` cuenta especie por cliente | Máximo 2 por especie/cliente (`@Resultado = -3`) |
| 4.4 | Validación jQuery (todos los campos, peso numérico ≥ 0.01) | `Scripts/registrar-mascota.js` |
| 4.5 | Redirección a consulta tras éxito | `RedirectToAction("Consultar")` |

### Fase 5 — Consulta de mascotas ✅

| Paso | Descripción | Columnas mostradas |
|------|-------------|-------------------|
| 5.1 | `spConsultarMascotas()` (JOIN en SQL) | Cédula, nombre cliente, nombre mascota, especie, peso |
| 5.2 | Tabla Bootstrap en vista Razor | `Views/Mascotas/Consultar.cshtml` |
| 5.3 | Mensaje si no hay registros | *"No hay mascotas registradas."* |

### Fase 6 — Manejo de errores ✅

| Paso | Descripción | Archivos |
|------|-------------|----------|
| 6.1 | try/catch en todas las acciones de controlador | `Controllers/*.cs` |
| 6.2 | Registrar error con `UtilitarioService` → `spRegistrarError` | `Servicios/UtilitarioService.cs`, tabla `tbError` |
| 6.3 | Vista de error genérica | `Views/Shared/Error.cshtml` |

### Fase 7 — Verificación y entrega (este plan)

| Paso | Descripción | Estado |
|------|-------------|--------|
| 7.1 | Verificar BD con `sqlcmd` | ✅ Ejecutado (jun 2026) |
| 7.2 | Compilar solución con MSBuild | ✅ Ejecutado (jun 2026) |
| 7.3 | Auditar código vs documentación | ✅ Ejecutado — ver `APRENDIZAJE.md` §0 |
| 7.4 | Pruebas manuales en IIS Express | Pendiente usuario |
| 7.5 | Empaquetar entrega campus | Pendiente usuario |
| 7.6 | Documentación `PLAN.md` y `APRENDIZAJE.md` | Actualizada tras auditoría |

---

## 4. Checklist de pruebas manuales

### Base de datos

- [ ] BD `Practica2` existe en SQL Server
- [ ] Ejecutar `Practica2_StoredProcedures.sql` (SPs + `tbError`)
- [ ] Tablas `Clientes`, `Mascotas` y `tbError` con columnas correctas
- [ ] FK `FK_Mascotas_Clientes` activa

### Navegación y layout

- [ ] Al abrir la app se muestra bienvenida en `Home/Index`
- [ ] Sidebar muestra 3 opciones de menú
- [ ] Cada enlace lleva a la vista correcta

### Registro de clientes (`/Clientes/Registrar`)

- [ ] Enviar formulario vacío → jQuery muestra errores de campos obligatorios
- [ ] Correo inválido → mensaje de formato no válido
- [ ] Registrar cliente válido → redirección a Home
- [ ] Repetir misma cédula → mensaje *"La información no se ha podido registrar"*
- [ ] Verificar en BD: nuevo registro con `Estado = 1`

### Registro de mascotas (`/Mascotas/Registrar`)

- [ ] Dropdown solo muestra clientes activos
- [ ] Formulario vacío → validación jQuery
- [ ] Peso no numérico o ≤ 0 → error de validación
- [ ] Registrar 1ª y 2ª mascota misma especie → OK
- [ ] Registrar 3ª mascota misma especie → mensaje de error
- [ ] Tras éxito → redirección a Consulta

### Consulta de mascotas (`/Mascotas/Consultar`)

- [ ] Tabla muestra: cédula, nombre cliente, nombre mascota, especie, peso
- [ ] Peso formateado con 2 decimales
- [ ] Sin datos → mensaje *"No hay mascotas registradas."*

### Errores

- [ ] Desconectar BD temporalmente → vista `Error` (opcional, avanzado)
- [ ] Errores registrados en tabla `tbError` (vía `spRegistrarError`)

---

## 5. Checklist de entrega campus

- [ ] Incluir `Practica2.Web.sln`
- [ ] Incluir carpeta `Practica2.Web/` completa (código fuente)
- [ ] Incluir `Database script.sql` y `Practica2_StoredProcedures.sql`
- [ ] **Excluir:** `bin/`, `obj/`, `.vs/`, `packages/` (opcional según indicaciones del profesor), `RepoKN/`
- [ ] Verificar que la cadena de conexión use `localhost` e Integrated Security
- [ ] Probar compilación en Visual Studio 2022 antes de subir
- [ ] Subir al campus virtual antes de la fecha límite
- [ ] Incluir documentación de aprendizaje (`APRENDIZAJE.md`) si lo solicita el profesor

---

## 6. Cronograma / fecha límite

| Hito | Fecha | Notas |
|------|-------|-------|
| Creación BD y proyecto MVC | Semanas 1–4 | Fases 0–2 |
| Registro clientes y mascotas | Semanas 4–6 | Fases 3–4 |
| Consulta y validaciones | Semana 6 | Fase 5 |
| Pruebas y documentación | Semana 7 | Fases 6–7 |
| **Entrega final** | **Semana 7, 6:00 pm** | Campus virtual |

---

## 7. Comandos útiles

### SQL Server — verificación de BD

```powershell
# Comprobar que existe la BD
sqlcmd -S localhost -E -Q "SELECT name FROM sys.databases WHERE name = 'Practica2'"

# Listar tablas
sqlcmd -S localhost -E -d Practica2 -Q "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'"

# Ver esquema de columnas y FK
sqlcmd -S localhost -E -d Practica2 -Q "SELECT c.name, t.name AS tipo FROM sys.columns c JOIN sys.types t ON c.user_type_id = t.user_type_id WHERE object_id = OBJECT_ID('dbo.Clientes')"

# Contar registros
sqlcmd -S localhost -E -d Practica2 -Q "SELECT COUNT(*) FROM Clientes; SELECT COUNT(*) FROM Mascotas"

# Verificar cédulas duplicadas (debe devolver 0 filas)
sqlcmd -S localhost -E -d Practica2 -Q "SELECT Cedula, COUNT(*) FROM Clientes GROUP BY Cedula HAVING COUNT(*) > 1"

# Verificar regla de 2 mascotas por especie (debe devolver 0 filas)
sqlcmd -S localhost -E -d Practica2 -Q "SELECT IdCliente, Especie, COUNT(*) FROM Mascotas GROUP BY IdCliente, Especie HAVING COUNT(*) > 2"
```

### Crear BD desde script

```powershell
sqlcmd -S localhost -E -i "C:\workspace\Practica 2\Database script.sql"
sqlcmd -S localhost -E -i "C:\workspace\Practica 2\Practica2_StoredProcedures.sql"
```

### NuGet y compilación

```powershell
# Restaurar paquetes (Visual Studio 2022 Community)
& "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" `
  "C:\workspace\Practica 2\Practica2.Web.sln" /t:Restore /p:RestorePackagesConfig=true

# Compilar Debug
& "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" `
  "C:\workspace\Practica 2\Practica2.Web.sln" /t:Build /p:Configuration=Debug /verbosity:minimal
```

### Ejecutar la aplicación

1. Abrir `Practica2.Web.sln` en Visual Studio 2022.
2. Establecer `Practica2.Web` como proyecto de inicio.
3. Presionar **F5** → IIS Express en `https://localhost:44300/`.

### Git

```powershell
cd "C:\workspace\Practica 2"
git status
git add PLAN.md APRENDIZAJE.md
git commit -m "Agregar plan de implementacion y guia de aprendizaje."
git push origin main
```

---

## 8. Resultados de ejecución del plan (verificación automatizada)

Última verificación: **junio 2026** (auditoría código + `sqlcmd` + MSBuild).

| Verificación | Resultado | Detalle |
|--------------|-----------|---------|
| Código fuente fases 0–6 | ✅ OK | Controladores, vistas, EF, scripts y layout presentes |
| BD `Practica2` existe | ✅ OK | Confirmado con `sqlcmd` |
| Tablas `Clientes`, `Mascotas`, `tbError` | ✅ OK | Script base + `Practica2_StoredProcedures.sql` |
| SPs importados en EDMX | ✅ OK | 4 procedimientos en `Model1.edmx` |
| FK `FK_Mascotas_Clientes` | ✅ OK | Presente en script SQL |
| Compilación MSBuild Debug | ✅ OK | `Practica2.Web.dll` generado sin errores |
| Pruebas manuales navegador | ⏳ Pendiente | Requiere F5 en Visual Studio |

---

*Documento generado como parte de la verificación y entrega de la Práctica 2.*
