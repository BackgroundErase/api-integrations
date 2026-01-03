import requests
import base64
from PIL import Image,ImageOps
import io
import numpy as np

def predict_image(image, api_key, api_url="https://api.backgrounderase.net/v2"):


    image = ImageOps.exif_transpose(image)

    buffer = io.BytesIO()
    image_resized = image.resize((1024, 1024), Image.BILINEAR)
    image_resized.save(buffer, format='JPEG', quality=85, optimize=True)
    image_bytes = buffer.getvalue()
    image_base64 = base64.b64encode(image_bytes).decode('utf-8')
    
    headers = {
        'x-api-key': api_key,
        'Content-Type': 'application/json'
    }
    payload = {
        "image": image_base64
    }
    response = requests.post(
        api_url, 
        headers=headers, 
        json=payload 
    )
    if response.status_code == 200:
        try:
            result = response.json()
            mask_bytes = base64.b64decode(result['mask'])
            
            mask_img = Image.open(io.BytesIO(mask_bytes))
            
            mask_array = np.array(mask_img)

            mask = Image.fromarray(mask_array)

            image = image.convert("RGB")
            mask = mask.resize(image.size)

            image.putalpha(mask)

            return mask, image 
        except Exception as e:
            print(f"Error processing response: {e}")
            return None
    else:
        print(f"Error: {response.status_code}")
        print("Response:", response.content)
        return None
