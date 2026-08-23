import json
import urllib.request
import urllib.error
from app.config import settings

def calculate_route(origin_lat: float, origin_lng: float, dest_lat: float, dest_lng: float) -> dict:
    """
    Calculates a route between origin and destination coordinates using the Google Routes API (New).
    """
    api_key = settings.GOOGLE_ROUTES_API_KEY or settings.MAP_KEY
    if not api_key:
        raise ValueError("Google Routes API key (GOOGLE_ROUTES_API_KEY) is not set in backend settings.")

    url = "https://routes.googleapis.com/directions/v2:computeRoutes"
    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": api_key,
        "X-Goog-FieldMask": "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline"
    }

    body = {
        "origin": {
            "location": {
                "latLng": {
                    "latitude": origin_lat,
                    "longitude": origin_lng
                }
            }
        },
        "destination": {
            "location": {
                "latLng": {
                    "latitude": dest_lat,
                    "longitude": dest_lng
                }
            }
        },
        "travelMode": "DRIVE",
        "routingPreference": "TRAFFIC_AWARE",
        "units": "METRIC",
        "languageCode": "en-US"
    }

    req_data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=req_data, headers=headers, method="POST")

    try:
        with urllib.request.urlopen(req, timeout=15) as response:
            res_body = response.read().decode("utf-8")
            data = json.loads(res_body)
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8")
        raise Exception(f"Routes API returned HTTP {e.code}: {error_body}")
    except Exception as e:
        raise Exception(f"Failed to call Routes API: {str(e)}")

    routes = data.get("routes", [])
    if not routes:
        raise ValueError("No route found between the specified coordinates.")

    route = routes[0]
    distance_meters = route.get("distanceMeters", 0)
    duration_str = route.get("duration", "0s")

    # duration is returned as string e.g. "123.4s" or "123s"
    clean_duration = duration_str.replace("s", "")
    try:
        duration_seconds = round(float(clean_duration))
    except ValueError:
        duration_seconds = 0

    polyline = route.get("polyline", {}).get("encodedPolyline", "")

    # Format distance text
    distance_km = distance_meters / 1000.0
    distance_text = f"{distance_km:.1f} km"

    # Format duration text
    duration_min = round(duration_seconds / 60)
    duration_text = f"{duration_min} min" if duration_min >= 1 else "1 min"

    return {
        "distance_meters": distance_meters,
        "duration_seconds": duration_seconds,
        "duration_text": duration_text,
        "distance_text": distance_text,
        "polyline": polyline
    }
