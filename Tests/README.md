# Practica 2 — Smoke Tests

Verificación automatizada del flujo del **enunciado** sin usar el test runner de Visual Studio.

## Qué cubren

| Prueba | Requisito |
|--------|-----------|
| Registrar cliente (cédula única) | Inserción OK (`Resultado = 1`) |
| Cédula duplicada rechazada | Segundo insert falla (`Resultado = -1`) |
| Registrar mascota | Mascota vinculada a cliente activo |
| Máx. 2 misma especie | Tercera mascota falla (`Resultado = -2`) |
| Consulta devuelve datos | `spConsultarMascotas` lista las mascotas |

Con la web en ejecución, también se prueban HTTP: layout, `POST` de clientes/mascotas y `GET /Mascotas/Consultar`.

## Requisitos

- SQL Server con BD `Practica2` y SPs de `Practica2_StoredProcedures.sql`
- `sqlcmd` en el PATH
- (Opcional) IIS Express en `https://localhost:44300/` para pruebas HTTP

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
