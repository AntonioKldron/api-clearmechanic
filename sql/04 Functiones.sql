/********************************************************************/
/********************fnCA_CatParametrosSucursalValor*****************/
/********************************************************************/
IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.fnCA_CatParametrosSucursalValor')
            AND TYPE = 'FN')
    DROP FUNCTION dbo.fnCA_CatParametrosSucursalValor;
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[fnCA_CatParametrosSucursalValor](
    @Sucursal int,
    @Clave VARCHAR(100)
)
    RETURNS VARCHAR(255)
AS
BEGIN
    DECLARE @Valor varchar(255)

    IF EXISTS(SELECT *
              FROM dbo.CA_CatParametrosSucursal ccps
              WHERE ccps.Clave = @clave
                AND ccps.Sucursal = @Sucursal)
        SELECT @Valor = ccps.Valor
        FROM dbo.CA_CatParametrosSucursal ccps
        WHERE ccps.Clave = @Clave
          AND ccps.Sucursal = @Sucursal
    ELSE
        SET @Valor = ''

    RETURN @Valor
END
GO

/********************************************************************/
/********************fnCA_GeneraSucursalValida***********************/
/********************************************************************/

IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.fnCA_GeneraSucursalValida')
            AND TYPE = 'FN')
    DROP FUNCTION dbo.fnCA_GeneraSucursalValida;
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

-- =============================================
-- Autor:Giovanni Trujillo 
-- Par�metros: Modulo, Movimiento,Sucursal
-- Resultado: Retorna la sucursal valida para afectacion de movimeintos
-- =============================================
CREATE FUNCTION [dbo].[fnCA_GeneraSucursalValida](@Modulo Varchar(5), @Mov Varchar(20), @Sucursal int)
    RETURNS INT
AS
BEGIN

    IF @Mov IN ('Venta Perdida', 'Dias', 'Reservar') OR @Mov LIKE 'Nota%'
        BEGIN
            IF @Sucursal % 2 = 1
                SELECT @Sucursal = @Sucursal - 1
        END
    IF @Mov IN ('Cita Servicio')
        BEGIN
            IF @Sucursal % 2 = 0
                SELECT @Sucursal = @Sucursal + 1
        END

    RETURN @Sucursal
END
GO
/********************************************************************/
/********************fnCA_GeneraAlmacenlValido***********************/
/********************************************************************/

IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.fnCA_GeneraAlmacenlValido')
            AND TYPE = 'FN')
    DROP FUNCTION dbo.fnCA_GeneraAlmacenlValido;
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

-- =============================================
-- Autor:Giovanni Trujillo 
-- Parametros: Modulo, Movimiento,Sucursal
-- Resultado: Retorna el Almacen valido para afectaciones
-- =============================================
CREATE FUNCTION [dbo].[fnCA_GeneraAlmacenlValido](@Modulo Varchar(5), @Mov Varchar(20), @Sucursal int)
    RETURNS Varchar(4)
AS
BEGIN
    DECLARE
        @Almacen Varchar(4)

    IF @Mov IN ('Venta Perdida', 'Hist Refacc', 'Reservar') OR @Mov LIKE 'Nota%'
        BEGIN
            IF @Sucursal % 2 = 1
                SELECT @Sucursal = @Sucursal - 1
            SELECT @Almacen = Almacen
            FROM ALM
            WHERE Sucursal = @Sucursal
              AND (Almacen = 'R' OR Almacen LIKE 'RS%')
        END
    ELSE
        SELECT @Almacen = Almacen
        FROM ALM
        WHERE Sucursal = @Sucursal
          AND Almacen like 'S%'

    RETURN @Almacen

END


GO
/***************************************************************/
/********************fnCA_GeneraUENValida***********************/
/***************************************************************/

IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.fnCA_GeneraUENValida')
            AND TYPE = 'FN')
    DROP FUNCTION dbo.fnCA_GeneraUENValida;
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
-- =============================================
-- Autor:Giovanni Trujillo 
-- Parametros: Modulo, Movimiento, Sucursal,Concepto del Movimiento
-- Resultado: Retorna una UEN que sea valida con o sin validacion de concepto
-- =============================================
CREATE FUNCTION [dbo].[fnCA_GeneraUENValida](@Modulo Varchar(5), @Mov Varchar(20), @Sucursal int, @Concepto varchar(50))
    RETURNS INT
