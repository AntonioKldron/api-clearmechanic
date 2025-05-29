from django.urls import path
from .views import *

urlpatterns = [
    path('orders'                       ,OrdenesDeServicioAPIView.as_view()      , name='OrdenesDeServicio'),
    path('orders/<str:pk>'              ,OrdenesDeServicioAPIView.as_view()      , name='OrdenesDeServicio'),
    path('appointments'                 ,CitasDeServicioAPIView.as_view()        , name='CitasDeServicio'),
    path('appointments/<str:pk>'        ,CitasDeServicioAPIView.as_view()        , name='CitasDeServicio'),
    path('appointments/<str:pk>/jobs'   ,CitasDeServicioDetalleAPIView.as_view() , name='CitasDeServicioDetalle'),
    path('vehicles/<str:pk>'            ,VehiculosAPIView.as_view()              , name='Vin'),
    path('vehiclesPlate/<str:pk>'       ,VehiculosPlacaAPIView.as_view()         , name='Vin'),
    path('vehicles/<str:pk>/warranties' ,VinGarantiaAPIView.as_view()            , name='VinGarantia'),
    path('vehicles/<str:pk>/campaigns'  ,VinRecallAPIView.as_view()              , name='VinRecall'),
    path('customers/<str:pk>'           ,ClientesAPIView.as_view()               , name='Clientes'),
    path('customers/'                   ,ClientesAPIView.as_view()               , name='Clientes'),
    path('technicians'                  ,TecnicosAPIView.as_view()               , name='Tecnicos'),
    path('inventoryItems'               ,InventarioAPIView.as_view()             , name='Inventario'),
    path('inventoryItems/<str:pk>'      ,InventarioAPIView.as_view()             , name='Inventario'),
    path('advisors'                     ,AsesoresAPIView.as_view()               , name='Asesores'),
    path('orderTypes'                   ,TipoOrdenesAPIView.as_view()            , name='TipoOrden'),
    path('orderTypesList'               ,TipoOrdenesListAPIView.as_view()        , name='TipoOrden'),
    path('offers'                       ,OfertasAPIView.as_view()                , name='Ofertas'),
    path('quotation'                    ,CotizacionesAPIView.as_view()           , name='Cotizaciones'),
]
