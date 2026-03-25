#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULES_FILE="${ROOT_DIR}/modules.json"
NGINX_VERSION="${1:-1.29.6}"
OUTPUT_DIR="${2:-${ROOT_DIR}/dist/${NGINX_VERSION}}"
MODULE_FILTER="${MODULE_NAME:-}"

if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required" >&2
    exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
    echo "docker is required" >&2
    exit 1
fi

mkdir -p "${OUTPUT_DIR}"

jq_filter='.[]'
if [[ -n "${MODULE_FILTER}" ]]; then
    jq_filter=".[] | select(.name == \"${MODULE_FILTER}\")"
fi

matched=0

while IFS= read -r module; do
    matched=1
    name="$(jq -r '.name' <<<"${module}")"
    repo="$(jq -r '.repo' <<<"${module}")"
    ref="$(jq -r '.ref // empty' <<<"${module}")"
    target_dir="${OUTPUT_DIR}/${name}"

    rm -rf "${target_dir}"
    mkdir -p "${target_dir}"

    build_args=(
        --build-arg "NGINX_VERSION=${NGINX_VERSION}"
        --build-arg "MODULE_NAME=${name}"
        --build-arg "MODULE_REPO=${repo}"
    )

    if [[ -n "${ref}" ]]; then
        build_args+=(--build-arg "MODULE_REF=${ref}")
    fi

    docker buildx build \
        --file "${ROOT_DIR}/Dockerfile" \
        --target export_so \
        --output "type=local,dest=${target_dir}" \
        "${build_args[@]}" \
        "${ROOT_DIR}"

    so_name="$(<"${target_dir}/module.so.name")"
    test -s "${target_dir}/${so_name}"
done < <(jq -c "${jq_filter}" "${MODULES_FILE}")

if [[ "${matched}" -eq 0 ]]; then
    echo "module not found: ${MODULE_FILTER}" >&2
    exit 1
fi
