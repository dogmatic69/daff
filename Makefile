
# This is not so much a Makefile as a collection of scripts.
# If you are just interested in Javascript only the js
# and test targets are important.

default: test

js:
	@echo "#######################################################"
	@echo "## Set up directories"
	mkdir -p bin
	mkdir -p lib
	@echo "#######################################################"
	@echo "## Generate javascript"
	haxe language/js.hxml # produces lib/daff.js
	@echo "#######################################################"
	@echo "## Make library version"
	cat env/js/fix_exports.js >> lib/daff.js
	cat env/js/table_view.js >> lib/daff.js
	cat env/js/util.js >> lib/daff.js
	@echo "#######################################################"
	@echo "## Make executable version (just add shebang)"
	echo "#!/usr/bin/env node" > bin/daff.js
	cat lib/daff.js >> bin/daff.js
	chmod u+x bin/daff.js
	@echo "#######################################################"
	@echo "## Check size"
	@wc bin/daff.js

test: js
	./scripts/run_tests.sh

min: js
	uglifyjs lib/daff.js > lib/daff.min.js
	gzip -k -f lib/daff.min.js
	@wc lib/daff.js
	@wc lib/daff.min.js
	@wc lib/daff.min.js.gz

cpp:
	haxe language/cpp.hxml

version:
	grep "\"version\"" package.json | grep -E -o "[.0-9]+" > version.txt
	cat coopy/Coopy.hx | sed "s/VERSION = .*;/VERSION = \"`cat version.txt`\";/" > coopy/Coopy.hx.next
	cmp coopy/Coopy.hx.next coopy/Coopy.hx || cp coopy/Coopy.hx.next coopy/Coopy.hx
	rm -f coopy/Coopy.hx.next version.txt
	@grep "\"version\"" package.json
	@grep "var VERSION" coopy/Coopy.hx

tag:
	# yes I know about npm-version
	@make version
	@make test
	@grep "\"version\"" package.json | grep -E -o "[.0-9]+" | tee version.txt
	@echo "git commit -m \"`cat version.txt`\" -a"
	@echo "git tag -a \"v`cat version.txt`\" -m \"`cat version.txt`\""
	read x
	git commit -m "`cat version.txt`" -a && git tag -a "v`cat version.txt`" -m "`cat version.txt`"

doc:
	haxe -xml doc.xml language/js.hxml
	haxedoc doc.xml -f coopy

cpp_package:
	haxe language/cpp_for_package.hxml

php:
	haxe language/php.hxml
	cp scripts/PhpTableView.class.php php_bin/lib/coopy/
	cp scripts/example.php php_bin/
	@echo 'Output in php_bin, run "php php_bin/index.php" for an example utility'
	@echo 'or try "php php_bin/example.php" for an example of using daff as a library'


java:
	haxe language/java.hxml
	cp scripts/JavaTableView.java java_bin/src/coopy
	cp scripts/Example.java java_bin
	echo "src/coopy/JavaTableView.java" >> java_bin/cmd
	cd java_bin && javac -sourcepath src -d obj -g:none "@cmd"
	cd java_bin && rm *.jar
	cd java_bin/obj && jar cvfm ../daff.jar ../manifest .
	cd java_bin && javac -cp daff.jar Example.java
	@echo 'Output in java_bin, run "java -jar java_bin/daff.jar" for help'
	@echo 'Run example with "java -cp java_bin/daff.jar:java_bin Example"'

cs:
	haxe language/cs.hxml
	@echo 'Output in cs_bin, do something like "gmcs -recurse:*.cs -main:coopy.Coopy -out:coopyhx.exe" in that directory'

py:
	mkdir -p python_bin lib
	haxe language/py.hxml
	haxe language/py_util.hxml
	cp scripts/python_table_view.py python_bin/
	cat python_bin/coopyhx.py scripts/python_table_view.py > lib/daff.py
	cp scripts/example.py python_bin/
	@echo 'Output in python_bin, run "python3 python_bin/daff.py" for an example utility'
	@echo 'or try "python3 python_bin/example.py" for an example of using daff as a library'

rb:
	haxe language/rb.hxml || { echo "Ruby failed, do you have paulfitz/haxe?"; exit 1; }
	grep -v "Coopy.main" < ruby_bin/index.rb > ruby_bin/daff.rb
	echo "Daff = Coopy" >> ruby_bin/daff.rb
	echo 'if __FILE__ == $$0' >> ruby_bin/daff.rb
	echo "\tCoopy::Coopy.main" >> ruby_bin/daff.rb
	echo "end" >> ruby_bin/daff.rb
	rm -f ruby_bin/index.rb
	chmod u+x ruby_bin/daff.rb
	cp scripts/ruby_table_view.rb ruby_bin/
	cp scripts/example.rb ruby_bin/
	chmod u+x ruby_bin/example.rb

