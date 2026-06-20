# Practica2.Web

Proyecto ASP.NET MVC 5 para la práctica Clientes / Mascotas.

## Crear el proyecto en Visual Studio

1. **File → New → Project** → ASP.NET Web Application (.NET Framework)
2. Nombre: `Practica2.Web`, ubicación: raíz del workspace (`C:\workspace\Practica 2\`)
3. Plantilla: **MVC**, .NET Framework **4.8.1**
4. Guardar la solución como `Practica2.Web.sln` en la raíz del workspace

## Estructura esperada

```
Practica2.Web/
├── App_Start/       RouteConfig, FilterConfig, BundleConfig
├── Controllers/     ClientesController, MascotasController, HomeController
├── Models/          ClienteModel, MascotaModel (ViewModels)
├── EF/              EDMX + entidades generadas (Practica2Entities)
├── Servicios/       UtilitarioService (bitácora de errores)
├── Views/           Razor por controlador + Shared/_Layout.cshtml
├── Scripts/         Validación jQuery por formulario
├── Content/         CSS (Bootstrap, Mazer)
└── Web.config       Cadena de conexión a Practica2
```

## Base de datos

- Ejecutar `Database script.txt` en SQL Server
- Añadir **ADO.NET Entity Data Model** (Database First) contra `Practica2`
- Contexto sugerido: `Practica2Entities`

## Convenciones

Ver reglas en `.cursor/rules/practica2-*.mdc` (namespace `Practica2.Web`, UI en español).
