# Use latest stable channel SDK.
FROM dart:stable AS build

# 使用国内 pub 镜像，解决 Docker 构建环境无法访问 pub.dev 的问题
ENV PUB_HOSTED_URL=https://pub.flutter-io.cn
ENV FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# Resolve app dependencies.
# 需先复制本地 path 依赖包的 pubspec，否则 dart pub get 会因找不到包而失败
WORKDIR /app
COPY pubspec.* ./
COPY packages/kpi_scorer/pubspec.yaml packages/kpi_scorer/pubspec.yaml
COPY packages/rent_escalation_engine/pubspec.yaml packages/rent_escalation_engine/pubspec.yaml
RUN dart pub get

# Copy app source code (except anything in .dockerignore) and AOT compile app.
COPY . .
RUN dart build cli --target bin/server.dart -o output

# Build minimal serving image from AOT-compiled `/server`
# and the pre-built AOT-runtime in the `/runtime/` directory of the base image.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/output/bundle/ /app/

# Start server.
EXPOSE 8080
CMD ["/app/bin/server"]
