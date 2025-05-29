IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.vwCA_OrdenesClearMechanics')
            AND TYPE = 'V')
    DROP VIEW dbo.vwCA_OrdenesClearMechanics;
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[vwCA_OrdenesClearMechanics] AS
    SELECT o.ID                                                                               AS orderId,
           ISNULL(o.MovID, '')                                                                AS orderNumber,
           o.Agente                                                                           AS serviceAdvisorId,
           CONVERT(VARCHAR(10), ISNULL(o.FechaEmision, ''), 126) + 'T' + ISNULL(o.HoraRecepcion, '') +
           ':00.000Z'                                                                         AS orderDate,
           ISNULL(o.ServicioTipoOrden, '')                                                    AS orderType,
           ISNULL(o.ServicioTipoOperacion, '')                                                AS serviceType,
           o.Estatus                                                                          AS status,
           CONVERT(VARCHAR(10), ISNULL(o.FechaRequerida, ''), 126) + 'T' +
           ISNULL(o.HoraRequerida, '') +
           ':00.000Z'                                                                         AS promisedDate,
           o.Importe                                                                          AS total,
           case
               when MTOpen.FechaComenzo IS NOT NULL then CONVERT(VARCHAR(23), MTOpen.FechaComenzo, 126) + 'Z'
               else '' end                                                                    as openDate,
           case
               when MTClose.FechaComenzo IS NOT NULL then CONVERT(VARCHAR(23), MTClose.FechaComenzo, 126) + 'Z'
               else '' end                                                                    as closedDate,
           case
               when o.FechaEmision IS NOT NULL then CONVERT(VARCHAR(23), o.FechaEmision, 126) + '0Z'
               else '' end                                                                    AS checkin,
           case
               when o.FechaRequerida IS NOT NULL then CONVERT(VARCHAR(23), o.FechaRequerida, 126) + '0Z'
               else '' end                                                                    AS checkout,
           ISNULL(o.ServicioSerie, '')                                                        AS vin,
           ISNULL(artvin.Fabricante, '')                                                      AS brand,
           ISNULL(artvin.Descripcion1, '')                                                    AS model,
           ISNULL(artvin.Modelo, '')                                                          AS year,
           ISNULL(vin.Placas, '')                                                             AS licensePlate,
           CONVERT(VARCHAR(20), ISNULL(
            CASE 
                WHEN O.estatus IN ('PENDIENTE') THEN vin.Km
                ELSE vin.Km
            END
            , ''))                                           AS kilometers,
           (
               case
                   when artvin.categoria = 'Refacciones'
                       then
                       vdin.Preciototal
                   else
                       0.00
                   end
               )                                                                              AS customerParts,
           --ISNULL((select SUM(Preciototal) from ventatcalc vdin
           --INNER JOIN Art A ON A.Articulo = vdin.Articulo
           --where A.categoria='Refacciones' AND vdin.id = o.ID
           --group by vdin.id),'') AS customerParts,
           (
               case
                   when artvin.Tipo = 'Servicio' and artvin.categoria not in ('TOT', 'Refacciones')
                       then
                       vdin.Preciototal
                   else
                       0.00
                   end
               )                                                                              AS customerLabor,
           --ISNULL((select SUM(Preciototal) from ventatcalc vdin
           --INNER JOIN Art A ON A.Articulo = vdin.Articulo
           --where A.Tipo = 'Servicio' AND A.categoria not in ('TOT','Refacciones') AND vdin.id = o.ID
           --group by vdin.id),'') AS customerLabor,
           (
               case
                   when artvin.Tipo NOT IN ('Servicio', 'REFAC') and artvin.categoria NOT IN ('TOT', 'Refacciones')
                       AND (artvin.Rama = 'REFAC' AND
                            (artvin.Descripcion1 NOT LIKE '%gasolina%' or artvin.Descripcion1 NOT LIKE '%ACEITE%' or
                             artvin.Descripcion1 NOT LIKE '%GRASA%'))
                       then
                       vdin.Preciototal
                   else
                       0.00
                   end
               )                                                                              AS customerMisc,
           (
               case
                   when artvin.categoria = 'TOT'
                       then
                       vdin.Preciototal
                   else
                       0.00
                   end
               )                                                                              AS totsCost,
           (
               case
                   when artvin.Rama = 'REFAC' AND
                        (artvin.Descripcion1 LIKE '%gasolina%' or artvin.Descripcion1 LIKE '%ACEITE%' or
                         artvin.Descripcion1 LIKE '%GRASA%')
                       then
                       vdin.Preciototal
                   else
                       0.00
                   end
               )                                                                              AS gogCost,


           vdin.Preciototal                                                                   AS totalBeforeTaxes,

           ISNULL(
                   (SELECT TOP 1
                        CONVERT(VARCHAR(10), ISNULL(FV.FechaEmision, ''), 126) + ' ' + ISNULL(FV.HoraRecepcion, '')
                    FROM VENTA FV
                    WHERE FV.ORIGENID = o.MOVID),
                   '')                                                                        AS invoiceDate,

           '{"insuranceVehiclesData": "","insurancePolicyNumber": "","insuranceCompany": ""}' AS insuranceData,

           ISNULL((select TOP 1 vdin.Agente
                   from VentaD vdin
                   where vdin.id = o.id),
                  '')                                                                         AS technicianId,
           ISNULL(o.ServicioNumero, '')                                                       AS towerNumber,
           (
               case
                   when artvin.Tipo = 'Servicio' AND artvin.categoria not in ('TOT', 'Refacciones')
                       then
                       vdin.Preciototal
                   else
                       0.00
                   end
               )                                                                              AS utsSold,
           ISNULL(o.Observaciones, '')                                                        AS comments,
           o.Cliente                                                                          AS clientId,
           IIF(LEN(CTE.RFC) = 12, ISNULL(CTE.NOMBRE, ''), ISNULL(dbo.Cte.PersonalNombres, 
           (dbo.fnCA_fnDivideNombre(dbo.cte.Nombre,'nombre'))))                                AS firstName,
           IIF(LEN(CTE.RFC) = 12,'',ISNULL(dbo.Cte.PersonalApellidoPaterno, 
           (dbo.fnCA_fnDivideNombre(dbo.cte.Nombre,'Paterno'))) + ' ' +
           ISNULL(dbo.Cte.PersonalApellidoMaterno, 
           (dbo.fnCA_fnDivideNombre(dbo.cte.Nombre,'Materno'))))                               AS lastName,
           ISNULL(Cte.Direccion, '') + ',#' + ISNULL(Cte.DireccionNumero, '') + ' ' +
           ISNULL(Cte.DireccionNumeroInt, '') +
           ',col. ' + ISNULL(Cte.Colonia, '') + ',CP. ' + ISNULL(Cte.CodigoPostal, '') + ',del. ' +
           ISNULL(Cte.Delegacion, '') + ',pobl. ' + ISNULL(Cte.Poblacion, '') + ',Edo. ' + ISNULL(Cte.Estado, '') +
           ',' +
           ISNULL(Cte.Pais, '')                                                               AS 'address',
           ISNULL(Cte.Poblacion, '')                                                          AS City,
           ISNULL(Cte.Estado, '')                                                             AS 'State',
           ISNULL(Cte.CodigoPostal, '')                                                       AS zip,
           ISNULL(Cte.TelefonosLada, '') + ISNULL(Cte.Telefonos, '')                          AS mainPhone,
           ISNULL(Cte.PersonalTelefonoMovil, '')                                              AS mobile,
           ISNULL(Cte.eMail1, '')                                                             AS email,
           o.FechaEmision                                                                     AS FechaEmision,
           o.sucursal                                                                         AS Sucursal
    FROM VENTA AS o WITH (NOLOCK)
             INNER JOIN dbo.Cte WITH (NOLOCK) ON o.Cliente = dbo.Cte.Cliente
             LEFT JOIN MovTiempo MTOpen WITH (NOLOCK)
                       ON MTOpen.Modulo = 'VTAS' AND MTOpen.IDOrden = o.ID AND MTOpen.Situacion = 'Asignada'
             LEFT JOIN MovTiempo MTClose WITH (NOLOCK) 
                       ON MTClose.Modulo = 'VTAS' AND MTClose.IDOrden = o.ID AND MTClose.Situacion = 'Orden Cerrada'
             LEFT JOIN vin WITH (NOLOCK) on o.ServicioSerie = vin.vin 
             LEFT JOIN art artvin WITH (NOLOCK) on vin.articulo = artvin.articulo
             LEFT JOIN ventatcalc vdin WITH (NOLOCK) on vdin.ID = o.ID and vdin.Articulo = artvin.articulo
    where o.Estatus IN ('CANCELADO', 'PENDIENTE', 'CONCLUIDO')
      AND o.Mov = 'Servicio'
      --AND o.ServicioTipoOrden = 'Publico'
      AND O.AnexoID IS NULL
