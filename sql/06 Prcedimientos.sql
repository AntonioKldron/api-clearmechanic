/***************************************************************************/
/********************xpCA_OrdenesClearMechanicsUpdate***********************/
/***************************************************************************/
IF EXISTS(SELECT * FROM SYSOBJECTS WHERE ID = OBJECT_ID('dbo.xpCA_OrdenesClearMechanicsUpdate') AND TYPE = '')
DROP PROCEDURE dbo.xpCA_OrdenesClearMechanicsUpdate;
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  PROCEDURE [dbo].[xpCA_OrdenesClearMechanicsUpdate](
    @movid VARCHAR(10),
    @vin VARCHAR(25),
    @sucursal int,
    @serviceAdvisorId VARCHAR(25),
    @promisedDate VARCHAR(25),
    @kilometers int,
    @orderType VARCHAR(50),
    @cone VARCHAR(25),
    @appointmentId VARCHAR(25))
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRY
    DECLARE @IDVenta    INT=NULL,
            @ok         VARCHAR(50),
            @OkRef      VARCHAR(250),
            @Lista      VARCHAR(max)
            
    SELECT
    @IDVenta=s.ID
    FROM Venta S
    WHERE S.MOV = 'SERVICIO' AND s.MovID=@movid AND s.estatus in ('PENDIENTE')

    SET @vin=(SELECT ServicioSerie FROM venta WHERE movid=@movid and mov='SERVICIO') 


    IF @IDVenta IS NOT NULL
    BEGIN
        IF @serviceAdvisorId IS NOT NULL
        BEGIN
            IF EXISTS(SELECT TOP 1 * FROM Agente WHERE Agente=@serviceAdvisorId)
            BEGIN
                UPDATE Venta SET Agente=@serviceAdvisorId WHERE ID=@IDVenta
            END
            ELSE
            BEGIN
                SELECT '' AS 'Folio', 'No exite el serviceAdvisor en intelisis' AS 'OkRef'
                RETURN
            END
        END
        IF @kilometers IS NOT NULL
        BEGIN
            IF ISNULL((SELECT km from VIN where vin=@vin),0)<@kilometers
            BEGIN
                UPDATE Venta SET ServicioKms=@kilometers WHERE ID=@IDVenta
            END
            ELSE
            BEGIN
                SELECT '' AS 'Folio', 'El kilometraje es inferior' AS 'OkRef'
                RETURN
            END
        END
        IF @cone IS NOT NULL
        BEGIN
            UPDATE Venta SET ServicioNumero=@cone WHERE ID=@IDVenta
        END
            SELECT TOP 1 *
            FROM vwCA_OrdenesClearMechanics
            WHERE orderId = @IDVenta
            ORDER BY orderDate DESC
    END
    ELSE
    BEGIN
        SELECT '' AS 'Folio', 'Servicio no encontrado o ya fue finalizado en Intelisis' AS 'OkRef'
        RETURN
    END
    END TRY
    BEGIN CATCH
        SELECT '' AS 'Folio', ERROR_MESSAGE() + ' ' + CONVERT(VARCHAR(100), ERROR_LINE()) AS 'OkRef'
    END CATCH
END
GO
/***************************************************************************/
/********************xpCA_OrdenesClearMechanicsInsert***********************/
/***************************************************************************/
IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.xpCA_OrdenesClearMechanicsInsert')
            AND TYPE = 'P')
    DROP PROCEDURE dbo.xpCA_OrdenesClearMechanicsInsert;
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[xpCA_OrdenesClearMechanicsInsert](@vin VARCHAR(25),
                                                          @sucursal int,
                                                          @serviceAdvisorId VARCHAR(25),
                                                          @promisedDate NVARCHAR(25),
                                                          @kilometers int,
                                                          @orderType VARCHAR(50),
                                                          @cone VARCHAR(25),
                                                          @appointmentId VARCHAR(25))
