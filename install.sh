#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查Docker是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        exit 1
    fi
}

# 检查命令执行状态
check_status() {
    if [ $? -ne 0 ]; then
        log_error "$1 失败"
        exit 1
    else
        log_info "$1 成功"
    fi
}

# 检查端口是否被占用（避免启动冲突）
check_port() {
    local port=$1
    if lsof -i:"$port" >/dev/null 2>&1; then
        log_error "端口 $port 已被占用，请释放后重试"
        exit 1
    fi
}

# 核心功能：拉取固定镜像（swr.ap-southeast-1.myhuaweicloud.com/renniliu/html2img:1.0.1）并运行容器
build() {
    # 固定目标镜像（无需用户传入，避免参数错误）
    local target_image="swr.ap-southeast-1.myhuaweicloud.com/renniliu/html2img:1.0.1"
    # 固定容器名（与镜像名关联，便于识别和管理）
    local container_name="html2img"
    # 固定端口（与原逻辑一致，如需修改可在此处调整）
    local port=15600

    log_info "=== 开始拉取镜像并运行容器 ==="
    log_info "目标镜像: $target_image"
    log_info "容器名称: $container_name"
    log_info "映射端口: $port:$port"

    # 1. 拉取固定镜像
    log_info "正在拉取镜像..."
    docker pull "$target_image"
    check_status "镜像拉取"

    # 2. 删除同名旧容器（若存在，避免冲突）
    if docker ps -a --format '{{.Names}}' | grep -q "^$container_name$"; then
        log_warn "发现同名容器 $container_name，正在删除..."
        docker stop "$container_name" >/dev/null 2>&1
        docker rm "$container_name" >/dev/null 2>&1
        check_status "旧容器删除"
    fi

    # 3. 检查端口是否可用
    log_info "检查端口 $port 是否可用..."
    check_port "$port"

    # 4. 启动新容器（使用拉取的固定镜像）
    log_info "正在启动新容器..."
    docker run -d \
      -p "$port:$port" \
      -e TZ=Asia/Shanghai \
      --memory 512m \
      --memory-swap 1g \
      --name "$container_name" \
      "$target_image"
    check_status "容器启动"

    # 5. 验证容器状态（可选增强：确保容器真的在运行）
    if docker ps --format '{{.Names}}' | grep -q "^$container_name$"; then
        log_info "=== 操作完成 ==="
        log_info "容器 $container_name 已成功运行"
        log_info "镜像: $target_image"
        log_info "访问端口: http://localhost:$port"
    else
        log_error "容器启动后未检测到运行状态，请检查Docker日志：docker logs $container_name"
        exit 1
    fi
}