GO

/***/

SELECT DISTINCT v.MovID                                         AS appointmentId,
    COALESCE(o.MovID, '')                                       AS orderId,
    v.Estatus                                                   AS status,
    c.Cliente                                                   AS clientId,
    -- Nombre dividido
    nd.firstName,
    nd.lastName,
    -- Dirección formateada
    ad.address,
    -- Teléfonos
    ph.mainPhone,
    ph.secondaryPhone,
    ph.mobile,
    -- Contacto
    COALESCE(c.eMail1, '')                                      AS email,
    v.Agente                                                    AS serviceAdvisorId,
    -- Datos del vehículo
    dbo.fnCA_DepuraVIN(COALESCE(v.ServicioSerie, ''))			AS vin,
    COALESCE(v.ServicioPlacas, '')                              AS licensePlate,
    COALESCE(artvin.Fabricante, '')                             AS brand,
    COALESCE(artvin.Descripcion1, '')                           AS model,
    COALESCE(v.serviciomodelo, '')                              AS year,
    -- Fecha de cita en UTC (FechaEmision+HoraRecepcion +6h)
    CONVERT(varchar(23),adate.dateUtc,127)+'0Z'                  AS date,
    -- Fecha de promesa: si hay FechaRequerida la suma 6h, 
    -- si no, FechaEmision+HoraRecepcion +14h
    COALESCE(
        CONVERT(varchar(23), adate.promiseDate, 127), 
        CONVERT(varchar(23), (DATEADD(HOUR, 6,adate.dateUtc)), 127)
    ) +'0Z'                                                     AS promiseDate,
    -- Flags y metadatos
    IIF(v.Estatus = 'CONFIRMAR', '1', '0')                      AS confirmed,
    COALESCE(c.Nombre, '')                                      AS socialName,
    COALESCE(v.Observaciones, '')                               AS comments,
    ''                                                          AS preOrderId,
    COALESCE(v.ServicioTipoOrden, '')                           AS orderTypeId,
    COALESCE(v.ServicioTipoOrden, '')                           AS orderType,
    COALESCE(v.ServicioTipoOperacion, '')                       AS serviceType,
    IIF(v.ServicioTipoOperacion = 'Mantenimiento', '1', '0')    AS isService,
    IIF(v.ServicioTipoOperacion = 'Reparacion',    '1', '0')    AS isRepair,
    IIF(v.ServicioTipoOperacion = 'Diagnostico',   '1', '0')    AS isDiagnostic,
    v.Mov                                                       AS mainType,
    ''                                                          AS secondType,
    ''                                                          AS thirdType,
    COALESCE(v.Agente, '')                                      AS appointmentPersonId,
    v.FechaEmision                                              AS FechaEmision,
    v.Sucursal                                                  AS Sucursal
