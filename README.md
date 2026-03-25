# nginx-dynamic-modules

统一构建并发布 3 个 Nginx 动态模块：

- `ngx_rtmp_module.so`
- `ngx_http_vhost_traffic_status_module.so`
- `ngx_http_ip2region_module.so`

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

## GitHub Actions

工作流文件：`.github/workflows/release-modules.yml`

行为：

- 每小时轮询一次 `nginx/nginx` 的最新 Release
- 也支持手动触发并指定 `nginx_version`
- 如果当前仓库还没有对应的 `nginx-<version>` Release，则构建 3 个模块
- 构建完成后创建当前仓库的 GitHub Release，并上传 3 个 `.so` 产物

说明：

- GitHub Actions 不能直接原生订阅别的仓库的 `release` 事件，所以这里采用“定时轮询 + 去重发布”的方式实现“监听 nginx 发布后触发”
- 模块源码来源在 `modules.json`，后续如果要固定 commit/tag，只需要填写对应模块的 `ref`
