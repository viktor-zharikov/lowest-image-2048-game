FROM  alpine:latest as build

#Define build argument for version
# set nginx version, see all version on: http://nginx.org/download/
ARG VERSION=1.21.6

# Install build tools, libraries and utilities 
RUN apk add --no-cache --virtual .build-deps                                        \
        build-base                                                                  \   
        gnupg                                                                       \
        pcre-dev                                                                    \
        wget                                                                        \
        zlib-dev                                                                    \
        zlib-static                                                                 \
        zlib
                                                                       
# unpack nginx  
RUN set -x                                                                      &&  \
    cd /tmp                                                                     &&  \
    wget -q http://nginx.org/download/nginx-${VERSION}.tar.gz                   &&  \
    wget -q http://nginx.org/download/nginx-${VERSION}.tar.gz.asc               &&  \
    tar -xf nginx-${VERSION}.tar.gz                                             &&  \
    echo ${VERSION}                                           

WORKDIR /tmp/nginx-${VERSION}

# Build and install nginx
RUN ./configure                                                                     \
        --with-ld-opt="-static"                                                     \
        --with-http_sub_module                                                  &&  \
    make install                                                                &&  \
    strip /usr/local/nginx/sbin/nginx

# Symlink access and error logs to /dev/stdout and /dev/stderr, in 
# order to make use of Docker's logging mechanism
RUN ln -sf /dev/stdout /usr/local/nginx/logs/access.log                         &&  \
    ln -sf /dev/stderr /usr/local/nginx/logs/error.log

FROM scratch 

# Customise static content, and configuration
COPY --from=build /etc/passwd /etc/group /etc/
COPY --from=build /usr/local/nginx /usr/local/nginx

COPY 2048 /usr/local/nginx/html/
#Change default stop signal from SIGTERM to SIGQUIT
STOPSIGNAL SIGQUIT

# Define entrypoint and default parameters 
CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"] 