from     
    -- Filtrado previo para evitar filas innecesarias
    dbo.Venta AS v WITH (NOLOCK)
    INNER JOIN dbo.Cte   AS c       WITH (NOLOCK) ON v.Cliente = c.Cliente
    LEFT  JOIN dbo.VIN   AS vin     WITH (NOLOCK) ON v.ServicioSerie = vin.VIN
    LEFT  JOIN dbo.Art   AS artvin  WITH (NOLOCK) ON vin.Articulo = artvin.Articulo
    LEFT  JOIN dbo.Venta AS o       WITH (NOLOCK) ON v.MovID = o.OrigenID AND v.Mov   = o.Origen
    -- División de nombre
    CROSS APPLY (
      SELECT
        IIF(
          LEN(c.RFC) = 12,
          COALESCE(c.Nombre, ''),
          COALESCE(c.PersonalNombres, dbo.fnCA_fnDivideNombre(c.Nombre, 'nombre'))
        )                                   AS firstName,
        IIF(
          LEN(c.RFC) = 12,
          '',
          COALESCE(c.PersonalApellidoPaterno, dbo.fnCA_fnDivideNombre(c.Nombre,'Paterno'))
          + ' '
          + COALESCE(c.PersonalApellidoMaterno, dbo.fnCA_fnDivideNombre(c.Nombre,'Materno'))
        )                                   AS lastName
    ) AS nd
    -- Dirección compuesta
    CROSS APPLY (
      SELECT
        COALESCE(c.Direccion, '')     + ',#' + COALESCE(c.DireccionNumero, '') + ' '
      + COALESCE(c.DireccionNumeroInt, '') + ',col. ' + COALESCE(c.Colonia, '')
      + ',CP. ' + COALESCE(c.CodigoPostal, '') + ',del. ' + COALESCE(c.Delegacion, '')
      + ',pobl. ' + COALESCE(c.Poblacion, '') + ',Edo. ' + COALESCE(c.Estado, '')
      + ','    + COALESCE(c.Pais, '')            AS address
    ) AS ad
    -- Teléfonos
    CROSS APPLY (
      SELECT
        COALESCE(c.TelefonosLada,'') + COALESCE(c.Telefonos,'')     AS mainPhone,
        COALESCE(c.PersonalTelefonoMovil,'')                        AS secondaryPhone,
        COALESCE(c.PersonalTelefonoMovil,'')                        AS mobile
    ) AS ph
    -- Fecha de cita (UTC)
    CROSS APPLY (
	  SELECT
        dbo.fnCA_UnirFechaHoraUTC(v.FechaEmision,v.HoraRecepcion,1)
        AS dateUtc,
        dbo.fnCA_UnirFechaHoraUTC(v.FechaRequerida,v.HoraRequerida,1)
      AS promiseDate
    ) AS adate
