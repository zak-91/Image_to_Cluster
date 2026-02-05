------------------------------------------------------------------------------------------------------
ATELIER FROM IMAGE TO CLUSTER
------------------------------------------------------------------------------------------------------
L’idée en 30 secondes : Cet atelier consiste à **industrialiser le cycle de vie d’une application** simple en construisant une **image applicative Nginx** personnalisée avec **Packer**, puis en déployant automatiquement cette application sur un **cluster Kubernetes** léger (K3d) à l’aide d’**Ansible**, le tout dans un environnement reproductible via **GitHub Codespaces**.
L’objectif est de comprendre comment des outils d’Infrastructure as Code permettent de passer d’un artefact applicatif maîtrisé à un déploiement cohérent et automatisé sur une plateforme d’exécution.
  
-------------------------------------------------------------------------------------------------------
Séquence 1 : Codespace de Github
-------------------------------------------------------------------------------------------------------
Objectif : Création d'un Codespace Github  
Difficulté : Très facile (~5 minutes)
-------------------------------------------------------------------------------------------------------
**Faites un Fork de ce projet**. Si besion, voici une vidéo d'accompagnement pour vous aider dans les "Forks" : [Forker ce projet](https://youtu.be/p33-7XQ29zQ) 
  
Ensuite depuis l'onglet [CODE] de votre nouveau Repository, **ouvrez un Codespace Github**.
  
---------------------------------------------------
Séquence 2 : Création du cluster Kubernetes K3d
---------------------------------------------------
Objectif : Créer votre cluster Kubernetes K3d  
Difficulté : Simple (~5 minutes)
---------------------------------------------------
Vous allez dans cette séquence mettre en place un cluster Kubernetes K3d contenant un master et 2 workers.  
Dans le terminal du Codespace copier/coller les codes ci-dessous etape par étape :  

**Création du cluster K3d**  
```
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```
```
k3d cluster create lab \
  --servers 1 \
  --agents 2
```
**vérification du cluster**  
```
kubectl get nodes
```
**Déploiement d'une application (Docker Mario)**  
```
kubectl create deployment mario --image=sevenajay/mario
kubectl expose deployment mario --type=NodePort --port=80
kubectl get svc
```
**Forward du port 80**  
```
kubectl port-forward svc/mario 8080:80 >/tmp/mario.log 2>&1 &
```
**Réccupération de l'URL de l'application Mario** 
Votre application Mario est déployée sur le cluster K3d. Pour obtenir votre URL cliquez sur l'onglet **[PORTS]** dans votre Codespace et rendez public votre port **8080** (Visibilité du port).
Ouvrez l'URL dans votre navigateur et jouer !

