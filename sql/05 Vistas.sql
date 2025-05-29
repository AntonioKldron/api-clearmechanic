/*******************************************************************/
/********************vwCA_CitasClearMechanics***********************/
/*******************************************************************/
IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.vwCA_CitasClearMechanics')
            AND TYPE = 'V')
    DROP VIEW dbo.vwCA_CitasClearMechanics;
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[vwCA_CitasClearMechanics] AS
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
    FORMAT(adate.dateUtc,'yyyy-MM-ddTHH:mm.ss')+'0Z'            AS date,
    -- Fecha de promesa: si hay FechaRequerida la suma 6h, 
    -- si no, FechaEmision+HoraRecepcion +14h
    COALESCE(
        FORMAT(adate.promiseDate,'yyyy-MM-ddTHH:mm.ss'),
        FORMAT((DATEADD(HOUR, 6,adate.dateUtc)),'yyyy-MM-ddTHH:mm.ss')
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
GO
/*********************************************************************/
/********************vwCA_OrdenesClearMechanics***********************/
/*********************************************************************/
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
           CONVERT(varchar(23), dbo.fnCA_UnirFechaHoraUTC(o.FechaRequerida,o.HoraRequerida,0), 127) +
           '0Z'                                                                         AS orderDate,
           ISNULL(o.ServicioTipoOrden, '')                                                    AS orderType,
           ISNULL(o.ServicioTipoOperacion, '')                                                AS serviceType,
           o.Estatus                                                                          AS status,
            COALESCE(
                CONVERT(varchar(23), dbo.fnCA_UnirFechaHoraUTC(o.FechaRequerida,o.HoraRequerida,0), 127), 
                CONVERT(varchar(23), (DATEADD(HOUR, 6,dbo.fnCA_UnirFechaHoraUTC(o.FechaEmision,o.HoraRecepcion,0))), 127)
            )+'0Z'                                                                            AS promisedDate,
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
/*********************************************************************/
/********************vwCA_VehiculosClearMechanics*********************/
/*********************************************************************/
IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.vwCA_VehiculosClearMechanics')
            AND TYPE = 'V')
    DROP VIEW dbo.vwCA_VehiculosClearMechanics;
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW vwCA_VehiculosClearMechanics AS
SELECT VIN                                                                                     AS vehicleId,
       VIN                                                                                     AS vin,
       A.Fabricante                                                                            AS brand,
       A.Descripcion1                                                                          AS model,
       VIN.Modelo                                                                              AS year,
       ISNULL(Placas, '')                                                                      AS licensePlate,
       ISNULL(Km, '')                                                                          AS kilometers,
       ISNULL(VIN.Cliente, '')                                                                 AS idClient,
       ISNULL(Cte.PersonalNombres, '')                                                         AS firstName,
       ISNULL(Cte.PersonalApellidoPaterno, '') + ' ' + ISNULL(Cte.PersonalApellidoMaterno, '') AS lastName,
       ISNULL(Cte.TelefonosLada, '') + ISNULL(Cte.Telefonos, '')                               AS mainPhone,
       ISNULL(Cte.PersonalTelefonoMovil, '')                                                   as mobile,
       ISNULL(eMail1, '')                                                                      as email
FROM VIN WITH (NOLOCK)
    INNER JOIN Cte WITH (NOLOCK) ON Cte.Cliente = VIN.Cliente
    INNER JOIN Art A WITH (NOLOCK) ON A.Articulo = VIN.Articulo
WHERE A.TIPO = 'VIN'
GO
/*********************Integracio API Nueva****************************/
/*********************************************************************/
/*********************vwCA_JobsClearMechanics*************************/
/*********************************************************************/
IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.vwCA_JobsClearMechanics')
            AND TYPE = 'V')
    DROP VIEW dbo.vwCA_JobsClearMechanics;
GO
CREATE VIEW [dbo].[vwCA_JobsClearMechanics] AS
SELECT
    source='Asesor de Servicio reporta',
    technician=ISNULL(AG.Nombre,'Sin asignar'),
    work=A.Descripcion1,
    time=VC.Cantidad,
    movid=VT.MovID