WHERE
    v.Mov    = 'cita servicio'
    AND v.Estatus <> 'SINAFECTAR'
	AND v.MovId IS NOT NULL
    AND v.FechaEmision=CAST(GETDATE() as date)


/***/
WITH TechnicianCTE AS (
    SELECT 
        vdin.id,
        vdin.Agente,
        ROW_NUMBER() OVER (PARTITION BY vdin.id ORDER BY (SELECT NULL)) AS rn  
    FROM VentaD vdin WITH (NOLOCK)
),
InvoiceDateCTE AS (
    SELECT
        FV.ORIGENID,
        FV.ORIGEN,
        FV.FechaEmision,
        FV.HoraRecepcion
    FROM VENTA FV WITH (NOLOCK)
    WHERE FV.Mov = 'SERVICIO'
      AND FV.Estatus IN ('CANCELADO', 'PENDIENTE', 'CONCLUIDO')
)

SELECT TOP 50
    o.ID AS orderId,
    ISNULL(o.MovID, '') AS orderNumber,
    o.Agente AS serviceAdvisorId,

    -- Fechas
    ISNULL(CONVERT(varchar(23), adate.dateUtc, 127) + '0Z', '') AS orderDate,
    ISNULL(CONVERT(varchar(23), adate.dataPromised, 127) + '0Z', 
           CONVERT(varchar(23), DATEADD(HOUR, 6, adate.dateUtc), 127) + '0Z') AS promisedDate,
    ISNULL(CONVERT(varchar(23), adate.openDateUtc, 127) + '0Z', '') AS openDate,
    ISNULL(CONVERT(varchar(23), adate.closedDateUtc, 127) + '0Z', '') AS closedDate,
    ISNULL(CONVERT(varchar(23), adate.checkinUtc, 127) + '0Z', '') AS checkin,
    ISNULL(CONVERT(varchar(23), adate.checkout, 127) + '0Z', '') AS checkout,
    ISNULL(adate.invoiceDate, '') AS invoiceDate,

    -- Información del servicio
    ISNULL(o.ServicioTipoOrden, '') AS orderType,
    ISNULL(o.ServicioTipoOperacion, '') AS serviceType,
    o.Estatus AS status,
    o.Importe AS total,
    ISNULL(o.ServicioNumero, '') AS towerNumber,
    ISNULL(o.Observaciones, '') AS comments,

    -- Cliente y vehículo
    ISNULL(dbo.fnCA_DepuraVin(o.ServicioSerie), '') AS vin,
    ISNULL(artvin.Fabricante, '') AS brand,
    ISNULL(artvin.Descripcion1, '') AS model,
    ISNULL(o.ServicioModelo, artvin.Modelo) AS year,
    ISNULL(o.ServicioPlacas, vin.Placas) AS licensePlate,
    ISNULL(o.ServicioKms, vin.Km) AS kilometers,
    o.Cliente AS clientId,
    nd.firstName,
    nd.lastName,
    ad.address AS address,
    ISNULL(c.Poblacion, '') AS City,
    ISNULL(c.Estado, '') AS State,
    ISNULL(c.CodigoPostal, '') AS zip,
    ISNULL(c.TelefonosLada, '') + ISNULL(c.Telefonos, '') AS mainPhone,
    ISNULL(c.PersonalTelefonoMovil, '') AS mobile,
    ISNULL(c.eMail1, '') AS email,

    -- Costos
    cs.customerParts,
    cs.customerLabor,
    cs.customerMisc,
    cs.totsCost,
    cs.gogCost,
    vdin.Preciototal AS totalBeforeTaxes,
    cs.utsSold,

    -- Otros
    ISNULL(tc.Agente, '') AS technicianId,
    o.FechaEmision,
    o.Sucursal,
    '{"insuranceVehiclesData": "", "insurancePolicyNumber": "", "insuranceCompany": ""}' AS insuranceData

