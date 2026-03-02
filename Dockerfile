# Use lightweight Java image
FROM eclipse-temurin:21-jdk-jammy

# Set working directory
WORKDIR /app

# Copy JAR file into container
COPY target/spring-petclinic-2.1.0.BUILD-SNAPSHOT.jar app.jar

# Expose internal container port
EXPOSE 8085

# Run application
ENTRYPOINT ["java", "-jar", "app.jar"]
