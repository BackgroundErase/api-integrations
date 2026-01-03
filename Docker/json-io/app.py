

from flask import Flask, jsonify, request 
from PIL import Image
from api import predict_image
app = Flask(__name__)
import base64 
import io


api_url = "https://api.backgrounderase.net/v2"


@app.route('/', methods=['POST'])
def home():
    try:

        api_token = request.headers.get('x-api-key')
        
        if request.is_json:
            # Check if base64 image exists in request
            if 'image' in request.json:
                base64_image = request.json.get('image')
                # Decode base64 string to bytes
                image_bytes = base64.b64decode(base64_image.encode('utf-8'))
                image = Image.open(io.BytesIO(image_bytes))
            elif 'image_path' in request.json:
                image_path = request.json.get('image_path')
                image = Image.open(image_path)

            else:
                return jsonify({"error": "No image or image_path provided in JSON"})
        else:
            return jsonify({"error": "Request must be JSON"})
        

        mask, foreground = predict_image(image,api_token,api_url)
        buffer = io.BytesIO()
        foreground.save(buffer, format='PNG')
        buffer.seek(0)

        base64_string = base64.b64encode(buffer.getvalue()).decode('utf-8')


        return jsonify({
            "image": base64_string
        })

    except Exception as e:
        return jsonify({"Error": str(e)})

if __name__ == '__main__': 
    app.run(debug=True, host='0.0.0.0', port=8585) 



# docker build -t ben-api .   
# docker run -p 8585:8585 ben-api  

