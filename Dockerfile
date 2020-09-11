FROM lambci/lambda:python3.6

USER root
# ultemately, /var/task/bin, /var/task/src, /var/task/lib, /var/task/requirements.txt
ENV APP_DIR /var/task

WORKDIR $APP_DIR

COPY requirements.txt .
COPY bin ./bin

RUN mkdir -p $APP_DIR/lib
RUN pip3 install -r requirements.txt -t /var/task/lib