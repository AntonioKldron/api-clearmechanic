from django.db import models

"""
===========================
    CitasDeServicio
===========================
"""
class CitasClearMechanics(models.Model):
    appointmentId = models.CharField(max_length=255, primary_key=True)
    orderId = models.CharField(max_length=255)
    status = models.CharField(max_length=255)
    clientId = models.CharField(max_length=255)
    firstName = models.CharField(max_length=255)
    lastName = models.CharField(max_length=255)
    address = models.CharField(max_length=255)
    mainPhone = models.CharField(max_length=255)
    secondaryPhone = models.CharField(max_length=255)
    mobile = models.CharField(max_length=255)
    email = models.CharField(max_length=255)
    serviceAdvisorId = models.CharField(max_length=255)
    vin = models.CharField(max_length=255)
    licensePlate = models.CharField(max_length=255)
    brand = models.CharField(max_length=255)
    model = models.CharField(max_length=255)
    year = models.CharField(max_length=255)
    date = models.CharField(max_length=255)
    promiseDate = models.CharField(max_length=255)
    confirmed = models.CharField(max_length=255)
    socialName = models.CharField(max_length=255)
    comments = models.CharField(max_length=255)
    preOrderId = models.CharField(max_length=255)
    orderTypeId = models.CharField(max_length=255)
    orderType = models.CharField(max_length=255)
    serviceType = models.CharField(max_length=255)
    isService = models.CharField(max_length=255)
    isRepair = models.CharField(max_length=255)
    isDiagnostic = models.CharField(max_length=255)
    mainType = models.CharField(max_length=255)
    secondType = models.CharField(max_length=255)
    thirdType = models.CharField(max_length=255)
    appointmentPersonId = models.CharField(max_length=255)
    FechaEmision = models.DateField()
    Sucursal = models.IntegerField()

    @classmethod
    def get_field_names(cls):
        excluded_fields = ['FechaEmision', 'Sucursal']
        field_names = [field.name for field in cls._meta.fields if field.name not in excluded_fields]
        field_names_string = ', '.join(field_names)
        return field_names_string

    class Meta:
        managed = False
        db_table = 'vwCA_CitasClearMechanics'
"""
===========================
    TipoOrdenes
===========================
"""
class TipoOrdenesClearMechanics(models.Model):
    ServicioTipoOrden = models.CharField(max_length=100, primary_key=True)
    ServicioTipoOperacion = models.CharField(max_length=100)

    @classmethod
    def get_field_names(cls):
        excluded_fields = []
        field_names = [field.name for field in cls._meta.fields if field.name not in excluded_fields]
        field_names_string = ', '.join(field_names)
        return field_names_string

    class Meta:
        managed = False
        db_table = 'vwCA_TipoOrdenClearMechanics'
"""
===========================
    OrdenesDeServicio
===========================
"""
class OrdenesClearMechanics(models.Model):
    orderId = models.CharField(max_length=20, primary_key=True)
    orderNumber = models.CharField(max_length=20)
    serviceAdvisorId = models.CharField(max_length=255)
    orderdate = models.CharField(max_length=20)
    orderType = models.CharField(max_length=20)
    serviceType = models.CharField(max_length=20)
    status = models.CharField(max_length=20)
    promisedDate = models.CharField(max_length=20)
    total = models.CharField(max_length=20)
    openDate = models.CharField(max_length=20)
    closedDate = models.CharField(max_length=20)
    checkin = models.CharField(max_length=20)
    checkout = models.CharField(max_length=20)
    vin = models.CharField(max_length=20)
    brand = models.CharField(max_length=20)
    model = models.CharField(max_length=20)
    year = models.CharField(max_length=20)
    licensePlate = models.CharField(max_length=20)
    kilometers = models.CharField(max_length=20)
    customerParts = models.CharField(max_length=20)
    customerLabor = models.CharField(max_length=20)
    customerMisc = models.CharField(max_length=20)
    totsCost = models.CharField(max_length=20)
    gogCost = models.CharField(max_length=20)
    totalBeforeTaxes = models.CharField(max_length=20)
    invoiceDate = models.CharField(max_length=20)
    insuranceData = models.CharField(max_length=20)
    technicianId = models.CharField(max_length=20)
    towerNumber = models.CharField(max_length=20)
    utsSold = models.CharField(max_length=20)
    comments = models.CharField(max_length=20)
    clientId = models.CharField(max_length=20)
    firstName = models.CharField(max_length=20)
    lastName = models.CharField(max_length=20)
    address = models.CharField(max_length=20)
    City = models.CharField(max_length=20)
    State = models.CharField(max_length=20)
    zip = models.CharField(max_length=20)
    mainPhone = models.CharField(max_length=20)
    mobile = models.CharField(max_length=20)
    email = models.CharField(max_length=20)
    FechaEmision = models.CharField(max_length=20)
    Sucursal = models.CharField(max_length=20)

    @classmethod
    def get_field_names(cls):
        excluded_fields = ['FechaEmision', 'Sucursal']
        field_names = [field.name for field in cls._meta.fields if field.name not in excluded_fields]
        field_names_string = ', '.join(field_names)
        return field_names_string

    class Meta:
        managed = False
        db_table = 'vwCA_OrdenesClearMechanics'
