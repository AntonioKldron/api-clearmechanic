from functools import lru_cache
from isapilib.api.models import SepaBranch
from isapilib.core.router import BaseRouter


@lru_cache
def get_branch(dealer_id: str) -> SepaBranch:
    branch = SepaBranch.objects.filter(id=dealer_id, id__isnull=False).first()
    if branch is None: raise SepaBranch.DoesNotExist('El DealerID no existe')
    return branch

class BranchRouter(BaseRouter):
    def get_branch(self, user, request) -> SepaBranch:
        return get_branch(request.headers.get('organizationId'))