release: js test php py rb java
	echo "========================================================"
	echo "=== Setup"
	rm -rf release
	mkdir -p release
	echo "========================================================"
	echo "=== Javascript"
	cp bin/daff.js release
	echo "========================================================"
	echo "=== PHP"
	rm -rf daff_php
	mv php_bin daff_php
	rm -f daff_php.zip
	zip -r daff_php daff_php
	mv daff_php.zip release
	echo "========================================================"
	echo "=== Python"
	rm -rf daff_py
	mv python_bin daff_py
	rm -f daff_py.zip
	zip -r daff_py daff_py
	mv daff_py.zip release
	echo "========================================================"
	echo "=== Ruby"
	rm -rf daff_rb
	mv ruby_bin daff_rb
	rm -f daff_rb.zip
	zip -r daff_rb daff_rb
	mv daff_rb.zip release
	echo "========================================================"
	echo "=== Java"
	rm -rf daff_java
	mv java_bin daff_java
	rm -rf daff_java/obj
	rm -rf daff_java/hxjava_build.txt
	rm -rf daff_java/cmd
	rm -rf daff_java/manifest
	rm -f daff_java.zip
	zip -r daff_java daff_java
	mv daff_java.zip release
	echo "========================================================"
	echo "=== C++"
	rm -f /tmp/coopyhx_cpp/build/daff_cpp.zip
	rm -rf /tmp/coopyhx_cpp
	./packaging/cpp_recipe/build_cpp_package.sh /tmp/coopyhx_cpp
	cp /tmp/coopyhx_cpp/build/coopyhx_cpp.zip release/daff_cpp.zip

clean:
	rm -rf bin cpp_pack daff_php daff_py daff_rb release py_bin php_bin ruby_bin coopy.js coopy_node.js daff.js daff_java daff_util.js MANIFEST Gemfile

##############################################################################
##############################################################################
## 
## This is a stub where I'll be adding cross-target tests
##

ntest: ntest_js ntest_py ntest_php

ntest_js:
	haxe -js ntest.js -main harness.Main
	NODE_PATH=$$PWD/lib node ntest.js

ntest_py:
	haxe -python ntest.py -main harness.Main
	PYTHONPATH=$$PWD/lib python3 ntest.py 

ntest_php:
	haxe -php ntest_php_dir -main harness.Main
	cp scripts/PhpTableView.class.php ntest_php_dir/lib/coopy/
	time php5 ntest_php_dir/index.php
	#php5 -d xdebug.profiler_enable=1 -d xdebug.profiler_output_dir=/tmp ntest_php_dir/index.php

# Not ready for this yet
#ntest_rb:
#	haxe -rb ntestdotrb -main harness.Main
#	RUBYLIB=$$PWD/ruby_bin ruby ntestdotrb/index.rb 

##############################################################################
##############################################################################
## 
## PYTHON PACKAGING
##

setup_py: py
	echo "#!/usr/bin/env python" > daff.py
	cat python_bin/daff.py | sed "s|.*Coopy.main.*||" >> daff.py
	cat python_bin/python_table_view.py | sed "s|import coopyhx as daff||" | sed "s|daff[.]||g" >> daff.py
	echo "if __name__ == '__main__':" >> daff.py
	echo "\tCoopy.main()" >> daff.py
	mkdir -p daff
	cp daff.py daff/__init__.py

sdist: setup_py
	rm -rf dist
	mv page /tmp/sdist_does_not_like_page
	python3 setup.py sdist
	cd dist && mkdir tmp && cd tmp && tar xzvf ../daff*.tar.gz && cd daff-*[0-9] && ./setup.py build
	python3 setup.py sdist upload
	rm -rf dist/tmp
	mv /tmp/sdist_does_not_like_page page


##############################################################################
##############################################################################
## 
## RUBY PACKAGING
##

rdist:
	make rb
	rm -rf lib bin
	mkdir -p lib
	cp ruby_bin/daff.rb lib
	cp -R ruby_bin/lib lib
	mkdir -p bin
	echo "#!/usr/bin/env ruby" > bin/daff.rb
	echo "require 'daff'" >> bin/daff.rb
	echo "Daff::Coopy.main" >> bin/daff.rb
	rm -f daff-*.gem
	gem build daff.gemspec

##############################################################################
##############################################################################
## 
## RELEASES
##

releases:
	@echo "Hey so you want to make a release?"
	@echo "And you've forgotten how?"
	@echo "Steps:"
	@echo "  make test && make ntest"
	@echo "  # Update version number in package.json"
	@echo "  make tag"
	@echo "  git push && git push --tags"
	@echo "  # move to a fresh checkout"
	@echo "  npm publish  # node"
	@echo "  make sdist   # pip"
	@echo "  make rdist   # gem"
	@echo "  gem push daff-.....gem"
	@echo "  make php"
	@echo "  # now, checkout daff-php at same level as daff"
	@echo "  # now, in daff-php"
	@echo "  ./fetch.sh"
	@echo "  git push && git push --tags"
