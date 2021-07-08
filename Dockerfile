FROM nginx:1.20-perl

RUN apt update && apt-get install -y lsb-release nodejs gnupg2 git

COPY app/static/nginx.conf /etc/nginx/nginx.conf
COPY app/static/vhost.conf /etc/nginx/conf.d/default.conf
COPY app/static/ssl-include.conf /etc/nginx/include/ssl-include.conf
COPY app/static/vhost-shared.conf /etc/nginx/include/vhost-shared.conf
COPY app/certs/self-signed.crt /etc/ssl/certs-custom/self-signed.crt
COPY app/certs/self-signed.key /etc/ssl/certs-custom/self-signed.key
COPY app/certs/dhparam.pem /etc/ssl/certs-custom/dhparam.pem

COPY app/ /app

WORKDIR /app

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -

RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt update
RUN apt install yarn

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - \
    && apt-get install -y nodejs



RUN yarn install

RUN chmod 777 node_modules && yarn run build

RUN mkdir -p /var/www/html

RUN cp -R /app/build/* /var/www/html/ && chmod 777 -Rc /var/www/html