FROM
Venta VT WITH (NOLOCK)
INNER JOIN
Agente AG WITH (NOLOCK) ON AG.Agente=VT.Agente
INNER JOIN
VentaDCalc VC WITH (NOLOCK) ON VC.ID=VT.ID
INNER JOIN
Art A WITH (NOLOCK) ON A.Articulo = VC.Articulo 
WHERE vt.mov = 'Cita Servicio' AND A.categoria = 'Mano de Obra'
GO
/*********************************************************************/
/*******************vwCA_AsesoresClearMechanics***********************/
/*********************************************************************/
IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.vwCA_AsesoresClearMechanics')
            AND TYPE = 'V')
    DROP VIEW dbo.vwCA_AsesoresClearMechanics;
GO
CREATE VIEW [dbo].[vwCA_AsesoresClearMechanics] AS
SELECT 
    Tipo                                                AS tipo,
    Agente                                              AS serviceAdvisorId,
    PersonalNombres                                     AS firstName,
    PersonalApellidoPaterno+' '+PersonalApellidoMaterno  AS lastName,
    ISNULL(eMail,'')                                    AS email,
    ISNULL(Telefonos,'')                                AS mobile, 
    SucursalEmpresa                                     AS sucursal
FROM Agente WITH (NOLOCK) WHERE Estatus='ALTA'
GO
/*********************************************************************/
/*******************vwCA_GarantiasClearMechanics**********************/
/*********************************************************************/
IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.vwCA_GarantiasClearMechanics')
            AND TYPE = 'V')
    DROP VIEW dbo.vwCA_GarantiasClearMechanics;
GO
CREATE VIEW [dbo].[vwCA_GarantiasClearMechanics] AS
select 
ISNULL(movid,'') as warrantyId,
ISNULL(ServicioKms,'')AS kilometers,
J.adescription AS 'description',
Estatus as 'status',
CONVERT(varchar(32), CONVERT(datetimeoffset(0), FechaRequerida), 103) AS repairDate,
servicioSerie as vin
from 
venta WITH (NOLOCK) CROSS APPLY ( select top 1 ISNULL(VentaD.Articulo,'')+' '+ISNULL(VentaD.DescripcionExtra,'') AS adescription from ventad WITH (NOLOCK)
JOIN Art AS a WITH (NOLOCK) ON a.Articulo=ventad.Articulo 
where a.Categoria='Mano de Obra' and ventaD.ID=venta.ID)J where AnexoID IS NULL AND Mov='Servicio' AND ServicioTipoOrden='Garantia'
GO
/*********************************************************************/
/*******************vwCA_TipoOrdenClearMechanics**********************/
/*********************************************************************/
IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.vwCA_TipoOrdenClearMechanics')
            AND TYPE = 'V')
    DROP VIEW dbo.vwCA_TipoOrdenClearMechanics;
GO
CREATE VIEW [dbo].[vwCA_TipoOrdenClearMechanics] AS
SELECT 
  ServicioTipoOrden     =EVC.Concepto,
  ServicioTipoOperacion =ISNULL(CA.TipoOrden,evc.Concepto)
FROM 
  EmpresaConceptoValidar EVC WITH (NOLOCK)
LEFT JOIN
  CA_ServicioTipoOrdenValidarConcepto CA WITH (NOLOCK) ON EVC.Concepto=CA.Concepto
WHERE EVC.Mov='SERVICIO' 
GO
/*********************************************************************/
/*******************vwCA_VinCampanaClearMechanics**********************/
/*********************************************************************/
IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.vwCA_VinCampanaClearMechanics')
            AND TYPE = 'V')
    DROP VIEW dbo.vwCA_VinCampanaClearMechanics;
GO
CREATE VIEW [dbo].[vwCA_VinCampanaClearMechanics] AS
SELECT 
    campaignId=v.id,
    description=Asunto,
    vin
FROM 
CA_VINRecall V WITH (NOLOCK)
INNER JOIN
CA_VINRecallD  VD WITH (NOLOCK) ON v.id=vd.ID
go

/*********************************************************************/
/******************vwCA_ItemsQuotesClearMechanicsAPI******************/
/*********************************************************************/
IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.vwCA_ItemsQuotesClearMechanicsAPI')
            AND TYPE = 'V')
    DROP VIEW dbo.vwCA_ItemsQuotesClearMechanicsAPI;
