USE [Practica2]
GO

-- Bitácora de errores (tabla auxiliar, no modifica Clientes/Mascotas)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tbError' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[tbError](
        [Consecutivo] [int] IDENTITY(1,1) NOT NULL,
        [Fecha] [datetime] NOT NULL,
        [Mensaje] [varchar](500) NOT NULL,
        [Lugar] [varchar](100) NOT NULL,
        [Usuario] [int] NOT NULL,
     CONSTRAINT [PK_tbError] PRIMARY KEY CLUSTERED ([Consecutivo] ASC)
    ) ON [PRIMARY]
END
GO

IF OBJECT_ID('dbo.spRegistrarError', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[spRegistrarError]
GO

CREATE PROCEDURE [dbo].[spRegistrarError]
    @Mensaje VARCHAR(500),
    @Lugar VARCHAR(100),
    @Usuario INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @vFecha DATETIME = GETDATE();

    INSERT INTO [dbo].[tbError] ([Fecha], [Mensaje], [Lugar], [Usuario])
    VALUES (@vFecha, @Mensaje, @Lugar, @Usuario);
END
GO

IF OBJECT_ID('dbo.spRegistrarCliente', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[spRegistrarCliente]
GO

CREATE PROCEDURE [dbo].[spRegistrarCliente]
    @Cedula VARCHAR(50),
    @Nombre VARCHAR(100),
    @Correo VARCHAR(100),
    @Resultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    IF EXISTS (SELECT 1 FROM [dbo].[Clientes] WHERE [Cedula] = @Cedula)
    BEGIN
        SET @Resultado = -1;
        RETURN;
    END

    INSERT INTO [dbo].[Clientes] ([Cedula], [Nombre], [Correo], [Estado])
    VALUES (@Cedula, @Nombre, @Correo, 1);

    IF @@ROWCOUNT > 0
        SET @Resultado = 1;
END
GO

IF OBJECT_ID('dbo.spRegistrarMascota', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[spRegistrarMascota]
GO

CREATE PROCEDURE [dbo].[spRegistrarMascota]
    @Nombre VARCHAR(100),
    @Especie VARCHAR(100),
    @Raza VARCHAR(100),
    @Peso DECIMAL(8, 2),
    @IdCliente BIGINT,
    @Resultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    IF NOT EXISTS (SELECT 1 FROM [dbo].[Clientes] WHERE [IdCliente] = @IdCliente AND [Estado] = 1)
    BEGIN
        SET @Resultado = -1;
        RETURN;
    END

    IF (SELECT COUNT(*) FROM [dbo].[Mascotas]
        WHERE [IdCliente] = @IdCliente AND [Especie] = @Especie) >= 2
    BEGIN
        SET @Resultado = -2;
        RETURN;
    END

    INSERT INTO [dbo].[Mascotas] ([Nombre], [Especie], [Raza], [Peso], [IdCliente])
    VALUES (@Nombre, @Especie, @Raza, @Peso, @IdCliente);

    IF @@ROWCOUNT > 0
        SET @Resultado = 1;
END
GO

IF OBJECT_ID('dbo.spConsultarMascotas', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[spConsultarMascotas]
GO

CREATE PROCEDURE [dbo].[spConsultarMascotas]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        C.[Cedula] AS CedulaCliente,
        C.[Nombre] AS NombreCliente,
        M.[Nombre] AS NombreMascota,
        M.[Especie] AS Especie,
        M.[Peso] AS Peso
    FROM [dbo].[Mascotas] M
    INNER JOIN [dbo].[Clientes] C ON M.[IdCliente] = C.[IdCliente]
    ORDER BY C.[Nombre], M.[Nombre];
END
GO
