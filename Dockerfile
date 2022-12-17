FROM eclipse-temurin:17-jdk-jammy as base

WORKDIR /app
COPY .mvn/ .mvn
COPY mvnw pom.xml ./
RUN ./mvnw dependency:resolve
COPY src ./src

FROM base as development
CMD ["./mvnw", "spring-boot:run", "-Dspring-boot.run.profiles=mysql", "-Dspring-boot.run.jvmArguments='-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:8000'"]

FROM base as build
RUN ./mvnw package

FROM eclipse-temurin:17-jre-jammy as production
ENV MYSQL_URL=jdbc:mysql://petclinic_database/petclinic
EXPOSE 8080
COPY --from=build /app/target/spring-petclinic-*.jar /spring-petclinic.jar
# CMD ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/spring-petclinic.jar"]
CMD ["java", "-Dspring.profiles.active=mysql", "-jar", "/spring-petclinic.jar"]


# docker network create petclinic-net
# docker run --rm -d --name petclinic_application --network petclinic-net -p 8080:8080 zhajili/petclinic-app:40


