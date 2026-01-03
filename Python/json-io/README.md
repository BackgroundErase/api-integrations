# BackgroundErase API Python Integration

Python wrapper for the BackgroundErase API.

## Installation

```bash
git clone https://github.com/BackgroundErase/api-integrations.git
cd api-integrations/Python/json-io
pip install -r requirements.txt
```

## Generate API Key 
You must have an active business subscription which can be found at https://backgrounderase.com/pricing. To generate your API key navigate to
https://backgrounderase.com/account and scroll to the 'API Access' section then press 'Generate Key'.

## Example
create example.py
```python
from PIL import Image
from main import predict_image # import predict image function from repo

image = Image.open("image.jpg") # your image file path or pil image object


mask, foregorund = predict_image(image,"YOUR_API_TOKEN")


mask.save("mask.png")
foregorund.save("foreground.png")

```


## API documentation
For full API documentation visit: https://backgrounderase.com/docs
