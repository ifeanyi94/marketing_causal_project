# FastAPI Deployment on AWS EC2 Using Docker

http://54.242.206.194:8000/docs

---

## **Overview**

This document provides a step-by-step guide to deploy a FastAPI application using Docker on an AWS EC2 instance.

---

## **Pre-requisites**

- AWS account with EC2 access
- SSH client (e.g., terminal, PuTTY)
- Docker installed on the EC2 instance
- GitHub repository containing your FastAPI project

---

## **Directory Structure (Example)**

```
marketing_causal_project/
├── python_models/
│   └── api_uplift.py
├── requirements.txt
└── Dockerfile
```

---

## **Step 1: Launch an AWS EC2 Instance**

1. Log in to the **AWS Management Console**.
2. Launch a new **EC2 instance** (Ubuntu or Amazon Linux 2 recommended).
3. Select instance type, e.g., `t3.micro` (Free tier eligible) or larger.
4. Configure **Security Group**:
   - **Port 22 (SSH):** `0.0.0.0/0`
   - **Port 8000 (FastAPI):** `0.0.0.0/0`
5. Attach a **key pair** for SSH access.

---

## **Step 2: SSH Into Your Instance**

Open terminal and run:

```
ssh -i path_to_your_key.pem ubuntu@<your-public-ip>
```

Replace `<your-public-ip>` with your EC2 instance’s IP address.

---

## **Step 3: Install Docker**

On the EC2 instance, run:

```
sudo apt update
sudo apt install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu
```

Log out and log back in to apply Docker group permissions.

---

## **Step 4: Clone Your GitHub Repository**

On your EC2 instance:

```
sudo apt install git -y

# Clone your repository
git clone https://github.com/<your-github-username>/<your-repo-name>.git

cd <your-repo-name>
```

Replace `<your-github-username>` and `<your-repo-name>` with your actual GitHub details.

**Example (for your project):**

```
git clone https://github.com/IfeanyiEnekwa/marketing_causal_project.git
cd marketing_causal_project
```

---

## **Step 5: Create the Dockerfile**

In your project root (if not already present), create `Dockerfile`:

```
# Use official Python image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy requirements
COPY requirements.txt ./

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY python_models/api_uplift.py ./api_uplift.py

# Expose port
EXPOSE 8000

# Run the FastAPI application
CMD ["uvicorn", "api_uplift:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## **Step 6: Build and Run the Docker Container**

Inside the project directory:

```
# Build Docker image
sudo docker build -t uplift-api .

# Run the container
sudo docker run -d -p 8000:8000 uplift-api
```

---

## **Step 7: Access the FastAPI App**

Open your browser and visit:

```
http://<your-public-ip>:8000
```

Swagger documentation is available at:

```
http://<your-public-ip>:8000/docs
```

---

## **Step 8: Verify Container is Running**

Check running containers:

```
sudo docker ps
```

---

## **Summary of Important Paths**

- **Requirements File:**

  - `C:\Users\Ifeanyi Enekwa\Web dev projects\Datascience\marketing_causal_project\requirements.txt`

- **API Script:**

  - `C:\Users\Ifeanyi Enekwa\Web dev projects\Datascience\marketing_causal_project\python_models\api_uplift.py`

---

## **Optional: Keep Docker Running After Logout**

Use Docker in detached mode (as shown), or consider using `tmux`, `screen`, or Docker Compose to manage long-running containers.

---

## **Notes**

- Ensure **port 8000** is open in your AWS Security Group.
- If using custom environments, configure firewall settings appropriately.

---

## **Maintenance**

- **Stop the container:**

```
sudo docker stop <container_id>
```

- **Remove the container:**

```
sudo docker rm <container_id>
```

---

## **Troubleshooting**

- View container logs:

```
docker logs <container_id>
```

- Monitor EC2 instance CPU and memory usage if performance issues occur.

---

## **End of Guide**

