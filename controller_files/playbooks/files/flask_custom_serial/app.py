from flask import Flask, make_response, request, Response
from base64 import b64encode, b64decode
from io import BytesIO
import pickle
import uuid

# dta_flag{2daf5c09-b62c-453e-92c8-1c2b572e0002}

app = Flask(__name__)

page = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Under Construction</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            height: 100vh;
            background: radial-gradient(circle at top, #0a0a0a, #111);
            color: #f8f8f8;
            font-family: monospace;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            text-align: center;
        }
        h1 {
            font-size: 3em;
            margin-bottom: 0.2em;
            text-transform: uppercase;
            letter-spacing: 3px;
            color: #ff5555;
        }
        p {
            font-size: 1.2em;
            color: #bbb;
        }
        hr {
            width: 40%;
            border: 1px solid #ff5555;
            margin: 1em auto;
        }
        .hint {
            position: absolute;
            bottom: 20px;
            left: 0;
            right: 0;
            text-align: center;
            color: #666;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <h1>Under Construction</h1>
    <hr />
    <p>Something cool is coming soon.</p>
    <div class="hint">{{}}</div>
</body>
</html>
"""

class User:
    def __init__(self):
        self.user_id = str(uuid.uuid4())

    def __repr__(self):
        return self.user_id

class SafeUnpickler(pickle.Unpickler):
    FORBIDDEN = {
        ('posix', 'system'),
        ('posix', 'popen'),
        ('posix', 'spawnl'),
        ('posix', 'spawnle'),
        ('posix', 'spawnlp'),
        ('posix', 'spawnlpe'),
        ('posix', 'spawnv'),
        ('posix', 'spawnve'),
        ('posix', 'spawnvp'),
        ('posix', 'spawnvpe'),
        ('posix', 'fork'),
        ('posix', 'execv'),
        ('posix', 'execve'),
        ('posix', 'execvp'),
        ('posix', 'execvpe'),
        ('os', 'system'),
        ('os', 'popen'),
        ('os', 'spawnl'),
        ('os', 'spawnle'),
        ('os', 'spawnlp'),
        ('os', 'spawnlpe'),
        ('os', 'spawnv'),
        ('os', 'spawnve'),
        ('os', 'spawnvp'),
        ('os', 'spawnvpe'),
        ('os', 'fork'),
        ('os', 'execv'),
        ('os', 'execve'),
        ('os', 'execvp'),
        ('os', 'execvpe'),
        ('subprocess', 'Popen'),
        ('subprocess', 'call'),
        ('subprocess', 'run'),
        ('subprocess', 'check_call'),
        ('subprocess', 'check_output'),
        ('socket', 'socket'),
        ('ssl', 'SSLContext'),
        ('urllib', 'request'),
        ('http', 'client'),
        ('shlex', 'split'),
        ('pathlib', 'Path'),
        ('builtins', 'open'),
        ('tempfile', 'NamedTemporaryFile'),
        ('tempfile', 'TemporaryFile'),
        ('code', 'compile'),
        ('code', 'compile_command'),
        ('pty', 'spawn'),
        ('threading', 'Thread'),
        ('webbrowser', 'open'),
        ('ctypes', 'CDLL'),
        ('ctypes', 'POINTER'),}

    def find_class(self, module, name):
        if (module, name) in self.FORBIDDEN:
            raise pickle.UnpicklingError(f"Forbidden: {module}.{name}")
        return super().find_class(module, name)

def safe_loads(data):
    return SafeUnpickler(BytesIO(b64decode(data))).load()

@app.route('/')
def index() -> Response:
    cookie = request.cookies.get('user')
    if (not cookie):
        user = User()
        resp = make_response(page.replace("{{}}", "New user!"))
        resp.set_cookie('user', b64encode(pickle.dumps(user)).decode('utf-8'))
        return resp
    else:
        user = safe_loads(cookie)

    return make_response(page.replace("{{}}", "Welcome back!"))


if (__name__ == "__main__"):
    app.run(host="0.0.0.0", port=8080)
