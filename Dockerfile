FROM python:alpine
WORKDIR /code
ADD . '/code'
RUN pip install -r requirements.txt
CMD ["python3","app.py"]