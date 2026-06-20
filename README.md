# Practica 2

Proyecto **ASP.NET MVC 5** para la práctica Clientes / Mascotas, desarrollado desde cero.

## Contenido del repositorio

| Path | Propósito |
|------|-----------|
| `Database script.txt` | Esquema SQL de la BD `Practica2` |
| `Enunciado Práctica 2.pdf` | Requisitos funcionales |
| `.cursor/rules/` | Reglas Cursor (`practica2-*`, `workspace-overview`) |
| `Practica2.Web/` | Proyecto web MVC (código de la práctica) |
| `Practica2.Web.sln` | Solución Visual Studio |

## Referencia local (no en Git)

La carpeta **`RepoKN/`** puede existir en tu máquina como copia de la plantilla del profesor. Ya **no forma parte del flujo de desarrollo**: los patrones están en `.cursor/rules/practica2-*.mdc`. Toda `RepoKN/` está excluida de Git (`.gitignore`).

## Primeros pasos

1. Ejecutar `Database script.txt` en SQL Server (crea la BD `Practica2`).
2. Crear el proyecto MVC en Visual Studio (ver `Practica2.Web/README.md`).
3. Añadir modelo EF6 Database First apuntando a `Practica2`.
4. Implementar `ClientesController`, `MascotasController` y vistas según el enunciado.

## Requisitos principales

- Layout con bienvenida y 3 opciones de menú
- Registro de clientes (cédula única)
- Registro de mascotas (máx. 2 por especie por cliente)
- Consulta de mascotas por cédula/nombre de cliente
