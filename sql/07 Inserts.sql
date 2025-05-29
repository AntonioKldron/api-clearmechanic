/***************************************************************/
/********************Inserts a CatParametros***********************/
/***************************************************************/
IF NOT EXISTS(SELECT *
              FROM CA_CatParametros
              WHERE Clave = 'ClearMechanics')
    BEGIN
        INSERT INTO dbo.CA_CatParametros
            (Clave, Tipo, Marca, Grupo, DescCorta, DescCompleta)
        VALUES (N'ClearMechanics', N'Empresa', N'Hyundai', N'Interfaz', N'Interfaz Citas ClearMechanics',
                N'Si la agencia tiene activo este par�metro significa que estar� reviviendo y compartiendo informaci�n a ClearMechanics de las citas Generadas');
    END
IF NOT EXISTS(SELECT *
              FROM CA_CatParametros
              WHERE Clave = 'CMUsuario')
    BEGIN
        INSERT INTO dbo.CA_CatParametros
            (Clave, Tipo, Marca, Grupo, DescCorta, DescCompleta)
        VALUES (N'CMUsuario', N'Sucursal', N'Hyundai', N'ClearMechanics', N'Usuario de Intelisis que detona Citas',
                N'Este par�metro contendr� al usuario que ara el proceso de afectaci�n en Intelisis');
    END
IF NOT EXISTS(SELECT *
              FROM CA_CatParametros
              WHERE Clave = 'CMArticuloMO')
    BEGIN
        INSERT INTO dbo.CA_CatParametros
            (Clave, Tipo, Marca, Grupo, DescCorta, DescCompleta)
        VALUES (N'CMArticuloMO', N'Sucursal', N'Hyundai', N'ClearMechanics', N'Numero de articulo', N'Articulo MO');
    END
/*********************Creamos los parametros por sucursal en los
 cuales se debe configurar el usuario que se usara para afectar y la
  mano de obra generica que se usara pra el detalle de la orde
*******************************/
DECLARE
    @Sucursal INT,
    @Empresa VARCHAR(10),
    @Usuario VARCHAR(10)='SOPDESA',
    @ManoObra VARCHAR(20)='MEC2'

SELECT TOP 1 @Empresa = EMPRESA
FROM EMPRESA

DECLARE crSucursalCM CURSOR FOR
    SELECT SUCURSAL
    FROM SUCURSAL
    WHERE SUCURSAL % 2 = 1
OPEN crSucursalCM;
FETCH NEXT FROM crSucursalCM INTO @Sucursal;
WHILE @@FETCH_STATUS = 0
    BEGIN


        IF NOT EXISTS(SELECT *
                      FROM CA_CatParametrosSucursal
                      WHERE Sucursal = @Sucursal
                        and Clave = 'CMUsuario')
            BEGIN
                INSERT [dbo].[CA_CatParametrosSucursal]
                    ([Empresa], [Sucursal], [Clave], [Descripcion], [Grupo], [Valor])
                VALUES (@Empresa, @Sucursal, N'CMUsuario', N'Usuario de Intelisis que detona Citas', N'ClearMechanics',
                        @Usuario)
            END

        IF NOT EXISTS(SELECT *
                      FROM CA_CatParametrosSucursal
                      WHERE Sucursal = @Sucursal
                        and Clave = 'CMArticuloMO')
            BEGIN
                INSERT [dbo].[CA_CatParametrosSucursal]
                    ([Empresa], [Sucursal], [Clave], [Descripcion], [Grupo], [Valor])
                VALUES (@Empresa, @Sucursal, N'CMArticuloMO', N'Numero de articulo', N'ClearMechanics', @ManoObra)
            END
        FETCH NEXT FROM crSucursalCM INTO @Sucursal;
    END;
CLOSE crSucursalCM;
DEALLOCATE crSucursalCM;
GO

DECLARE @Empresa varchar(50)=(SELECT empresa FROM empresa)
INSERT INTO CA_CatParametrosSucursal
SELECT
@Empresa,
Sucursal,
'CMOrderMode',
'Modo 0.-Foliar orden, 1.-Afectar orden',
'ClearMechanics',
'0'
FROM Sucursal WHERE Sucursal%2=1
AND Sucursal NOT IN (SELECT Sucursal FROM CA_CatParametrosSucursal WHERE Clave='CMOrderMode')