GO
CREATE VIEW [dbo].[vwCA_ItemsQuotesClearMechanicsAPI] AS 
SELECT 
    vt.id                           AS idVenta,
    vtd.Renglon                     AS renglonId,
    art.descripcion1                AS itemName,
    art.Articulo                    AS itemId,
    CASE 
        WHEN art.Categoria = 'Refacciones' THEN COALESCE(vtd.Cantidad - COALESCE(vtd.CantidadCancelada, 0), 0)
        ELSE NULL
    END AS quantity,
    CASE 
        WHEN art.Categoria = 'Refacciones' THEN COALESCE(art.PrecioLista, 0)
        ELSE NULL
    END AS unitPrice,
    COALESCE(aei.inventario, 0)     AS availability,
    CASE 
        WHEN art.Categoria = 'Mano de Obra' THEN (COALESCE(vtd.Cantidad - COALESCE(vtd.CantidadCancelada, 0), 0) * 60)
        ELSE NULL
    END AS hours,
    CASE 
        WHEN art.Categoria = 'Mano de Obra' THEN COALESCE(art.PrecioLista, 0)
        ELSE NULL
    END AS hourPrice,
    COALESCE(vtc.PrecioTotal, 0)         AS subtotal,
    vtd.Almacen                     AS warehouseId,
    CASE 
        WHEN vt.estatus = 'CANCELADO' THEN 'Rejected'
        WHEN vt.estatus IN ('CONCLUIDO', 'CONFIRMAR') THEN 'Approved'
        WHEN vt.estatus IN ('PENDIENTE', 'SINAFECTAR') THEN 'Pending'
        ELSE NULL
    END                             AS status,
    COALESCE(art.Categoria, '')     AS typeArt
FROM Venta vt WITH (NOLOCK)
INNER JOIN VentaD vtd WITH (NOLOCK) ON vt.id = vtd.id
INNER JOIN Art art WITH (NOLOCK) ON vtd.Articulo = art.Articulo
INNER JOIN ventatcalc vtc WITH (NOLOCK) ON vt.id=vtc.id and art.Articulo=vtc.articulo and vtd.renglon=vtc.renglon
OUTER APPLY (
    SELECT SUM(Existencia) AS inventario 
    FROM ArtExistenciaNeta  WITH (NOLOCK)
    WHERE Articulo = art.Articulo 
    AND Almacen =vtd.Almacen
) aei
WHERE 
    COALESCE(vtd.Precio, 0) > 0
    AND COALESCE(vtd.Cantidad - COALESCE(vtd.CantidadCancelada, 0), 0) > 0
    AND art.Categoria IN ('Refacciones', 'Mano de Obra')
GO
/*********************************************************************/
/********************vwCA_QuotesClearMechanicsAPI*********************/
/*********************************************************************/
IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.vwCA_QuotesClearMechanicsAPI')
            AND TYPE = 'V')
    DROP VIEW dbo.vwCA_QuotesClearMechanicsAPI;
