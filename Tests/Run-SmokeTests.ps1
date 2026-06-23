#Requires -Version 5.1
<#
.SYNOPSIS
    Smoke tests for Practica 2 (enunciado flow).

.DESCRIPTION
    Phase 1 - SQL: validates tables Clientes/Mascotas and business rules via direct SQL.
    Phase 2 - HTTP: validates MVC endpoints when the web app is running (optional).

    Uses ONLY the schema from Database script.txt (no stored procedures required).

.PARAMETER SqlServer
    SQL Server instance. Default: localhost

.PARAMETER Database
    Database name. Default: Practica2

.PARAMETER BaseUrl
    Web app base URL (e.g. https://localhost:44300). GET/POST smoke tests run when reachable.

.PARAMETER SkipHttp
    Skip HTTP endpoint tests even if BaseUrl is set.

.EXAMPLE
    .\Run-SmokeTests.ps1

.EXAMPLE
    .\Run-SmokeTests.ps1 -BaseUrl "https://localhost:44300/"
#>
[CmdletBinding()]
param(
    [string]$SqlServer = "localhost",
    [string]$Database = "Practica2",
    [string]$BaseUrl = "",
    [switch]$SkipHttp
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:Passed = 0
$script:Failed = 0
$script:Skipped = 0
$TestRunId = "SMOKE-{0:yyyyMMddHHmmss}" -f (Get-Date)
$TestCedula = "$TestRunId-001"
$TestNombre = "Cliente Smoke Test"
$TestCorreo = "smoke@test.local"

function Write-TestResult {
    param(
        [string]$Name,
        [ValidateSet("PASS", "FAIL", "SKIP")]
        [string]$Status,
        [string]$Detail = ""
    )
    switch ($Status) {
        "PASS" { $script:Passed++; $color = "Green" }
        "FAIL" { $script:Failed++; $color = "Red" }
        "SKIP" { $script:Skipped++; $color = "Yellow" }
    }
    $msg = "[$Status] $Name"
    if ($Detail) { $msg += " - $Detail" }
    Write-Host $msg -ForegroundColor $color
}

function Invoke-SqlScalar {
    param(
        [string]$Query
    )
    $result = sqlcmd -S $SqlServer -d $Database -W -h -1 -Q $Query 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "sqlcmd failed: $result"
    }
    $lines = @($result | Where-Object {
        $_ -and $_.Trim() -ne "" -and $_ -notmatch '^\(\d+ rows? affected\)$'
    })
    if ($lines.Count -eq 0) {
        throw "sqlcmd returned no scalar value."
    }
    return $lines[-1].ToString().Trim()
}

function Invoke-SqlNonQuery {
    param(
        [string]$Query
    )
    $null = sqlcmd -S $SqlServer -d $Database -Q $Query 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "sqlcmd failed executing query."
    }
}

function Test-ClienteCedulaExists {
    param([string]$Cedula)
    $safe = $Cedula.Replace("'", "''")
    $q = "SET NOCOUNT ON; SELECT CASE WHEN EXISTS (SELECT 1 FROM dbo.Clientes WHERE Cedula = N'$safe') THEN 1 ELSE 0 END;"
    return [int](Invoke-SqlScalar -Query $q) -eq 1
}

function Invoke-RegistrarCliente {
    param(
        [string]$Cedula,
        [string]$Nombre,
        [string]$Correo
    )
    if (Test-ClienteCedulaExists -Cedula $Cedula) {
        return -1
    }
    $safeCedula = $Cedula.Replace("'", "''")
    $safeNombre = $Nombre.Replace("'", "''")
    $safeCorreo = $Correo.Replace("'", "''")
    Invoke-SqlNonQuery -Query @"
SET NOCOUNT ON;
INSERT INTO dbo.Clientes (Cedula, Nombre, Correo, Estado)
VALUES (N'$safeCedula', N'$safeNombre', N'$safeCorreo', 1);
"@
    return 1
}

