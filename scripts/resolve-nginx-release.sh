#!/usr/bin/env bash

set -euo pipefail

readonly GITHUB_RELEASES_API="https://api.github.com/repos/nginx/nginx/releases?per_page=10"

usage() {
    cat >&2 <<'EOF'
Usage:
  resolve-nginx-release.sh latest-docker-published
  resolve-nginx-release.sh require-docker-tag <version-or-release-tag>
EOF
    exit 1
}

normalize_release_tag() {
    local value="${1:-}"
    value="$(echo "${value}" | tr -d '[:space:]')"
    if [[ -z "${value}" || "${value}" == "null" ]]; then
        echo ""
        return 0
    fi
    if [[ "${value}" != release-* ]]; then
        value="release-${value}"
    fi
    echo "${value}"
}

normalize_docker_tag() {
    local release_tag
    release_tag="$(normalize_release_tag "${1:-}")"
    echo "${release_tag#release-}"
}

github_auth_headers=()
if [[ -n "${GH_TOKEN:-}" ]]; then
    github_auth_headers+=(-H "Authorization: Bearer ${GH_TOKEN}")
fi

docker_tag_exists() {
    local docker_tag="${1:?docker tag is required}"
    docker manifest inspect "nginx:${docker_tag}" >/dev/null 2>&1
}

latest_docker_published_release() {
    local candidate
    while IFS= read -r candidate; do
        [[ -n "${candidate}" ]] || continue
        if docker_tag_exists "${candidate#release-}"; then
            echo "${candidate}"
            return 0
        fi
    done < <(
        curl -fsSL "${github_auth_headers[@]}" \
            -H "Accept: application/vnd.github+json" \
            "${GITHUB_RELEASES_API}" \
        | jq -r '
            [
                .[]
                | select(.draft == false and .prerelease == false)
                | .tag_name
                | select(startswith("release-"))
            ]
            | sort_by(sub("^release-"; "") | split(".") | map(tonumber))
            | reverse
            | .[]
        '
    )

    echo "failed to resolve a docker-published nginx release" >&2
    exit 1
}

cmd="${1:-}"
case "${cmd}" in
    latest-docker-published)
        shift
        [[ $# -eq 0 ]] || usage
        latest_docker_published_release
        ;;
    require-docker-tag)
        shift
        [[ $# -eq 1 ]] || usage
        docker_tag="$(normalize_docker_tag "$1")"
        if [[ -z "${docker_tag}" ]]; then
            echo "nginx version is required" >&2
            exit 1
        fi
        if docker_tag_exists "${docker_tag}"; then
            echo "release-${docker_tag}"
        else
            echo "docker tag nginx:${docker_tag} is not published yet" >&2
            exit 1
        fi
        ;;
    *)
        usage
        ;;
esac
