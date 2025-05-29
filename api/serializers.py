from rest_framework import serializers
from isapilib.models import Cte
from .models import *


"""
===========================
    CitasDeServicio
===========================
"""
class CitasSerializer(serializers.ModelSerializer):
    class Meta:
        model = CitasClearMechanics
        fields = '__all__'
"""
===========================
    Clientes
===========================
"""
class CteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Cte
        fields = '__all_'
"""
===========================
    OrdenesDeServicio
===========================
"""
class OrdenesSerializer(serializers.ModelSerializer):
    class Meta:
        model = OrdenesClearMechanics
        fields = '__all__'
"""
===========================
    Agentes
===========================
"""
class AsesorSerializer(serializers.ModelSerializer):
    class Meta:
        model = AsesorClearMechanics
        fields = '__all_'
"""
===========================
    Vin
===========================
"""
class VehiculosSerializer(serializers.ModelSerializer):
    class Meta:
        model = VehiculosClearMechanics
        fields = '__all__'
"""
===========================
    VinGarantias
===========================
"""
class GarantiasSerializer(serializers.ModelSerializer):
    class Meta:
        model = GarantiasClearMechanics
        fields = '__all__'
"""
===========================
    VinRecall
===========================
"""
class VinCampanaSerializer(serializers.ModelSerializer):
    class Meta:
        model = VinCampanaClearMechanics
        fields = '__all__'