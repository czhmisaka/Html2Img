'''
Date: 2025-05-08 03:10:30
LastEditors: CZH
LastEditTime: 2025-05-08 03:26:27
FilePath: /html生成图片/test.py
'''
import requests
import base64

def main(html: str) -> str:
    url = "http://118.25.84.228:15600/api/screenshot"
    headers = {"Content-Type": "application/json"}
    payload = {
        "html": html,
        "options": {
        }
    }
    
    response = requests.post(url, headers=headers, json=payload)
    
    # 返回Base64编码的Data URI格式
    base64_data = base64.b64encode(response.content).decode('utf-8')
    return f"![Base64图片](data:image/png;base64,{base64_data})"

print(main("```html\n<!DOCTYPE html>\n<html>\n<head>\n    <style>\n        .diagram {\n            width: 200px;\n            height: 200px;\n            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);\n            border-radius: 10px;\n            padding: 10px;\n            box-shadow: 0 4px 8px rgba(0,0,0,0.1);\n            position: relative;\n            overflow: hidden;\n        }\n        .box {\n            position: absolute;\n            border-radius: 5px;\n            display: flex;\n            align-items: center;\n            justify-content: center;\n            color: white;\n            font-family: Arial, sans-serif;\n            font-size: 10px;\n            text-align: center;\n            box-shadow: 0 2px 4px rgba(0,0,0,0.2);\n        }\n        .client {\n            width: 60px;\n            height: 30px;\n            background: #FF6B6B;\n            top: 20px;\n            left: 70px;\n        }\n        .server {\n            width: 80px;\n            height: 40px;\n            background: #4ECDC4;\n            top: 70px;\n            left: 60px;\n        }\n        .database {\n            width: 70px;\n            height: 35px;\n            background: #FFBE0B;\n            top: 140px;\n            left: 65px;\n        }\n        .arrow {\n            position: absolute;\n            width: 2px;\n            background: #6C5CE7;\n        }\n        .arrow1 {\n            height: 30px;\n            top: 50px;\n            left: 100px;\n        }\n        .arrow2 {\n            height: 30px;\n            top: 110px;\n            left: 100px;\n        }\n        .arrow:after {\n            content: '';\n            position: absolute;\n            width: 0;\n            height: 0;\n            border-left: 5px solid transparent;\n            border-right: 5px solid transparent;\n            border-top: 8px solid #6C5CE7;\n            bottom: -8px;\n            left: -4px;\n        }\n    </style>\n</head>\n<body>\n    <div class=\"diagram\">\n        <div class=\"box client\">Client</div>\n        <div class=\"arrow arrow1\"></div>\n        <div class=\"box server\">Server</div>\n        <div class=\"arrow arrow2\"></div>\n        <div class=\"box database\">Database</div>\n    </div>\n</body>\n</html>\n```"))
