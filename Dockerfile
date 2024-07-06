# Use the official lightweight Alpine image
FROM alpine:latest

# Install necessary packages
RUN apk add --no-cache bash curl jq openrc dcron

WORKDIR /app

# Copy the scripts and make them executable
COPY ./app/script.sh /app/script.sh
COPY ./app/setup_script_docker.sh /app/setup_script_docker.sh
RUN chmod +x /app/script.sh /app/setup_script_docker.sh

# Copy the files directory to the container
COPY files /app/files

# Run the setup script
RUN /app/setup_script_docker.sh

# Ensure the cron log file exists
RUN touch /var/log/cron.log

# Create a cron job file
RUN echo "0 3 * * * /app/script.sh >> /var/log/cron.log 2>&1" > /etc/crontabs/root

# Expose a volume for the files directory
VOLUME ["/app/files"]

# Entry point to run the script at startup and then start cron
CMD ["sh", "-c", "/app/script.sh && crond -f & tail -f /var/log/cron.log"]
