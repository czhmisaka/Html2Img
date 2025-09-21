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

# 检查参数是否提供
check_required() {
    if [ -z "$1" ]; then
        log_error "缺少必要参数: $2"
        exit 1
    fi
}

build() {
    # 检查必要参数
    check_required "$1" "镜像名称"
    check_required "$2" "构建路径"
    
    local image_name="$1"
    local build_path="$2"
    local base_image="swr.ap-southeast-1.myhuaweicloud.com/renniliu/html2img:1.0.1"
    
    log_info "开始构建容器: $image_name"
    
    # 检查构建路径是否存在
    if [ ! -d "$build_path" ]; then
        log_error "构建路径不存在: $build_path"
        exit 1
    fi
    
    # 拉取基础镜像
    log_info "正在拉取基础镜像: $base_image"
    docker pull "$base_image"
    check_status "拉取镜像"
    
    # 删除同名容器（如果存在）
    if docker ps -a --format '{{.Names}}' | grep -q "^$image_name$"; then
        log_warn "发现同名容器，准备删除: $image_name"
        docker stop "$image_name" >/dev/null 2>&1
        docker rm "$image_name" >/dev/null 2>&1
        check_status "删除容器"
    fi
    
    # 运行容器
    log_info "正在创建并运行容器: $image_name"
    docker run -d \
    -p 15600:15600 \
    -e TZ=Asia/Shanghai \
    --memory 512m \
    --memory-swap 1g \
    --name "$image_name" \
    "$image_name"
    check_status "创建容器"
    
    log_info "容器 $image_name 已成功运行在端口 15600"
}

delete() {
    # 解析参数和选项
    local target=""
    local force=0
    
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
    check_required "$target" "容器/镜像名称或ID"
    
    log_info "开始删除操作: $target"
    
    # 智能识别输入类型（容器ID/名称/镜像名）
    local container_id=""
    local is_image=0
    
    # 先尝试按容器ID匹配
    if docker ps -a --format "{{.ID}}" | grep -q "^$target$"; then
        container_id="$target"  # 完整ID匹配
    elif docker ps -a --format "{{.ID}}" | grep -q "^${target:0:12}"; then
        container_id=$(docker ps -a --format "{{.ID}}" | grep "^${target:0:12}" | head -n1)  # 短ID匹配
    else
        # 尝试按容器名称匹配
        container_id=$(docker ps -a --format "{{.ID}} {{.Names}}" | grep -w "^.* $target$" | awk '{print $1}' | head -n1)
        
        # 若未找到容器，检查是否为镜像名
        if [ -z "$container_id" ] && docker images -q "$target" | grep -q .; then
            is_image=1
        fi
    fi
    
    if [ $is_image -eq 1 ]; then
        # 按镜像名删除
        log_info "按镜像名 $target 查找相关容器"
        local containers=$(docker ps -a --filter "ancestor=$target" --format "{{.ID}}")
        
        if [ -z "$containers" ]; then
            log_warn "未找到使用该镜像的容器"
        else
            for container_id in $containers; do
                # 停止并删除容器
                if docker ps -q --filter "id=$container_id" | grep -q .; then
                    docker stop "$container_id" >/dev/null 2>&1
                fi
                docker rm "$container_id" >/dev/null 2>&1
                log_info "删除容器 $container_id"
            done
        fi
        
        # 删除镜像
        if docker images -q "$target" | grep -q .; then
            if [ $force -eq 1 ]; then
                docker image rm -f "$target" >/dev/null 2>&1
            else
                docker image rm "$target" >/dev/null 2>&1
            fi
            log_info "删除镜像 $target"
        else
            log_warn "镜像 $target 不存在"
        fi
        return 0
    fi
    
    # 按容器删除
    if [ -z "$container_id" ]; then
        log_error "未找到容器或镜像: $target"
        exit 1
    fi
    
    # 停止并删除容器
    if docker ps -q --filter "id=$container_id" | grep -q .; then
        if [ $force -eq 1 ]; then
            docker rm -f "$container_id" >/dev/null 2>&1
            log_info "强制删除容器 $container_id"
        else
            docker stop "$container_id" >/dev/null 2>&1
            log_info "停止容器 $container_id"
            docker rm "$container_id" >/dev/null 2>&1
            log_info "删除容器 $container_id"
        fi
    else
        docker rm "$container_id" >/dev/null 2>&1
        log_info "删除容器 $container_id"
    fi
    
    # 删除容器对应的镜像（如果没有其他容器使用该镜像）
    local image_id=$(docker inspect -f "{{.Config.Image}}" "$container_id" 2>/dev/null || docker ps -a --filter "id=$container_id" --format "{{.Image}}" | head -n1)
    
    if [ -n "$image_id" ]; then
        # 检查是否有其他容器使用该镜像
        local dependent_containers=$(docker ps -a --filter "ancestor=$image_id" --format "{{.ID}}" | grep -v "^$container_id$")
        
        if [ -z "$dependent_containers" ]; then
            # 没有其他容器使用该镜像，删除它
            if docker images -q "$image_id" | grep -q .; then
                if [ $force -eq 1 ]; then
                    docker image rm -f "$image_id" >/dev/null 2>&1
                else
                    docker image rm "$image_id" >/dev/null 2>&1
                fi
                log_info "删除镜像 $image_id"
            fi
        else
            log_info "镜像 $image_id 仍被其他容器使用，保留"
        fi
    fi
}

# 显示帮助信息
show_help() {
    echo "Docker容器管理脚本"
    echo "用法: $0 {build|delete|help} [参数]"
    echo ""
    echo "命令:"
    echo "  build <image_name> <build_path>          构建并运行容器"
    echo "  delete [--force] <target>                删除容器或镜像（自动识别）"
    echo "  help                                     显示此帮助信息"
    echo ""
    echo "选项:"
    echo "  --force, -f       强制删除（直接删除运行中容器/镜像）"
    echo ""
    echo "示例:"
    echo "  $0 build my-app ./app"
    echo "  $0 delete my-container                  # 按容器名删除"
    echo "  $0 delete 1234567890ab                  # 按容器ID删除"
    echo "  $0 delete my-image:tag                  # 按镜像名删除"
    echo "  $0 delete -f container-id               # 强制删除容器"
}

# 主程序
check_docker

case "$1" in
    build)
        if [ $# -ne 3 ]; then
            log_error "build命令需要2个参数: <image_name> <build_path>"
            show_help
            exit 1
        fi
        build "$2" "$3"
        ;;
    delete)
        if [ $# -lt 2 ]; then
            log_error "delete命令需要1个参数: <target>（可加--force选项）"
            show_help
            exit 1
        fi
        delete "$2" "$3"
        ;;
    help|*)
        show_help
        ;;
esac