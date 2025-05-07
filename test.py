import requests
import json

def main(html: str) -> str:
    url = "http://118.25.84.228:15600/api/screenshot-id"
    headers = {"Content-Type": "application/json"}
    payload = {
        "html": html,
        "options": {
        }
    }
    
    response = requests.post(url, headers=headers, json=payload)
    
    # 返回Base64编码的Data URI格式
    response_data = json.loads(response.content.decode('utf-8'))
    return response_data['cacheId']

print(main("""1"""))