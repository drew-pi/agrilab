## How to run Flask server

Navigate to the directory of the flask server

Create the virtual environment in that directory (make sure it is called venv otherwise it will be tracked by github)
```
python -m venv venv
```

Activate the virtual environment
```
source venv/bin/activate
```

Install the necessary dependencies
```
pip install -r requirements.txt
```

Run the Flask application (should not need ```python3``` because the virtual environment has the alias python)
```
python app.py
```
