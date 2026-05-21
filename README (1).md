# Innovatech Chile: Containerized Pet Store Platform

**Documentación Completa - Complete Documentation**

> Innovatech Chile runs two Spring Boot APIs, a React frontend, and MySQL on AWS — orchestrated with Docker Compose and deployed via GitHub Actions CI/CD.

Innovatech Chile — Tienda de Perritos is a containerized microservices platform that powers an online pet store. The system consists of two Spring Boot REST APIs (Sales and Dispatch), a React/Vite frontend, a MySQL database, and a full AWS infrastructure managed via Terraform and deployed automatically through GitHub Actions CI/CD.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Local Development](#local-development)
5. [Services](#services)
   - [Ventas API](#ventas-api)
   - [Despachos API](#despachos-api)
   - [Frontend](#frontend)
6. [Infrastructure](#infrastructure)
   - [Docker](#docker)
   - [Terraform](#terraform)
   - [AWS ECR](#aws-ecr)
7. [CI/CD Pipeline](#cicd-pipeline)
8. [Deployment](#deployment)

---

## Quick Start

Clone the repo, set up your environment, and run the entire stack with Docker Compose in minutes.

```bash
git clone https://github.com/DevOpsDuoc/Evaluacion02_Devop_Innovatech.git
cd Evaluacion02_Devop_Innovatech/proyect
export AWS_ACCOUNT_ID=your-account-id
docker compose up -d
```

Access the application at `http://localhost`. The Ventas API is available at `http://localhost:3001` and the Despachos API at `http://localhost:3002`.

---

## Architecture

### Microservices System Architecture Overview

Innovatech Chile runs four services wired together by Docker Compose for local development and mirrored on AWS as a 3-tier VPC for production. Understanding how the layers connect — frontend to APIs to database — and how security groups enforce that boundary on AWS is the foundation for working with any part of this platform.

### Services Overview

| Service | Type | Port | Purpose |
|---------|------|------|---------|
| **Ventas API** | Spring Boot REST | 3001 | Manages sales records (purchase address, value, date, dispatch status) |
| **Despachos API** | Spring Boot REST | 3002 | Manages dispatch records (truck plate, delivery attempts, delivery status) |
| **Frontend** | React + Vite + NGINX | 80 | Admin dashboard for managing sales and dispatches |
| **MySQL DB** | Database | 3306 | MySQL 8.0 shared database, user: `tienda` |

### Docker Compose Orchestration

Both backend services must be healthy before the frontend starts. The complete dependency chain:

```
db (MySQL)
├── backend (Ventas API) — depends_on: db
├── backend-despachos (Despachos API) — depends_on: db
└── frontend (React + NGINX) — depends_on: backend, backend-despachos
```

Database connections use `jdbc:mysql://db:3306/tienda` with credentials `tienda:tienda123`.

### AWS 3-Tier VPC Architecture

Production deployment uses a dedicated VPC (`academy-vpc`, CIDR `10.0.0.0/20`) across two availability zones (`us-east-1a`, `us-east-1b`).

| Tier | Subnet | CIDR Range | EC2 Instance | Internet Access |
|------|--------|-----------|--------------|-----------------|
| Web (public) | `public-subnet-1,2` | `10.0.0.0/24`, `10.0.1.0/24` | `ec2-web` | Direct via IGW |
| App (private) | `private-app-subnet-1,2` | `10.0.2.0/24`, `10.0.3.0/24` | `ec2-app` | Outbound via NAT |
| Data (private) | `private-data-subnet-1,2` | `10.0.4.0/24`, `10.0.5.0/24` | `ec2-datos` | Outbound via NAT |

### Security Group Chaining

Traffic flows unidirectionally: `sg_web` → `sg_app` → `sg_datos`

```
Internet (HTTP :80, SSH :22)
    ↓
sg_web  (ec2-web — public subnet)
    ↓ (ports :3001, :3002, SSH :22)
sg_app  (ec2-app — private app subnet)
    ↓ (MySQL :3306, SSH :22 from sg_web)
sg_datos  (ec2-datos — private data subnet)
```

- **sg_web**: HTTP (80), SSH (22), ICMP from `0.0.0.0/0`
- **sg_app**: Ports 3001/3002 (Spring Boot), SSH, ICMP from `sg_web`
- **sg_datos**: MySQL (3306) from `sg_app`, SSH from `sg_web`, ICMP from `sg_app`

### End-to-End Data Flow

1. Browser request arrives at `ec2-web` on port 80 (HTTP)
2. React frontend makes requests to backend APIs on ports 3001/3002
3. Backend services query MySQL using JDBC connection
4. MySQL returns results, backend returns JSON, frontend renders response
5. No layer can initiate a connection to a higher layer

---

## Prerequisites

### Required Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| **Docker with Compose** | Runs all four services in containers | Included with Docker Desktop; Docker Engine ≥ 23 on Linux |
| **Git** | Clone the repository | Any recent version |
| **AWS CLI** | Production deployment only | Required for ECR authentication and credential management |

### Optional Tools

These are only needed if you want to build services **outside** of Docker:

- **Java 17 JRE + Maven** — Build backends locally
- **Node.js 20** — Build frontend locally

### Environment Variables

Set the following **before** running Docker Compose:

```bash
# macOS / Linux
export AWS_ACCOUNT_ID=123456789012

# Windows (PowerShell)
$env:AWS_ACCOUNT_ID = "123456789012"
```

Replace `123456789012` with your 12-digit AWS account ID. This variable is referenced in `docker-compose.yml` to tag and pull container images from Amazon ECR.

```bash
# Persist across sessions (macOS/Linux)
echo "export AWS_ACCOUNT_ID=123456789012" >> ~/.bashrc
source ~/.bashrc
```

**Note**: `AWS_ACCOUNT_ID` must be set even for local development because `docker-compose.yml` uses it to name the images that are built and stored locally.

---

## Local Development

### Running the Full Stack with Docker Compose

#### Step 1: Clone the Repository

```bash
git clone https://github.com/DevOpsDuoc/Evaluacion02_Devop_Innovatech.git
cd Evaluacion02_Devop_Innovatech/proyect
```

#### Step 2: Set the Required Environment Variable

```bash
export AWS_ACCOUNT_ID=123456789012
```

Replace `123456789012` with your actual 12-digit AWS account ID.

#### Step 3: Start All Services

```bash
docker compose up -d
```

Docker builds the `backend` and `frontend` images from their local Dockerfiles on the first run, then starts all four containers in detached mode.

#### Step 4: Verify Services Are Running

```bash
docker compose ps
```

All four services should show status `running`:
- `frontend`
- `backend` (Ventas API)
- `backend-despachos` (Despachos API)
- `db` (MySQL)

### Service URLs

| Service | URL |
|---------|-----|
| Frontend | `http://localhost` |
| Ventas API | `http://localhost:3001` |
| Despachos API | `http://localhost:3002` |
| MySQL | `localhost:3306` |

### Managing the Stack

**View logs from all services**:
```bash
docker compose logs -f
```

**View logs from a specific service**:
```bash
docker compose logs -f backend
```

**Stop the stack** (data persists):
```bash
docker compose down
```

**Reset the database to clean state**:
```bash
docker compose down -v
```

### Database Persistence

MySQL data is stored in a named Docker volume called `tienda_db_data`. The volume survives container recreation, so your database persists across `docker compose down` and `docker compose up` cycles.

---

## Services

### Ventas API

**Spring Boot REST API on port 3001** — Manages sales records for Tienda de Perritos.

#### Overview

| Property | Value |
|----------|-------|
| **Port** | `3001` |
| **Base Path** | `api/v1/ventas` |
| **Framework** | Spring Boot + JPA/Hibernate |
| **Database** | MySQL 8.0 (shared `tienda` schema) |

#### The Venta Entity

```java
@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Venta {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long idVenta;

    @NotBlank(message = "La dirección es obligatoria")
    private String direccionCompra;

    private int valorCompra;

    @NotNull(message = "Fecha de compra es obligatoria")
    @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
    private LocalDate fechaCompra;

    @NotNull(message = "El campo de despacho debe ser proporcionado")
    private Boolean despachoGenerado = false;
}
```

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `idVenta` | `Long` | Auto-generated PK | `GenerationType.AUTO` |
| `direccionCompra` | `String` | `@NotBlank` | Purchase delivery address |
| `valorCompra` | `int` | — | Purchase amount |
| `fechaCompra` | `LocalDate` | `@NotNull`, ISO date | Format: `YYYY-MM-DD` |
| `despachoGenerado` | `Boolean` | `@NotNull`, default `false` | Set to `true` once a dispatch is created |

#### REST Endpoints

All endpoints are at `http://localhost:3001/api/v1/ventas`:

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/ventas` | Create a new sale |
| `GET` | `/api/v1/ventas` | List all sales |
| `GET` | `/api/v1/ventas/{idVenta}` | Get a single sale by ID |
| `PUT` | `/api/v1/ventas/{idVenta}` | Update an existing sale |
| `DELETE` | `/api/v1/ventas/{idVenta}` | Delete a sale |

#### Environment Variables

| Variable | Example | Description |
|----------|---------|-------------|
| `SPRING_DATASOURCE_URL` | `jdbc:mysql://db:3306/tienda` | JDBC connection string |
| `SPRING_DATASOURCE_USERNAME` | `tienda` | Database username |
| `SPRING_DATASOURCE_PASSWORD` | `tienda123` | Database password |
| `SPRING_JPA_HIBERNATE_DDL_AUTO` | `update` | Hibernate schema strategy (`update`, `create`, `validate`, or `none`) |

**Warning**: Do not use `SPRING_JPA_HIBERNATE_DDL_AUTO: create` or `create-drop` in production — these options destroy existing data on startup.

---

### Despachos API

**Spring Boot REST API on port 3002** — Manages dispatch records for Tienda de Perritos.

#### Overview

| Property | Value |
|----------|-------|
| **Port** | `3002` |
| **Base Path** | `api/v1/despachos` |
| **Framework** | Spring Boot + JPA/Hibernate |
| **Database** | MySQL 8.0 (shared `tienda` schema) |

#### The Despacho Entity

```java
@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Despacho {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long idDespacho;

    @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
    private LocalDate fechaDespacho;

    private String patenteCamion;
    private int intento;
    private Long idCompra;
    private String direccionCompra;
    private Long valorCompra;
    private boolean despachado = false;
}
```

| Field | Type | Notes |
|-------|------|-------|
| `idDespacho` | `Long` | Auto-generated PK |
| `fechaDespacho` | `LocalDate` | Dispatch date, ISO format `YYYY-MM-DD` |
| `patenteCamion` | `String` | Truck license plate |
| `intento` | `int` | Delivery attempt number (1, 2, 3…) |
| `idCompra` | `Long` | References `idVenta` in the Ventas API |
| `direccionCompra` | `String` | Delivery address copied from the sale |
| `valorCompra` | `Long` | Purchase value copied from the sale |
| `despachado` | `boolean` | `true` once delivered, default `false` |

#### REST Endpoints

All endpoints are at `http://localhost:3002/api/v1/despachos`:

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/despachos` | Create a new dispatch |
| `GET` | `/api/v1/despachos` | List all dispatch records |
| `GET` | `/api/v1/despachos/{idDespacho}` | Get a single dispatch |
| `PUT` | `/api/v1/despachos/{idDespacho}` | Update a dispatch |
| `DELETE` | `/api/v1/despachos/{idDespacho}` | Delete a dispatch |

#### Environment Variables

Same as Ventas API (both services share the same database):

| Variable | Example | Description |
|----------|---------|-------------|
| `SPRING_DATASOURCE_URL` | `jdbc:mysql://db:3306/tienda` | JDBC connection string |
| `SPRING_DATASOURCE_USERNAME` | `tienda` | Database username |
| `SPRING_DATASOURCE_PASSWORD` | `tienda123` | Database password |
| `SPRING_JPA_HIBERNATE_DDL_AUTO` | `update` | Hibernate schema strategy |

---

### Frontend

**React 18 + Vite admin dashboard served by NGINX on port 80**

#### Overview

| Property | Value |
|----------|-------|
| **Port** | `80` (NGINX in Docker) |
| **Framework** | React 18 + Vite 5 |
| **Styling** | Tailwind CSS 3 |
| **Routing** | React Router v6 |
| **HTTP Client** | Axios |

#### Technology Stack

| Package | Version | Purpose |
|---------|---------|---------|
| `react` | `^18.2.0` | UI component framework |
| `react-dom` | `^18.2.0` | DOM renderer |
| `react-router-dom` | `^6.24.1` | Client-side routing |
| `axios` | `^1.6.8` | HTTP client for API requests |
| `react-hook-form` | `^7.52.1` | Form state management |
| `sweetalert2` | `^11.11.0` | Modal dialogs |
| `react-icons` | `^5.1.0` | Icon library |
| `tailwindcss` | `^3.4.3` | Utility-first CSS |
| `vite` | `^5.2.0` | Build tool |

#### Component Structure

```
src/componentes/
├── CrudAdmin/
│   ├── CardComponent.jsx       # Summary stat cards
│   ├── FormCierreDespacho.jsx  # Form to close a dispatch
│   ├── FormDespacho.jsx        # Form to create dispatch
│   ├── Modal.jsx               # Reusable modal wrapper
│   ├── SearchBar.jsx           # Search input
│   ├── TableCompras.jsx        # Sales data table
│   └── TableDespachos.jsx      # Dispatches data table
├── CrudAdmin.jsx               # Main admin view
└── Layouts/
    ├── Carrusel.jsx            # Image carousel
    ├── Footer.jsx              # Page footer
    ├── Navbar.jsx              # Navigation bar
    └── Reviews.jsx             # Reviews section
```

#### Environment Variables

| Variable | Example | Description |
|----------|---------|-------------|
| `VITE_API_BASE_URL` | `http://backend:3001` | Base URL for the Ventas API |
| `VITE_API_DESPACHOS_URL` | `http://backend-despachos:3002` | Base URL for the Despachos API |

**Note**: In Docker Compose, use service hostnames (`backend`, `backend-despachos`). For local development outside Docker, use `http://localhost:3001` and `http://localhost:3002`.

#### Local Development (Outside Docker)

```bash
cd proyect/front_despacho
npm install

# Create .env.local
cat > .env.local << EOF
VITE_API_BASE_URL=http://localhost:3001
VITE_API_DESPACHOS_URL=http://localhost:3002
EOF

npm run dev
```

Vite starts a dev server with HMR at `http://localhost:5173` by default. Make sure the two Spring Boot APIs are running first.

---

## Infrastructure

### Docker

#### Containerization Strategy

- **Backend services** (Ventas and Despachos): Maven builds inside `maven:3.9.9`, runtime uses `eclipse-temurin:17-jre` with non-root user `appuser`
- **Frontend**: Compiled with `node:20-alpine`, served by `nginx:stable-alpine`
- **Orchestration**: Single `docker-compose.yml` in `proyect/` root
- **Data persistence**: Named Docker volume `tienda_db_data` for MySQL

#### Multi-Stage Dockerfiles

**Backend (Ventas API)**:
```dockerfile
# Stage 1 — compile with Maven
FROM maven:3.9.9 AS builder
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn -B -DskipTests package

# Stage 2 — runtime with JRE
FROM eclipse-temurin:17-jre AS runtime
WORKDIR /app
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
COPY --chown=appuser:appgroup --from=builder /app/target/*.jar /app/app.jar
USER appuser
EXPOSE 3001
ENV JAVA_TOOL_OPTIONS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
```

**Frontend**:
```dockerfile
# Stage 1 — build with Node
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2 — serve with NGINX
FROM nginx:stable-alpine AS runtime
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

#### Docker Compose Services

```yaml
services:
  backend:
    build: ./back-Ventas_SpringBoot/Springboot-API-REST
    image: ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/tienda-backend:latest
    ports: ["3001:3001"]
    environment:
      SPRING_DATASOURCE_URL: jdbc:mysql://db:3306/tienda
      SPRING_DATASOURCE_USERNAME: tienda
      SPRING_DATASOURCE_PASSWORD: tienda123
      SPRING_JPA_HIBERNATE_DDL_AUTO: update
    depends_on: [db]

  backend-despachos:
    image: ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/tienda-backend-despachos:latest
    restart: always
    ports: ["3002:3002"]
    environment:
      SPRING_DATASOURCE_URL: jdbc:mysql://db:3306/tienda
      SPRING_DATASOURCE_USERNAME: tienda
      SPRING_DATASOURCE_PASSWORD: tienda123
      SPRING_JPA_HIBERNATE_DDL_AUTO: update
    depends_on: [db]

  frontend:
    build: ./front_despacho
    image: ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/tienda-frontend:latest
    ports: ["80:80"]
    environment:
      VITE_API_BASE_URL: http://backend:3001
      VITE_API_DESPACHOS_URL: http://backend-despachos:3002
    depends_on: [backend, backend-despachos]

  db:
    image: mysql:8.0
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: tienda
      MYSQL_USER: tienda
      MYSQL_PASSWORD: tienda123
    ports: ["3306:3306"]
    volumes: [tienda_db_data:/var/lib/mysql]

volumes:
  tienda_db_data:
    name: tienda_db_data
```

#### Named Volume Rationale

MySQL data uses a **named volume** instead of a bind mount:

| Concern | Named Volume | Bind Mount |
|---------|-------------|-----------|
| Isolation | No host paths exposed | Exposes host directories |
| Portability | Docker-managed, movable | Tied to specific path |
| Data Integrity | Survives container recreation | Prone to host-side changes |
| Performance | Optimized I/O | Subject to host latency |
| Coupling | Stateless backend | Depends on local paths |

---

### Terraform

#### Provision AWS Infrastructure

Terraform scripts create a 3-tier AWS VPC across two availability zones in `us-east-1` with six subnets, two gateways, and three EC2 instances.

#### Provider Configuration

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
```

Authentication uses environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`) that AWS Academy injects at session start.

#### Network: VPC and Subnets

VPC uses `10.0.0.0/20` CIDR with DNS support enabled. Six `/24` subnets distributed across two AZs:

| Tier | Subnet | CIDR | AZ |
|------|--------|------|-----|
| Public | `public-subnet-1` | `10.0.0.0/24` | `us-east-1a` |
| Public | `public-subnet-2` | `10.0.1.0/24` | `us-east-1b` |
| App | `private-app-subnet-1` | `10.0.2.0/24` | `us-east-1a` |
| App | `private-app-subnet-2` | `10.0.3.0/24` | `us-east-1b` |
| Data | `private-data-subnet-1` | `10.0.4.0/24` | `us-east-1a` |
| Data | `private-data-subnet-2` | `10.0.5.0/24` | `us-east-1b` |

Public subnets have `map_public_ip_on_launch = true`. App and data subnets have no direct internet access.

#### Gateways and Routing

- **Internet Gateway** (`academy-igw`): Handles inbound/outbound internet traffic for public subnets
- **NAT Gateway** (`academy-nat`): Allows private instances to reach the internet without inbound exposure
- **Public route table**: `0.0.0.0/0` → Internet Gateway
- **Private route table**: `0.0.0.0/0` → NAT Gateway
- **S3 Gateway Endpoint**: Routes S3 traffic directly, bypassing NAT Gateway to eliminate per-GB NAT charges

#### Security Groups

Three chained security groups enforce unidirectional traffic flow:

**sg_web** (Web Layer):
- Inbound: HTTP (80), SSH (22), ICMP from `0.0.0.0/0`
- Outbound: All traffic

**sg_app** (App Layer):
- Inbound: Ports 3001/3002 (Spring Boot), SSH, ICMP from `sg_web`
- Outbound: All traffic

**sg_datos** (Data Layer):
- Inbound: MySQL (3306) from `sg_app`, SSH from `sg_web` (Bastion), ICMP from `sg_app`
- Outbound: All traffic

#### EC2 Instances

All instances use latest Amazon Linux 2023 AMI and `t3.micro` instance type with IAM instance profile wrapping `LabRole`:

| Instance | Subnet | Security Group | Public IP |
|----------|--------|----------------|-----------|
| `ec2-web` | `public-subnet-1` | `sg_web` | Elastic IP |
| `ec2-app` | `private-app-subnet-1` | `sg_app` | None |
| `ec2-datos` | `private-data-subnet-1` | `sg_datos` | None |

`ec2-web` receives a dedicated Elastic IP that persists across instance stops/starts.

#### Outputs

After `terraform apply`, Terraform prints four values:

```hcl
output "web_eip_public_ip" {
  description = "Stable public Elastic IP of the Web/Bastion instance"
  value       = aws_eip.web_eip.public_ip
}

output "web_instance_private_ip" {
  description = "The private IP of the Web instance"
  value       = aws_instance.ec2_web.private_ip
}

output "app_instance_private_ip" {
  description = "The private IP of the Application instance"
  value       = aws_instance.ec2_app.private_ip
}

output "datos_instance_private_ip" {
  description = "The private IP of the Data instance"
  value       = aws_instance.ec2_datos.private_ip
}
```

#### Applying the Configuration

```bash
# Export AWS credentials from AWS Academy
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...

# Set the SSH key pair name
export TF_VAR_key_name=vockey

# Initialize Terraform
terraform init

# Preview resources
terraform plan

# Create infrastructure
terraform apply
```

---

### AWS ECR

#### Private Container Image Registry

Three private ECR repositories store Docker images for each service:

| Repository | Service | Port |
|-----------|---------|------|
| `tienda-frontend` | React/NGINX | 80 |
| `tienda-backend` | Spring Boot Ventas API | 3001 |
| `tienda-backend-despachos` | Spring Boot Despachos API | 3002 |

Full image URI: `{AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/{repository}:latest`

#### Authenticating with ECR

```bash
aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin \
    ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com
```

EC2 instances use their IAM role credentials automatically (no static keys required).

#### Pulling Images

```bash
export AWS_ACCOUNT_ID=your-account-id
docker compose pull
docker compose up -d --remove-orphans
```

#### IAM Permissions

The `LabRole` IAM role includes required ECR permissions:
- `ecr:GetAuthorizationToken` — Get authentication tokens
- `ecr:BatchGetImage` — Pull image layers
- `ecr:GetDownloadUrlForLayer` — Access layer download URLs

---

## CI/CD Pipeline

### GitHub Actions Workflow

The workflow defined in `.github/workflows/deploy.yml` is triggered on every push to the `main` branch and runs two jobs:

1. **build-and-push**: Build all three Docker images and push to ECR
2. **deploy-by-ssm**: Pull and restart containers on EC2 instances via AWS Systems Manager

#### Environment Variables

| Variable | Value |
|----------|-------|
| `AWS_REGION` | `us-east-1` |
| `AWS_ACCOUNT_ID` | `118812498736` |
| `ECR_REGISTRY` | `118812498736.dkr.ecr.us-east-1.amazonaws.com` |
| `REPO_FRONTEND` | `tienda-frontend` |
| `REPO_BACKEND` | `tienda-backend` |
| `REPO_DESPACHOS` | `tienda-backend-despachos` |

#### Required GitHub Secrets

Configure in **Settings → Secrets and variables → Actions**:

- `AWS_ACCESS_KEY_ID` — AWS access key
- `AWS_SECRET_ACCESS_KEY` — Corresponding secret key
- `AWS_SESSION_TOKEN` — Required for AWS Academy

**Important**: AWS Academy credentials expire after a few hours. Update secrets before each deployment session.

#### Job 1: Build and Push

1. Checkout code
2. Configure AWS credentials
3. Authenticate with Amazon ECR
4. Build and push all three Docker images to ECR, tagged `:latest`

Each image (frontend, backend, backend-despachos) is built from its Dockerfile and pushed independently.

#### Job 2: Deploy via SSM

After successful build, AWS Systems Manager sends shell commands to EC2 instances:

- **ec2-web**: Authenticate with ECR, pull `tienda-frontend:latest`, remove old container, start new one on port 80
- **ec2-app**: Authenticate with ECR, pull both backend images, remove old containers, start new ones on ports 3001/3002

No inbound SSH ports required; SSM Session Manager handles all communication.

#### Full Workflow Configuration

```yaml
name: Deploy to Amazon ECS Instances (Innovatech)

on:
  push:
    branches: [ "main" ]

env:
  AWS_REGION: us-east-1
  AWS_ACCOUNT_ID: "118812498736"
  ECR_REGISTRY: "118812498736.dkr.ecr.us-east-1.amazonaws.com"
  REPO_FRONTEND: tienda-frontend
  REPO_BACKEND: tienda-backend
  REPO_DESPACHOS: tienda-backend-despachos

permissions:
  contents: read

jobs:
  build-and-push:
    name: Build and Push to ECR
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-session-token: ${{ secrets.AWS_SESSION_TOKEN }}
        aws-region: ${{ env.AWS_REGION }}
    - uses: aws-actions/amazon-ecr-login@v2
      id: login-ecr
    - name: Build and Push Frontend
      run: |
        docker build -t ${{ env.ECR_REGISTRY }}/${{ env.REPO_FRONTEND }}:latest -f proyect/frontend/Dockerfile ./proyect/frontend
        docker push ${{ env.ECR_REGISTRY }}/${{ env.REPO_FRONTEND }}:latest
    - name: Build and Push Backend
      run: |
        docker build -t ${{ env.ECR_REGISTRY }}/${{ env.REPO_BACKEND }}:latest -f proyect/backend/Dockerfile ./proyect/backend
        docker push ${{ env.ECR_REGISTRY }}/${{ env.REPO_BACKEND }}:latest
    - name: Build and Push Backend Despachos
      run: |
        docker build -t ${{ env.ECR_REGISTRY }}/${{ env.REPO_DESPACHOS }}:latest -f proyect/backend-despachos/Dockerfile ./proyect/backend-despachos
        docker push ${{ env.ECR_REGISTRY }}/${{ env.REPO_DESPACHOS }}:latest

  deploy-by-ssm:
    name: Update Instances via SSM
    needs: build-and-push
    runs-on: ubuntu-latest
    steps:
    - uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-session-token: ${{ secrets.AWS_SESSION_TOKEN }}
        aws-region: ${{ env.AWS_REGION }}
    - name: Refresh Frontend Container on ec2-web
      run: |
        aws ssm send-command \
          --document-name "AWS-RunShellScript" \
          --targets "Key=tag:Name,Values=ec2-web" \
          --parameters 'commands=[
            "aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin ${{ env.ECR_REGISTRY }}",
            "sudo docker pull ${{ env.ECR_REGISTRY }}/${{ env.REPO_FRONTEND }}:latest",
            "sudo docker rm -f tienda-frontend || true",
            "sudo docker run -d --name tienda-frontend --restart always -p 80:80 ${{ env.ECR_REGISTRY }}/${{ env.REPO_FRONTEND }}:latest"
          ]'
    - name: Refresh Backend Containers on ec2-app
      run: |
        aws ssm send-command \
          --document-name "AWS-RunShellScript" \
          --targets "Key=tag:Name,Values=ec2-app" \
          --parameters 'commands=[
            "aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin ${{ env.ECR_REGISTRY }}",
            "sudo docker pull ${{ env.ECR_REGISTRY }}/${{ env.REPO_BACKEND }}:latest",
            "sudo docker pull ${{ env.ECR_REGISTRY }}/${{ env.REPO_DESPACHOS }}:latest",
            "sudo docker rm -f tienda-backend || true",
            "sudo docker rm -f tienda-backend-despachos || true",
            "sudo docker run -d --name tienda-backend --restart always -p 3001:3001 ${{ env.ECR_REGISTRY }}/${{ env.REPO_BACKEND }}:latest",
            "sudo docker run -d --name tienda-backend-despachos --restart always -p 3002:3002 ${{ env.ECR_REGISTRY }}/${{ env.REPO_DESPACHOS }}:latest"
          ]'
```

---

## Deployment

### EC2 Architecture

| Instance | Tier | Network | Services |
|----------|------|---------|----------|
| `ec2-web` | Web/Bastion | Public subnet — Elastic IP | `tienda-frontend` on port 80 |
| `ec2-app` | Application | Private subnet | `tienda-backend` (3001), `tienda-backend-despachos` (3002) |
| `ec2-datos` | Data | Private subnet | MySQL on port 3306 |

`ec2-web` is the only instance with a public-facing Elastic IP. Use it as a bastion to reach private instances.

### Automatic Deployment

Pushing to `main` triggers the GitHub Actions workflow, which:

1. Builds and pushes updated images to Amazon ECR
2. Sends SSM `RunShellScript` commands to `ec2-web` and `ec2-app`
3. Each instance pulls the latest image and restarts the container

No SSH access or open inbound ports required.

### Manual Deployment

#### SSH Access

```bash
# Connect to ec2-web (bastion) using its Elastic IP
ssh -i your-key.pem ec2-user@<ELASTIC_IP>

# Jump to ec2-app or ec2-datos from ec2-web
ssh -i your-key.pem ec2-user@<APP_PRIVATE_IP>
ssh -i your-key.pem ec2-user@<DATOS_PRIVATE_IP>
```

Get the IP addresses from `terraform output`.

#### SSM Session Manager (No SSH Key Required)

```bash
aws ssm start-session --target <INSTANCE_ID> --region us-east-1
```

Requires AWS CLI and Session Manager plugin installed.

#### First-Time Instance Setup

Run `00-init.sh` once on each instance to install Docker:

```bash
bash proyect/remote-setup/00-init.sh
```

Log out and back in for Docker group membership to take effect.

#### Manual Container Deployment

```bash
# Authenticate with ECR
export AWS_ACCOUNT_ID=118812498736
aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin \
    ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com

# Copy docker-compose.yml to the instance
scp -i your-key.pem proyect/docker-compose.yml \
  ec2-user@<ELASTIC_IP>:/home/ec2-user/app/docker-compose.yml

# From inside the instance, run the deploy script
bash proyect/remote-setup/01-pull_and_deploy.sh
```

The script authenticates with ECR, pulls the latest images, and starts the full stack with `docker compose up -d --remove-orphans`.

---

## Summary

Innovatech Chile is a complete microservices platform demonstrating professional DevOps practices:

- **Local Development**: Docker Compose orchestrates all four services
- **Architecture**: 3-tier AWS VPC with security group chaining
- **Infrastructure as Code**: Terraform provisions the entire AWS environment
- **Container Registry**: Amazon ECR stores private Docker images
- **CI/CD**: GitHub Actions automatically builds, pushes, and deploys on every push to main
- **Security**: No open SSH ports; SSM Session Manager for remote execution
- **Scalability**: Multi-AZ deployment with load balancing ready

For the complete documentation index, visit: https://mintlify.com/DevOpsDuoc/Evaluacion02_Devop_Innovatech/llms.txt
