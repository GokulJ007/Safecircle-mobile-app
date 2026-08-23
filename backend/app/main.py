from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import auth_router, contact_router, journey_router, sos_router, routes_router

# Initialize FastAPI application
app = FastAPI(
    title="SafeCircle Backend API",
    description="A smart companion backend that keeps trusted contacts informed throughout a journey.",
    version="1.0.0",
)

# Enable CORS for frontend clients (e.g. Flutter mobile app, web dashboard)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict this to trusted domains
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount all routers
app.include_router(auth_router)
app.include_router(contact_router)
app.include_router(journey_router)
app.include_router(sos_router)
app.include_router(routes_router)

@app.get("/")
def read_root():
    """Root endpoint to check API status and link to the OpenAPI/Swagger docs."""
    return {
        "app": "SafeCircle Backend API",
        "status": "online",
        "docs_url": "/docs"
    }
