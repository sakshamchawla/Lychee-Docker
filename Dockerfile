FROM debian:bookworm-slim

# Set version label
LABEL maintainer="lycheeorg"

# Environment variables
ENV PUID='1000'
ENV PGID='1000'
ENV USER='lychee'
ENV PHP_TZ=UTC

# Arguments
# To use the latest Lychee release instead of master pass `--build-arg TARGET=release` to `docker build`
ARG TARGET=dev

# Install base dependencies, add user and group, clone the repo and install php libraries
RUN \
    set -ev && \
    apt-get update && \
    apt-get upgrade -qy && \
    apt-get install -qy --no-install-recommends\
    adduser \
    nginx-light \
    php8.2-mysql \
    php8.2-pgsql \
    php8.2-sqlite3 \
    php8.2-imagick \
    php8.2-mbstring \
    php8.2-gd \
    php8.2-xml \
    php8.2-zip \
    php8.2-fpm \
    php8.2-redis \
    php8.2-bcmath \
    php8.2-intl \
    curl \
    libimage-exiftool-perl \
    ffmpeg \
    git \
    jpegoptim \
    optipng \
    pngquant \
    gifsicle \
    webp \
    cron \
    composer \
    ssh \
    unzip && \
    addgroup --gid "$PGID" "$USER" && \
    adduser --gecos '' --no-create-home --disabled-password --uid "$PUID" --gid "$PGID" "$USER" && \
    cd /var/www/html && \
    if [ "$TARGET" = "release" ] ; then RELEASE_TAG="-b v$(curl -s https://raw.githubusercontent.com/LycheeOrg/Lychee/master/version.md)" ; fi && \
    git clone https://github.com/sakshamchawla/Lychee.git && \
    chown -R lychee:lychee . && \
    chmod 777 -R . && \
    mv Lychee/.git/refs/heads/master Lychee/master || cp Lychee/.git/HEAD Lychee/master && \
    mv Lychee/.git/HEAD Lychee/HEAD && \
    rm -r Lychee/.git/* && \
    mkdir -p Lychee/.git/refs/heads && \
    mv Lychee/HEAD Lychee/.git/HEAD && \
    mv Lychee/master Lychee/.git/refs/heads/master && \
    echo "$TARGET" > /var/www/html/Lychee/docker_target && \
    cd /var/www/html/Lychee && \
    echo "Last release: $(cat version.md)" && \
    composer install --no-dev --prefer-dist && \
    find . -wholename '*/[Tt]ests/*' -delete && \
    find . -wholename '*/[Tt]est/*' -delete && \
    rm -r storage/framework/cache/data/* 2> /dev/null || true && \
    rm    storage/framework/sessions/* 2> /dev/null || true && \
    rm    storage/framework/views/* 2> /dev/null || true && \
    rm    storage/logs/* 2> /dev/null || true && \    
    echo "* * * * * www-data cd /var/www/html/Lychee && php artisan schedule:run >> /dev/null 2>&1" >> /etc/crontab && \
    apt-get purge -y --autoremove git composer && \
    apt-get clean -qy &&\
    chown -R www-data:www-data /var/www/html/Lychee/storage && \
    rm -rf /var/lib/apt/lists/*

# Add custom Nginx configuration
COPY default.conf /etc/nginx/nginx.conf

EXPOSE 80
VOLUME /conf /uploads /sym

WORKDIR /var/www/html/Lychee

COPY entrypoint.sh inject.sh /

RUN chmod +x /entrypoint.sh && \
    chmod +x /inject.sh && \
    if [ ! -e /run/php ] ; then mkdir /run/php ; fi

HEALTHCHECK CMD curl --fail http://localhost:80/ || exit 1

ENTRYPOINT [ "/entrypoint.sh" ]

CMD [ "nginx" ]
