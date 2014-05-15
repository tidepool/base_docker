# Dockerfile for a Rails application using Nginx and Unicorn

# Select ubuntu as the base image
FROM ubuntu
MAINTAINER Kerem Karatal, kkaratal@tidepool.co

# Install nginx, nodejs and curl
RUN apt-get update -q
RUN apt-get install -qy nginx
RUN apt-get install -qy curl
RUN apt-get install -qy nodejs
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# Install Postgres client
RUN apt-get install -qy libpq-dev

# Install packages for building ruby
RUN apt-get install -qy build-essential curl git
RUN apt-get install -qy zlib1g-dev libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt-dev
RUN apt-get clean

# Install rbenv and ruby-build
RUN git clone https://github.com/sstephenson/rbenv.git /root/.rbenv
RUN git clone https://github.com/sstephenson/ruby-build.git /root/.rbenv/plugins/ruby-build
RUN ./root/.rbenv/plugins/ruby-build/install.sh
ENV PATH /root/.rbenv/bin:$PATH
RUN echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh # or /etc/profile
RUN echo 'eval "$(rbenv init -)"' >> .bashrc

# Install multiple versions of ruby
ENV CONFIGURE_OPTS --disable-install-doc
ADD ./ruby_versions.txt /root/ruby_versions.txt
RUN xargs -L 1 rbenv install < /root/ruby_versions.txt

# Install Bundler for each version of ruby
RUN echo 'gem: --no-rdoc --no-ri' >> /.gemrc
RUN bash -l -c 'for v in $(cat /root/ruby_versions.txt); do rbenv global $v; gem install bundler; done'

# Setup nginx permissions and web folder
RUN mkdir /var/www
RUN useradd -s /sbin/nologin -r nginx
RUN groupadd web
RUN usermod -a -G web nginx
RUN chgrp -R web /var/www
RUN chmod -R 775 /var/www
RUN usermod -a -G web root