function Invoke-RegistrarMascota {
    param(
        [string]$Nombre,
        [string]$Especie,
        [string]$Raza,
        [decimal]$Peso,
        [long]$IdCliente
    )
    $q = @"
SET NOCOUNT ON;
DECLARE @IdCliente BIGINT = $IdCliente;
DECLARE @Especie NVARCHAR(100) = N'$($Especie.Replace("'", "''"))';
DECLARE @Resultado INT = 0;

IF NOT EXISTS (SELECT 1 FROM dbo.Clientes WHERE IdCliente = @IdCliente AND Estado = 1)
    SET @Resultado = -1;
ELSE IF (SELECT COUNT(*) FROM dbo.Mascotas WHERE IdCliente = @IdCliente AND Especie = @Especie) >= 2
    SET @Resultado = -2;
ELSE
BEGIN
    INSERT INTO dbo.Mascotas (Nombre, Especie, Raza, Peso, IdCliente)
    VALUES (N'$($Nombre.Replace("'", "''"))', @Especie, N'$($Raza.Replace("'", "''"))', $($Peso.ToString([System.Globalization.CultureInfo]::InvariantCulture)), @IdCliente);
    SET @Resultado = 1;
END
SELECT @Resultado;
"@
    return [int](Invoke-SqlScalar -Query $q)
}

function Get-ClienteIdByCedula {
    param([string]$Cedula)
    $q = "SET NOCOUNT ON; SELECT CAST(IdCliente AS BIGINT) FROM dbo.Clientes WHERE Cedula = N'$($Cedula.Replace("'", "''"))';"
    return [long](Invoke-SqlScalar -Query $q)
}

function Get-ConsultaMascotaCount {
    param([string]$Cedula)
    $safe = $Cedula.Replace("'", "''")
    $q = @"
SET NOCOUNT ON;
SELECT COUNT(*)
FROM dbo.Mascotas M
INNER JOIN dbo.Clientes C ON M.IdCliente = C.IdCliente
WHERE C.Cedula = N'$safe';
"@
    return [int](Invoke-SqlScalar -Query $q)
}

function Remove-SmokeTestData {
    param([string]$CedulaPrefix)
    $safePrefix = $CedulaPrefix.Replace("'", "''")
    Invoke-SqlNonQuery -Query @"
SET NOCOUNT ON;
DELETE M FROM dbo.Mascotas M
INNER JOIN dbo.Clientes C ON M.IdCliente = C.IdCliente
WHERE C.Cedula LIKE N'$safePrefix%';
DELETE FROM dbo.Clientes WHERE Cedula LIKE N'$safePrefix%';
"@
}

function Test-SqlPrerequisites {
    Write-Host "`n=== SQL prerequisites ===" -ForegroundColor Cyan
    try {
        $dbOk = Invoke-SqlScalar -Query "SELECT DB_NAME();"
        if ($dbOk -ne $Database) {
            throw "Connected to '$dbOk' instead of '$Database'."
        }
        Write-TestResult "Database connection" "PASS" "$SqlServer / $Database"

        foreach ($table in @("Clientes", "Mascotas")) {
            $exists = Invoke-SqlScalar -Query "SELECT CASE WHEN OBJECT_ID('dbo.$table','U') IS NOT NULL THEN 1 ELSE 0 END;"
            if ([int]$exists -ne 1) {
                throw "Missing table dbo.$table. Run Database script.txt first."
            }
        }
        Write-TestResult "Tables Clientes and Mascotas present" "PASS"
    }
    catch {
        Write-TestResult "SQL prerequisites" "FAIL" $_.Exception.Message
        throw
    }
}

