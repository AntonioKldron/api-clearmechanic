from django.core.cache import cache
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.decorators import action
from isapilib.external.utilities import execute_sp,execute_query
from isapilib.logger.decorators import logger
from isapilib.api.models import SepaBranch
from isapilib.models import Cte
from .utils import *
from .serializers import *
import json
import datetime
import threading

"""
===========================
    CitasDeServicio
===========================
"""
@logger('CitasDeServicio', interfaz=None, log_all=True)
class CitasDeServicioAPIView(APIView):
    queryset = CitasClearMechanics.objects.all()
    serializer_class = CitasSerializer
    required_scopes = ['write']

    @action(detail=True, methods=['GET'])
    def get(self, request, pk=None):
        try:
            organization_id = request.headers.get('organizationId')
            query = Q()
            sucursal = SepaBranch.objects.get(pk=organization_id).id_intelisis
            query &= Q(Sucursal=sucursal)
            requests = request.GET.copy()

            # Verificamos si está la fecha para iterarla por rango.
            if requests.get('dateFrom') and requests.get('dateTo'):
                date_from = datetime.datetime.strptime(request.GET["dateFrom"], '%Y-%m-%d').date()
                date_to = datetime.datetime.strptime(request.GET["dateTo"],
                                                     '%Y-%m-%d').date()
                query &= Q(FechaEmision__range=(date_from, date_to))
                requests.pop('dateFrom')
                requests.pop('dateTo')

            if requests.get("organizationId"):
                requests.pop("organizationId")

            if pk != None:
                query &= Q(appointmentId=pk)


            # Iteramos por lo que resta de parámetros.
            for params in requests:
                query &= Q(**{params: request.GET[params]})

            # Hacemos la consulta
            citas = CitasClearMechanics.objects.filter(query)
            # Obtenemos el nombre de los campos que se desean
            lista = CitasClearMechanics.get_field_names()
            lista_campos = lista.split(", ")
            citas = list(citas.values(*lista_campos))

            response = {'success': True, 'message': None, 'data': citas}
            return Response(response, status=status.HTTP_200_OK)
        except Exception as e:
            response = {'success': False, 'message': 'ERROR', 'data': str(e)}
            return Response(response, status=status.HTTP_400_BAD_REQUEST)
"""
===========================
    CitasDeServicioDetalle
===========================
"""
@logger('CitasDeServicioDetalle', interfaz=None, log_all=True)
class CitasDeServicioDetalleAPIView(APIView):
    queryset = OrdenesClearMechanics.objects.all()
    serializer_class = OrdenesSerializer
    required_scopes = ['write']

    @action(detail=True, methods=['GET'])
    def get(self, request, pk=None):
        try:
            pk=''+pk+''
            query = 'SELECT * FROM vwCA_JobsClearMechanics WHERE MOVID = %s'
            res = execute_query(query, [pk])
            res=(res[0])
            if not res:
                response = {'success': False, 'message': 'La cita no tiene mano de obra/partes', 'data': []}
                return Response(response, status=status.HTTP_400_BAD_REQUEST)
            etiquetas={'technician','source','time','work'}
            etiquetas = list(etiquetas)
            lista_diccionarios = []
            if res[0] is None:
                response = {'success': False, 'message': 'No se encontro la cita', 'data': []}
                return Response(response, status=status.HTTP_400_BAD_REQUEST)
            else:
                for i in range(len(res)):
                    diccionario = {}
                    for j in range(len(etiquetas)):
                        diccionario[etiquetas[j]] = str(res[i][j])
                    lista_diccionarios.append(diccionario)

                response = {'success': True, 'message': None, 'data': [lista_diccionarios]}
                return Response(response, status=status.HTTP_201_CREATED)

        except Exception as e:
            response = {'success': False, 'message': 'ERROR', 'data': str(e)}
            return Response(response, status=status.HTTP_400_BAD_REQUEST)

