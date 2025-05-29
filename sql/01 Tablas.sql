/*******************************************************************/
/********************CA_CatParametros*******************************/
/*******************************************************************/
IF NOT EXISTS (SELECT *
               FROM sys.objects
               WHERE object_id = OBJECT_ID(N'[dbo].[CA_CatParametros]')
                 AND type in (N'U'))
    BEGIN
        CREATE TABLE [dbo].[CA_CatParametros]
        (
            [Clave]        [varchar](30)  NOT NULL,
            [Tipo]         [varchar](20)  NOT NULL,
            [Marca]        [varchar](30)  NULL,
            [Grupo]        [varchar](50)  NULL,
            [DescCorta]    [varchar](200) NOT NULL,
            [DescCompleta] [varchar](max) NULL
        ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
    END
GO
/*******************************************************************/
/********************CA_CatParametrosSucursal***********************/
/*******************************************************************/
IF NOT EXISTS (SELECT *
               FROM sys.objects
               WHERE object_id = OBJECT_ID(N'[dbo].[CA_CatParametrosSucursal]')
                 AND type in (N'U'))
    BEGIN
        CREATE TABLE [dbo].[CA_CatParametrosSucursal]
        (
            [Empresa]     [varchar](5)   NOT NULL,
            [Sucursal]    [int]          NOT NULL,
            [Clave]       [varchar](30)  NOT NULL,
            [Descripcion] [varchar](200) NULL,
            [Grupo]       [varchar](20)  NULL,
            [Valor]       [varchar](100) NULL
        ) ON [PRIMARY]
    END
GO
/*******************************************************************/
/********************CA_LOGClearMechanics***************************/
/*******************************************************************/
IF NOT EXISTS (SELECT *
               FROM sys.objects
               WHERE object_id = OBJECT_ID(N'[dbo].[CA_LOGClearMechanics]')
                 AND type in (N'U'))
    BEGIN
        CREATE TABLE [dbo].[CA_LOGClearMechanics]
        (
            [vin]              [varchar](25)        NULL,
            [sucursal]         [int]                NULL,
            [serviceAdvisorId] [varchar](25)        NULL,
            [promisedDate]     [varchar](25)        NULL,
            [kilometers]       [int]                NULL,
            [orderType]        [varchar](50)        NULL,
            [cone]             [varchar](25)        NULL,
            [appointmentId]    [varchar](25)        NULL,
            [ID]               [int] IDENTITY (1,1) NOT NULL,
            [FECHA]            [datetime]           NULL DEFAULT (getdate())
        ) ON [PRIMARY]
    END
GO
/*******************************************************************/
/********************CA_LOGClearMechanics***************************/
/*******************************************************************/
IF NOT EXISTS (SELECT *
               FROM sys.objects
               WHERE object_id = OBJECT_ID(N'[dbo].[CA_LOGClearMechanics]')
                 AND type in (N'U'))
    BEGIN
        CREATE TABLE [dbo].[CA_ClearmechanicsOffers]
        (
            [id]           [int] IDENTITY (1,1) NOT NULL,
            [titulo]       [varchar](250)       NOT NULL,
            [descripcion]  [varchar](5000)      NULL,
            [precio]       [money]              NULL,
            [vin]          [varchar](20)        NULL,
            [modelo]       [varchar](100)       NULL,
            [fecha_inicio] [datetime]           NULL,
            [fecha_fin]    [datetime]           NULL,
            [eliminado]    [bit]                NOT NULL DEFAULT ((0))
        ) ON [PRIMARY]
    END
GO
/*******************************************************************/
/********************CA_ServicioPaquetes****************************/
/*******************************************************************/
IF NOT EXISTS (SELECT *
               FROM sys.objects
               WHERE object_id = OBJECT_ID(N'[dbo].[CA_ServicioPaquetes]')
                 AND type in (N'U'))
    BEGIN
        CREATE TABLE [dbo].[CA_ServicioPaquetes]
        (
            [Id]            [int] IDENTITY (1,1) NOT NULL,
            [DescripcionC]  [varchar](150)       NOT NULL,
            [DescripcionL]  [varchar](250)       NULL,
            [TipoPaquete]   [varchar](30)        NULL,
            [Kilometraje]   [int]                NULL,
            [Precio]        [money]              NULL,
            [TipoPrecio]    [varchar](20)        NULL,
            [Prorrateo]     [varchar](25)        NULL,
            [TTabulador]    [float]              NULL,
            [TFacturado]    [float]              NULL,
            [ClavePlanta]   [varchar](100)       NULL,
            [Estatus]       [int]                NULL,
            [Actualizacion] [smalldatetime]      NULL,
            [TipoArticulo]  [varchar](20)        NULL,
            [Origen]        [varchar](100)       NULL,
            [PrecioTotal]   [money]              NULL,
            [InternalId]    [varchar](20)        NULL
        ) ON [PRIMARY]
    END
GO
/*******************************************************************/
/********************CA_ServicioPaquetesD***************************/
/*******************************************************************/
IF NOT EXISTS (SELECT *
               FROM sys.objects
               WHERE object_id = OBJECT_ID(N'[dbo].[CA_ServicioPaquetesD]')
                 AND type in (N'U'))
    BEGIN
        CREATE TABLE [dbo].[CA_ServicioPaquetesD]
        (
            [IdPaquete]       [int]           NOT NULL,
            [Renglon]         [float]         NOT NULL,
            [Articulo]        [varchar](20)   NULL,
            [SubtipoCuenta]   [varchar](20)   NULL,
            [Cantidad]        [float]         NULL,
            [TTabulado]       [float]         NULL,
            [AlmacenEsp]      [varchar](10)   NULL,
            [ListaPreciosEsp] [varchar](20)   NULL,
            [PrecioUnitario]  [money]         NULL,
            [PrecioTotal]     [money]         NULL,
            [Actualizacion]   [smalldatetime] NULL,
            [TipoArticulo]    [varchar](20)   NULL,
            [Descripcion]     [varchar](100)  NULL,
            CONSTRAINT [pkCA___Servicio__7E1E34280C85DE4D] PRIMARY KEY CLUSTERED
                (
                 [IdPaquete] ASC,
                 [Renglon] ASC
                    ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
        ) ON [PRIMARY]
    END
GO
/*******************************************************************/
/********************CA_ClearmechanicsOffers************************/
/*******************************************************************/
IF NOT EXISTS (SELECT *
               FROM sys.objects
               WHERE object_id = OBJECT_ID(N'[dbo].[CA_ClearmechanicsOffers]')
                 AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[CA_ClearmechanicsOffers](
    	[id] [int] IDENTITY(1,1) NOT NULL,
    	[titulo] [varchar](250) NOT NULL,
    	[descripcion] [varchar](5000) NULL,
    	[precio] [money] NULL,
    	[vin] [varchar](20) NULL,
    	[modelo] [varchar](100) NULL,
    	[fecha_inicio] [datetime] NULL,
    	[fecha_fin] [datetime] NULL,
    	[eliminado] [bit] NOT NULL
    ) ON [PRIMARY]
    ALTER TABLE [dbo].[CA_ClearmechanicsOffers] ADD  DEFAULT ((0)) FOR [eliminado]
END
GO
IF NOT EXISTS (SELECT *
               FROM sys.objects
               WHERE object_id = OBJECT_ID(N'[dbo].[CA_LOGClearMechanicsQuotes]')
                 AND type in (N'U'))
    BEGIN
        CREATE TABLE [dbo].[CA_LOGClearMechanicsQuotes]
        (
            [orderNumber]      [varchar](25)        NULL,
            [sucursal]         [int]                NULL,
            [artList]		   [varchar](max)       NULL,
			[ok]			   [varchar](100)       NULL,
			[okRef]			   [varchar](max)       NULL,
            [ID]               [int] IDENTITY (1,1) NOT NULL,
            [FECHA]            [datetime]           NULL DEFAULT (getdate())
        ) ON [PRIMARY]
    END
GO