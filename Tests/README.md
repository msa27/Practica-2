# Practica 2 — Smoke Tests

Automated verification of the **enunciado** business flow without requiring the Visual Studio test runner.

## What is covered

| Test | Requirement |
|------|-------------|
| Register client (unique cédula) | Client insert succeeds (`Resultado = 1`) |
| Duplicate cédula rejected | Second insert with same cédula fails (`Resultado = -1`) |
| Register mascota | Pet linked to active client succeeds |
| Max 2 same species | Third pet of same species fails (`Resultado = -2`) |
| Consulta returns data | `spConsultarMascotas` lists registered pets |

When the web app is running, HTTP tests also verify:

- Home layout with welcome message and menu routes
- `POST /Clientes/Registrar` success redirect and duplicate error message
- `POST /Mascotas/Registrar` success redirect and species limit error
- `GET /Mascotas/Consultar` renders test data in the table

## Prerequisites

- SQL Server with database `Practica2` and stored procedures from `Practica2_StoredProcedures.sql`
- `sqlcmd` on PATH
- (Optional) IIS Express / web app at `https://localhost:44300/` for HTTP tests

## Run

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File "Tests\Run-SmokeTests.ps1"
```

With explicit web URL:

```powershell
powershell -ExecutionPolicy Bypass -File "Tests\Run-SmokeTests.ps1" -BaseUrl "https://localhost:44300/"
```

SQL-only (skip HTTP):

```powershell
powershell -ExecutionPolicy Bypass -File "Tests\Run-SmokeTests.ps1" -SkipHttp
```

Exit code `0` = all executed tests passed; `1` = at least one failure.

Test data uses a unique `SMOKE-*` cédula prefix and is cleaned up automatically.
