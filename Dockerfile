FROM nimlang/nim:2.0.6-alpine AS build
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && apk add openssl-libs-static
COPY src/ /
RUN nim --mm:arc --threads:off -d:release -d:nimDisableCertificateValidation --passL:"-ffunction-sections -fdata-sections" --passL:"-Wl,--gc-sections" --dynlibOverrideAll --passL:-s --passL:-static --passL:-lssl --passL:-lcrypto -d:ssl --opt:size c main && \
    strip -s main && cp -f main /check

FROM alpine
COPY --from=build /check /usr/local/bin/
