#Requires -Version 5.1
<#
.SYNOPSIS
    Smoke tests for Practica 2 (enunciado flow).

.DESCRIPTION
    Phase 1 - SQL: validates stored procedures (cedula unica, max 2 especies, consulta).
    Phase 2 - HTTP: validates MVC endpoints when the web app is running (optional).

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
    [switch]$SkipHttp,
    [int]$HttpTimeoutSec = 45
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

function Invoke-SpRegistrarCliente {
    param(
        [string]$Cedula,
        [string]$Nombre,
        [string]$Correo
    )
    $q = @"
DECLARE @r INT;
EXEC dbo.spRegistrarCliente
    @Cedula = N'$($Cedula.Replace("'", "''"))',
    @Nombre = N'$($Nombre.Replace("'", "''"))',
    @Correo = N'$($Correo.Replace("'", "''"))',
    @Resultado = @r OUTPUT;
SELECT @r;
"@
    return [int](Invoke-SqlScalar -Query $q)
}

function Invoke-SpRegistrarMascota {
    param(
        [string]$Nombre,
        [string]$Especie,
        [string]$Raza,
        [decimal]$Peso,
        [long]$IdCliente
    )
    $pesoText = $Peso.ToString([System.Globalization.CultureInfo]::InvariantCulture)
    $q = @"
DECLARE @r INT;
EXEC dbo.spRegistrarMascota
    @Nombre = N'$($Nombre.Replace("'", "''"))',
    @Especie = N'$($Especie.Replace("'", "''"))',
    @Raza = N'$($Raza.Replace("'", "''"))',
    @Peso = $pesoText,
    @IdCliente = $IdCliente,
    @Resultado = @r OUTPUT;
SELECT @r;
"@
    return [int](Invoke-SqlScalar -Query $q)
}

function Get-ClienteIdByCedula {
    param([string]$Cedula)
    $q = "SET NOCOUNT ON; SELECT CAST(IdCliente AS BIGINT) FROM dbo.Clientes WHERE Cedula = N'$($Cedula.Replace("'", "''"))';"
    return [long](Invoke-SqlScalar -Query $q)
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

        foreach ($sp in @("spRegistrarCliente", "spRegistrarMascota", "spConsultarMascotas")) {
            $exists = Invoke-SqlScalar -Query "SELECT CASE WHEN OBJECT_ID('dbo.$sp','P') IS NOT NULL THEN 1 ELSE 0 END;"
            if ([int]$exists -ne 1) {
                throw "Missing stored procedure dbo.$sp. Run Practica2_StoredProcedures.sql first."
            }
        }
        Write-TestResult "Stored procedures present" "PASS"
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
        # 1. Register client (unique cedula)
        $r1 = Invoke-SpRegistrarCliente -Cedula $TestCedula -Nombre $TestNombre -Correo $TestCorreo
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

        # 2. Duplicate cedula fails
        $rDup = Invoke-SpRegistrarCliente -Cedula $TestCedula -Nombre "Otro" -Correo "dup@test.local"
        if ($rDup -eq -1) {
            Write-TestResult "Duplicate cedula rejected" "PASS" "Resultado=-1"
        } else {
            Write-TestResult "Duplicate cedula rejected" "FAIL" "Expected -1, got $rDup"
        }

        # 3. Register mascota
        $rPet1 = Invoke-SpRegistrarMascota -Nombre "Firulais" -Especie "Perro" -Raza "Labrador" -Peso 12.5 -IdCliente $idCliente
        if ($rPet1 -eq 1) {
            Write-TestResult "Register mascota (1st Perro)" "PASS"
        } else {
            Write-TestResult "Register mascota (1st Perro)" "FAIL" "Expected 1, got $rPet1"
        }

        # 4. Second same species succeeds
        $rPet2 = Invoke-SpRegistrarMascota -Nombre "Max" -Especie "Perro" -Raza "Beagle" -Peso 10.0 -IdCliente $idCliente
        if ($rPet2 -eq 1) {
            Write-TestResult "Register mascota (2nd Perro)" "PASS"
        } else {
            Write-TestResult "Register mascota (2nd Perro)" "FAIL" "Expected 1, got $rPet2"
        }

        # 5. Max 2 same species fails
        $rPet3 = Invoke-SpRegistrarMascota -Nombre "Rocky" -Especie "Perro" -Raza "Bulldog" -Peso 15.0 -IdCliente $idCliente
        if ($rPet3 -eq -2) {
            Write-TestResult "Max 2 same species rejected" "PASS" "Resultado=-2"
        } else {
            Write-TestResult "Max 2 same species rejected" "FAIL" "Expected -2, got $rPet3"
        }

        # 6. Consulta returns data
        $consultaCount = [int](Invoke-SqlScalar -Query @"
SET NOCOUNT ON;
DECLARE @t TABLE (CedulaCliente VARCHAR(50), NombreCliente VARCHAR(100), NombreMascota VARCHAR(100), Especie VARCHAR(100), Peso DECIMAL(8,2));
INSERT INTO @t EXEC dbo.spConsultarMascotas;
SELECT COUNT(*) FROM @t WHERE CedulaCliente = N'$($TestCedula.Replace("'", "''"))';
"@)
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
        -WebSession $Session -MaximumRedirection 0 -ErrorAction SilentlyContinue -UseBasicParsing -TimeoutSec $HttpTimeoutSec
}

function Warmup-HttpApp {
    param(
        [string]$Base,
        [Microsoft.PowerShell.Commands.WebRequestSession]$Session,
        [int]$TimeoutSec
    )
    $null = Invoke-WebRequest -Uri "$Base/Clientes/Registrar" -WebSession $Session -UseBasicParsing -TimeoutSec $TimeoutSec
    $null = Invoke-WebRequest -Uri "$Base/Mascotas/Registrar" -WebSession $Session -UseBasicParsing -TimeoutSec $TimeoutSec
}

function Test-HttpEndpoints {
    param([string]$Url)

    Write-Host "`n=== HTTP endpoint smoke tests ===" -ForegroundColor Cyan
    $base = $Url.TrimEnd("/")
    $httpCedula = "$TestRunId-HTTP"
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

    Enable-TlsSkipCertValidation

    try {
        Warmup-HttpApp -Base $base -Session $session -TimeoutSec $HttpTimeoutSec
        $homeResp = Invoke-WebRequest -Uri "$base/" -WebSession $session -UseBasicParsing -TimeoutSec $HttpTimeoutSec
        if ($homeResp.StatusCode -eq 200 -and $homeResp.Content -match "Bienvenido") {
            Write-TestResult "Home page loads (layout/welcome)" "PASS"
        } else {
            Write-TestResult "Home page loads (layout/welcome)" "FAIL" "Status $($homeResp.StatusCode)"
        }

        $clientGet = Invoke-WebRequest -Uri "$base/Clientes/Registrar" -WebSession $session -UseBasicParsing -TimeoutSec $HttpTimeoutSec
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

        $mascGet = Invoke-WebRequest -Uri "$base/Mascotas/Registrar" -WebSession $session -UseBasicParsing -TimeoutSec $HttpTimeoutSec
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

        $consulta = Invoke-WebRequest -Uri "$base/Mascotas/Consultar" -WebSession $session -UseBasicParsing -TimeoutSec $HttpTimeoutSec
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
        $r = Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec 15
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