AS
BEGIN
    SET NOCOUNT ON
    DECLARE
        @ArticuloMO VARCHAR(25),
        @Usuario VARCHAR(25),
        @GenerarID INT,
        @OK INT,
        @OkRef VARCHAR(255),
        @Cliente VARCHAR(20),
        @ArticuloVin VARCHAR(40),
        @ModeloVin VARCHAR(40),
        @NumeroEconomicoVin VARCHAR(50),
        @DescripcionVin VARCHAR(100),
        @IDCita INT,
        @Placas VARCHAR(20),
        @IndicadorColor VARCHAR(20),
        @Empresa VARCHAR(10)=(SELECT TOP 1 Empresa
                              FROM EMPRESA),
        @color VARCHAR(50),
		@fechaInsert DATETIME,
        @idLog      INT

        INSERT INTO CA_LOGClearMechanics
        (vin, sucursal, serviceAdvisorId, promisedDate, kilometers, orderType, cone,
         appointmentId, FECHA)
        SELECT @vin,
               @sucursal,
               @serviceAdvisorId,
               @promisedDate,
               @kilometers,
               @orderType,
               @cone,
               @appointmentId,
               GETDATE()

        SET @idLog=IDENT_CURRENT('CA_LOGClearMechanics')
    BEGIN TRY
        SELECT @ArticuloMO = dbo.fnCA_CatParametrosSucursalValor(@Sucursal, 'CMArticuloMO')
        SELECT @Usuario = dbo.fnCA_CatParametrosSucursalValor(@Sucursal, 'CMUsuario')

        IF TRY_CONVERT(DATETIMEOFFSET, @promisedDate) IS NULL
            BEGIN
                UPDATE CA_LOGClearMechanics 
                SET mensaje='Formato incorrecto en el envio de la fecha el formato debe ser YYYY-MM-DDTHH:MM:SS.sssZ no :'+@promisedDate
                WHERE id=@idLog
                SELECT  ''                                                                                                          AS 'Folio', 
                        'Formato incorrecto en el envio de la fecha el formato debe ser YYYY-MM-DDTHH:MM:SS.sssZ no :'+@promisedDate AS 'OkRef'
                RETURN
            END

        SELECT @fechaInsert=@promisedDate

        IF  CAST(@fechaInsert AS DATE) < CAST(GETDATE() AS DATE)
        BEGIN
            UPDATE CA_LOGClearMechanics 
            SET mensaje='La fecha promesa es menor a la fecha actual, verifica que la fecha promesa esté correctamente registrada el dato mandado fue: '+@promisedDate
            WHERE id=@idLog
            SELECT  ''                                                                                                          AS 'Folio', 
                    'La fecha promesa es menor a la fecha actual, verifica que la fecha promesa esté correctamente registrada el dato mandado fue: '+@promisedDate AS 'OkRef'
            RETURN
        END

        IF PATINDEX('%[^0-9]%', @cone) <> 0
        BEGIN
            UPDATE CA_LOGClearMechanics 
            SET mensaje='La torre/cone tiene que ser un numero entero y se mando:'+@cone
            WHERE id=@idLog
            SELECT  ''                                                               AS 'Folio', 
                    'La torre/cone tiene que ser un numero entero y se mando:'+@cone AS 'OkRef'
            RETURN
        END

        SET @IndicadorColor = 'AMARILLO'

        -- VALIDAR EXISTENCIA DEL VIN
        IF NOT EXISTS(SELECT VIN
                      FROM VIN WITH (NOLOCK)
                      WHERE VIN = @VIN)
            BEGIN
                UPDATE CA_LOGClearMechanics 
                SET mensaje='No se encontro el VIN dentro de INTELISIS'
                WHERE id=@idLog
                SELECT ''                                           AS 'Folio',
                       N'No se encontro el VIN dentro de INTELISIS' AS 'OkRef'
                RETURN
            end


        SELECT @Cliente = VIN.Cliente,
               @ArticuloVin = VIN.Articulo,
               @ModeloVin = VIN.Modelo,
               @NumeroEconomicoVin = VIN.NumeroEconomico,
               @DescripcionVin = ART.Descripcion1,
               @Placas = ISNULL(Placas, ''),
               @color=vin.ColorExteriorDescripcion
        FROM VIN WITH (NOLOCK)
                 INNER JOIN ART WITH (NOLOCK) ON VIN.Articulo = ART.Articulo
        WHERE VIN.VIN = @vin

        IF ISNULL(@Cliente, '') = '' --OR ISNULL(@appointmentId, '') IN ('', '0')
            BEGIN
                IF ISNULL(@appointmentId, '') IN ('', '0')
                    BEGIN
                        UPDATE CA_LOGClearMechanics 
                        SET mensaje='No se encontraron coincidencias de cliente para el VIN enviado dentro de INTELISIS'
                        WHERE id=@idLog
                        SELECT ''                                                                                   AS 'Folio',
                               'No se encontraron coincidencias de cliente para el VIN enviado dentro de INTELISIS' AS 'OkRef'
                        RETURN
                    END
            END
        IF @appointmentId IS NOT NULL AND @appointmentId != '0'
            BEGIN
			IF (SELECT ServicioPlacas FROM VENTA WITH (NOLOCK) WHERE movId=@appointmentId AND Mov='Cita Servicio'  AND Sucursal = @sucursal) IS NULL
			BEGIN
				Update VENTA set ServicioPlacas=ISNULL(ServicioPlacas,'SINPLACAS') WHERE movId=@appointmentId AND Mov='Cita Servicio' AND Sucursal = @sucursal
			END
            IF EXISTS (SELECT TOP 1 * FROM venta c WITH (NOLOCK)
                INNER JOIN Venta S WITH (NOLOCK) ON s.origen=c.mov and s.OrigenID = c.Movid and s.estatus='PENDIENTE' WHERE s.ORIGENID = @appointmentId order by s.id desc)
                BEGIN
                    UPDATE CA_LOGClearMechanics 
                    SET mensaje='SUCCESS'
                    WHERE id=@idLog
                    SELECT TOP 1 *FROM vwCA_OrdenesClearMechanics WITH (NOLOCK) WHERE 
                    orderId = (SELECT ID FROM VENTA WITH (NOLOCK) WHERE ORIGENID = @appointmentId AND ESTATUS  = 'PENDIENTE')
                    ORDER BY orderDate DESC                                     
                    RETURN
                END
            ELSE 
                IF NOT EXISTS(SELECT *
                              FROM VENTA WITH (NOLOCK)
                              WHERE MOVID = @appointmentId
                                AND ESTATUS = 'CONFIRMAR')
                    BEGIN
                        UPDATE CA_LOGClearMechanics 
                        SET mensaje='No se puede generar el movimiento debido a que la cita ya fue Concluida en Intelisis'
                        WHERE id=@idLog
                        SELECT ''                                                                                     AS 'Folio',
                               'No se puede generar el movimiento debido a que la cita ya fue Concluida en Intelisis' AS 'OkRef'
                        RETURN
                    END
            END


        BEGIN TRANSACTION
            IF @appointmentId IS NOT NULL AND @appointmentId != '0'
                BEGIN
                    SELECT @IDCita = ID
                    FROM VENTA AS Cita WITH (NOLOCK)
                    WHERE MovID = @appointmentId
                      AND Mov = 'Cita Servicio'
                      AND Sucursal = @sucursal
                    IF @IDCita IS NOT NULL
                        BEGIN
                            EXEC spAfectar 'VTAS', @IDCita, 'GENERAR', 'Todo', 'Servicio', @Usuario, @Estacion=1000,
                                 @EnSilencio=1--,@Ok=@OK OUTPUT,@OkRef=@OkRef OUTPUT
                            SELECT @GenerarID = IDENT_CURRENT('Venta')

                            IF (SELECT MOVID
                                FROM VENTA WITH (NOLOCK)
                                WHERE ID = @GenerarID
                                  AND ESTATUS = 'SINAFECTAR'
                                  AND MOV = 'SERVICIO') IS NULL
                                BEGIN
                                    UPDATE Venta
                                    set Condicion=CASE
                                                      WHEN ISNULL(Condicion, '') = '' THEN 'Contado'
                                                      ELSE ServicioPlacas END,
                                        Concepto = ISNULL(@orderType, 'Publico'),
                                        ServicioArticulo=@ArticuloVin,
                                        ServicioSerie=@vin,
                                        ServicioPlacas= CASE
                                                            WHEN ISNULL(ServicioPlacas, '') = ''
                                                                THEN COALESCE(@PLACAS, 'SINPLACAS')
                                                            ELSE ServicioPlacas END,
                                        ServicioKms=@kilometers,
                                        ServicioTipoOrden= CASE
                                                               WHEN ISNULL(ServicioTipoOrden, '') = '' THEN 'Publico'
                                                               ELSE ServicioTipoOrden END,
                                        ListaPreciosEsp= CASE
                                                             WHEN ISNULL(ListaPreciosEsp, '') = '' THEN '(Precio Lista)'
                                                             ELSE ListaPreciosEsp END,
                                        ServicioTipoOperacion= CASE
                                                                   WHEN ISNULL(ServicioTipoOperacion, '') = ''
                                                                       THEN 'Mantenimiento'
                                                                   ELSE ServicioTipoOperacion END,
                                        ServicioModelo=@ModeloVin,
                                        ServicioNumeroEconomico=@NumeroEconomicoVin,
                                        ServicioDescripcion=@color,
                                        AgenteServicio=@serviceAdvisorId,
                                        ServicioIdentificador='AMARILLO',
                                        ServicioNumero	=	@cone,
                                        UEN=IIF(Concepto = @orderType, UEN, dbo.fnCA_GeneraUENValida('VTAS', 'Servicio',
                                                                                                     dbo.fnCA_GeneraSucursalValida('VTAS', 'Servicio', @sucursal),
                                                                                                     @orderType)),
                                        Agente			=	@serviceAdvisorId,
										FechaEmision	=	@fechaInsert, 
										FechaRequerida	=	DATEADD(mi, 60, @fechaInsert), 
										HoraRequerida	=	CAST(FORMAT(DATEADD(mi, 60, @fechaInsert),'HH:mm')AS VARCHAR(5)), 
										HoraRecepcion	=	CAST(FORMAT(@fechaInsert,'HH:mm')AS VARCHAR(5)),
                                        Almacen=dbo.fnCA_GeneraAlmacenlValido('VTAS', 'Servicio',
                                                                              dbo.fnCA_GeneraSucursalValida('VTAS', 'Servicio', @sucursal)),
                                        Sucursal=dbo.fnCA_GeneraSucursalValida('VTAS', 'Servicio', @sucursal),
                                        Comentarios=ISNULL(CONVERT(VARCHAR(MAX), Comentarios), '') +
                                                    ' Creada desde Interfaz ClearMechanics'
                                    where ID = @GenerarID
                                END
                            ELSE
                                BEGIN
                                    UPDATE CA_LOGClearMechanics 
                                    SET mensaje='Error en la afectacion de la Orden de Servicio'
                                    WHERE id=@idLog
                                    SELECT @OK = 1065, @OkRef = 'Error en la afectacion de la Orden de Servicio'
                                    RETURN
                                END

                        END
                END
            ELSE
                BEGIN
                    INSERT INTO Venta
                    (Empresa, Mov, FechaEmision, Concepto, UEN, Moneda, TipoCambio, Usuario, Estatus,
                     Cliente, Almacen, Agente, FechaRequerida, HoraRequerida, HoraRecepcion
                        , Condicion, ServicioArticulo, ServicioSerie, ServicioPlacas, ServicioKms, Ejercicio, Periodo,
                     ListaPreciosEsp, Sucursal, Comentarios, SucursalOrigen,
                     ServicioTipoOrden, ServicioTipoOperacion, ServicioModelo,
                     ServicioNumeroEconomico, ServicioDescripcion, AgenteServicio,
                     ServicioIdentificador, ServicioNumero)
                    SELECT @Empresa,
                           'Servicio',
                           @fechaInsert,
                           @orderType,
                           dbo.fnCA_GeneraUENValida('VTAS', 'Servicio',
                                                    dbo.fnCA_GeneraSucursalValida('VTAS', 'Servicio', @sucursal),
                                                    @orderType),
                           'Pesos',
                           1,
                           ISNULL(@Usuario, 'SOPDESA'),
                           'SINAFECTAR',
                           @Cliente,
                           dbo.fnCA_GeneraAlmacenlValido('VTAS', 'Servicio',
                                                         dbo.fnCA_GeneraSucursalValida('VTAS', 'Servicio', @sucursal)),
                           @serviceAdvisorId,
                           DATEADD(mi, 60, @fechaInsert),
                           CAST(FORMAT( DATEADD(mi, 60, @fechaInsert),'HH:mm')AS VARCHAR(5)),
                           CAST(FORMAT(@fechaInsert,'HH:mm')AS VARCHAR(5)),
                           'Contado',
                           @ArticuloVin,
                           @vin,
                           ISNULL(@PLACAS, 'SINPLACAS'),
                           @kilometers,
                           YEAR(GETDATE()),
                           MONTH(GETDATE()),
                           'Precio Publico',
                           dbo.fnCA_GeneraSucursalValida('VTAS', 'Servicio', @sucursal),
                           'Creada desde Interfaz ClearMechanics',
                           @sucursal,
                           @orderType,
                           @orderType,
                           @ModeloVin,
                           @NumeroEconomicoVin,
                           @color,
                           @serviceAdvisorId,
                           @IndicadorColor,
                           @cone
                    SELECT @GenerarID = IDENT_CURRENT('Venta')

                    INSERT INTO VENTAD
                    (ID, Renglon, RenglonSub, RenglonID, RenglonTipo, Almacen, UEN, Sucursal,
                     SucursalOrigen, Cantidad, Articulo, Impuesto1, DescripcionExtra, UT,
                     CCTiempoTab, costo, Agente)
                    SELECT @GenerarID,
                           (2048 * (ROW_NUMBER() OVER (ORDER BY ARTICULO))),
                           0,
                           ROW_NUMBER() OVER (ORDER BY ARTICULO) AS Row#,
                           'N',
                           dbo.fnCA_GeneraAlmacenlValido('VTAS', 'Cita Servicio',
                                                         dbo.fnCA_GeneraSucursalValida('VTAS', 'Cita Servicio', @Sucursal)),
                           dbo.fnCA_GeneraUENValida('VTAS', 'Cita Servicio',
                                                    dbo.fnCA_GeneraSucursalValida('VTAS', 'Cita Servicio', @Sucursal),
                                                    'Publico'),
                           dbo.fnCA_GeneraSucursalValida('VTAS', 'Cita Servicio', @Sucursal),
                           dbo.fnCA_GeneraSucursalValida('VTAS', 'Cita Servicio', @Sucursal),
                           ISNULL(Horas, 1),
                           Articulo,
                           Impuesto1,
                           Descripcion1,
                           ISNULL(Horas, 1),
                           ISNULL(Horas, 1),
                           '0.00',
                           (select top 1 Agente
                            from agente WITH (NOLOCK)
                            where Tipo = 'Mecanico'
                              AND Estatus = 'ALTA'
                              AND (SucursalEmpresa = @Sucursal OR SucursalEmpresa = (@Sucursal - 1)))
                    FROM ART
                    WHERE ARTICULO = @ArticuloMO
                    ---Se debe cambiar por el articulo generico que use la agencia
                END

                EXEC spAfectar 'VTAS', @GenerarID, 'AFECTAR', 'Todo', NULL, @Usuario, @Estacion=1000, @EnSilencio=1,
                     @Ok=@OK OUTPUT, @OkRef=@OkRef OUTPUT

    END TRY
    BEGIN CATCH
        SELECT @OK = 1065, @OkRef = ERROR_MESSAGE() + ' ' + CONVERT(VARCHAR(100), ERROR_LINE()) + ' ' + CONVERT(VARCHAR(100), ERROR_PROCEDURE())
    END CATCH

    IF @OkRef = 'OK'
        SET @OkRef = NULL

    IF @Ok IS NOT NULL AND @OkRef IS NULL AND ISNUMERIC(@Ok) = 1
        BEGIN
            SELECT @OkRef = Descripcion
            FROM MENSAJELISTA
            WHERE MENSAJE = @OK
        END

    IF @Ok IS NOT NULL
        SELECT '' AS 'Folio', @OkRef AS 'OkRef'

    IF @OkRef IS NULL AND @Ok IS NULL
        COMMIT TRANSACTION
    ELSE
        ROLLBACK TRANSACTION

    IF EXISTS(SELECT *
              FROM vwCA_OrdenesClearMechanics WITH (NOLOCK)
              WHERE orderId = @GenerarID)
        BEGIN
            UPDATE CA_LOGClearMechanics 
            SET mensaje='SUCCESS'
            WHERE id=@idLog
            SELECT TOP 1 *
            FROM vwCA_OrdenesClearMechanics WITH (NOLOCK)
            WHERE orderId = @GenerarID
            ORDER BY orderDate DESC
        END
    ELSE
        BEGIN
            UPDATE CA_LOGClearMechanics 
            SET mensaje=COALESCE(NULLIF(@OkRef, ''), 'No se pudo generar la Orden de Servicio')
            WHERE id=@idLog
            SELECT '' AS 'Folio', COALESCE(NULLIF(@OkRef, ''), 'No se pudo generar la Orden de Servicio') AS 'OkRef'
        END
    RETURN
