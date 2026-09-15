# Dois ambientes, um repositório: kind para o dia a dia, EKS para a nuvem.
SHELL := /bin/bash
REGIAO ?= us-east-1
CLUSTER ?= oficina-eks

.PHONY: ajuda local-up local-down cloud-up cloud-down kubeconfig nlb teardown

ajuda:
	@grep -E '^[a-z-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

local-up: ## Sobe o cluster kind com Postgres, metrics-server e (opcional) New Relic
	terraform -chdir=kind init -input=false
	terraform -chdir=kind apply -input=false

local-down: ## Destrói o cluster kind
	terraform -chdir=kind destroy -input=false

cloud-up: ## Provisiona o EKS, o ingress e o agente do New Relic
	terraform -chdir=terraform apply -input=false

cloud-down: ## Destrói o EKS inteiro (inclusive o NLB)
	terraform -chdir=terraform destroy -input=false

kubeconfig: ## Registra o cluster EKS no kubeconfig local
	aws eks update-kubeconfig --region $(REGIAO) --name $(CLUSTER)

nlb: ## Mostra a URL do NLB para alimentar backend_base_url em oficina-auth-lambda
	@kubectl -n ingress-nginx get svc ingress-nginx-controller \
		-o jsonpath='{.status.loadBalancer.ingress[0].hostname}'; echo

# O AWS Academy Learner Lab encerra as instâncias EC2 ao fim da sessão, mas NÃO
# o Network Load Balancer, que segue cobrando. Rode isto ao encerrar o dia:
# derruba o ingress (e com ele o NLB) e depois o cluster.
teardown: ## Rotina de fim de sessão: remove o NLB e destrói o cluster
	-helm uninstall ingress-nginx -n ingress-nginx
	@echo "Aguardando a AWS liberar o NLB..."
	@sleep 45
	$(MAKE) cloud-down
