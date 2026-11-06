.PHONY: all build test dmg clean

all: test build

build:
	swift build -c release

test:
	swift run MacStashTestRunner

dmg:
	./Scripts/build_dmg.sh

clean:
	swift package clean
	rm -rf dist .build/package_staging .build/dmg_source
