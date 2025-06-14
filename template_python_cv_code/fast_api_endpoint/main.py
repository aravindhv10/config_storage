#!/usr/bin/env python3
import os

try:
    __file__
except:
    basepath = "."
else:
    basepath = os.path.abspath(os.path.dirname(__file__) + "/")

import sys

sys.path.append(basepath)

from fastapi import FastAPI
from fastapi import File
from fastapi import HTTPException
from fastapi import UploadFile
from fastapi.responses import StreamingResponse
from PIL import Image
import io

app = FastAPI(
    title="Infer face expression",
    description="Upload an image (JPG or PNG) to infer facian expression.",
    version="1.0.0",
)


@app.post("/convert-to-monochrome/", response_class=StreamingResponse)
async def create_monochrome_image(file: UploadFile = File(...)):
    """
    Accepts an image file, converts it to monochrome, and returns the result.

    **Args**:
    - **file**: The uploaded image file (must be in JPG or PNG format).

    **Returns**:
    - A streaming response containing the monochrome image in PNG format.
    """
    # 1. Validate the uploaded file type
    if file.content_type not in ["image/jpeg", "image/png"]:
        raise HTTPException(
            status_code=400,
            detail="Invalid file type. Please upload a JPG or PNG image.",
        )

    # 2. Read the image data from the uploaded file
    # `await file.read()` reads the file content into memory.
    contents = await file.read()

    # 3. Use Pillow to open the image from the in-memory bytes
    try:
        image = Image.open(io.BytesIO(contents))
    except Exception:
        raise HTTPException(status_code=500, detail="Could not process the image file.")

    # 4. Convert the image to monochrome (grayscale)
    # The 'L' mode in Pillow stands for luminance, which is grayscale.
    monochrome_image = image.convert("L")

    # 5. Save the converted image to an in-memory buffer
    # We save it in PNG format to preserve quality.
    img_byte_arr = io.BytesIO()
    monochrome_image.save(img_byte_arr, format="PNG")

    # The `seek(0)` is crucial. After writing to the buffer, the "cursor" is at the end.
    # We need to move it back to the beginning before reading the data to send it.
    img_byte_arr.seek(0)

    # 6. Return the image as a StreamingResponse
    # This is an efficient way to send binary data like images.
    return StreamingResponse(img_byte_arr, media_type="image/png")


# Optional: Add a root endpoint for basic API health check
@app.get("/")
def read_root():
    return {
        "message": "Welcome to the Monochrome Image Converter API. Go to /docs for usage."
    }