END
GO
/***************************************************************************/
/********************xpCA_InventoryItemClearMechanics***********************/
/***************************************************************************/
IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.xpCA_InventoryItemClearMechanics')
            AND TYPE = 'P')
    DROP PROCEDURE dbo.xpCA_InventoryItemClearMechanics;
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[xpCA_InventoryItemClearMechanics](
    @id varchar(50),
    @Sucursal INT =NULL)
AS
BEGIN
    SET NOCOUNT ON
    DECLARE
        @Almacen VARCHAR(4)

    IF @Sucursal % 2 = 1
        SELECT @Sucursal = @Sucursal - 1

    /*Declaracion de Almacen para realizar la busqueda de articulos en base al almacen*/
    SELECT TOP 1 @Almacen = Almacen
    FROM ALM
    WHERE SUCURSAL = @Sucursal
      AND ALMACEN IN ('R', 'RS1', 'RS2', 'RS3', 'RS4', 'RS5', 'RS6', 'RS7', 'RS8', 'RS9')

    IF ISNULL(@ALMACEN, '') = ''
        SET @Almacen = 'R'

    SELECT CASE
               WHEN ISNUMERIC(@id) = 1 THEN
                   ('[' + (SELECT SUBSTRING((SELECT TOP 100 ',',
                                                            ('{"jobName":"' + DescripcionC + '","jobId":"' +
                                                             CONVERT(varchar(10), Id)
                                                                + '","parts":' +
                                                             ('[' + (SELECT SUBSTRING((SELECT ',',
                                                                                              ('{"partName":"' +
                                                                                               ISNULL(PD.Articulo, '') +
                                                                                               ' ' +
                                                                                               ISNULL(REPLACE(PD.Descripcion, '"', ''), '') +
                                                                                               '","partId":"' +
                                                                                               PD.Articulo +
                                                                                               '","quantity":"' +
                                                                                               CONVERT(varchar(30), ISNULL(PD.Cantidad, 0)) +
                                                                                               '","partUnitPrice":"' +
                                                                                               CONVERT(varchar(30), ISNULL(PD.PrecioUnitario, 0)) +
                                                                                               '","availability":"' +
                                                                                               CONVERT(varchar(30), ISNULL(AD.Disponible, 0)) +
                                                                                               '","laborHours":"","laborHourPrice":"","comments":""}') as 'data()'
                                                                                       FROM CA_ServicioPaquetesD AS PD
                                                                                                LEFT JOIN ArtDisponible AS AD
                                                                                                          ON AD.Articulo = PD.Articulo AND AD.Almacen = @Almacen
                                                                                       where PD.TipoArticulo = 'Normal'
                                                                                         AND PD.IdPaquete = CA_ServicioPaquetes.Id
                                                                                       FOR XML PATH('')), 2, 999999)) +
                                                              ']')
                                                                + ',"labors":' +
                                                             ('[' + (SELECT SUBSTRING((SELECT ',',
                                                                                              ('{"laborName":"' +
                                                                                               ISNULL(SD.Articulo, '') +
                                                                                               ' ' +
                                                                                               ISNULL(REPLACE(SD.Descripcion, '"', ''), '') +
                                                                                               '","laborId":"' +
                                                                                               SD.Articulo +
                                                                                               '","laborHours":"' +
                                                                                               CONVERT(varchar(30), ISNULL(SD.Cantidad, 0)) +
                                                                                               '","labourHourPrice":"' +
                                                                                               CONVERT(varchar(30), ISNULL(SD.PrecioUnitario, 0)) +
                                                                                               '","comments":""}') as 'data()'
                                                                                       FROM CA_ServicioPaquetesD AS SD
                                                                                       where SD.TipoArticulo = 'Servicio'
                                                                                         AND SD.IdPaquete = CA_ServicioPaquetes.Id
                                                                                       FOR XML PATH('')), 2, 999999)) +
                                                              ']')
                                                                + '}') as 'data()'
                                             FROM CA_ServicioPaquetes
                                             WHERE Id = @id
                                             FOR XML PATH('')), 2, 9999999)) + ']')
               ELSE
                   NULL
               END
                                                                           AS 'jobs',
           ('[' + (SELECT SUBSTRING((SELECT ',',
                                            ('{"partName":"' + ISNULL(A.Articulo, '') + ' ' +
                                             ISNULL(REPLACE(A.Descripcion1, '"', ''), '') + '","partId":"' + A.Articulo +
                                             '","quantity":1,"partUnitPrice":"' +
                                             CONVERT(varchar(30), ISNULL(A.precioLista, 0)) + '","availability":"' +
                                             CONVERT(varchar(30), ISNULL(AD.Disponible, 0)) +
                                             '","laborHours":null,"laborHourPrice":null,"comments":"' +
                                             ISNULL(Descripcion2, '') + '"}') as 'data()'
                                     FROM Art as A
                                              INNER JOIN ArtDisponible AS AD ON AD.Articulo = a.Articulo
                                     WHERE AD.Almacen = @Almacen
                                       AND Estatus = 'ALTA'
                                       AND AD.Disponible IS NOT NULL
                                       AND AD.Disponible >= 0
                                       AND A.Articulo = @id
                                     FOR XML PATH('')), 2, 999999)) + ']') AS 'parts',
           ('[' + (SELECT SUBSTRING((SELECT ',',
                                            ('{"laborName":"' + REPLACE(ISNULL(A.Articulo, ''), char(39), '') + ' ' +
                                             REPLACE(ISNULL(REPLACE(A.Descripcion1, '"', ''), ''), char(39), '') + '","laborId":"' +
                                             A.Articulo + '","laborHours":"' +
                                             CONVERT(varchar(10), ISNULL(A.Horas, 0)) + '","laborHourPrice":"' +
                                             CONVERT(varchar(10), ISNULL(A.CostoEstandar, 0)) + '","comments":"' +
                                             ISNULL(A.Descripcion2, '') + '"}') as 'data()'
                                     FROM Art as A
                                     WHERE A.Tipo = 'Servicio'
                                       AND Categoria = 'Mano de Obra'
                                       AND Estatus = 'ALTA'
                                       AND A.Articulo = @id
                                     FOR XML PATH('')), 2, 999999)) + ']') AS 'labors'

