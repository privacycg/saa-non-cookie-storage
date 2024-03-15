.PHONY: all publish clean
.SUFFIXES: .bs .html

all: publish

publish: _site/index.html

clean:
	rm -rf build *~

_site/index.html: spec.bs Makefile
	mkdir -p _site
	bikeshed --die-on=warning spec
