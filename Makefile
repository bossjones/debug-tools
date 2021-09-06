copy:
	find . -maxdepth 1 -type f -perm /a+x -exec cp -va {} /usr/local/bin/ \;

ls:
	find . -maxdepth 1 -type f -perm /a+x -exec ls {} \;

config:
	cp -a /usr/local/src/debug-tools/install-config-sample /usr/local/bin/install-config
