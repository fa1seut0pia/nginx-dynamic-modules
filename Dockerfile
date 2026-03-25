# syntax=docker/dockerfile:1.7

ARG NGINX_VERSION=1.29.6
ARG NGINX_IMAGE=nginx

FROM ${NGINX_IMAGE}:${NGINX_VERSION} AS build

ARG NGINX_VERSION
ARG MODULE_NAME
ARG MODULE_REPO
ARG MODULE_REF=

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list.d/debian.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        git \
        libpcre2-dev \
        libssl-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src

RUN curl -fsSL -o nginx-${NGINX_VERSION}.tar.gz \
        https://github.com/nginx/nginx/releases/download/release-${NGINX_VERSION}/nginx-${NGINX_VERSION}.tar.gz \
    && tar -zxf nginx-${NGINX_VERSION}.tar.gz \
    && git clone --depth=1 "${MODULE_REPO}" /usr/src/module \
    && if [[ -n "${MODULE_REF}" ]]; then \
        git -C /usr/src/module fetch --depth=1 origin "${MODULE_REF}" \
        && git -C /usr/src/module checkout FETCH_HEAD; \
    fi

RUN set -eux; \
    so_name=""; \
    module_path=""; \
    case "${MODULE_NAME}" in \
        rtmp) \
            so_name="ngx_rtmp_module.so"; \
            module_path="/usr/src/module"; \
            ;; \
        vts) \
            so_name="ngx_http_vhost_traffic_status_module.so"; \
            module_path="/usr/src/module"; \
            ;; \
        ip2region) \
            make -C /usr/src/module/binding/c xdb_searcher_lib; \
            cp -r /usr/src/module/binding/c/build/include/. /usr/local/include/; \
            cp -r /usr/src/module/binding/c/build/lib/. /usr/local/lib/; \
            ldconfig; \
            so_name="ngx_http_ip2region_module.so"; \
            module_path="/usr/src/module/binding/nginx"; \
            ;; \
        *) \
            echo "unsupported module: ${MODULE_NAME}" >&2; \
            exit 1; \
            ;; \
    esac; \
    configure_args="$(nginx -V 2>&1 | sed -n 's/^.*arguments: //p')"; \
    cd /usr/src/nginx-${NGINX_VERSION}; \
    eval "./configure ${configure_args} --add-dynamic-module='${module_path}'"; \
    make modules; \
    mkdir -p /out; \
    cp "objs/${so_name}" "/out/${so_name}"; \
    printf '%s\n' "${so_name}" > /out/module.so.name

FROM scratch AS export_so

COPY --from=build /out/ /
