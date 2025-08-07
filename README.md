# End-to-End-CI-CD-GitOps-Deployment

## Overview

The task is divided into four main parts, covering containerization, CI/CD, configuration management, and deployment using Kubernetes with GitOps. Each part aims to simulate real-world DevOps practices using open-source tools.

---

## Tools Used

Here’s a explanation of all the tools used in this project:

---

- Docker
- Docker Compose
- Ansible
- Minikube
- kubectl
- ArgoCD CLI

---

## Part 1: Dockerization and CI Pipeline with GitHub Actions

The first step of the project involved containerizing the Todo List Node.js application and setting up a CI pipeline to build and push Docker images to a private Docker registry using GitHub Actions.

---

### Cloning the Application and Environment Setup

```bash
git clone https://github.com/Ankit6098/Todo-List-nodejs.git
```

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/clone.png?raw=true)

The `.env` file was updated to include a custom MongoDB connection string using MongoDB Atlas. This file was not committed to version control for security reasons.

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/code.png?raw=true)

### Dockerfile

A `Dockerfile` was created to package the Node.js application into a lightweight and secure Docker image using the `node:22-alpine` base image.

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/code%201.png?raw=true)

### Security Considerations:

- The application runs as a **non-root user** (`appuser`) to reduce attack surface.
- File permissions and ownership are tightly restricted inside the container.
- A **health check** was added to monitor application readiness and container health.

### Build the Docker Image

```bash
docker build -t mohamedsamir170/todolist:test .
```

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/image.png?raw=true)

### Start and Access the Container

```bash
docker run -d -p 4001:4000 --name todolist mohamedsamir170/todolist:test
```

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/image%201.png?raw=true)

The Website is accessible at: 

```bash
localhost:4001
```

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/image%202.png?raw=true)

### CI/CD Pipeline with GitHub Actions

A GitHub Actions workflow was created under `.github/workflows/main.yml` to automate the following steps:

1. Build the Docker image
2. Authenticate with Docker Hub using GitHub Secrets
3. Push the image to the registry

The pipeline was triggered automatically on every push to the `main` branch.

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/code%202.png?raw=true)

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/image%203.png?raw=true)

---

### Variables and Secrets Configuration

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/image%204.png?raw=true)

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/image%205.png?raw=true)

These were used to authenticate securely with Docker Hub and prevent credentials from being hardcoded in the workflow.

---

### Result

After successful execution of the pipeline, the Docker image was published to Docker Hub at:

```bash
docker.io/mohamedsamir170/todolist:latest
```

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/image%206.png?raw=true)

This image was then pulled and used for deployment in Part 3 (Docker Compose) and Part 4 (Kubernetes).

---

## Part 2: Remote Provisioning Using Ansible

In this part of the project, Ansible was used to automate the configuration of a remote virtual machine where the application would run. The Ansible setup was responsible for preparing the environment by installing required system packages, configuring Docker, and deploying the application using Docker Compose.

### Remote Machine Setup

- A virtual machine (VM) was provisioned on **AWS EC2** using a `t2.micro` instance running **Ubuntu**.
- SSH access was configured using a PEM key file.
- The target host was declared in an inventory file (Ansible/hosts) as follows:

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/code%203.png?raw=true)

### Ansible Playbooks

### 1. `docker-install.yaml`

This playbook installs **Docker** using Docker's official installation script, a quick and tested method recommended by Docker for Linux-based systems.

Tasks performed:

- Downloads the `get.docker.com` installation script to the remote machine at `/tmp/get-docker.sh`
- Executes the script using a shell command and logs the output to `/var/log/docker-installation.txt`
- Starts the Docker service and ensures it is enabled on system startup

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/code%204.png?raw=true)

### 2. `deploy-todolist.yaml`

This playbook handles application deployment via Docker Compose.

Tasks performed:

- Created a project directory on the remote machine (`/home/ubuntu/todolist`)
- Copied local project files using the `synchronize` module while excluding `.git` and `node_modules`
- Executed `docker-compose up -d` inside the deployment directory to launch the application and the Watchtower container

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/code%205.png?raw=true)

### Running Ansible Playbooks

After preparing the Ansible inventory and writing the necessary playbooks, the provisioning and deployment process was executed in two steps: one for installing Docker, and another for deploying the application with Docker Compose.

---

### `docker-install.yaml` – Install Docker and Docker Compose

This playbook installs Docker on the remote server by downloading and executing the official Docker installation script. It also ensures that the Docker service is enabled and started.

To run the playbook:

```bash
ansible-playbook -i Ansible/hosts Ansible/docker-install.yaml
```

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/image%207.png?raw=true)

After execution, Docker and Docker Compose should be installed. You can verify this by SSHing into the server and running:

```bash
docker --version
docker compose version
```

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/image%208.png?raw=true)

### `deploy-todolist.yaml` – Deploy the Todo List Application

This playbook transfers the application files to the remote VM, sets up the project directory, and uses Docker Compose to start the application and Watchtower services.

To run the deployment playbook:

```bash
ansible-playbook -i Ansible/hosts Ansible/deploy-todolist.yaml
```

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/image%209.png?raw=true)

Once completed, verify that the containers are running on the remote server:

```bash
docker ps
```

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/image%2010.png?raw=true)

### Outcome

The remote environment was fully configured using Ansible without manual SSH interaction. Docker and Docker Compose were correctly installed and the application stack was deployed automatically, ensuring a repeatable and version-controlled setup.

---

## Part 3: Application Deployment Using Docker Compose with Auto-Update

After setting up Docker on the remote machine, the application was deployed using **Docker Compose**. The deployment included the main application container (`todo-list`) and a second container running **Watchtower** to handle automatic image updates.