FROM Venta o WITH (NOLOCK)
INNER JOIN Cte c ON o.Cliente = c.Cliente
LEFT JOIN MovTiempo MTOpen ON MTOpen.Modulo = 'VTAS' AND MTOpen.IDOrden = o.ID AND MTOpen.Situacion = 'Asignada'
LEFT JOIN MovTiempo MTClose ON MTClose.Modulo = 'VTAS' AND MTClose.IDOrden = o.ID AND MTClose.Situacion = 'Orden Cerrada'
LEFT JOIN vin ON dbo.fnCA_DepuraVin(o.ServicioSerie) = vin.vin
LEFT JOIN art artvin ON vin.articulo = artvin.articulo
LEFT JOIN ventatcalc vdin ON vdin.ID = o.ID AND vdin.Articulo = artvin.articulo
LEFT JOIN TechnicianCTE tc ON tc.id = o.ID AND tc.rn = 1
LEFT JOIN InvoiceDateCTE ic ON ic.ORIGEN = 'Servicio' AND ic.ORIGENID = o.MovID

-- CROSS APPLY para nombre
CROSS APPLY (
    SELECT
        IIF(LEN(c.RFC) = 12, ISNULL(c.Nombre, ''), ISNULL(c.PersonalNombres, dbo.fnCA_fnDivideNombre(c.Nombre, 'nombre'))) AS firstName,
        IIF(LEN(c.RFC) = 12, '', 
            ISNULL(c.PersonalApellidoPaterno, dbo.fnCA_fnDivideNombre(c.Nombre, 'Paterno')) + ' ' + 
            ISNULL(c.PersonalApellidoMaterno, dbo.fnCA_fnDivideNombre(c.Nombre, 'Materno'))
        ) AS lastName
) AS nd

