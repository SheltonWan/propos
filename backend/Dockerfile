# =============================================================================
# Multi-stage Dockerfile：Dart AOT 后端 + Python 切分脚本运行时
#
# 设计要点：
#   1. 构建阶段使用 dart:stable（Debian-based）编译 AOT 二进制
#   2. 运行阶段使用 python:3.12-slim（同样 Debian-based，与 dart:stable 的
#      libc/glibc 版本兼容），从而 Dart AOT 二进制可直接运行
#   3. 装入 ezdxf + lxml（pip wheel 含预编译 manylinux 二进制，无需 apt 装
#      libxml2-dev/libxslt-dev 系统库）
#   4. 把 scripts/split_dxf_by_floor.py 复制进 /app/scripts 供 CadImportService
#      通过 Process.run('python3', ['/app/scripts/split_dxf_by_floor.py', ...])
#      调用
#
# 部署目标：腾讯云容器镜像服务，OpenCloudOS 8 + Docker 26.1.3
# =============================================================================

FROM dart:stable AS build

# 国内 pub 镜像，解决 Docker 构建环境无法访问 pub.dev 的问题
ENV PUB_HOSTED_URL=https://pub.flutter-io.cn
ENV FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# 解析依赖：先复制 path 依赖包的 pubspec
# 构建上下文为项目根目录，backend/ 为前缀
WORKDIR /app
COPY backend/pubspec.* ./
COPY backend/packages/kpi_scorer/pubspec.yaml packages/kpi_scorer/pubspec.yaml
COPY backend/packages/rent_escalation_engine/pubspec.yaml packages/rent_escalation_engine/pubspec.yaml
RUN dart pub get

# 复制 backend 源码并 AOT 编译
COPY backend/ .
RUN dart build cli --target bin/server.dart -o output

# =============================================================================
# 运行阶段：基于 python:3.12-slim（替换原 scratch 基础镜像）
# 镜像体积估算 ~205MB（基础 ~130MB + ezdxf/lxml/Pillow ~45MB + DejaVu字体 ~4MB + Dart 运行时 ~25MB）
# =============================================================================
FROM python:3.12-slim

# 升级 base 镜像系统包到最新安全补丁，修复 Debian 基础层的 CVE
# fonts-dejavu-core 是 ezdxf drawing 渲染器的字体依赖（slim 镜像无字体会报 no default font found）
# 必须与 apt-get update 在同一 RUN 中，并清理 apt 缓存以减小镜像体积
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        fonts-dejavu-core \
    && fc-cache -f \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 升级 pip / setuptools / wheel 到最新版（消除 setuptools 等 Python 自带包的 CVE）
RUN pip install --no-cache-dir --upgrade \
    -i https://pypi.tuna.tsinghua.edu.cn/simple \
    pip setuptools wheel

# 安装 DXF → SVG 切分所需的 Python 依赖
# 注：使用清华 PyPI 镜像加速；--no-cache-dir 减小镜像体积
# Pillow 是 ezdxf drawing 插件的隐式依赖（PIL.Image）
RUN pip install --no-cache-dir \
    -i https://pypi.tuna.tsinghua.edu.cn/simple \
    ezdxf lxml Pillow

# Dart AOT 运行时（python:3.12-slim 基于 Debian Bookworm，usrmerge 导致 /lib 是
# /usr/lib 的符号链接；Docker BuildKit COPY 不跟随符号链接目录，直接写入实际目录
# /usr/lib/ 来绕过 "cannot copy to non-directory" 错误）
COPY --from=build /runtime/lib/ /usr/lib/

# Dart 编译产物
COPY --from=build /app/output/bundle/ /app/

# 切分脚本（Python，由 CadImportService 调用）
COPY scripts/split_dxf_by_floor.py /app/scripts/split_dxf_by_floor.py

# 文件存储根目录（与 AppConfig.fileStoragePath 对齐，由 docker run -v 挂载）
RUN mkdir -p /data/uploads
VOLUME ["/data/uploads"]

EXPOSE 8080
CMD ["/app/bin/server"]
