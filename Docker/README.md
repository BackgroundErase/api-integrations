# Background Removal API Docker Server Integration

Docker flask server for the BEN API that removes backgrounds from images.

## Installation

```bash
git clone https://github.com/PramaLLC/ben-api-python-docker-integration
cd ben-api-python-docker-integration
docker build -t ben-api .
docker run -p 8585:8585 ben-api
```

## Generate api token 
You must have a business subscription that can be found at https://backgrounderase.net/pricing. To generate the token navigate to
https://backgrounderase.net/account and scroll to the bottom of the page.

## Example Request
create example.py
```python
import requests
import base64
from PIL import Image
import io

def test_flask_server():
    # API endpoint
    url = 'http://localhost:8585'
    
    # Your API key
    headers = {
        'Content-Type': 'application/json',
        'x-api-key': 'your_ben_api_token' # your ben api token here
    }

    with open('image.jpg', 'rb') as image_file: # your image file path
        image_data = base64.b64encode(image_file.read()).decode('utf-8')
    
    # Prepare the payload
    payload = {
        'image': image_data
    }

    try:
        # Make POST request
        response = requests.post(url, headers=headers, json=payload)
        
        if response.status_code == 200:
            # Save returned image
            image_data = base64.b64decode(response.json()['image'])
            image = Image.open(io.BytesIO(image_data))
            image.save('response_image.png')
            print("Response image saved as 'response_image.png'")
        else:
            print(f"Error: {response.text}")
    
    except requests.exceptions.RequestException as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    test_flask_server()

```


## API Documentation
For full API documentation visit: https://backgrounderase.net/docs