This setup ensures the application is not only deployed but also continuously updated whenever a new version of the Docker image is pushed to the registry.

---

### Docker Compose File

The `docker-compose.yml` defines two services:

### `todo-list`

The main Node.js application container, built and pushed in Part 1.

### `watchtower`

A lightweight container that monitors running services and automatically pulls and redeploys updated images from Docker Hub.

### Auto-Update with Watchtower

Watchtower was added to monitor for updated versions of the `todo-list` image on Docker Hub. It works by:

- Polling for image changes (every 30 seconds via `-interval 30`)
- Pulling the new image if it detects a change in the digest
- Gracefully shutting down the existing container
- Restarting it with the updated image

This approach enabled **lightweight continuous deployment** without using full orchestration tools like Kubernetes or writing custom update scripts.

---

### Verification

Once deployed, the services were running and accessible on port 4010. To test the auto-update:

1. A new version of the image was pushed to Docker Hub using the same tag (`latest`).
2. Watchtower automatically pulled the updated image and restarted the `todo-list` container.
3. Logs confirmed the successful update:

```bash
docker logs -f watchtower
```

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/Screenshot_2025-07-28_124055.png?raw=true)


## Part 4: Kubernetes Deployment with ArgoCD (Bonus)

As an extension of the main deployment, the application was also deployed to a **Kubernetes cluster** running on the same virtual machine. This was done using **Minikube**, and **ArgoCD** was used to implement a GitOps-style continuous delivery pipeline.

### Deployment Configuration

A `Deployment` resource was created for the `todo-list` application, with the number of replicas set to **2**. This ensures high availability and basic load balancing across pods. If one pod crashes or is terminated, Kubernetes automatically reschedules it.

### NodePort Service

To expose the application to external users (outside the cluster), a `Service` of type `NodePort` was created.

### Using Kustomize for Clean Configuration

**Kustomize** is a built-in Kubernetes tool for customizing YAML manifests without duplication. Instead of editing the same files for each environment (e.g., dev, staging, prod), Kustomize lets you maintain:

- A reusable **base** folder for common config (`deployment`, `service`, `secrets`)
- One or more **overlays** with environment-specific patches (e.g., different replica counts, image tags)

In this project:

- The `base` directory contains default settings.
- The `overlays` patch updates or overrides configurations as needed for production (e.g., bump replicas to 3 if desired later).

### Deployment Process

The manifests were applied using Kustomize via:

```bash
kubectl apply -k base/
```

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/image%2011.png?raw=true)

Deployment was verified with:

```bash
kubectl get pods
kubectl get svc
```

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/image%2012.png?raw=true)

---

## ArgoCD – GitOps Continuous Delivery for Kubernetes

To implement automated Continuous Delivery (CD) in a declarative and GitOps-based workflow, **ArgoCD** was used to deploy the Kubernetes manifests managed with Kustomize.

ArgoCD continuously monitors the Git repository and ensures the live Kubernetes environment always matches the desired configuration defined in Git. Any changes committed to the repository are automatically synced to the cluster.

## ArgoCD Installation

1. Create ArgoCD namespace

```bash
kubectl create ns argocd
```

1. Install ArgoCD Core Components

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/image%2013.png?raw=true)

1. Verify the installation

```bash
kubectl get all -n argocd
```

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/image%2014.png?raw=true)

## Retrieve ArgoCD Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/image%2015.png?raw=true)

- **Username:** admin
- **Password:** ManOLUarYAOQqCzy

## **Access The Argo CD API Server**

By default, the Argo CD API server is not externally accessible. Use port forwarding to access the UI.

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/image%2016.png?raw=true)

The API server can then be accessed using https://localhost:8080

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/image%2017.png?raw=true)

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/image%2018.png?raw=true)

## Login to ArgoCD using argocd Cli

```bash
argocd login localhost:8080 --username admin --password ManOLUarYAOQqCzy --insecure
```

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/image%2019.png?raw=true)

## Connecting ArgoCD to a GitHub Repository

Argo CD requires a **GitHub access token** to authenticate and access your GitHub repository. Follow these steps to set it up:

### Step 1: Generate a GitHub Access Token

1. Go to your GitHub account settings.
2. Navigate to **Developer settings > Personal access tokens**.
3. Click **"Generate new token"**, select the appropriate scopes:
    
   ![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/Screenshot_2025-07-28_111251.png?raw=true)
    
4. Copy the token and store it securely.

### Step 2: Add the Token to ArgoCD

Use the `argocd` CLI to add the GitHub repository and authenticate using the token:

```bash
argocd repo add https://github.com/mohamedsamir170/todolist.git \
  --username mohamedsamir170 \
  --password ghp_*******************************ntQc
```

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/Untitled%20design.png?raw=true)

### Declarative ArgoCD Application Manifest

An **`Application` custom resource** was created and applied directly to the Kubernetes cluster.

This YAML manifest defines the `todo-list` application and instructs ArgoCD to automatically deploy and synchronize it with the Kubernetes manifests in the GitHub repository.

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/code%206.png?raw=true)

### Key Features Enabled

- **Git Source:** Points to the `main` branch of the GitHub repo in the `overlays` directory
- **Target Cluster:** Applies to the current cluster (`kubernetes.default.svc`) and the `default` namespace
- **Auto Sync Policy:**
    - `automated`: Enables GitOps-style deployment without manual syncs
    - `selfHeal`: Reverts any  anual changes made outside Git
    - `prune`: Removes resources that are no longer tracked in Git

```bash
kubectl apply -f argo-cd/todo-list.yaml
```

![image alt](https://github.com/mohamedsamir170/todolist/blob/main/Images/image%2022.png?raw=true)