"""
===========================
    Agentes
===========================
"""
class AsesorClearMechanics(models.Model):
     serviceAdvisorId = models.CharField(max_length=20, primary_key=True)
     tipo=models.CharField(max_length=20)
     firstName = models.CharField(max_length=20)
     lastName = models.CharField(max_length=20)
     email = models.CharField(max_length=20)
     mobile = models.CharField(max_length=20)
     sucursal = models.CharField(max_length=20)

     @classmethod
     def get_field_names(cls):
         excluded_fields = ['sucursal','tipo']
         field_names = [field.name for field in cls._meta.fields if field.name not in excluded_fields]
         field_names_string = ', '.join(field_names)
         return field_names_string

     class Meta:
         managed = False
         db_table = 'vwCA_AsesoresClearMechanics'
"""
===========================
    Vin
===========================
"""
class VehiculosClearMechanics(models.Model):
    vehicleId = models.CharField(max_length=20, primary_key=True)
    vin = models.CharField(max_length=20)
    brand = models.CharField(max_length=255)
    model = models.CharField(max_length=255)
    year = models.CharField(max_length=255)
    licensePlate = models.CharField(max_length=45)
    kilometers = models.CharField(max_length=255)
    idClient = models.CharField(max_length=255)
    firstName = models.CharField(max_length=255)
    lastName = models.CharField(max_length=255)
    mainPhone = models.CharField(max_length=255)
    mobile = models.CharField(max_length=10)
    email = models.CharField(max_length=255)

    @classmethod
    def get_field_names(cls):
        excluded_fields = []
        field_names = [field.name for field in cls._meta.fields if field.name not in excluded_fields]
        field_names_string = ', '.join(field_names)
        return field_names_string

    class Meta:
        managed = False
        db_table = 'vwCA_VehiculosClearMechanics'
"""
===========================
    VinGarantias
===========================
"""
class GarantiasClearMechanics(models.Model):
    warrantyId = models.CharField(max_length=20, primary_key=True)
    kilometers = models.CharField(max_length=20)
    description = models.CharField(max_length=255)
    status = models.CharField(max_length=255)
    repairDate = models.CharField(max_length=255)
    vin = models.CharField(max_length=20)

    @classmethod
    def get_field_names(cls):
        excluded_fields = []
        field_names = [field.name for field in cls._meta.fields if field.name not in excluded_fields]
        field_names_string = ', '.join(field_names)
        return field_names_string

    class Meta:
        managed = False
        db_table = 'vwCA_GarantiasClearMechanics'
"""
===========================
    VinRecall
===========================
"""
class VinCampanaClearMechanics(models.Model):
    campaignId = models.CharField(max_length=20, primary_key=True)
    description = models.CharField(max_length=245)
    vin = models.CharField(max_length=20)

    @classmethod
    def get_field_names(cls):
        excluded_fields = []
        field_names = [field.name for field in cls._meta.fields if field.name not in excluded_fields]
        field_names_string = ', '.join(field_names)
        return field_names_string

    class Meta:
        managed = False
        db_table = 'vwCA_VinCampanaClearMechanics'