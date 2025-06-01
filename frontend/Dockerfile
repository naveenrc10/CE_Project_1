# Use OpenJDK 17 as the base image
FROM eclipse-temurin:17-jdk

# Set the working directory
WORKDIR /app

# Copy the JAR file into the container
COPY ./target/frontend.jar /app/frontend.jar

# Run the JAR file
CMD ["java", "-jar", "/app/frontend.jar"]
