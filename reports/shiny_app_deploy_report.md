**Summary Report: Attempt to Deploy Shiny App using Docker on AWS EC2 Instance**


**Date:** July 22, 2025

---

## **1. Objective**

The goal was to deploy a Shiny dashboard application using Docker on an AWS EC2 instance. The application would be accessible via a public IP and run concurrently with an existing FastAPI server.

---

## **2. Actions Taken**

### **2.1 Environment Setup**

- **AWS EC2 Instance:**

  - Instance type: (details not specified, assumed t2.micro or similar)
  - Disk size: 8 GB EBS volume
  - OS: Ubuntu (version not explicitly mentioned, likely Ubuntu 20.04 or 22.04)

- **Existing Services:**

  - FastAPI server running on port `8000`
  - Docker was already installed and in use

### **2.2 Project Setup**

- Navigated to `~/marketing_causal_project/dashboard/`
- Files present:
  - `Dockerfile` (for Shiny app)
  - `shiny_app.R` (main application code)
  - `www/` (static resources)

### **2.3 Docker Commands Executed**

#### **Initial Build & Run**

- Built the Docker image:
  ```bash
  docker build -t my-shiny-app .
  ```
- Ran the container:
  ```bash
  docker run -d -p 3838:3838 --name serene_curie my-shiny-app
  ```
- Attempted to access via browser:
  - `http://54.242.206.194:3838/shiny_app/`
  - Encountered error: **"An error has occurred. The application failed to start. The application exited during initialization."**

#### **Container Management**

- Listed running containers using `docker ps`
- Restarted the container with `docker restart serene_curie`
- Stopped and removed the container with:
  ```bash
  docker stop serene_curie
  docker rm serene_curie
  ```
- Rebuilt and reran the container multiple times to troubleshoot

### **2.4 Log Review**

- Checked Docker logs using:
  ```bash
  docker logs serene_curie
  ```
- Relevant log messages:
  - Shiny Server started successfully
  - Error repeated: **"Error getting worker: Error: The application exited during initialization."**

### **2.5 Disk Space Management**

- Attempted to resolve possible space issues:

  - Ran `docker system prune -a -f` (removed all unused images/containers)
  - Ran `docker volume prune -f` (removed unused volumes)

- Checked disk space with `df -h`:

  ```
  /dev/root: 6.8 GB total, 6.0 GB used, 799 MB available (89% used)
  ```

- Tried to rebuild the Docker image again:

  - Build failed at extracting base image layer:
    ```
    failed to register layer: write /usr/lib/x86_64-linux-gnu/libLLVM-15.so.1: no space left on device
    ```

---

## **3. Reasons for Deployment Failure**

### **3.1 Insufficient Disk Space**

- The EC2 instance was running with an **8 GB EBS volume**, and most of it was already used:
  - Docker images and layers consume significant space
  - The FastAPI server and related files are likely stored on `/dev/root`
  - With only **799MB free**, there was **not enough room for the Shiny Docker image layers** to be extracted during `docker build`
- Even after running `docker system prune -a`, only **10.87MB was reclaimed**, indicating most space was still in use by active services or necessary files.

### **3.2 Shiny App Errors**

- The log message: **"The application exited during initialization"** indicates a possible error in `shiny_app.R` or missing dependencies.
- However, due to the disk space problem, it's likely that the image build was incomplete or corrupted, further causing runtime failures.

### **3.3 Running as Root Warning (Minor Issue)**

- Logs showed:
  - **"Running as root unnecessarily is a security risk!"**
  - This is a warning, **not the cause of failure**, but could be addressed in future improvements.

---

## **4. Recommendations**

### **4.1 Increase EBS Volume Size**

- **Resize from 8GB to at least 20-30GB**
- Estimated cost:
  - **20GB**: \~\$1.92/month
  - **30GB**: \~\$2.88/month
- Use AWS Console or CLI to increase the volume size
- Run `sudo growpart` and `resize2fs` to expand the filesystem after resizing

### **4.2 Review Application Code**

- Check `shiny_app.R` for errors:
  - Ensure correct folder structure
  - Validate dependency installation in Dockerfile

### **4.3 Monitor Disk Usage Continuously**

- Use `du -sh *` in `/` and `/home/ubuntu/` to identify large directories
- Monitor Docker image sizes with `docker images`

### **4.4 Consider Using BuildKit**

- Use `docker buildx` for better layer caching and disk efficiency

---

## **5. Conclusion**

Despite multiple attempts to deploy the Shiny app via Docker on AWS EC2, the process was unsuccessful primarily due to **disk space limitations** on the instance. The failure to build and run the Docker container, along with persistent Shiny initialization errors, were exacerbated by the lack of available storage.

Upgrading the EBS volume is a necessary step to proceed with the deployment.

---

**End of Report**