END
GO
/****************************************************************************/
/********************xpCA_InventoryItemsClearMechanics***********************/
/****************************************************************************/

IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.xpCA_InventoryItemsClearMechanics')
            AND TYPE = 'P')
    DROP PROCEDURE dbo.xpCA_InventoryItemsClearMechanics;
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[xpCA_InventoryItemsClearMechanics](
    @keyword varchar(50)=NULL,
    @Sucursal INT =NULL)
AS
BEGIN
    SET NOCOUNT ON
    DECLARE
        @Almacen VARCHAR(4)

    IF @Sucursal % 2 = 1
        SELECT @Sucursal = @Sucursal - 1
    /*Declaracion de Almacen para realizar la busqueda de articulos en base al almacen*/
    SELECT TOP 1 @Almacen = Almacen
    FROM ALM
    WHERE SUCURSAL = @Sucursal
      AND ALMACEN IN ('R', 'RS1', 'RS2', 'RS3', 'RS4', 'RS5', 'RS6', 'RS7', 'RS8', 'RS9')

    IF ISNULL(@ALMACEN, '') = ''
        SET @Almacen = 'R'

    IF @keyword IS NULL
        BEGIN
            SELECT ('[' + (SELECT REPLACE(SUBSTRING((SELECT TOP 200 ',',
                                                                    ('{"jobName":"' + DescripcionC + '","jobId":"' +
                                                                     CONVERT(varchar(10), Id)
                                                                        + '","parts":' +
                                                                     ('[' + (SELECT SUBSTRING((SELECT TOP 200 ',',
                                                                                                              ('{"partName":"' +
                                                                                                               ISNULL(REPLACE(PD.Articulo, '"', ''), '') +
                                                                                                               ' ' +
                                                                                                               ISNULL(REPLACE(PD.Descripcion, '"', ''), '') +
                                                                                                               '","partId":"' +
                                                                                                               PD.Articulo +
                                                                                                               '","quantity":"' +
                                                                                                               CONVERT(varchar(30), ISNULL(PD.Cantidad, 0)) +
                                                                                                               '","partUnitPrice":"' +
                                                                                                               CONVERT(varchar(30), ISNULL(PD.PrecioUnitario, 0)) +
                                                                                                               '","availability":"' +
                                                                                                               CONVERT(varchar(30), ISNULL(AD.Disponible, 0)) +
                                                                                                               '","laborHours":"","laborHourPrice":"","comments":""}') as 'data()'
                                                                                               FROM CA_ServicioPaquetesD AS PD
                                                                                                        LEFT JOIN ArtDisponible AS AD
                                                                                                                  ON AD.Articulo = PD.Articulo AND AD.Almacen = @Almacen
                                                                                               where PD.TipoArticulo = 'Normal'
                                                                                                 AND PD.IdPaquete = CA_ServicioPaquetes.Id
                                                                                               FOR XML PATH('')), 2,
                                                                                              999999)) + ']')
                                                                        + ',"labors":' +
                                                                     ('[' + (SELECT SUBSTRING((SELECT TOP 200 ',',
                                                                                                              ('{"laborName":"' +
                                                                                                               ISNULL(REPLACE(SD.Articulo, '"', ''), '') +
                                                                                                               ' ' +
                                                                                                               ISNULL(REPLACE(SD.Descripcion, '"', ''), '' ) +
                                                                                                               '","laborId":"' +
                                                                                                               SD.Articulo +
                                                                                                               '","laborHours":"' +
                                                                                                               CONVERT(varchar(30), ISNULL(SD.Cantidad, 0)) +
                                                                                                               '","labourHourPrice":"' +
                                                                                                               CONVERT(varchar(30), ISNULL(SD.PrecioUnitario, 0)) +
                                                                                                               '","comments":""}') as 'data()'
                                                                                               FROM CA_ServicioPaquetesD AS SD
                                                                                               where SD.TipoArticulo = 'Servicio'
                                                                                                 AND SD.IdPaquete = CA_ServicioPaquetes.Id
                                                                                               FOR XML PATH('')), 2,
                                                                                              999999)) + ']')
                                                                        + '}') as 'data()'
                                                     FROM CA_ServicioPaquetes
                                                     FOR XML PATH('')), 2, 9999999), ',,', ',')) + ']') AS 'jobs',

                   REPLACE(REPLACE(REPLACE(('[' + (SELECT SUBSTRING((SELECT TOP 200 ',',
                                                                                    ('{"partName":"' +
                                                                                     ISNULL(REPLACE(A.Articulo, '"', ''), '') +
                                                                                     ' ' +
                                                                                     ISNULL(REPLACE(A.Descripcion1, '"', ''), '') +
                                                                                     '","partId":"' + A.Articulo +
                                                                                     '","quantity":1,"partUnitPrice":"' +
                                                                                     CONVERT(varchar(30), ISNULL(A.precioLista, 0)) +
                                                                                     '","availability":"' +
                                                                                     CONVERT(varchar(30), ISNULL(AD.Disponible, 0)) +
                                                                                     '","laborHours":null,"laborHourPrice":null,"comments":"' +
                                                                                     ISNULL(Descripcion2, '') +
                                                                                     '"}') as 'data()'
                                                                     FROM Art as A
                                                                              INNER JOIN ArtDisponible AS AD ON AD.Articulo = a.Articulo
                                                                     WHERE AD.Almacen = @Almacen
                                                                       AND Estatus = 'ALTA'
                                                                       AND AD.Disponible IS NOT NULL
                                                                       AND AD.Disponible >= 0
                                                                     FOR XML PATH('')), 2, 999999)) + ']'), CHAR(9),
                                           ''), CHAR(10), ''), CHAR(13), '')                            AS 'parts',
                   REPLACE(REPLACE(REPLACE(('[' + (SELECT SUBSTRING((SELECT TOP 200 ',',
                                                                                    ('{"laborName":"' +
                                                                                     ISNULL(REPLACE(A.Articulo, '"', ''), '') +
                                                                                     ' ' + REPLACE(
                                                                                             ISNULL(REPLACE(A.Descripcion1, '"', ''), ''),
                                                                                             char(39), '') +
                                                                                     '","laborId":"' + A.Articulo +
                                                                                     '","laborHours":"' +
                                                                                     CONVERT(varchar(10), ISNULL(A.Horas, 0)) +
                                                                                     '","laborHourPrice":"' +
                                                                                     CONVERT(varchar(10), ISNULL(A.CostoEstandar, 0)) +
                                                                                     '","comments":"' +
                                                                                     ISNULL(A.Descripcion2, '') +
                                                                                     '"}') as 'data()'
                                                                     FROM Art as A
                                                                     WHERE A.Tipo = 'Servicio'
                                                                       AND Categoria = 'Mano de Obra'
                                                                       AND Estatus = 'ALTA'
                                                                     FOR XML PATH('')), 2, 999999)) + ']'), CHAR(9),
                                           ''), CHAR(10), ''), CHAR(13), '')                            AS 'labors'
        END
    ELSE
        BEGIN
            SELECT ('[' + (SELECT SUBSTRING((SELECT TOP 200 ',',
                                                            ('{"jobName":"' + DescripcionC + '","jobId":"' +
                                                             CONVERT(varchar(10), Id)
                                                                + '","parts":' +
                                                             ('[' + (SELECT SUBSTRING((SELECT TOP 200 ',',
                                                                                                      ('{"partName":"' +
                                                                                                       ISNULL(REPLACE(PD.Articulo, '"', ''), '') +
                                                                                                       ' ' +
                                                                                                       ISNULL(REPLACE(PD.Descripcion, '"', ''), '') +
                                                                                                       '","partId":"' +
                                                                                                       PD.Articulo +
                                                                                                       '","quantity":"' +
                                                                                                       CONVERT(varchar(30), ISNULL(PD.Cantidad, 0)) +
                                                                                                       '","partUnitPrice":"' +
                                                                                                       CONVERT(varchar(30), ISNULL(PD.PrecioUnitario, 0)) +
                                                                                                       '","availability":"' +
                                                                                                       CONVERT(varchar(30), ISNULL(AD.Disponible, 0)) +
                                                                                                       '","laborHours":"","laborHourPrice":"","comments":""}') as 'data()'
                                                                                       FROM CA_ServicioPaquetesD AS PD
                                                                                                LEFT JOIN ArtDisponible AS AD ON AD.Articulo = PD.Articulo
                                                                                       where PD.TipoArticulo = 'Normal'
                                                                                         AND PD.IdPaquete = CA_ServicioPaquetes.Id
                                                                                       FOR XML PATH('')), 2, 999999)) +
                                                              ']')
                                                                + ',"labors":' +
                                                             ('[' + (SELECT SUBSTRING((SELECT TOP 200 ',',
                                                                                                      ('{"laborName":"' +
                                                                                                       ISNULL(REPLACE(SD.Articulo, '"', ''), '') +
                                                                                                       ' ' +
                                                                                                       ISNULL(REPLACE(SD.Descripcion, '"', ''), '') +
                                                                                                       '","laborId":"' +
                                                                                                       SD.Articulo +
                                                                                                       '","laborHours":"' +
                                                                                                       CONVERT(varchar(30), ISNULL(SD.Cantidad, 0)) +
                                                                                                       '","labourHourPrice":"' +
                                                                                                       CONVERT(varchar(30), ISNULL(SD.PrecioUnitario, 0)) +
                                                                                                       '","comments":""}') as 'data()'
                                                                                       FROM CA_ServicioPaquetesD AS SD
                                                                                       where SD.TipoArticulo = 'Servicio'
                                                                                         AND SD.IdPaquete = CA_ServicioPaquetes.Id
                                                                                       FOR XML PATH('')), 2, 999999)) +
                                                              ']')
                                                                + '}') as 'data()'
                                             FROM CA_ServicioPaquetes
                                             WHERE DescripcionC LIKE '%' + @keyword + '%'
                                                OR Id LIKE '%' + @keyword + '%'
                                             FOR XML PATH('')), 2, 9999999)) + ']') AS 'jobs',

                   REPLACE(REPLACE(REPLACE(('[' + (SELECT SUBSTRING((SELECT TOP 200 ',',
                                                                                    ('{"partName":"' +
                                                                                     ISNULL(REPLACE(A.Articulo, '"', ''), '') +
                                                                                     ' ' + ISNULL(REPLACE(A.Descripcion1, '"', ''), '') +
                                                                                     '","partId":"' + A.Articulo +
                                                                                     '","quantity":1,"partUnitPrice":"' +
                                                                                     CONVERT(varchar(30), ISNULL(A.precioLista, 0)) +
                                                                                     '","availability":"' +
                                                                                     CONVERT(varchar(30), ISNULL(AD.Disponible, 0)) +
                                                                                     '","laborHours":null,"laborHourPrice":null,"comments":"' +
                                                                                     ISNULL(Descripcion2, '') +
                                                                                     '"}') as 'data()'
                                                                     FROM Art as A
                                                                              INNER JOIN ArtDisponible AS AD ON AD.Articulo = a.Articulo
                                                                     WHERE AD.Almacen = @Almacen
                                                                       AND Estatus = 'ALTA'
                                                                       AND AD.Disponible IS NOT NULL
                                                                       AND AD.Disponible >= 0
                                                                       AND (A.Descripcion1 LIKE '%' + @keyword + '%' OR
                                                                            A.Articulo LIKE '%' + @keyword + '%')
                                                                     FOR XML PATH('')), 2, 999999)) + ']'), CHAR(9),
                                           ''), CHAR(10), ''), CHAR(13), '')        AS 'parts',
                   REPLACE(REPLACE(REPLACE(('[' + (SELECT SUBSTRING((SELECT TOP 200 ',',
                                                                                    ('{"laborName":"' +
                                                                                     ISNULL(REPLACE(A.Articulo, '"', ''), '') +
                                                                                     ' ' +
                                                                                     REPLACE(ISNULL(REPLACE(A.Descripcion1, '"', ''), ''), char(39), '') +
                                                                                     '","laborId":"' + A.Articulo +
                                                                                     '","laborHours":"' +
                                                                                     CONVERT(varchar(10), ISNULL(A.Horas, 0)) +
                                                                                     '","laborHourPrice":"' +
                                                                                     CONVERT(varchar(10), ISNULL(A.CostoEstandar, 0)) +
                                                                                     '","comments":"' +
                                                                                     ISNULL(A.Descripcion2, '') +
                                                                                     '"}') as 'data()'
                                                                     FROM Art as A
                                                                     WHERE A.Tipo = 'Servicio'
                                                                       AND Categoria = 'Mano de Obra'
                                                                       AND Estatus = 'ALTA'
                                                                       AND (A.Descripcion1 LIKE '%' + @keyword + '%' OR
                                                                            A.Articulo LIKE '%' + @keyword + '%')
                                                                     FOR XML PATH('')), 2, 999999)) + ']'), CHAR(9),
                                           ''), CHAR(10), ''), CHAR(13), '')        AS 'labors'
        END
END
GO