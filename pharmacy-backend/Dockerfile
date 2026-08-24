# Build stage — compiles the Spring Boot app into a runnable jar
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Run stage — small final image, just the JRE + the built jar
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /app/target/pharmacy-backend-0.0.1.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