function Test-SqlBusinessFlow {
    Write-Host "`n=== SQL business flow (enunciado) ===" -ForegroundColor Cyan

    Remove-SmokeTestData -CedulaPrefix $TestRunId

    try {
        $r1 = Invoke-RegistrarCliente -Cedula $TestCedula -Nombre $TestNombre -Correo $TestCorreo
        if ($r1 -eq 1) {
            Write-TestResult "Register client (unique cedula)" "PASS" "Resultado=1"
        } else {
            Write-TestResult "Register client (unique cedula)" "FAIL" "Expected 1, got $r1"
        }

        $idCliente = Get-ClienteIdByCedula -Cedula $TestCedula
        if ($idCliente -gt 0) {
            Write-TestResult "Client persisted in DB" "PASS" "IdCliente=$idCliente"
        } else {
            Write-TestResult "Client persisted in DB" "FAIL" "IdCliente not found"
        }

        $rDup = Invoke-RegistrarCliente -Cedula $TestCedula -Nombre "Otro" -Correo "dup@test.local"
        if ($rDup -eq -1) {
            Write-TestResult "Duplicate cedula rejected" "PASS" "Resultado=-1"
        } else {
            Write-TestResult "Duplicate cedula rejected" "FAIL" "Expected -1, got $rDup"
        }

        $rPet1 = Invoke-RegistrarMascota -Nombre "Firulais" -Especie "Perro" -Raza "Labrador" -Peso 12.5 -IdCliente $idCliente
        if ($rPet1 -eq 1) {
            Write-TestResult "Register mascota (1st Perro)" "PASS"
        } else {
            Write-TestResult "Register mascota (1st Perro)" "FAIL" "Expected 1, got $rPet1"
        }

        $rPet2 = Invoke-RegistrarMascota -Nombre "Max" -Especie "Perro" -Raza "Beagle" -Peso 10.0 -IdCliente $idCliente
        if ($rPet2 -eq 1) {
            Write-TestResult "Register mascota (2nd Perro)" "PASS"
        } else {
            Write-TestResult "Register mascota (2nd Perro)" "FAIL" "Expected 1, got $rPet2"
        }

        $rPet3 = Invoke-RegistrarMascota -Nombre "Rocky" -Especie "Perro" -Raza "Bulldog" -Peso 15.0 -IdCliente $idCliente
        if ($rPet3 -eq -2) {
            Write-TestResult "Max 2 same species rejected" "PASS" "Resultado=-2"
        } else {
            Write-TestResult "Max 2 same species rejected" "FAIL" "Expected -2, got $rPet3"
        }

        $consultaCount = Get-ConsultaMascotaCount -Cedula $TestCedula
        if ($consultaCount -ge 2) {
            Write-TestResult "Consulta returns registered mascotas" "PASS" "Rows for test client: $consultaCount"
        } else {
            Write-TestResult "Consulta returns registered mascotas" "FAIL" "Expected >= 2 rows, got $consultaCount"
        }
    }
    finally {
        Remove-SmokeTestData -CedulaPrefix $TestRunId
        Write-Host "Cleaned up smoke test data ($TestRunId)." -ForegroundColor DarkGray
    }
}

function Enable-TlsSkipCertValidation {
    if (-not ([System.Management.Automation.PSTypeName]"TrustAllCertsPolicy").Type) {
        Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(ServicePoint sp, X509Certificate cert, WebRequest req, int problem) { return true; }
}
"@
    }
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
}