# 删除功能（保持原有智能识别逻辑，支持删除容器/镜像）
delete() {
    local target=""
    local force=0

    # 解析参数（--force/-f 强制删除）
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--force)
                force=1
                shift
                ;;
            *)
                target="$1"
                shift
                ;;
        esac
    done

    # 检查必要参数
    if [ -z "$target" ]; then
        log_error "缺少必要参数：容器/镜像名称或ID"
        show_help
        exit 1
    fi

    log_info "=== 开始删除操作 ==="
    log_info "目标: $target"

    # 智能识别：先检查是否为容器，再检查是否为镜像
    local container_id=""
    local is_image=0

    # 匹配容器（完整ID/短ID/名称）
    if docker ps -a --format "{{.ID}}" | grep -q "^$target$"; then
        container_id="$target"
    elif docker ps -a --format "{{.ID}}" | grep -q "^${target:0:12}"; then
        container_id=$(docker ps -a --format "{{.ID}}" | grep "^${target:0:12}" | head -n1)
    else
        container_id=$(docker ps -a --format "{{.ID}} {{.Names}}" | grep -w "^.* $target$" | awk '{print $1}' | head -n1)
        # 若容器不存在，检查是否为镜像
        if [ -z "$container_id" ] && docker images -q "$target" | grep -q .; then
            is_image=1
        fi
    fi

    # 场景1：删除镜像（及依赖它的容器）
    if [ $is_image -eq 1 ]; then
        log_info "识别为镜像，正在删除依赖容器..."
        local dependent_containers=$(docker ps -a --filter "ancestor=$target" --format "{{.ID}}")
        if [ -n "$dependent_containers" ]; then
            for cid in $dependent_containers; do
                docker stop "$cid" >/dev/null 2>&1
                docker rm "$cid" >/dev/null 2>&1
                log_info "已删除依赖容器: $cid"
            done
        else
            log_warn "未找到依赖该镜像的容器"
        fi

        # 删除镜像（支持强制删除）
        log_info "正在删除镜像 $target..."
        if [ $force -eq 1 ]; then
            docker image rm -f "$target" >/dev/null 2>&1
        else
            docker image rm "$target" >/dev/null 2>&1
        fi
        check_status "镜像删除"
        return 0
    fi

    # 场景2：删除容器（及无依赖的镜像）
    if [ -z "$container_id" ]; then
        log_error "未找到容器或镜像：$target"
        exit 1
    fi

    # 删除容器（运行中容器需先停止，或强制删除）
    log_info "识别为容器，ID: $container_id"
    if docker ps -q --filter "id=$container_id" | grep -q .; then
        if [ $force -eq 1 ]; then
            docker rm -f "$container_id" >/dev/null 2>&1
            log_info "已强制删除运行中容器"
        else
            docker stop "$container_id" >/dev/null 2>&1
            check_status "容器停止"
            docker rm "$container_id" >/dev/null 2>&1
            log_info "已删除停止的容器"
        fi
    else
        docker rm "$container_id" >/dev/null 2>&1
        log_info "已删除已停止的容器"
    fi
    check_status "容器删除"

    # 可选：删除容器对应的镜像（仅当无其他容器依赖时）
    local image_id=$(docker inspect -f "{{.Config.Image}}" "$container_id" 2>/dev/null)
    if [ -n "$image_id" ]; then
        local dependent_count=$(docker ps -a --filter "ancestor=$image_id" --format "{{.ID}}" | wc -l)
        if [ "$dependent_count" -eq 0 ]; then
            log_info "镜像 $image_id 无其他依赖，正在删除..."
            docker image rm "$image_id" >/dev/null 2>&1
            check_status "关联镜像删除"
        else
            log_warn "镜像 $image_id 仍被其他容器依赖，暂不删除"
        fi
    fi

    log_info "=== 删除操作完成 ==="
}

# 帮助信息（同步更新build命令说明）
show_help() {
    echo "Docker容器管理脚本（专注拉取固定镜像：swr.ap-southeast-1.myhuaweicloud.com/renniliu/html2img:1.0.1）"
    echo "用法: $0 {build|delete|help}"
    echo ""
    echo "命令说明:"
    echo "  build                拉取固定镜像并启动容器（无需额外参数）"
    echo "                       固定配置：镜像=swr.ap-southeast-1.myhuaweicloud.com/renniliu/html2img:1.0.1"
    echo "                                 容器名=html2img"
    echo "                                 端口=15600:15600"
    echo "  delete [--force] <target>  删除容器或镜像（自动识别）"
    echo "                             --force/-f：强制删除（跳过停止容器步骤）"
    echo "  help                 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 build                  # 拉取固定镜像并启动容器"
    echo "  $0 delete html2img  # 删除运行的容器"
    echo "  $0 delete -f swr.ap-southeast-1.myhuaweicloud.com/renniliu/html2img:1.0.1  # 强制删除镜像及依赖容器"
}

# 主程序入口
check_docker

case "$1" in
    build)
        # build命令无需额外参数，若传参则报错
        if [ $# -ne 1 ]; then
            log_error "build命令无需额外参数，正确用法：$0 build"
            show_help
            exit 1
        fi
        build
        ;;
    delete)
        # 传递delete的后续参数（如--force和target）
        delete "${@:2}"
        ;;
    help|*)
        show_help
        ;;
esac