-- CROSS APPLY para dirección
CROSS APPLY (
    SELECT 
        ISNULL(c.Direccion, '') + ',#' + ISNULL(c.DireccionNumero, '') + ' ' +
        ISNULL(c.DireccionNumeroInt, '') + ',col. ' + ISNULL(c.Colonia, '') + ',CP. ' + 
        ISNULL(c.CodigoPostal, '') + ',del. ' + ISNULL(c.Delegacion, '') + ',pobl. ' + 
        ISNULL(c.Poblacion, '') + ',Edo. ' + ISNULL(c.Estado, '') + ',' + 
        ISNULL(c.Pais, '') AS address
) AS ad

-- CROSS APPLY para desglose de costos
CROSS APPLY (
    SELECT
        CASE WHEN artvin.Tipo = 'Servicio' AND artvin.categoria NOT IN ('TOT', 'Refacciones') THEN vdin.Preciototal ELSE 0.00 END AS utsSold,
        CASE WHEN artvin.categoria = 'Refacciones' THEN vdin.Preciototal ELSE 0.00 END AS customerParts,
        CASE WHEN artvin.Tipo = 'Servicio' AND artvin.categoria NOT IN ('TOT', 'Refacciones') THEN vdin.Preciototal ELSE 0.00 END AS customerLabor,
        CASE 
            WHEN artvin.Tipo NOT IN ('Servicio', 'REFAC') AND artvin.categoria NOT IN ('TOT', 'Refacciones') AND 
                 artvin.Rama = 'REFAC' AND artvin.Descripcion1 NOT LIKE '%gasolina%' AND 
                 artvin.Descripcion1 NOT LIKE '%ACEITE%' AND artvin.Descripcion1 NOT LIKE '%GRASA%'
            THEN vdin.Preciototal ELSE 0.00 
        END AS customerMisc,
        CASE WHEN artvin.categoria = 'TOT' THEN vdin.Preciototal ELSE 0.00 END AS totsCost,
        CASE 
            WHEN artvin.Rama = 'REFAC' AND (
                artvin.Descripcion1 LIKE '%gasolina%' OR
                artvin.Descripcion1 LIKE '%ACEITE%' OR
                artvin.Descripcion1 LIKE '%GRASA%')
            THEN vdin.Preciototal ELSE 0.00 
        END AS gogCost
) AS cs

-- CROSS APPLY para fechas
CROSS APPLY (
    SELECT
        dbo.fnCA_UnirFechaHoraUTC(o.FechaEmision, o.HoraRecepcion, 0) AS dateUtc,
        dbo.fnCA_UnirFechaHoraUTC(o.FechaRequerida, o.HoraRequerida, 0) AS dataPromised,
        MTOpen.FechaComenzo AS openDateUtc,
        MTClose.FechaComenzo AS closedDateUtc,
        o.FechaEmision AS checkinUtc,
        o.FechaRequerida AS checkout,
        LEFT(TRY_CAST(dbo.fnCA_UnirFechaHoraUTC(ic.FechaEmision, ic.HoraRecepcion, 0) AS datetime2), 16) AS invoiceDate
) AS adate

WHERE o.Estatus IN ('CANCELADO', 'PENDIENTE', 'CONCLUIDO')
  AND o.Mov = 'Servicio'
  AND o.AnexoID IS NULL
ORDER BY o.ID DESC
