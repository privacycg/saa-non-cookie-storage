.PHONY: all publish clean
.SUFFIXES: .bs .html

all: publish

publish: build/index.html

clean:
	rm -rf build

build/index.html: spec.bs Makefile
	mkdir -p build
	bikeshed --die-on=warning spec $< $@
