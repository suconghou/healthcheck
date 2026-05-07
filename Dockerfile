FROM nimlang/nim:2.2.10 AS build
RUN apt update && apt install libssl-dev -y
COPY src/ /
WORKDIR /
RUN nim --mm:orc --threads:off -d:release -d:nimDisableCertificateValidation -d:useOpenSsl3 --passL:"-ffunction-sections -fdata-sections" --passL:"-Wl,--gc-sections" --dynlibOverrideAll --passL:-s --passL:-static --passL:-lssl --passL:-lcrypto -d:ssl --opt:size c main && \
    strip -s main && cp -f main /check

FROM alpine
COPY --from=build /check /usr/local/bin/
