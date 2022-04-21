build:
	cd src && \
	nim c main.nim

release:
	cd src && \
	nim c -d:release main.nim

ssl:
	cd src && \
	nim --gc:regions -d:release -d:ssl -d:nimDisableCertificateValidation --opt:size c main.nim

