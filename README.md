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

exercice 3 :

Automatisation complète avec Makefile, Packer, Ansible & Kubernetes (K3d)

Ce projet permet de construire automatiquement une image Docker customisée, puis de la déployer sur un cluster Kubernetes K3d, le tout dans GitHub Codespaces.

L'objectif : industrialiser un pipeline complet
➡️ Code → Image → Cluster Kubernetes → Service en ligne

Ce repository inclut un Makefile qui automatise toutes les étapes techniques de l'exercice.

🧰 2. Le pipeline complet (100% automatisé)

Au lieu de taper manuellement les commandes Packer / Docker / Ansible / Kubernetes,
un seul Makefile orchestre l’ensemble du workflow.

🎯 Commande principale :

make all


Cette commande exécute successivement :

make install

make build-image

make deploy

make status

À la fin, votre application customisée tourne dans votre cluster K3d 🎉

🧩 3. Détails : ce que fait le Makefile

Voici une explication pédagogique, section par section.

📦 A. Installation — make install

Cette étape installe toutes les dépendances nécessaires :

✔️ Nettoyage des dépôts APT cassés

Certaines images Codespaces contiennent un dépôt Yarn obsolète → le Makefile le désactive automatiquement.

✔️ Installation automatique de :

Ansible

Packer 1.11.2

k3d

kubectl

✔️ Vérification

À la fin, les versions installées sont affichées :

packer version
k3d --version


👉 C’est l’équivalent d’un bootstrap complet de votre workstation DevOps.

🐳 B. Build de l’image — make build-image

Cette étape :

Initialise Packer :

packer init .

Corrige automatiquement le tag si nécessaire (bug Packer classique).

Lance la construction de l’image Docker Nginx + index.html :

packer build .


Vérifie l’image :

docker images | grep nginx-custom


🔎 L'image générée est :
nginx-custom:1.0

☸️ C. Déploiement sur K3d — make deploy

Étape clé !
Cette commande fait 4 choses essentielles :

1️⃣ Création du cluster K3d (si absent)
k3d cluster create lab

2️⃣ Import de l’image dans le runtime Kubernetes
k3d image import nginx-custom:1.0 -c lab

3️⃣ Lancement du playbook Ansible
ansible-playbook ansible/deploy.yml


Ce playbook :

applique les manifests Kubernetes (k8s/)

attend le rollout du déploiement

affiche pods & services

4️⃣ Exposition de l’application (port-forward)
kubectl port-forward svc/nginx-custom 8081:80 &


➡️ L’application devient accessible sur
👉 http://localhost:8081

🧪 D. Vérification — make status

Affiche :

les nœuds Kubernetes

les pods

l’URL de l’application

🌐 4. Accéder à l'application

Dans Codespaces → onglet PORTS

Ouvrez l'URL dans votre navigateur.

Vous devriez voir votre page Nginx customisée 🎉

🗂️ 5. Architecture finale
Packer → Image Docker → Import K3d → Ansible → K8s Deployment → Service → Port-forward


🎯 Le tout automatisé via :

make all