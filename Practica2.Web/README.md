# Practica2.Web

Proyecto ASP.NET MVC 5 para la práctica Clientes / Mascotas.

## Requisitos

- Visual Studio 2022 (carga de trabajo ASP.NET)
- SQL Server con la base de datos `Practica2` (script en `Database script.sql`)
- .NET Framework 4.8.1

## Ejecutar

1. Abrir `Practica2.Web.sln` en Visual Studio.
2. Verificar la cadena de conexión `Practica2Entities` en `Web.config`.
3. Establecer `Practica2.Web` como proyecto de inicio.
4. Presionar F5 (IIS Express).

URL local sugerida: `https://localhost:44300/`

## Cadena de conexión

```xml
<add name="Practica2Entities"
     connectionString="data source=localhost;initial catalog=Practica2;integrated security=True;trustservercertificate=True;MultipleActiveResultSets=True;App=EntityFramework"
     providerName="System.Data.SqlClient" />
```

Ajuste `data source` si su instancia de SQL Server no es `localhost`.

## Estructura

```
Practica2.Web/
├── App_Start/       RouteConfig, FilterConfig, BundleConfig
├── Controllers/     ClientesController, MascotasController, HomeController
├── Models/          ClienteModel, MascotaModel, ConsultaMascotaModel
├── EF/              Entidades y Practica2Entities (EF6)
├── Servicios/       UtilitarioService
├── Views/           Razor por controlador + Shared/_Layout.cshtml
├── Scripts/         registrar-cliente.js, registrar-mascota.js
├── Content/         site.css
└── Web.config
```

## Pantallas

| Menú | Ruta | Descripción |
|------|------|-------------|
| Registro de Clientes | `/Clientes/Registrar` | Cédula, Nombre, Correo |
| Registro de Mascotas | `/Mascotas/Registrar` | Nombre, Especie, Raza, Peso, Cliente |
| Consulta de Mascotas | `/Mascotas/Consultar` | Listado con datos de cliente y mascota |

## Reglas de negocio

- Cédula única por cliente
- Máximo 2 mascotas de la misma especie por cliente
- Cliente activo (`Estado = true`) requerido al registrar mascota
- Validación de campos obligatorios en cliente (jQuery Validate)

## Restaurar paquetes (línea de comandos)

```powershell
nuget restore Practica2.Web.sln -PackagesDirectory packages
msbuild Practica2.Web.sln /p:Configuration=Debug
```

## Nota sobre EF

Las entidades en `EF/` están mapeadas manualmente contra la BD existente. En Visual Studio puede regenerar un EDMX Database First si lo prefiere; no modifique el esquema de `Practica2`.