function Invoke-WebFormPost {
    param(
        [string]$Url,
        [hashtable]$FormFields,
        [Microsoft.PowerShell.Commands.WebRequestSession]$Session
    )
    Enable-TlsSkipCertValidation
    $body = ($FormFields.GetEnumerator() | ForEach-Object {
        "{0}={1}" -f [uri]::EscapeDataString($_.Key), [uri]::EscapeDataString([string]$_.Value)
    }) -join "&"
    return Invoke-WebRequest -Uri $Url -Method Post -Body $body -ContentType "application/x-www-form-urlencoded" `
        -WebSession $Session -MaximumRedirection 0 -ErrorAction SilentlyContinue -UseBasicParsing
}

function Test-HttpEndpoints {
    param([string]$Url)

    Write-Host "`n=== HTTP endpoint smoke tests ===" -ForegroundColor Cyan
    $base = $Url.TrimEnd("/")
    $httpCedula = "$TestRunId-HTTP"
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

    Enable-TlsSkipCertValidation

    try {
        $homeResp = Invoke-WebRequest -Uri "$base/" -WebSession $session -UseBasicParsing -TimeoutSec 10
        if ($homeResp.StatusCode -eq 200 -and $homeResp.Content -match "Bienvenido") {
            Write-TestResult "Home page loads (layout/welcome)" "PASS"
        } else {
            Write-TestResult "Home page loads (layout/welcome)" "FAIL" "Status $($homeResp.StatusCode)"
        }

        $clientGet = Invoke-WebRequest -Uri "$base/Clientes/Registrar" -WebSession $session -UseBasicParsing -TimeoutSec 10
        if ($clientGet.StatusCode -eq 200 -and $clientGet.Content -match "Registro de Clientes") {
            Write-TestResult "GET /Clientes/Registrar" "PASS"
        } else {
            Write-TestResult "GET /Clientes/Registrar" "FAIL"
        }

        $clientPost = Invoke-WebFormPost -Url "$base/Clientes/Registrar" -Session $session -FormFields @{
            Cedula = $httpCedula
            Nombre = "HTTP Cliente"
            Correo = "http@test.local"
        }
        if ($clientPost.StatusCode -eq 302) {
            Write-TestResult "POST register client (success redirect)" "PASS" "Location: $($clientPost.Headers.Location)"
        } else {
            Write-TestResult "POST register client (success redirect)" "FAIL" "Status $($clientPost.StatusCode)"
        }

        $dupPost = Invoke-WebFormPost -Url "$base/Clientes/Registrar" -Session $session -FormFields @{
            Cedula = $httpCedula
            Nombre = "Duplicado"
            Correo = "dup2@test.local"
        }
        if ($dupPost.StatusCode -eq 200 -and $dupPost.Content -match "no se ha podido registrar") {
            Write-TestResult "POST duplicate cedula shows error" "PASS"
        } else {
            Write-TestResult "POST duplicate cedula shows error" "FAIL" "Status $($dupPost.StatusCode)"
        }

        $idCliente = Get-ClienteIdByCedula -Cedula $httpCedula

        $mascGet = Invoke-WebRequest -Uri "$base/Mascotas/Registrar" -WebSession $session -UseBasicParsing -TimeoutSec 10
        if ($mascGet.StatusCode -eq 200 -and $mascGet.Content -match "Registro de Mascotas") {
            Write-TestResult "GET /Mascotas/Registrar" "PASS"
        } else {
            Write-TestResult "GET /Mascotas/Registrar" "FAIL"
        }

        foreach ($petName in @("HttpPet1", "HttpPet2")) {
            $petPost = Invoke-WebFormPost -Url "$base/Mascotas/Registrar" -Session $session -FormFields @{
                IdCliente = [string]$idCliente
                Nombre    = $petName
                Especie   = "Gato"
                Raza      = "Siames"
                Peso      = "4.50"
            }
            if ($petPost.StatusCode -eq 302) {
                Write-TestResult "POST register mascota ($petName)" "PASS"
            } else {
                Write-TestResult "POST register mascota ($petName)" "FAIL" "Status $($petPost.StatusCode)"
            }
        }

        $petFail = Invoke-WebFormPost -Url "$base/Mascotas/Registrar" -Session $session -FormFields @{
            IdCliente = [string]$idCliente
            Nombre    = "HttpPet3"
            Especie   = "Gato"
            Raza      = "Persa"
            Peso      = "5.00"
        }
        if ($petFail.StatusCode -eq 200 -and $petFail.Content -match "no se ha podido registrar") {
            Write-TestResult "POST 3rd same species shows error" "PASS"
        } else {
            Write-TestResult "POST 3rd same species shows error" "FAIL" "Status $($petFail.StatusCode)"
        }

        $consulta = Invoke-WebRequest -Uri "$base/Mascotas/Consultar" -WebSession $session -UseBasicParsing -TimeoutSec 10
        if ($consulta.StatusCode -eq 200 -and $consulta.Content -match $httpCedula -and $consulta.Content -match "HttpPet1") {
            Write-TestResult "GET /Mascotas/Consultar shows data" "PASS"
        } else {
            Write-TestResult "GET /Mascotas/Consultar shows data" "FAIL"
        }
    }
    catch {
        Write-TestResult "HTTP smoke tests" "FAIL" $_.Exception.Message
    }
    finally {
        Remove-SmokeTestData -CedulaPrefix "$TestRunId-HTTP"
    }
}

function Resolve-BaseUrl {
    if ($BaseUrl) { return $BaseUrl }
    return "https://localhost:44300/"
}

function Test-WebAppReachable {
    param([string]$Url)
    try {
        Enable-TlsSkipCertValidation
        $uri = ($Url.TrimEnd("/")) + "/"
        $r = Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec 5
        return ($r.StatusCode -eq 200)
    }
    catch {
        return $false
    }
}

# --- Main ---
Write-Host "Practica 2 smoke tests ($TestRunId)" -ForegroundColor White

Test-SqlPrerequisites
Test-SqlBusinessFlow

if (-not $SkipHttp) {
    $resolvedUrl = Resolve-BaseUrl
    if (Test-WebAppReachable -Url $resolvedUrl) {
        Test-HttpEndpoints -Url $resolvedUrl
    }
    else {
        Write-Host "`n=== HTTP endpoint smoke tests ===" -ForegroundColor Cyan
        Write-TestResult "HTTP tests (web app not running)" "SKIP" "Start IIS Express (F5) and rerun with -BaseUrl '$resolvedUrl'"
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Passed: $script:Passed  Failed: $script:Failed  Skipped: $script:Skipped"

if ($script:Failed -gt 0) {
    exit 1
}
exit 0
