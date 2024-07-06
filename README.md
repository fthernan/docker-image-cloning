Sure, here's a detailed `README.md` file for your repository:

---

# Docker Image Cloning Script

This repository contains a setup for a Docker container that runs a script to clone Docker images from one repository to another based on specific tags and digests. The script is scheduled to run daily using a cron job.

## Overview

The main script (`script.sh`) performs the following tasks:

1. Logs into Docker Hub.
2. Fetches a list of Docker image tags and their corresponding digests from a specified Docker Hub repository.
3. Identifies all tags that share the same digest.
4. Pulls the Docker images and pushes them to another repository using all the identified tags.

## File Structure

```
project-directory/
├── Dockerfile
├── docker-compose.yml
├── files/
│   ├── .env
│   ├── urls.txt
│   ├── digests.txt
├── app/
│   ├── script.sh
│   ├── setup_script_manual.sh
│   ├── setup_script_docker.sh
└── README.md
```

### Files Description

- **Dockerfile**: Defines the Docker image for the container. It uses Alpine Linux as the base image, installs necessary packages, sets up cron, and copies the scripts and files into the container.
  
- **docker-compose.yml**: Defines the Docker Compose configuration for the service. It mounts the Docker socket and the `files` directory, sets environment variables for Docker Hub credentials, and specifies the restart policy.

- **files/**:
  - **.env**: Stores Docker Hub credentials (username, password and Docker Hub repository).
  - **urls.txt**: Contains URLs of Docker repositories to be processed.
  - **digests.txt**: Stores the digests of the Docker images.

- **script.sh**: The main script that performs the image cloning tasks.
  
- **setup_script_docker.sh** : Installs necessary packages and sets up the environment for the script. It runs once when the container starts.
  
- **setup_script_manual.sh**: Installs necessary packages and sets up the environment for the script when running manually.


## Environment Variables

The Docker Compose file uses the following environment variables:

- `DOCKERHUB_USERNAME`: Your Docker Hub username.
- `DOCKERHUB_PASSWORD`: Your Docker Hub password.
- `TARGET_REGISTRY`: Your Docker Hub registry name.

## Adding URLs

To track and clone additional Docker repositories, you can add more lines to the `urls.txt` file located in the `files` directory. Each line should follow the format:

```
source_repo tag target_repo
```

- `source_repo`: The source Docker repository.
- `tag`: The specific tag of the Docker image you want to clone.
- `target_repo`: The target repository in your main Docker registry (defined by the `TARGET_REGISTRY` variable in `.env`).


## Volume

The `files` directory is mounted as a volume to ensure persistent storage of the `.env`, `urls.txt`, and `digests.txt` files. This allows you to modify these files without rebuilding the Docker image.

## Usage with Docker

1. **Clone the repository**:

   ```sh
   git clone https://github.com/fthernan/docker-image-cloning.git
   cd docker-image-cloning
   ```

2. **Set up your environment variables**:

   Create a `.env` file inside the `files` directory with your Docker Hub credentials:

   ```env
   DOCKERHUB_USERNAME=your_username
   DOCKERHUB_PASSWORD=your_password
   TARGET_REGISTRY=your_dockerhub_registry_name
   ```

3. **Build and run the Docker container**:

   ```sh
   docker-compose build
   docker-compose up -d
   ```

4. **Check logs**:

   To view the cron job logs, run:

   ```sh
   docker-compose logs -f
   ```

## Usage without Docker

1. **Clone the repository**:

   ```sh
   git clone https://github.com/fthernan/docker-image-cloning.git
   cd docker-image-cloning
   ```

2.  **Create the `.env` File:**
    
    Create a file named `.env` in the same directory as the `script.sh` script and add your DockerHub credentials:
    
    ```env
    DOCKERHUB_USERNAME=your_main_account_username
    DOCKERHUB_PASSWORD=your_main_account_password
    TARGET_REGISTRY=your_dockerhub_registry_name
    ```
    
3.  **Make the Setup Script Executable:**
    
    `chmod +x ./app/setup_script_manual.sh` 
    
4.  **Run the Setup Script:**
    
    `./app/setup_script_manual.sh` 
    
5.  **Editing URLs:**
    
    Users can edit the `files/urls.txt` file to add or modify URLs. Each URL should be on a new line.
    

## Cron Job

The cron job is configured to run the `script.sh` daily at 3:00 AM. This can be adjusted in the `Dockerfile` or `setup_script_manual.sh` by modifying the cron schedule expression.

