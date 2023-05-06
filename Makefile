build:
	cd src && \
	nim c main.nim

release:
	cd src && \
	nim c -d:release main.nim

docker:
	docker build -t=check .

