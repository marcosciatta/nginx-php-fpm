#!/bin/bash

# Disable Strict Host checking for non interactive git clones

#echo -e "Host *\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config

# Pull down code form git for our site!
if [ ! -z "$GIT_REPO" ]; then
  rm -R /usr/share/nginx/html/*
  if [ ! -z "$GIT_BRANCH" ]; then
    git clone -b $GIT_BRANCH https://$GIT_TOKEN:x-oauth-basic@$GIT_REPO /usr/share/nginx/html/
  else
    git clone -u $GIT_TOKEN:x-oauth-basic $GIT_REPO /usr/share/nginx/html/
  fi
  chown -Rf nginx.nginx /usr/share/nginx/*
  composer --no-interaction --working-dir="/usr/share/nginx/html/" install > composer.log
fi

# Tweak nginx to match the workers to cpu's

procs=$(cat /proc/cpuinfo |grep processor | wc -l)
sed -i -e "s/worker_processes 5/worker_processes $procs/" /etc/nginx/nginx.conf

# Very dirty hack to replace variables in code with ENVIRONMENT values

for i in $(env)
do
  variable=$(echo "$i" | cut -d'=' -f1)
  value=$(echo "$i" | cut -d'=' -f2)
  if [[ "$variable" != '%s' ]] ; then
    replace='\$\$_'${variable}'_\$\$'
    find /usr/share/nginx/html -type f -exec sed -i -e 's/'${replace}'/'${value}'/g' {} \; 2> /dev/null ; fi
  done

# Start supervisord and services
echo "launch $@"
exec "$@"