AS
BEGIN
    DECLARE
        @UEN INT

    IF EXISTS (SELECT *
               FROM INFORMATION_SCHEMA.TABLES
               WHERE TABLE_NAME = 'CA_MovTipoValidarUEN'
                 AND TABLE_SCHEMA = 'dbo')/*Revisa si trae la nomenclatura CA_ en la tabla para buscar tablas de la V6000 */
        BEGIN
            IF EXISTS (SELECT *
                       FROM INFORMATION_SCHEMA.TABLES
                       WHERE TABLE_NAME = 'CA_ConceptoValidarUEN'
                         AND TABLE_SCHEMA = 'dbo') AND @Concepto IS NOT NULL
                SELECT DISTINCT @UEN = CVU.UENValida
                FROM CA_MovTipoValidarUEN AS MTVU
                         INNER JOIN CA_ConceptoValidarUEN AS CVU
                                    ON MTVU.Sucursal = CVU.Sucursal AND MTVU.Modulo = CVU.Modulo AND
                                       MTVU.UENValida = CVU.UENValida
                WHERE MTVU.Sucursal = @Sucursal
                  AND MTVU.Modulo = @Modulo
                  AND MTVU.Mov = @Mov
                  AND CVU.Concepto = @Concepto
            ELSE
                SELECT @UEN = UENValida
                FROM CA_MovTipoValidarUEN
                WHERE MOV = @Mov
                  AND Sucursal = @Sucursal
                  AND Modulo = @Modulo
        END
    ELSE
        BEGIN
            IF EXISTS (SELECT *
                       FROM INFORMATION_SCHEMA.TABLES
                       WHERE TABLE_NAME = 'ConceptoValidarUEN'
                         AND TABLE_SCHEMA = 'dbo') AND @Concepto IS NOT NULL
                SELECT DISTINCT @UEN = CVU.UENValida
                FROM MovTipoValidarUEN AS MTVU
                         INNER JOIN ConceptoValidarUEN AS CVU
                                    ON MTVU.Sucursal = CVU.Sucursal AND MTVU.Modulo = CVU.Modulo AND
                                       MTVU.UENValida = CVU.UENValida
                WHERE MTVU.Sucursal = @Sucursal
                  AND MTVU.Modulo = @Modulo
                  AND MTVU.Mov = @Mov
                  AND CVU.Concepto = @Concepto
            ELSE
                SELECT @UEN = UENValida
                FROM MovTipoValidarUEN
                WHERE MOV = @Mov
                  AND Sucursal = @Sucursal
                  AND Modulo = @Modulo
        END

    RETURN @UEN
END
GO
/****************************************************************************/
/*********************fnCA_ItemsQuotesClearMechanicsAPI**********************/
/****************************************************************************/
IF EXISTS(
    SELECT * FROM SYSOBJECTS 
    WHERE ID = OBJECT_ID('dbo.fnCA_ItemsQuotesClearMechanicsAPI') 
        AND TYPE = 'FN')
	DROP FUNCTION dbo.fnCA_ItemsQuotesClearMechanicsAPI;
GO

CREATE FUNCTION dbo.fnCA_ItemsQuotesClearMechanicsAPI(
    @idVenta INT
)
RETURNS VARCHAR(MAX)
AS
BEGIN
    DECLARE 
        @id INT,
        @json VARCHAR(MAX) = ''

    -- Obtener el primer renglonId
    SELECT @id = MIN(renglonId) 
    FROM vwCA_ItemsQuotesClearMechanicsAPI 
    WHERE idventa = @idVenta

    WHILE @id IS NOT NULL
    BEGIN
        SELECT @json += '{
            "itemName": ' + ISNULL('"' + CONVERT(VARCHAR, itemName) + '"', '"null"') + ',
            "itemId": ' + ISNULL('"' + CONVERT(VARCHAR, itemId) + '"', '"null"') + ',
            "quantity": ' + ISNULL(CONVERT(VARCHAR, quantity), 'null') + ',
            "unitPrice": ' + ISNULL(CONVERT(VARCHAR, unitPrice), 'null') + ',
            "availability": ' + ISNULL(CONVERT(VARCHAR, availability), 'null') + ',
            "hours": ' + ISNULL(CONVERT(VARCHAR, hours), 'null') + ',
            "hourPrice": ' + ISNULL(CONVERT(VARCHAR, hourPrice), 'null') + ',
            "subtotal": ' + ISNULL(CONVERT(VARCHAR, subtotal), 'null') + ',
            "warehouseId": ' + ISNULL('"' + CONVERT(VARCHAR, warehouseId) + '"', '"null"') + ',
            "status": ' + ISNULL('"' + CONVERT(VARCHAR, status) + '"', '"null"') + '
        },'
        FROM vwCA_ItemsQuotesClearMechanicsAPI  
        WHERE renglonid = @id AND idventa = @idVenta

        -- Obtener el siguiente renglonId
        SELECT @id = MIN(renglonId) 
        FROM vwCA_ItemsQuotesClearMechanicsAPI 
        WHERE renglonid > @id 
        AND idventa = @idVenta
    END

    -- Validación para evitar error en LEFT()
    RETURN '[' + CASE 
        WHEN LEN(@json) > 0 
        THEN LEFT(@json, LEN(@json) - 1)  -- Quita la última coma
        ELSE ''  -- Si está vacío, devuelve JSON vacío
    END + ']'
