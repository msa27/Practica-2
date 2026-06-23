# Practica 2

Aplicación **ASP.NET MVC 5** para gestión de Clientes y Mascotas (BD `Practica2`).

## Contenido del repositorio

| Path | Propósito |
|------|-----------|
| `Practica2.Web.sln` | Solución Visual Studio |
| `Practica2.Web/` | Proyecto MVC implementado |
| `Database script.sql` | Esquema SQL de la BD `Practica2` |
| `Practica2_StoredProcedures.sql` | SPs (`spRegistrarCliente`, etc.) y tabla `tbError` |
| `Enunciado Práctica 2.pdf` | Requisitos funcionales |
| `DOCUMENTACION_EJERCICIO.md` | Documentación corta del ejercicio por archivo |
| `PLAN.md` | Plan completo, checklists y resultados de verificación |
| `Tests/` | Smoke tests automatizados (SQL + HTTP opcional) — ver `Tests/README.md` |
| `APRENDIZAJE.md` | Guía didáctica del código y conceptos MVC |
| `.cursor/rules/` | Reglas Cursor de desarrollo |

## Cómo ejecutar

1. Ejecutar `Database script.sql` en SQL Server (BD `Practica2`).
2. Ejecutar `Practica2_StoredProcedures.sql` (SPs y tabla `tbError`).
3. Abrir `Practica2.Web.sln` en Visual Studio 2022.
4. Restaurar paquetes NuGet (clic derecho en la solución).
5. Revisar `Practica2.Web/Web.config` → cadena `Practica2Entities` (`data source=localhost`).
6. **F5** → IIS Express (`https://localhost:44300/`).

**Smoke tests:** desde la raíz, `powershell -ExecutionPolicy Bypass -File "Tests\Run-SmokeTests.ps1"`. Detalle en `Tests/README.md`.

## Funcionalidad implementada

- Layout con bienvenida y menú (Registro Clientes, Registro Mascotas, Consulta Mascotas)
- Registro de clientes con cédula única
- Registro de mascotas con dropdown de clientes activos (máx. 2 por especie/cliente)
- Consulta de mascotas (cédula, nombre cliente, nombre mascota, especie, peso)
- Validación jQuery en formularios

## Entrega

Empaquetar `Practica2.Web.sln`, carpeta `Practica2.Web/`, `Database script.sql` y `Practica2_StoredProcedures.sql`. Excluir `bin/`, `obj/`, `.vs/` y `RepoKN/`.

**Fecha límite:** Semana 7, 6:00 pm (campus virtual).

## Referencia local (no en Git)

`RepoKN/` puede existir en tu máquina como plantilla antigua del profesor. Está excluida de Git.