GO
CREATE VIEW [dbo].[vwCA_QuotesClearMechanicsAPI] AS 
WITH DetalleSuma AS (
    SELECT 
        vtc.ID,
        SUM(ISNULL(vtc.DescuentosTotales,0)) AS discounts, 
        SUM(COALESCE(vtc.precioTotal, 0)) AS subtotal, 
        SUM(COALESCE(vtc.Impuestos, 0)) AS taxes,
		SUM(ISNULL(vtd.cantidad,0)) - COALESCE(COALESCE(SUM(vtd.cantidadcancelada), 0) + COALESCE(SUM(vtd.cantidadpendiente), 0), 0)AS approved,
		COALESCE(SUM(vtd.cantidadcancelada), 0) AS declined,
		COALESCE(SUM(vtd.cantidadpendiente), 0) AS pending
    FROM ventaTCalc vtc WITH (NOLOCK)
	INNER JOIN Art WITH (NOLOCK) ON vtc.articulo=Art.Articulo
	INNER JOIN ventaD vtd WITH (NOLOCK) ON vtd.id=vtc.id and vtd.renglon = vtc.renglon AND vtd.articulo=art.articulo
	WHERE 
	art.Categoria IN ('Refacciones', 'Mano de Obra')
    AND
	COALESCE(vtd.Precio, 0) > 0
	GROUP BY vtc.ID
)
SELECT 
  ventaID                       =   vt.id,
  customerId                    =   ct.customerIdCM,--Identificador del cliente en CMOS.
  orderNumber                   =   vt.MovID,--Número de orden.
  date                          =   vt.UltimoCambio,--Fecha de la orden.
  orderNotes                    =   vt.Comentarios,--Notas de la orden.
  firstName                     =   cte.PersonalNombres,--Nombre del cliente.
  lastName                      =   cte.PersonalApellidoPaterno+' '+cte.PersonalApellidoMaterno,--Apellido del cliente.
  email                         =   cte.eMail1,--Correo electrónico del cliente.
  mobile                        =   cte.PersonalTelefonoMovil,--Número de teléfono móvil del cliente.
  phoneNumber                   =   cte.TelefonosLada +''+cte.Telefonos,--Número de teléfono del cliente.
  vin                           =   vt.ServicioSerie,--Número de identificación del vehículo.
  brand                         =   artvin.Fabricante,--Marca del vehículo.
  model                         =   artvin.Descripcion1,--Modelo del vehículo.
  year                          =   ISNULL(vt.serviciomodelo,artvin.modelo),--Año del vehículo.
  licensePlates                 =   isnull(vin.Placas,vt.ServicioPlacas),--Placas del vehículo.
  kilometers                    =   vin.Km,--kilomatraje
  businessName                  =   cte.Nombre,--Nombre del negocio.
  identificationDocumentType    =   NULL,--Tipo de documento de identificación.
  identificationDocumentNumber  =   NULL,--Número de documento de identificación.
  paymentMethod                 =   COALESCE(NULLIF(vt.FormaPagoTipo, ''), 'Efectivo'),--Método de pago.
  phase                         =   CASE 
										WHEN vt.estatus = 'CANCELADO' THEN 'Rejected'
										WHEN vt.estatus IN ('CONCLUIDO', 'CONFIRMAR') THEN 'Approved'
										WHEN vt.estatus IN ('PENDIENTE', 'SINAFECTAR') THEN 'Pending'
										ELSE NULL
									END,--Fase de la orden.
  tower                         =   vt.ServicioNumero,--Torre de la orden.
  orderType                     =   vt.ServicioTipoOrden,--Tipo de orden.
  userInCharge                  =   ag.Nombre,--Usuario a cargo de la orden.
  dmsIduserInCharge             =   ag.Agente,--
  assignedUser                  =   ag.Nombre,--Usuario asignado a la orden.
  dmsIdassignedUser             =   ag.Agente,--
  estimateNotes                 =   vt.SituacionNota,--Notas del presupuesto.
  discounts                     =   CONVERT(FLOAT,ISNULL(vtcl.discounts,0)),--Descuentos aplicados.
  subtotal                      =   COALESCE(vtcl.subtotal,0),--vtcl.subTotal,--Subtotal.
  taxes                         =   COALESCE(vtcl.taxes,0),--Impuestos.
  approved                      =   COALESCE(vtcl.approved,0),--Cantidad aprobada.
  declined                      =   COALESCE(vtcl.declined,0),--Cantidad rechazada.
  pending                       =   COALESCE(vtcl.pending,0),--Cantidad pendiente.
  totalEstimated                =   CAST((vtcl.subtotal - ISNULL(vtcl.discounts, 0) + vtcl.taxes) AS FLOAT),--Total estimado.
  inspectionLink                =   NULL,--Enlace de inspección.
  userInChargeCmosId            =   cag.serviceAdvisorId,--ID de CMOS del usuario a cargo de la OR.
  userInChargeDmsId             =   ag.Agente,--dmsId del usuario a cargo de la OR.
  assignedUserCmosId            =   cag.serviceAdvisorId,--ID de CMOS del usuario a cargo de la OR.
  assignedUserDmsId             =   ag.Agente,--ID de CMOS del usuario a cargo de la OR.
  items                         =   dbo.fnCA_ItemsQuotesClearMechanicsAPI(vt.id)--Ítems de la orden.

FROM Venta vt
INNER JOIN Cte ON vt.Cliente=cte.Cliente
LEFT JOIN CA_Cte ct ON Cte.Cliente=ct.Cliente
INNER JOIN VIN on vt.ServicioSerie=vin.VIN
LEFT JOIN Art artvin on artvin.Articulo = vin.Articulo
INNER JOIN Agente ag on vt.Agente=ag.Agente
LEFT JOIN CA_AGENTE cag on cag.Agente=ag.Agente
INNER JOIN DetalleSuma vtcl on vt.id=vtcl.id
GO
