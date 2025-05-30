from django.conf import settings
from django.http import HttpResponse

def index(request):
    url_doc = getattr(settings,'URL_DOCUMENTATION', '')
    interfaz =getattr(settings,'INTERFAZ_NAME','')

    return HttpResponse(f'''
        <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: sans-serif;
            color: #dfe2e6;
        }}

        body {{
            background: radial-gradient(#01579b,#1f1013);
            display: flex;
            height: 100vh;
            overflow: hidden;
            animation: fadeIn 1s ease-out;
        }}

        div {{
            margin: auto;
            display: flex;
            font-size: 6vw;
            user-select: none;
            text-align: center;
            flex-direction: column;
            align-items: center;
        }}

        a {{
            opacity: 0.8;
            font-size: 1.2rem;
            text-decoration: none;
            margin-top: 20px;
            transition: all 0.3s ease-in-out;
        }}

        a:hover {{
            transform: scale(1.3);
            opacity: 1;
        }}

        span {{
            opacity: 0.8;
            font-size: 1.5rem;
            margin-top: 10px;
            transition: all 0.3s ease-in-out;
        }}

        .light {{
            position: absolute;
            width: 0px;
            background-color: white;
            box-shadow: #e9f1f1 0px 0px 20px 2px;
            top: 100vh;
            bottom: 0px;
            left: 0px;
            right: 0px;
            margin: auto;
            opacity: 0.75;
        }}

        .x1 {{ animation: floatUp 4s infinite linear; transform: scale(1.0); }}
        .x2 {{ animation: floatUp 7s infinite linear; transform: scale(1.6); left: 15%; }}
        .x3 {{ animation: floatUp 2.5s infinite linear; transform: scale(0.5); left: -15%; }}
        .x4 {{ animation: floatUp 4.5s infinite linear; transform: scale(1.2); left: -34%; }}
        .x5 {{ animation: floatUp 8s infinite linear; transform: scale(2.2); left: -57%; }}
        .x6 {{ animation: floatUp 3s infinite linear; transform: scale(0.8); left: -81%; }}
        .x7 {{ animation: floatUp 5.3s infinite linear; transform: scale(3.2); left: 37%; }}
        .x8 {{ animation: floatUp 4.7s infinite linear; transform: scale(1.7); left: 62%; }}
        .x9 {{ animation: floatUp 4.1s infinite linear; transform: scale(0.9); left: 85%; }}

        @keyframes floatUp {{
            0%   {{ top: 100vh; opacity: 0; }}
            25%  {{ opacity: 1; }}
            50%  {{ top: 50vh; opacity: 0.8; }}
            75%  {{ opacity: 1; }}
            100% {{ top: -10vh; opacity: 0; }}
        }}

        @keyframes fadeIn {{
            from {{ opacity: 0; }}
            to {{ opacity: 1; }}
        }}

        @keyframes fadeOut {{
            0%   {{ opacity: 0; }}
            10%  {{ opacity: 1; }}
            90%  {{ opacity: 1; }}
            100% {{ opacity: 0; }}
        }}

        @keyframes finalFade {{
            0%   {{ opacity: 0; }}
            20%  {{ opacity: 1; }}
            100% {{ opacity: 1; }}
        }}

        .header {{
            position: absolute;
            top: 40%;
            left: 50%;
            transform: translate(-50%, -50%);
            font-family: 'Roboto', sans-serif;
            font-weight: 200;
            color: white;
            font-size: 3vw;
            text-align: center;
        }}

        #head1, #head2, #head3, #head4, #head5, #head6 {{
            opacity: 0;
        }}

        #head1 {{ animation: fadeOut 5s ease-in 0s forwards; }}
        #head2 {{ animation: fadeOut 5s ease-in 6s forwards; }}
        #head3 {{ animation: fadeOut 5s ease-in 12s forwards; }}
        #head4 {{ animation: fadeOut 5s ease-in 17s forwards; }}
        #head5 {{ animation: fadeOut 5s ease-in 22s forwards; }}
        #head6 {{ 
            animation: finalFade 5s ease-in 27s forwards; 
            font-size: 5vw; font-size: 12vw;
        }}
        
        .header-container {{
            display: flex;
            flex-direction: column;
            text-align: center;
            height: 75vh;
        }}
        .info-container {{
            display: flex;
            flex-direction: column;
            text-align: center;
            height: 25vh; 
        }}
        </style>
        <body>
            <div>
                <div class="header-container">
                    <p id='head1' class='header'>Unifica tu información</p>
                    <p id='head2' class='header'>Fácil</p>
                    <p id='head3' class='header'>Consulta</p>
                    <p id='head4' class='header'>Todas tus agencias en un solo lugar</p>
                    <p id='head5' class='header'>Bienvenido</p>
                    <p id='head6' class='header'>Intelisis</p>
                </div>
                <div class="info-container">
                    {f'<span>{interfaz}</span>' if interfaz else ''}
                    {f'<a href="{url_doc}">Documentación</a>' if url_doc else ''}
                </div>
            </div>
            <!-- Efectos visuales -->
            <div class="light x1"></div>
            <div class="light x2"></div>
            <div class="light x3"></div>
            <div class="light x4"></div>
            <div class="light x5"></div>
            <div class="light x6"></div>
            <div class="light x7"></div>
            <div class="light x8"></div>
            <div class="light x9"></div>
        </body>
    ''')