from fastapi import APIRouter, HTTPException, status
from app.schemas.route import RouteRequest, RouteResponse
from app.services.routes import calculate_route

router = APIRouter(prefix="/routes", tags=["routes"])

@router.post("/calculate", response_model=RouteResponse)
def calculate_route_endpoint(request: RouteRequest):
    try:
        result = calculate_route(
            origin_lat=request.origin_latitude,
            origin_lng=request.origin_longitude,
            dest_lat=request.destination_latitude,
            dest_lng=request.destination_longitude
        )
        return result
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(e)
        )
