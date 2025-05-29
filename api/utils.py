from django.db.models import Q
from rest_framework.response import Response
from rest_framework import status
from isapilib.external.utilities import execute_sp
from isapilib.external.connection import add_conn
from isapilib.api.models import SepaBranch, UserAPI
from .models import *
import time
import hashlib

"""
===========================
    Cotizaciones
===========================
"""
def generar_clave_unica(data, user, organization_id, method):
    vin = data.get('vin', 'sin_vin')
    promised_date = data.get('promisedDate', 'sin_fecha')
    raw = f"{method}-{user.username}-{organization_id}-{vin}-{promised_date}"
    return "solicitud_orden_" + hashlib.md5(raw.encode()).hexdigest()
"""
===========================
    Clientes
===========================
"""
def build_cte_query(pk, params):
    query = Q(cliente=pk)

    filters = {
        "firstName": lambda val: Q(personal_nombres__icontains=val),
        "lastName": lambda val: Q(personal_apellido_paterno__icontains=val) | Q(personal_apellido_materno__icontains=val),
        "secondaryPhone": lambda val: Q(personal_telefono_movil__icontains=val),
        "mainPhone": lambda val: Q(personal_telefonos_lada__icontains=val) | Q(personal_telefonos__icontains=val),
        "mobile": lambda val: Q(personal_telefono_movil__icontains=val),
        "email": lambda val: Q(email1__icontains=val),
        "socialName": lambda val: Q(nombre__icontains=val),
        "RFC": lambda val: Q(rfc__icontains=val),
        "fiscalEmail": lambda val: Q(email1__icontains=val),
        "contactable": lambda val: Q(contactar__icontains=val),
    }

    address_fields = [
        "direccion__icontains", "direccion_numero__icontains", "colonia__icontains",
        "codigo_postal__icontains", "delegacion__icontains", "estado__icontains", "pais__icontains"
    ]

    for key, func in filters.items():
        if key in params:
            query &= func(params[key])

    for key in ["address", "fiscalAddress"]:
        if key in params:
            address_query = Q()
            for field in address_fields:
                address_query |= Q(**{field: params[key]})
            query &= address_query

    return query

def format_address(cte):
    return f"{cte.direccion}, #{cte.direccion_numero}, col. {cte.colonia}, CP. {cte.codigo_postal}, del. {cte.delegacion}, pobl. {cte.poblacion}, Edo. {cte.estado}, {cte.pais}"

"""
===========================
    Agente
===========================
"""
def fetch_asesores(request, tipo_personal):
    organization_id = request.headers.get('organizationId')
    if not organization_id:
        raise ValueError("organizationId header is required.")

    sucursal = SepaBranch.objects.get(pk=organization_id).id_intelisis
    query = Q(sucursal=sucursal, tipo=tipo_personal)

    for param, value in request.GET.items():
        query &= Q(**{param: value})

    asesores_queryset = AsesorClearMechanics.objects.filter(query)
    fields = AsesorClearMechanics.get_field_names().split(", ")
    asesores = list(asesores_queryset.values(*fields))

    return asesores

def build_response(success, data=None, message=None, status_code=status.HTTP_200_OK):
    response = {'success': success, 'message': message, 'data': data}
    return Response(response, status=status_code)
"""
===========================
    OrdenesDeServicio
===========================
"""
def enviar_mensaje(task_status):
    time.sleep(30)
    task_status.update_response(True, 'La orden está siendo creada', [], status.HTTP_202_ACCEPTED)


def crear_orden(request, user, task_status, organization_id):
    try:
        username = UserAPI.objects.get(username=request.user.username)
        sepa = SepaBranch.objects.get(id=organization_id)
        external_db = add_conn(username, sepa)

        data = request.data
        sucursal = SepaBranch.objects.get(pk=organization_id).id_intelisis
        appointmentId = data.get('appointmentId', '0')
        resultados = execute_sp('xpCA_OrdenesClearMechanicsInsert', [
            data['vin'],
            sucursal,
            data['serviceAdvisorId'],
            data['promisedDate'],
            data['kilometers'],
            data['orderType'],
            data['cone'],
            appointmentId
        ], using=external_db)[0][0]
        if resultados[0] == "":
            task_status.update_response(False, resultados[1], [], status.HTTP_400_BAD_REQUEST)
            return
        etiquetas = OrdenesClearMechanics.get_field_names()
        lista_campos = etiquetas.split(", ")
        diccionario = {lista_campos[i]: str(resultados[i]) for i in range(len(lista_campos))}
        task_status.update_response(True, None, [diccionario], status.HTTP_201_CREATED)
    except Exception as e:
        task_status.update_response(False, 'ERROR', str(e), status.HTTP_400_BAD_REQUEST)


def validate_required_fields(data, required_fields):
    missing_fields = [field for field in required_fields if not data.get(field)]
    filter=None
    if missing_fields:
        filter={", ".join(missing_fields)}

    return filter

def generar_clave_unica(data, user, organization_id, method):
    raw = f"{method}-{user.username}-{organization_id}-{data['vin']}-{data['promisedDate']}"
    return "solicitud_orden_" + hashlib.md5(raw.encode()).hexdigest()