---------------------------------------------------
Séquence 3 : Exercice
---------------------------------------------------
Objectif : Customisez un image Docker avec Packer et déploiement sur K3d via Ansible
Difficulté : Moyen/Difficile (~2h)
---------------------------------------------------  
Votre mission (si vous l'acceptez) : Créez une **image applicative customisée à l'aide de Packer** (Image de base Nginx embarquant le fichier index.html présent à la racine de ce Repository), puis déployer cette image customisée sur votre **cluster K3d** via **Ansible**, le tout toujours dans **GitHub Codespace**.  

**Architecture cible :** Ci-dessous, l'architecture cible souhaitée.   
  
![Screenshot Actions](Architecture_cible.png)   
  
---------------------------------------------------  
## Processus de travail (résumé)

1. Installation du cluster Kubernetes K3d (Séquence 1)
2. Installation de Packer et Ansible
3. Build de l'image customisée (Nginx + index.html)
4. Import de l'image dans K3d
5. Déploiement du service dans K3d via Ansible
6. Ouverture des ports et vérification du fonctionnement

---------------------------------------------------
Séquence 4 : Documentation  
Difficulté : Facile (~30 minutes)
---------------------------------------------------
**Complétez et documentez ce fichier README.md** pour nous expliquer comment utiliser votre solution.  
Faites preuve de pédagogie et soyez clair dans vos expliquations et processus de travail.  
   
---------------------------------------------------
Evaluation
---------------------------------------------------
Cet atelier, **noté sur 20 points**, est évalué sur la base du barème suivant :  
- Repository exécutable sans erreur majeure (4 points)
- Fonctionnement conforme au scénario annoncé (4 points)
- Degré d'automatisation du projet (utilisation de Makefile ? script ? ...) (4 points)
- Qualité du Readme (lisibilité, erreur, ...) (4 points)
- Processus travail (quantité de commits, cohérence globale, interventions externes, ...) (4 points) 


Ce tutoriel explique toutes les étapes nécessaires pour :

✅ Construire une image Docker customisée via Packer
✅ Importer cette image dans un cluster K3d
✅ Déployer automatiquement l’application via Ansible
✅ Accéder à l’application via Kubernetes

L’ensemble est conçu pour être exécuté dans GitHub Codespaces.

🧩 1. Installer Ansible
sudo apt-get update
sudo apt-get install -y ansible
ansible --version

📦 2. Préparer la structure Packer

Créer le dossier :

mkdir -p packer


Créer le fichier de configuration Packer :

cat > packer/nginx.pkr.hcl <<'EOF'
packer {

  required_plugins {

    docker = {

      version = ">= 1.0.0"

      source  = "github.com/hashicorp/docker"

    }

  }

}
 
variable "image_name" {

  type    = string

  default = "nginx-custom:1.0"

}
 
source "docker" "nginx" {

  image  = "nginx:alpine"

  commit = true

}
 
build {

  sources = ["source.docker.nginx"]
 
  provisioner "shell" {

    inline = [

      "mkdir -p /usr/share/nginx/html",

      "rm -f /usr/share/nginx/html/*"

    ]

  }
 
  provisioner "file" {

    source      = "../index.html"

    destination = "/usr/share/nginx/html/index.html"

  }
 
  provisioner "shell" {

    inline = [

      "ls -la /usr/share/nginx/html",

      "nginx -v || true"

    ]

  }
 
  post-processor "docker-tag" {

    repository = "nginx-custom"

    tag = ["1.0"]

  }

}
EOF

🐳 3. Build de l’image Docker customisée

Se placer à la racine :

cd /workspaces/Image_to_Cluster


Initialiser Packer :

cd packer
packer init .
packer build .
cd ..


Vérification :

docker images | grep nginx-custom

🧰 4. Correction si nécessaire du fichier Packer

(Si une erreur de type tag must be a list apparaît)

sed -i 's/tag *= *"1.0"/tag = ["1.0"]/g' nginx.pkr.hcl
packer build .

☸️ 5. Importer l’image dans K3d
k3d image import nginx-custom:1.0 -c lab

📁 6. Création des fichiers Kubernetes

Créer le dossier :

mkdir -p k8s

Deployment :
cat > k8s/deployment.yml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-custom
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-custom
  template:
    metadata:
      labels:
        app: nginx-custom
    spec:
      containers:
        - name: nginx
          image: nginx-custom:1.0
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 80
EOF

Service :
cat > k8s/service.yml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: nginx-custom
spec:
  type: NodePort
  selector:
    app: nginx-custom
  ports:
    - port: 80
      targetPort: 80
EOF

🤖 7. Déploiement via Ansible

Créer le dossier :

mkdir -p ansible


Créer le playbook :

cat > ansible/deploy.yml <<'EOF'
- name: Deploy nginx-custom to k3d
  hosts: localhost
  gather_facts: false
  tasks:
    - name: Apply manifests
      ansible.builtin.command: kubectl apply -f ../k8s/
    - name: Wait rollout
      ansible.builtin.command: kubectl rollout status deployment/nginx-custom --timeout=120s
    - name: Show pods & svc
      ansible.builtin.command: kubectl get pods,svc -o wide
      register: out
    - debug:
        var: out.stdout_lines
EOF


Lancer le déploiement :

ansible-playbook ansible/deploy.yml

🌍 8. Accéder à l’application

Forward du port :

kubectl port-forward svc/nginx-custom 8081:80 >/tmp/app.log 2>&1 &


Dans GitHub Codespaces → PORTS → rendre 8081 public → ouvrir dans le navigateur.

✔️ Votre application Nginx customisée est maintenant en ligne !