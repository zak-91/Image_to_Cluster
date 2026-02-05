# Variables
PACKER_VERSION=1.11.2
IMAGE_NAME=nginx-custom
IMAGE_TAG=1.0
CLUSTER_NAME=lab
 
.PHONY: all install build-image deploy status clean
 
all: install build-image deploy status
 
## --- Section Installation ---
 
install:
	@echo "--- Nettoyage des dépôts apt corrompus (Yarn) ---"
	-sudo bash -lc 'for f in /etc/apt/sources.list.d/*.list; do \
		if grep -q "dl.yarnpkg.com" "$$f"; then \
			sudo mv "$$f" "$$f.disabled"; \
			echo "Disabled: $$f"; \
		fi; \
	done'
	@echo "--- Installation des dépendances ---"
	sudo apt-get update
	sudo apt-get install -y ansible unzip curl
	# Installation de Packer
	curl -fsSL "https://releases.hashicorp.com/packer/$(PACKER_VERSION)/packer_$(PACKER_VERSION)_linux_amd64.zip" -o /tmp/packer.zip
	sudo unzip -o /tmp/packer.zip -d /usr/local/bin
	# Installation de k3d
	curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=v5.6.0 bash
	# Installation de kubectl
	sudo curl -L "https://dl.k8s.io/release/$$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl
	sudo chmod +x /usr/local/bin/kubectl
	@packer version
	@k3d --version
 
## --- Section Packer ---
 
build-image:
	@echo "--- Build de l'image avec Packer ---"
	cd packer && packer init .
	sed -i 's/tag *= *"1.0"/tag = ["$(IMAGE_TAG)"]/g' packer/nginx.pkr.hcl
	cd packer && packer build .
	docker images | grep $(IMAGE_NAME)
 
## --- Section Cluster & Déploiement ---
 
deploy:
	@echo "--- Configuration du Cluster & Import ---"
	# Crée le cluster seulement s'il n'existe pas
	k3d cluster get $(CLUSTER_NAME) >/dev/null 2>&1 || k3d cluster create $(CLUSTER_NAME)
	# Import de l'image dans le runtime k3s
	k3d image import $(IMAGE_NAME):$(IMAGE_TAG) -c $(CLUSTER_NAME)
	# Déploiement Ansible
	ansible-playbook ansible/deploy.yml
	@echo "Lancement du port-forward (8081 -> 80)..."
	kubectl port-forward svc/$(IMAGE_NAME) 8081:80 >/tmp/app.log 2>&1 &
 
status:
	@echo "--- Vérification finale ---"
	kubectl get nodes
	kubectl get pods
	@echo "L'application devrait être accessible sur http://localhost:8081"