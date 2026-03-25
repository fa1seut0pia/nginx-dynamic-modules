# nginx-dynamic-modules

统一构建并发布 3 个 Nginx 动态模块：

- `ngx_rtmp_module.so`
- `ngx_http_vhost_traffic_status_module.so`
- `ngx_http_ip2region_module.so`

## 快速下载

下载模块到当前目录：

```bash
curl -fLO https://github.com/fa1seut0pia/nginx-dynamic-modules/releases/download/release-1.30.0/ngx_rtmp_module.so
curl -fLO https://github.com/fa1seut0pia/nginx-dynamic-modules/releases/download/release-1.30.0/ngx_http_vhost_traffic_status_module.so
curl -fLO https://github.com/fa1seut0pia/nginx-dynamic-modules/releases/download/release-1.30.0/ngx_http_ip2region_module.so
```

## 本地导出

要求：

- `docker buildx`
- `jq`

导出 3 个模块：

```bash
make export-all NGINX_VERSION=1.29.6
```

只导出单个模块：

```bash
make export-one MODULE_NAME=rtmp NGINX_VERSION=1.29.6
```

产物默认在 `dist/<nginx_version>/<module_name>/`，例如：

```text
dist/1.29.6/rtmp/ngx_rtmp_module.so-1.29.6
dist/1.29.6/vts/ngx_http_vhost_traffic_status_module.so-1.29.6
dist/1.29.6/ip2region/ngx_http_ip2region_module.so-1.29.6
```
