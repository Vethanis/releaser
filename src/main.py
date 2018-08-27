#!/usr/bin/env python

import os
from flask import Flask, request
import subprocess

# your github username
OWNER="gheshu"
# api token for your repo
API_TOKEN=""
# your repo's name
REPO="image_decompiler"
# path to your repo
REPO_PATH="/c/Users/Lauren/workspace/" + REPO   
# path to bash
BASHCMD="bash.exe"

CWD=os.getcwd().replace('\\', '/')
SCRIPT_PATH=CWD + "/main.sh"

app = Flask(__name__)

@app.route("/", methods=['GET', 'POST'])
def root():
    if request.method == 'POST':
        headers = request.headers
        if headers['X-GitHub-Event'] == 'push':
            cmd = "%s %s %s %s %s" % (SCRIPT_PATH, OWNER, REPO, REPO_PATH, API_TOKEN)
            subprocess.Popen([BASHCMD, '-c', cmd])
    return "Hello"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
