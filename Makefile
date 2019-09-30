ECHO := echo

all: verify-config verify-image-tags

.PHONY: config
config:
	@ $(ECHO) "\033[36mGenerating Config\033[0m"
	kubectl create configmap config --from-file=config.yaml=config/config.yaml -n default --dry-run -o yaml > prow/config.yaml
	kubectl create configmap plugins --from-file=plugins.yaml=config/plugins.yaml -n default --dry-run -o yaml > prow/plugins.yaml
	scripts/make-jobs-config.sh > prow/jobs.yaml
	for f in config plugins jobs; do printf '#############\n###\n### THIS IS AN AUTOGENERATED FILE!!! DO NOT EDIT THIS FILE DIRECTLY!!!\n###\n#############\n\n%s\n' "$$(cat prow/$${f}.yaml)" > prow/$${f}.yaml; done
	@ echo # Produce a new line at the end of each target to help readability

.PHONY: verify-config
verify-config: $(GOPATH)/bin/checkconfig
	@ $(ECHO) "\033[36mVerifying Config\033[0m"
	${GOPATH}/bin/checkconfig --config-path=config/config.yaml --job-config-path=config/jobs --plugin-config=config/plugins.yaml
	@ echo # Spacer between output
	make config
	@ $(ECHO) "\033[36mVerifying Git Status\033[0m"
	@ if [ "$$(git status -s)" != "" ]; then git diff --color; echo "\033[31;1mERROR: Git Diff found. Please run \`make config\` and commit the result.\033[0m"; exit 1; else echo "\033[32mValid config found\033[0m";fi
	@ echo # Produce a new line at the end of each target to help readability

$(GOPATH)/bin/checkconfig:
	@ $(ECHO) "\033[36mInstalling checkconfig\033[0m"
	mkdir -p $$GOPATH/src/k8s.io
	# Clone the test-infra source so that we can use the proper go.mod
	cd $$GOPATH/src/k8s.io; git clone https://github.com/kubernetes/test-infra
	cd $$GOPATH/src/k8s.io/test-infra; GOPROXY=https://proxy.golang.org GOSUMDB=sum.golang.org GO111MODULE=on go install k8s.io/test-infra/prow/cmd/checkconfig
	@ echo # Produce a new line at the end of each target to help readability

.PHONY:
check-image-tags:
	@ $(ECHO) "\033[36m\033[1mChecking image tags\033[0m"
	scripts/check-image-tags.sh
	@ echo # Produce a new line at the end of each target to help readability

TAG ?= v20190821-328974b
.PHONY:
update-image-tags:
	@ $(ECHO) "\033[36m\033[1mUpdating image tags\033[0m"
	scripts/update-image-tags.sh $(TAG)
	@ echo # Produce a new line at the end of each target to help readability


.PHONY:
verify-image-tags: update-image-tags check-image-tags
	@ $(ECHO) "\033[36m\033[1mVerifying Git Status\033[0m"
	@ if [ "$$(git status -s)" != "" ]; then git diff --color; echo "\033[31m\033[1mERROR: Git Diff found. Please run \`make update-image-tags\` and commit the result.\033[0m"; exit 1; else echo "\033[32mAll image tags verified\033[0m";fi
	@ echo # Produce a new line at the end of each target to help readability
