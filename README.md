# DESPLIEGUE DE PROYECTO API

## 📝 Indice de contenidos

- [Introducción](#about)
- [Tecnologías y Herramientas Utilizadas](#technologies_tools_used)
- [Requisitos Previos](#prerequisites)
- [Instalación](#getting_started)
- [Despliegue](#deployment)
- [Buenas Practicas en Commits](#gitstyles)

## Introduccion  <a name ='about'></a>
Este documento tiene como finalidad servir como guía completa para el despliegue, configuración e instalación de un proyecto API desarrollado en Django y Django REST Framework, cuya función principal es facilitar la integración con el sistema DMS Intelisis.

El proyecto está diseñado para centralizar y exponer datos clave de empresas, sucursales y versiones del sistema mediante una API, permitiendo así una comunicación estructurada entre plataformas. Está pensado para funcionar en entornos controlados con bases de datos SQL Server y servidores Windows o Ubuntu.

Además, se proporciona documentación detallada sobre las tablas involucradas en la operación del sistema, buenas prácticas para la instalación y ejecución del proyecto, así como consideraciones importantes para el manejo de usuarios y datos iniciales. Este README busca garantizar una implementación clara, reproducible y alineada con los estándares técnicos del equipo de desarrollo.

## 🛠️ Tecnologías y Herramientas Utilizadas <a name ='prerequisites'></a>
- Aplicación DMS Intelisis
* [Python 3.12.7](https://www.python.org/downloads/release/python-3117/) - Lenguaje usado 
* [Django](https://www.djangoproject.com/download/) - Framework web usado
* [Django REST framework](https://www.django-rest-framework.org/) - Framework REST
- **Base de Datos**: SQL Server 2019
- **Servidor**: Ununtu Server ó Windows Server 2019
  
---------------------------------------------------------


## Pasos para Levantar el Proyecto

### 📋 Requisitos Previos <a name ='prerequisites'></a>
Asegúrate de tener Python en su version 3.12 instalado en tu entorno de desarrollo.

### 🔧 Instalación <a name = 'getting_started'></a>

#### Clonar el Repositorio
````
git clone https://gitlabv2.intelisis-solutions.com:8008/TICS/Interfaces/servidores/clearmechanicsserver.git
cd clearmechanicsserver
````

#### Instalar Dependencias
````
pip install -r requirements.txt
````

#### Enviroment de BD con SQL Server (.env)
Debera crear un archiv de entorno con las credenciales para conexion a la base de datos (.env), el cual debera contener una estructura similar a la siguiente.

```` 
ISAPI-ENGINE=mssql
ISAPI-NAME=clearMechanics
ISAPI-USER=SA
ISAPI-PASSWORD=[PASSS]
ISAPI-HOST=111.1111.11.1111
ISAPI-PORT=1435
ISAPI-OPTIONS=ODBC Driver 17 for SQL Server
````

#### Aplicar Migraciones
````
python manage.py makemigrations
python manage.py migrate
````

#### 📘 Documentación de Tablas SQL

Este documento describe los campos, posibles valores y restricciones de 4 tablas: `api_sepa_current_version`,`api_sepa_companies`,`api_sepa_branch` y `api_branch_users`.


```
Nota: Los inserts en las tablas api_sepa_current_version, api_sepa_companies y api_sepa_branch deben ejecutarse antes de crear el usuario mediante el comando createsuperuser.
Por otro lado, el insert en la tabla api_branch_users debe realizarse después de crear el usuario, utilizando el ID del usuario generado.
```

---

##### 📄 Tabla: `api_sepa_current_version`

Contiene información sobre versiones o registros de integración/API relacionadas a Intelisis, incluyendo sus características y correcciones.

| Campo               | Tipo de dato     | Descripción                                                                 | Valores posibles / Notas                                           | ¿Puede ser nulo? |
|--------------------|------------------|------------------------------------------------------------------------------|--------------------------------------------------------------------|------------------|
| `nombre`           | `nvarchar`       | Nombre del sistema o componente relacionado.                                | Ej. `'Intelisis'`, `'CRM'`, `'DMS'`, etc.                          | ❌ No            |
| `features`         | `nvarchar`       | Descripción general de las funcionalidades agregadas.                       | Texto corto o clave como `'DEV'`, `'v1.2'`, `'NUEVAS RUTAS'`, etc. | ❌ No            |
| `fixes`            | `nvarchar`       | Detalle de correcciones aplicadas.                                          | Texto libre (puede ser `'DEV'`, descripción técnica, etc.).        | ❌ No            |
| `fecha_creacion`   | `datetime`       | Fecha y hora en que se creó el registro.                                    | Usualmente `GETDATE()` en el `INSERT`.                             | ❌ No            |
| `fecha_actualizacion` | `datetime`    | Fecha y hora de la última modificación.                                     | `GETDATE()` o cuando se actualice el registro.                     | ❌ No            |
| `eliminado`        | `bit`            | Indicador lógico de eliminación (soft delete).                              | `0` = Activo, `1` = Eliminado.                                     | ❌ No            |

```
INSERT INTO [dbo].[api_sepa_current_version]([nombre],[features],[fixes],[fecha_creacion],[fecha_actualizacion],[eliminado])
VALUES('Intelisis','DEV','DEV',GETDATE(),GETDATE(),0)
GO
```

---

##### 📄 Tabla: `api_sepa_companies`

Contiene la información de las empresas registradas en el sistema, relacionadas con sucursales e Intelisis.

| Campo                | Tipo de dato     | Descripción                                                                 | Valores posibles / Notas                                           | ¿Puede ser nulo? |
|---------------------|------------------|------------------------------------------------------------------------------|--------------------------------------------------------------------|------------------|
| `clave`             | `nvarchar`       | Clave única identificadora de la empresa.                                   | Ej. `'GFAME'`, `'BYORI'`.                                          | ❌ No            |
| `razonsocial`       | `nvarchar`       | Nombre legal o razón social de la empresa.                                  | Puede estar vacío si no está disponible.                           | ✅ Sí            |
| `rfc`               | `nvarchar`       | Registro Federal de Contribuyentes.                                         | Puede ser nulo o vacío si aún no se captura.                       | ✅ Sí            |
| `fecha_creacion`    | `datetime`       | Fecha de creación del registro.                                             | Generalmente `GETDATE()`.                                          | ❌ No            |
| `fecha_actualizacion` | `datetime`     | Fecha de la última actualización del registro.                              | Generalmente `GETDATE()`.                                          | ❌ No            |
| `id_intelisis`      | `int`            | Identificador relacionado con Intelisis.                                    | ID de la empresa en Intelisis.                                     | ❌ No            |
| `eliminado`         | `bit`            | Indicador lógico de eliminación (soft delete).                              | `0` = Activo, `1` = Eliminado.                                     | ❌ No            |

``` 
INSERT INTO [dbo].[api_sepa_companies] ([clave],[razonsocial],[rfc],[fecha_creacion],[fecha_actualizacion],[id_intelisis],[eliminado])
VALUES('GFAME','',GETDATE(),GETDATE(),1,0)
GO
```

---

##### 📄 Tabla: `api_sepa_branch`

Representa información detallada sobre una sucursal, incluyendo su configuración técnica y datos de ubicación.

| Campo              | Tipo de dato     | Descripción                                                                 | Valores posibles / Notas                                          | ¿Puede ser nulo? |
|-------------------|------------------|------------------------------------------------------------------------------|-------------------------------------------------------------------|------------------|
| `clave`           | `nvarchar`       | Clave única de la sucursal.                                                 | Código corto identificador (ej. 'BYORI').                         | ❌ No            |
| `nombre`          | `nvarchar`       | Nombre descriptivo de la sucursal.                                          | Texto libre (ej. 'BYD Taller Queretaro 2').                       | ❌ No            |
| `telefono`        | `nvarchar`       | Teléfono de contacto de la sucursal.                                        | Puede contener `'.'` si no hay valor.                             | ✅ Sí            |
| `correo`          | `nvarchar`       | Correo electrónico de contacto.                                             | Puede contener `'.'` o estar vacío.                               | ✅ Sí            |
| `fecha_creacion`  | `datetime`       | Fecha de creación del registro.                                             | `GETDATE()` al insertar.                                          | ❌ No            |
| `fecha_actualizacion` | `datetime`    | Fecha de la última actualización del registro.                              | `GETDATE()` o similar.                                             | ❌ No            |
| `conf_ip_ext`     | `nvarchar`       | IP externa para conexión a la base de datos.                                | Dirección IP válida.                                               | ❌ No            |
| `conf_ip_int`     | `nvarchar`       | IP interna para conexión a la base de datos.                                | Dirección IP válida.                                               | ❌ No            |
| `conf_user`       | `nvarchar`       | Usuario de la base de datos de Intelisis.                                   | Ej. `'sa'`.                                                        | ❌ No            |
| `conf_pass`       | `nvarchar`       | Contraseña del usuario de la base de datos.                                 | Ej. `'S0lutions2017??'`.                                           | ❌ No            |
| `conf_db`         | `nvarchar`       | Nombre de la base de datos.                                                 | Ej. `'FA_Orientales'`.                                             | ❌ No            |
| `conf_port`       | `int`            | Puerto de conexión a la base de datos.                                      | Número de puerto TCP (ej. 1433), puede estar en NULL.              | ✅ Sí            |
| `id_intelisis`    | `int`            | Identificador de la sucursal en Intelisis.                                  | Valor entero relacionado al ERP.                                  | ❌ No            |
| `empresa_intelisis` | `nvarchar`     | Clave de empresa en Intelisis.                                              | Ej. `'BYORI'`.                                                     | ❌ No            |
| `eliminado`       | `bit`            | Indicador lógico de eliminación.                                            | `0` = Activo, `1` = Eliminado.                                     | ❌ No            |
| `direccion`       | `nvarchar`       | Dirección física de la sucursal.                                            | Texto libre.                                                       | ✅ Sí            |
| `latitud`         | `float`          | Coordenada de latitud.                                                      | Decimal.                                                           | ✅ Sí            |
| `longitud`        | `float`          | Coordenada de longitud.                                                     | Decimal.                                                           | ✅ Sí            |
| `gwmbac`          | `nvarchar`       | Información relacionada a gateway (opcional).                               | Texto libre o identificador.                                       | ✅ Sí            |
| `id_district`     | `int`            | Relación con una tabla de distritos.                                        | Valor entero.                                                      | ✅ Sí            |
| `fotos_recepcion` | `nvarchar`       | Ruta o configuración para fotos de recepción.                               | Texto libre.                                                       | ✅ Sí            |
| `db_recepcion`    | `nvarchar`       | Nombre de la base de datos para recepción.                                  | Texto libre.                                                       | ✅ Sí            |
| `ciudad`          | `nvarchar`       | Nombre de la ciudad.                                                        | Texto libre.                                                       | ✅ Sí            |
| `id_agencia_crm`  | `int`            | Identificador de agencia en CRM.                                            | Valor entero.                                                      | ✅ Sí            |
| `version`         | `int`            | Versión del sistema o interfaz de sucursal.                                 | Usualmente `1` o mayor.                                            | ❌ No            |
| `id_company_id`   | `int`            | Relación con la empresa principal.                                          | Valor entero.                                                      | ❌ No            |
| `allow_test`      | `bit`            | Permite acceso de prueba o testing.                                         | `0` = No, `1` = Sí.                                                | ❌ No            |

```
INSERT [dbo].[api_sepa_branch] ( [clave], [nombre], [telefono], [correo], [fecha_creacion], [fecha_actualizacion], [conf_ip_ext], [conf_ip_int], [conf_user], [conf_pass], [conf_db], [conf_port], [id_intelisis], [empresa_intelisis], [eliminado], [direccion], [latitud], [longitud], [gwmbac], [id_district], [fotos_recepcion], [db_recepcion], [ciudad], [id_agencia_crm], [version], [id_company_id], [allow_test])
VALUES ( N'BYORI', N'BYD Taller Queretaro 2', N'.', N'.', GETDATE(), GETDATE(), N'10.120.0.96', N'10.120.0.96', N'sa', N'S0lutions2017??', N'FA_Orientales', NULL, 9, N'BYORI', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 0)
GO
```

---

##### 📄 Tabla: `api_branch_users`

Relaciona a los usuarios con las sucursales a las que pertenecen o tienen acceso.

| Campo             | Tipo de dato    | Descripción                                                                 | Valores posibles / Notas                                      | ¿Puede ser nulo? |
|------------------|------------------|------------------------------------------------------------------------------|---------------------------------------------------------------|------------------|
| `iduser`         | `int`            | Identificador único del usuario.                                            | ID existente en la tabla de usuarios.                         | ❌ No            |
| `idbranch`       | `int`            | Identificador único de la sucursal.                                         | ID existente en la tabla de sucursales.                       | ❌ No            |
| `fecharegistro`  | `datetime`       | Fecha y hora en que se registró el usuario en la sucursal.                  | Usualmente `GETDATE()` al momento del insert.                 | ❌ No            |
| `fechaactualiza` | `datetime`       | Fecha y hora de la última actualización del registro.                       | `GETDATE()` si es una creación inicial.                       | ❌ No            |
| `iduseractializa`| `int`            | Identificador del usuario que hizo la última modificación.                  | ID de un usuario administrador u operador.                    | ❌ No            |
| `eliminado`      | `bit`            | Indicador lógico de eliminación del registro.                               | `0` = Activo, `1` = Eliminado (soft delete).                  | ❌ No            |
```
INSERT [dbo].[api_branch_users] ( [iduser], [idbranch], [fecharegistro], [fechaactualiza], [iduseractializa], [eliminado]) 
VALUES ( 1, 7, GETDATE(), GETDATE(), 1, 0)
GO
```

---


#### Creacion de Usuario
  ```
  python manage.py createsuperuser

  Usuario: TESTDEV
  Id branch (sepa_branch.id): 1
  Id current version (sepa_current_version.id): 1
  Code verification: TESTDEV
  Correo: mail@mail.com
  Telefono: 0000000000
  Password: TESTDEV
  ```
#### ⚙️ Ejecutando las pruebas
````
python manage.py runserver 9000
````


#### Registro de aplicacion
  Para obtener un access_token válido primero debemos registrar una aplicación:

  ```http://localhost:9000/oauth/applications/```

  Haga clic en el enlace para crear una nueva aplicación y complete el formulario con los siguientes datos:

  * Nombre: solo un nombre de su elección
  * Tipo de cliente: confidencial
  * Tipo de concesión de autorización: propietario del recurso basado en contraseña

  ¡Guarde su aplicación!

### Credenciales a Compartir para su consumo

| Parametro | Descripción |
| --- | --- |
| username | Nombre de la cuenta de usuario |
| password | Contraseña asignada por el usuario |
| organizationID | ID de la tabal brach creada |
| client_id | ID Cliente Publico |
| client_secret | Cliente Secreto |
| grant_type | Tipo de concesión (password) |


## 🚀 Despliegue <a name = "deployment"></a>

El despliegue requiere de un sistema con un servidor como NGINX o IIS con los que se requiere que se cuenta previamente con los pasos anteriores.

---

### *Recomendaciones para publicar por medio de iis*

Instalar paquete fastcgi
````
pip install wfastcgi
````

Activar fastcgi
````
wfastcgi-enable
````

Configuración archivo web.config

```
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <handlers>
      <add name="Python FastCGI" 
      path="*" 
      verb="*" 
      modules="FastCgiModule" 
      scriptProcessor="C:\Python312\python.exe|C:\Python312\Lib\site-packages\wfastcgi.py" 
      resourceType="Unspecified" 
      requireAccess="Script" />
    </handlers>
  </system.webServer>

  <appSettings>
    <add key="PYTHONPATH" value="C:\inetpub\wwwroot\clearmecanicsapi" />
    <add key="WSGI_HANDLER" value="django.core.wsgi.get_wsgi_application()" />
    <add key="DJANGO_SETTINGS_MODULE" value="api.settings" />
  </appSettings>
</configuration>
```

---

## Buenas Practicas en Commits <a name = "gitstyles"></a>
[GitFlow](https://www.atlassian.com/es/git/tutorials/comparing-workflows/gitflow-workflow)

Lo incluido dentro del proyecto consiste en el siguiente tipo de commits:

* 👾 FIX: Correcciones a bugs, fallas de integridad de información o fallas de programación.

* ♻️ REFACTOR: Reconstrucción, modificación o anexo a funcionalidades y modulos ya existentes.

* ➕ FEAT: Nueva funcionalidad.

* 📝 SQL: Acciones a base de datos, archivos sql, actividades a migrations.

* 👔 STYLE: Desarrollo referente a ajustes de estetica.

* 📚 DOCS: Carga o modificacion de archivos de documentacion, minutas, acuerdos y soporte a modificaciones.

* 🧪 TEST: Se añadieron pruebas, refactorizacion de pruebas; Sin cambios en el codigo.

* 🔩 CHORE: Mantenimiento de código regular.

* ☠️ DELETE : Se eliminan funciones o archivos.

* 🔄 CI: Cambios en la integración continua.
