
FROM public.ecr.aws/lambda/python:3.12
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt || true
COPY index.py ${LAMBDA_TASK_ROOT}/

CMD [ "index.handler" ]