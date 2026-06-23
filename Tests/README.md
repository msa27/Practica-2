# Practica 2 — Smoke Tests

Verificación automatizada del flujo del **enunciado** sin usar el test runner de Visual Studio.

## Qué cubren

| Prueba | Requisito |
|--------|-----------|
| Registrar cliente (cédula única) | Inserción OK |
| Cédula duplicada rechazada | Segundo insert falla |
| Registrar mascota | Mascota vinculada a cliente activo |
| Máx. 2 misma especie | Tercera mascota rechazada |
| Consulta devuelve datos | JOIN Clientes/Mascotas lista las mascotas |

Con la web en ejecución, también se prueban HTTP: layout, `POST` de clientes/mascotas y `GET /Mascotas/Consultar`.

## Requisitos

- SQL Server con BD `Practica2` creada con **`Database script.txt`** (solo tablas `Clientes` y `Mascotas`)
- `sqlcmd` en el PATH
- (Opcional) IIS Express en `https://localhost:44300/` para pruebas HTTP

**No se requieren stored procedures.** Las pruebas SQL usan INSERT/SELECT directo con las mismas reglas que los controladores MVC.

## Ejecutar

Desde la raíz del repositorio:

```powershell
powershell -ExecutionPolicy Bypass -File "Tests\Run-SmokeTests.ps1"
```

Solo SQL (sin HTTP):

```powershell
powershell -ExecutionPolicy Bypass -File "Tests\Run-SmokeTests.ps1" -SkipHttp
```

URL personalizada: `-BaseUrl "https://localhost:44300/"`. Código de salida `0` = OK; `1` = fallo. Los datos de prueba usan cédula `SMOKE-*` y se limpian solos.