"""
===========================
    Clientes
===========================
"""
@logger('Clientes', interfaz=None, log_all=True)
class ClientesAPIView(APIView):
    required_scopes = ['write']

    def get(self, request, pk=None):
        if pk is None:
            return Response({
                'success': False,
                'message': 'Favor de especificar cliente',
                'data': []
            }, status=status.HTTP_400_BAD_REQUEST)

        try:
            query = build_cte_query(pk, request.GET)
            cte = Cte.objects.filter(query).first()

            if not cte:
                return Response({
                    'success': False,
                    'message': 'No se encontró el cliente',
                    'data': []
                }, status=status.HTTP_404_NOT_FOUND)

            address = format_address(cte)

            cte_data = {
                'customerId': cte.cliente,
                'firstName': cte.personal_nombres,
                'lastName': f"{cte.personal_apellido_paterno} {cte.personal_apellido_materno}",
                'address': address,
                'mainPhone': f"{cte.personal_telefonos_lada}{cte.personal_telefonos}",
                'secondaryPhone': cte.personal_telefono_movil,
                'mobile': cte.personal_telefono_movil,
                'email': cte.email1,
                'socialName': cte.nombre,
                'RFC': cte.rfc,
                'fiscalAddress': address,
                'fiscalEmail': cte.email1,
                'contactable': cte.contactar,
            }

            return Response({'success': True, 'message': None, 'data': cte_data}, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({
                'success': False,
                'message': str(e),
                'data': []
            }, status=status.HTTP_400_BAD_REQUEST)

"""
===========================
    Cotizaciones
===========================
"""
@logger('Cotizaciones', interfaz=None, log_all=True)
class CotizacionesAPIView(APIView):
    required_scopes = ['write']

    def post(self, request):
        clave_solicitud = None  # Para evitar error si ocurre excepción antes de generarla
        try:
            data = request.data
            organization_id = request.headers.get('organizationId')

            if not organization_id:
                return Response({'success': False, 'message': 'Falta indicar el organizationId', 'data': []},
                                status=status.HTTP_400_BAD_REQUEST)

            try:
                sucursal = SepaBranch.objects.get(pk=organization_id).id_intelisis
            except SepaBranch.DoesNotExist:
                return Response({'success': False, 'message': 'La sucursal no existe', 'data': []},
                                status=status.HTTP_400_BAD_REQUEST)

            articulos = data.get("items")
            orderId = data.get("orderNumber")

            clave_solicitud = generar_clave_unica(data, request.user, organization_id, 'Cotizaciones')

            if cache.get(clave_solicitud):
                return Response(
                    {'success': False, 'message': 'Se está procesando una solicitud con los mismos datos.', 'data': []},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Marcar la solicitud como en proceso por 15 segundos
            cache.set(clave_solicitud, True, timeout=15)

            articulos_json = json.dumps(articulos)
            respuesta = execute_sp('xpCA_QuotesClearMechanicsAPI', {
                'orderId': orderId,
                'sucursal': sucursal,
                'json': articulos_json
            })

            if respuesta[0] != '200':
                cache.delete(clave_solicitud)
                return Response({'success': False, 'message': respuesta[0], 'data': respuesta[1]},
                                status=status.HTTP_400_BAD_REQUEST)

            respuesta_json = json.loads(respuesta[1])
            cache.delete(clave_solicitud)
            return Response({'success': True, 'message': None, 'data': respuesta_json},
                            status=status.HTTP_200_OK)

        except Exception as e:
            if clave_solicitud:
                cache.delete(clave_solicitud)
            return Response({'success': False, 'message': f'Error inesperado: {str(e)}', 'data': []},
                            status=status.HTTP_500_INTERNAL_SERVER_ERROR)
"""
===========================
    Inventarios
===========================
"""
@logger('Inventarios', interfaz=None, log_all=True)
class InventarioAPIView(APIView):
    required_scopes = ['write']

    def get(self, request, pk=None):
        try:
            organization_id = request.headers.get('organizationId')
            sucursal = SepaBranch.objects.get(pk=organization_id).id_intelisis
            keyword = None
            if "keyword" in request.GET:
                keyword= request.GET["keyword"]
            if pk is not None:
                res = execute_sp('xpCA_InventoryItemClearMechanics', [pk, sucursal])
            else:
                res = execute_sp('xpCA_InventoryItemsClearMechanics', [keyword, sucursal])
            res_l1 = list(res[0])
            resultados = {}
            keys = ['jobs', 'parts', 'labors']

            for i in range(3):
                if res_l1[0][i] is not None:
                    resultados[keys[i]] = json.loads(res_l1[0][i])
                else:
                    resultados[keys[i]] = []

            return Response({'success': True, 'message': None, 'data': resultados}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'success': False, 'message': str(e), 'data': []}, status=status.HTTP_400_BAD_REQUEST)
"""
===========================
    Ofertas
===========================
"""
@logger('Ofertas', interfaz=None, log_all=True)
class OfertasAPIView(APIView):
    required_scopes = ['write']

    def get(self, request, pk=None):
        try:
            query = 'SELECT ID AS offerId,titulo AS title,Descripcion AS description,precio AS price FROM CA_ClearmechanicsOffers where Id!=%s'
            res = execute_query(query, [None])
            if not res:
                response = {'success': True, 'message': None, 'data': []}
                return Response(response, status=status.HTTP_201_CREATED)
            etiquetas={'offerId','title','description','price'}
            etiquetas = list(etiquetas)
            lista_diccionarios = []
            if res[0] is None:
                response = {'success': False, 'message':None, 'data': []}
                return Response(response, status=status.HTTP_400_BAD_REQUEST)
            else:
                for i in range(len(res)):
                    diccionario = {}
                    for j in range(len(etiquetas)):
                        diccionario[etiquetas[j]] = str(res[i][j])
                    lista_diccionarios.append(diccionario)

                response = {'success': True, 'message': None, 'data': [lista_diccionarios]}
                return Response(response, status=status.HTTP_201_CREATED)

        except Exception as e:
            response = {'success': False, 'message': 'ERROR', 'data': str(e)}
            return Response(response, status=status.HTTP_400_BAD_REQUEST)
"""
===========================
    TipoOrdenes
===========================
"""
@logger('TipoOrdenes', interfaz=None, log_all=True)
class TipoOrdenesAPIView(APIView):
    required_scopes = ['write']

    def get (self, request):
        try:
            coleccion={}
            resdata = TipoOrdenesClearMechanics.objects.values('ServicioTipoOrden').distinct()
            resdata = list(resdata)
            res = [[item['ServicioTipoOrden']] for item in resdata]

            for val in res:
                key=val[0]
                query=Q(ServicioTipoOrden=val[0])
                data=TipoOrdenesClearMechanics.objects.filter(query)
                lista = TipoOrdenesClearMechanics.get_field_names()
                lista_campos = lista.split(", ")
                data = list(data.values(*lista_campos))
                coleccion[key] = data

            response = {'success': True, 'message': None, 'data': coleccion}
            return Response(response, status=status.HTTP_200_OK)
        except Exception as e:
            response = {'success': False, 'message': 'ERROR', 'data': str(e)}
            return Response(response, status=status.HTTP_400_BAD_REQUEST)

@logger('TipoOrdenes', interfaz=None, log_all=True)
class TipoOrdenesListAPIView(APIView):
    required_scopes = ['write']

    def get (self, request):
        try:
            resdata = TipoOrdenesClearMechanics.objects.values('ServicioTipoOrden').distinct()
            response_data = []

            for val in resdata:
                key = val['ServicioTipoOrden']
                query = Q(ServicioTipoOrden=key)

                data = TipoOrdenesClearMechanics.objects.filter(query)
                lista_campos = TipoOrdenesClearMechanics.get_field_names().split(", ")
                data = list(data.values(*lista_campos))

                tipo_orden_dict = {
                    "key": key,
                    "description": key,
                    "subTypes": []
                }

                for index, item in enumerate(data, start=1):
                    tipo_orden_dict["subTypes"].append({
                        "key": item["ServicioTipoOperacion"],
                        "description": item["ServicioTipoOperacion"]
                    })

                response_data.append(tipo_orden_dict)

            response = {'success': True, 'message': None, 'data': response_data}
            return Response(response, status=status.HTTP_200_OK)
        except Exception as e:
            response = {'success': False, 'message': 'ERROR', 'data': str(e)}
            return Response(response, status=status.HTTP_400_BAD_REQUEST)
"""
===========================
    OrdenesDeServicio
===========================
"""
class TaskStatus:
    def __init__(self):
        self.response = None
        self.info_guardada = False

    def update_response(self, success, message, data, status_code):
        self.response = Response(
            {'success': success, 'message': message, 'data': data},
            status=status_code
        )
        self.info_guardada = True
        
@logger('OrdenesDeServicio', interfaz=None, log_all=True)
class OrdenesDeServicioAPIView(APIView):
    queryset = OrdenesClearMechanics.objects.all()
    serializer_class = OrdenesSerializer
    required_scopes = ['write']
    
    def is_valid_organization(self, organization_id):
        try:
            SepaBranch.objects.get(pk=organization_id)
            return True
        except SepaBranch.DoesNotExist:
            return False

    @action(detail=True, methods=['POST'])
    def post(self, request):
        organization_id = request.headers.get('organizationId')
        task_status = TaskStatus()
        if not self.is_valid_organization(organization_id):
            return Response(
                {'success': False, 'message': 'No se encontró el organizationId', 'data': []},
                status=status.HTTP_400_BAD_REQUEST
            )

        required_fields = ['vin','serviceAdvisorId','promisedDate','kilometers','orderType','cone','defaultService']
        data = request.data

        error_response = validate_required_fields(data, required_fields)
        if error_response is not None:
            return Response(
                {'success': False, 'message': 'Faltan los siguientes datos: ' + ", ".join(error_response), 'data': []},
                status=status.HTTP_400_BAD_REQUEST
            )

        clave_solicitud = generar_clave_unica(data, request.user, organization_id, 'Orden')

        if cache.get(clave_solicitud):
            return Response(
                {'success': False, 'message': 'Se está procesando una solicitud con los mismos datos.', 'data': []},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Marcar la solicitud como en proceso por 15 segundos
        cache.set(clave_solicitud, True, timeout=15)

        hilo_mensaje = threading.Thread(target=enviar_mensaje, args=(task_status,))
        hilo_orden = threading.Thread(target=crear_orden, args=(request, request.user, task_status, organization_id))

        hilo_mensaje.start()
        hilo_orden.start()

        while not task_status.info_guardada:
            time.sleep(1)

        cache.delete(clave_solicitud)  # Limpiar bloqueo

        return task_status.response
    
    @action(detail=True, methods=['GET'])
    def get(self, request, pk=None):
        try:
            organization_id = request.headers.get('organizationId')
            username = UserAPI.objects.get(username=request.user.username)
            sepa = SepaBranch.objects.get(id=organization_id)
            externaldb = add_conn(username, sepa)
            sucursal = SepaBranch.objects.get(pk=organization_id).id_intelisis
            query = Q()
            query &= Q(Sucursal=sucursal)
            requests = request.GET.copy()

            # Verificamos si está la fecha para iterarla por rango.
            if requests.get('dateFrom') and requests.get('dateTo'):
                date_from = datetime.datetime.strptime(request.GET["dateFrom"], '%Y-%m-%d').date()
                date_to = datetime.datetime.strptime(request.GET["dateTo"],
                                                     '%Y-%m-%d').date()
                query &= Q(FechaEmision__range=(date_from, date_to))
                requests.pop('dateFrom')
                requests.pop('dateTo')

            if requests.get("organizationId"):
                requests.pop("organizationId")

            if pk != None:
                query &= Q(orderId=pk)

            # Iteramos por lo que resta de parámetros.
            for params in requests:
                query &= Q(**{params: request.GET[params]})

            # Hacemos la consulta
            citas = OrdenesClearMechanics.objects.using(externaldb).filter(query)
            # Obtenemos el nombre de los campos que se desean
            lista = OrdenesClearMechanics.get_field_names()
            lista_campos = lista.split(", ")
            citas = list(citas.values(*lista_campos))

            response = {'success': True, 'message': None, 'data': citas}
            return Response(response, status=status.HTTP_200_OK)
        except Exception as e:
            response = {'success': False, 'message': 'ERROR', 'data': str(e)}
            return Response(response, status=status.HTTP_400_BAD_REQUEST)
        
    @action(detail=True, methods=['PUT'])
    def put(self, request,pk=None):
        try:
            organization_id = request.headers.get('organizationId')
            data = request.data
            sucursal = SepaBranch.objects.get(pk=organization_id).id_intelisis

            appointmentId = data.get('appointmentId') or None
            vin = data.get('vin') or None
            serviceAdvisorId=data.get('serviceAdvisorId') or None
            promisedDate=data.get('promisedDate') or None
            kilometers=data.get('kilometers') or None
            orderType=data.get('orderType') or None
            cone=data.get('cone') or None
            sucursal=sucursal
        

            if pk is None:
                response = {'success': False, 'message': 'Espesifica el numero de orden', 'data': []}
                return Response(response, status=status.HTTP_400_BAD_REQUEST)


            resultados = execute_sp('xpCA_OrdenesClearMechanicsUpdate', [
                pk,
                vin,
                sucursal,
                serviceAdvisorId,
                promisedDate,
                kilometers,
                orderType,
                cone,
                appointmentId
            ])[0]

            valida = 0
            if resultados[0][0] == "":
                valida = 1


            if valida == 1:
                response = {'success': False, 'message': resultados[0][1], 'data': []}
                return Response(response, status=status.HTTP_400_BAD_REQUEST)
            else:
                resultados = list(resultados[0])
                etiquetas = OrdenesClearMechanics.get_field_names()
                lista_campos = etiquetas.split(", ")
                diccionario = {lista_campos[i]: str(resultados[i]) for i in range(len(lista_campos))}
                response = {'success': True, 'message': None, 'data': [diccionario]}
                return Response(response, status=status.HTTP_201_CREATED)

        except Exception as e:
            response = {'success': False, 'message': 'ERROR', 'data': str(e)}
            return Response(response, status=status.HTTP_400_BAD_REQUEST)
"""
===========================
    Tecnicos
===========================
"""        
@logger('Tecnicos', interfaz=None, log_all=True)
class TecnicosAPIView(APIView):
    queryset = AsesorClearMechanics.objects.all()
    serializer_class = AsesorSerializer
    required_scopes = ['write']

    @action(detail=False, methods=['GET'])
    def get(self, request, pk=None):
        try:
            asesores = fetch_asesores(request, tipo_personal='Mecanico')
            for asesor in asesores:
                asesor['technicianId'] = asesor.pop('serviceAdvisorId')
            return build_response(success=True, data=asesores)
        except Exception as e:
            return build_response(success=False, message='ERROR', data=str(e), status_code=status.HTTP_400_BAD_REQUEST)
"""
===========================
    Asesores
===========================
""" 
@logger('Asesores', interfaz=None, log_all=True)
class AsesoresAPIView(APIView):
    queryset = AsesorClearMechanics.objects.all()
    serializer_class = AsesorSerializer
    required_scopes = ['write']

    @action(detail=False, methods=['GET'])
    def get(self, request, pk=None):
        try:
            asesores = fetch_asesores(request, tipo_personal='Asesor')
            return build_response(success=True, data=asesores)
        except Exception as e:
            return build_response(success=False, message='ERROR', data=str(e), status_code=status.HTTP_400_BAD_REQUEST)
"""
===========================
    Vin
===========================
""" 
@logger('Vin', interfaz=None, log_all=True)
class VinAPIView(APIView):
    serializer_class = VehiculosSerializer
    required_scopes = ['write']

    def get_vehiculos(self, request, pk=None, query_field=None):
        try:
            if pk is None:
                return Response({'success': False, 'message': 'No se ingresó VIN o Placa', 'data': []},
                                status=status.HTTP_400_BAD_REQUEST)

            # Establecer conexión a la base de datos externa
            query = Q(**{query_field: pk})

            # Ejecutar la consulta
            vehiculo = VehiculosClearMechanics.objects.filter(query)
            lista_campos = VehiculosClearMechanics.get_field_names().split(", ")
            vehiculo_data = list(vehiculo.values(*lista_campos))

            # Serializar la respuesta
            serializer = self.serializer_class(vehiculo_data, many=True)
            response = {'success': True, 'message': None, 'data': serializer.data}
            return Response(response, status=status.HTTP_200_OK)
        except Exception as e:
            response = {'success': False, 'message': 'ERROR', 'data': str(e)}
            return Response(response, status=status.HTTP_400_BAD_REQUEST)

class VehiculosAPIView(VinAPIView):
    def get(self, request, pk=None):
        return self.get_vehiculos(request, pk, query_field='vin')

class VehiculosPlacaAPIView(VinAPIView):
    def get(self, request, pk=None):
        return self.get_vehiculos(request, pk, query_field='licensePlate')

"""
===========================
    VinGarantia
===========================
""" 
@logger('VinGarantia', interfaz=None, log_all=True)
class VinGarantiaAPIView(VinAPIView):
    serializer_class = GarantiasSerializer
    required_scopes = ['write']

    def get(self, request, pk=None):
        try:
            if pk is None:
                return Response({'success': False, 'message': 'No se ingresó VIN', 'data': []},
                                status=status.HTTP_400_BAD_REQUEST)

            query = Q(vin=pk)

            vehiculo = GarantiasClearMechanics.objects.filter(query)
            lista_campos = GarantiasClearMechanics.get_field_names().split(", ")
            vehiculo_data = list(vehiculo.values(*lista_campos))

            serializer = self.serializer_class(vehiculo_data, many=True)
            response = {'success': True, 'message': None, 'data': serializer.data}
            return Response(response, status=status.HTTP_200_OK)
        except Exception as e:
            response = {'success': False, 'message': 'ERROR', 'data': str(e)}
            return Response(response, status=status.HTTP_400_BAD_REQUEST)
"""
===========================
    VinRecall
===========================
""" 
@logger('VinRecall', interfaz=None, log_all=True)
class VinRecallAPIView(VinAPIView):
    serializer_class = VinCampanaSerializer
    required_scopes = ['write']

    def get(self, request, pk=None):
        try:
            if pk is None:
                return Response({'success': False, 'message': 'No se ingresó VIN', 'data': []},
                                status=status.HTTP_400_BAD_REQUEST)

            query = Q(vin=pk)

            vehiculo = VinCampanaClearMechanics.objects.filter(query)
            lista_campos = VinCampanaClearMechanics.get_field_names().split(", ")
            vehiculo_data = list(vehiculo.values(*lista_campos))

            serializer = self.serializer_class(vehiculo_data, many=True)
            response = {'success': True, 'message': None, 'data': serializer.data}
            return Response(response, status=status.HTTP_200_OK)
        except Exception as e:
            response = {'success': False, 'message': 'ERROR', 'data': str(e)}
            return Response(response, status=status.HTTP_400_BAD_REQUEST)