END
GO
/***************************************************************
***************************************************************/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnCA_fnDivideNombre](@Cadena varchar(200), @Tipo varchar(15))
    RETURNS varchar(100)
AS
BEGIN
    DECLARE
        @SubCadena varchar(100),
        @Cadena1 varchar(100),
        @Cadena2 varchar(100),
        @Cadena3 varchar(100),
        @Cadena4 varchar(100),
        @Nombres varchar(100),
        @Paterno varchar(100),
        @Materno varchar(100),
        @Inicio int,
        @Fin int
    SELECT @Inicio = 0
    SELECT @Fin = CASE WHEN CHARINDEX(' ', @Cadena) = 0 THEN LEN(@Cadena) + 1 ELSE CHARINDEX(' ', @Cadena) END
    SELECT @Cadena1 = SUBSTRING(@Cadena, @Inicio, @Fin)
    SELECT @Cadena = SUBSTRING(@Cadena, @Fin + 1, LEN(@Cadena) - @Fin + 1)
    IF @Cadena <> ''
        BEGIN
            SELECT @Fin = CASE WHEN CHARINDEX(' ', @Cadena) = 0 THEN LEN(@Cadena) + 1 ELSE CHARINDEX(' ', @Cadena) END
            SELECT @Cadena2 = SUBSTRING(@Cadena, @Inicio, @Fin)
            SELECT @Cadena = SUBSTRING(@Cadena, @Fin + 1, LEN(@Cadena) - @Fin + 1)
        END
    IF @Cadena <> ''
        BEGIN
            SELECT @Fin = CASE WHEN CHARINDEX(' ', @Cadena) = 0 THEN LEN(@Cadena) + 1 ELSE CHARINDEX(' ', @Cadena) END
            SELECT @Cadena3 = SUBSTRING(@Cadena, @Inicio, @Fin)
            SELECT @Cadena = SUBSTRING(@Cadena, @Fin + 1, LEN(@Cadena) - @Fin + 1)
        END
    IF @Cadena <> ''
        BEGIN
            SELECT @Fin = CASE WHEN CHARINDEX(' ', @Cadena) = 0 THEN LEN(@Cadena) + 1 ELSE CHARINDEX(' ', @Cadena) END
            SELECT @Cadena4 = SUBSTRING(@Cadena, @Inicio, @Fin)
            SELECT @Cadena = SUBSTRING(@Cadena, @Fin + 1, LEN(@Cadena) - @Fin + 1)
        END
    IF NOT (@Cadena4 IS NULL)
        SELECT @Nombres = ISNULL(@Cadena1, '') + ' ' + ISNULL(@Cadena2, ''),
               @Paterno = @Cadena3,
               @Materno = @Cadena4
    ELSE
        SELECT @Nombres = ISNULL(@Cadena1, ''),
               @Paterno = ISNULL(@Cadena2, ''),
               @Materno = ISNULL(@Cadena3, '')
    IF @Tipo = 'Nombre'
        SELECT @SubCadena = @Nombres
    ELSE
        IF @Tipo = 'Paterno'
            SELECT @SubCadena = @Paterno
        ELSE
            IF @Tipo = 'Materno'
                SELECT @SubCadena = @Materno
    RETURN @SubCadena
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnCA_UnirFechaHoraUTC]
(
    @FechaBase DATETIME,
    @Hora VARCHAR(5),
    @UTC BIT
)
RETURNS DATETIME
AS
BEGIN
    -- Si la hora es válida, combinamos la fecha con la hora directamente sin declarar nuevas variables
    IF @Hora IS NOT NULL AND @Hora LIKE '[0-9][0-9]:[0-9][0-9]'
    BEGIN
        -- Intentamos combinar la fecha con la hora en una sola expresión
        SET @FechaBase = TRY_CAST(CONCAT(CONVERT(DATE, @FechaBase), ' ', @Hora) AS DATETIME);
    END

    -- Si es necesario, ajustamos la fecha a UTC sin nuevas variables
    IF @UTC = 1
    BEGIN
        SET @FechaBase = DATEADD(MINUTE, DATEDIFF(MINUTE, GETDATE(), GETUTCDATE()), @FechaBase);
    END

    RETURN @FechaBase;
END
GO

