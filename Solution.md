# DevOps Project Demo 2
## Deploying Spring PetClinic Sample Application localy using Docker

## Subtask 1

We will start to build Docker image for our Spring Boot Application ,source code could be found [here](https://github.com/spring-projects/spring-petclinic) ,in order to make our Docker Image smaller we will use multistage docker image. With multi-stage builds, you use multiple FROM statements in your Dockerfile. Each FROM instruction can use a different base, and each of them begins a new stage of the build. You can selectively copy artifacts from one stage to another, leaving behind everything you don't want in the final image. 

```
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

EXPOSE 8080
COPY --from=build /app/target/spring-petclinic-*.jar /spring-petclinic.jar
# CMD ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/spring-petclinic.jar"]
CMD ["java", "-Dspring.profiles.active=mysql", "-jar", "/spring-petclinic.jar"]

# docker run --rm -d --name petclinic_application --network petclinic-net -e MYSQL_URL=jdbc:mysql://petclinic_database/petclinic -p 8080:8080 zhajili/petclinic-app:1.9

```
We are using multiple FROM statements in order to leave previous BASE image and not to build new one if it is not needed. As seen we in CMD statement we are running our application with MYSQL profile. We can check this link [link](https://www.baeldung.com/spring-boot-docker-start-with-profile) for more information.

Please navigate to docker_application directory and build docker image with ,we are also adding **zhajili** keyword to our image name and tag ,basically it is repository name in DockerHub, this will be used while executing task3.

```
zhajili$ docker images | grep petclinic

zhajili/petclinic-app                   1.9               31f6b2fb6754   18 hours ago    319MB

```

We will not start our docker container until we have ready DB container ,because since we are starting our application with MySQL profile ,Hikari will try to connect but at the end it will time out.

```
:: Built with Spring Boot :: 2.7.3


2022-11-24 21:27:34.459  INFO 21661 --- [           main] o.s.s.p.service.ClinicServiceTests       : Starting ClinicServiceTests using Java 11.0.17 on app-vm with PID 21661 (started by ubuntu in /home/ubuntu/spring-petclinic)
2022-11-24 21:27:34.459  INFO 21661 --- [           main] o.s.s.p.service.ClinicServiceTests       : The following 1 profile is active: "mysql"
2022-11-24 21:27:34.617  INFO 21661 --- [           main] .s.d.r.c.RepositoryConfigurationDelegate : Bootstrapping Spring Data JPA repositories in DEFAULT mode.
2022-11-24 21:27:34.639  INFO 21661 --- [           main] .s.d.r.c.RepositoryConfigurationDelegate : Finished Spring Data repository scanning in 16 ms. Found 2 JPA repository interfaces.
2022-11-24 21:27:34.768  INFO 21661 --- [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-5 - Starting...

```

We will start our Docker container with following command .

```
docker run --rm -d --name petclinic_application --network petclinic-net -e MYSQL_URL=jdbc:mysql://petclinic_database/petclinic -p 8080:8080 zhajili/petclinic-app:1.9

```
Here ,we name our container as **petclinic_application** and putting it to private docker network called **petclinic-net** which was one of requirements in subtask1. We also add env variable for changing MySQL URL for DB connection ,make sure that DB name will match when you run DB container ,otherwise Application will not able to communicate through private network and start the application. In our case we name our DB container as **petclinic_database** .At the end we are exposing port 8080 with our docker image which we tagged with out repo and tag number.

## Subtask 2

We will navigate to the docker_mysql directory and build our db docker image ,please make sure that user.sql script is located in the same directory with Dockerfile.We will copy it and then run it.

Script will create **petclinic** database and grant all priviliges to the username **petclinic** with password **petclinic**.

```
CREATE DATABASE IF NOT EXISTS petclinic;

ALTER DATABASE petclinic
  DEFAULT CHARACTER SET utf8
  DEFAULT COLLATE utf8_general_ci;

GRANT ALL PRIVILEGES ON petclinic.* TO 'petclinic'@'%' IDENTIFIED BY 'petclinic';

```
Our dockerfile looks like below ,it is quite simple and we are creating it with base of MySQL 5.7

```
FROM mysql:5.7

ENV MYSQL_ROOT_PASSWORD=1234
COPY ./user.sql /docker-entrypoint-initdb.d
EXPOSE 3306

# docker run -d --network petclinic-net -v /Users/zhajili/Documents/dockerVolumes/mysql-data:/var/lib/mysql -p 3306:3306 --name petclinic_database zhajili/petclinic-mysql:1.2 

```

After build we will have below images in our local repo.

```

zhajili$ docker images | grep petclinic

zhajili/petclinic-app                   1.9               31f6b2fb6754   19 hours ago    319MB
zhajili/petclinic-mysql                 1.2               2e062b4cb4bc   28 hours ago    495MB

```

We will run our docker container with following command 

docker run -d --network petclinic-net -v /Users/zhajili/Documents/dockerVolumes/mysql-data:/var/lib/mysql -p 3306:3306 --name petclinic_database zhajili/petclinic-mysql:1.2 

It will also put our DB container to the **petclinic-net** and also it will attach local host Volume which will make our data persistent even we will restart our Container .Important point is we name our container **petclinic_database** which is very crucial for communication.

Now we will run our containers ,firstly we will start MySQL and then App container.

```

zhajili$ docker ps
CONTAINER ID   IMAGE                         COMMAND                  CREATED        STATUS        PORTS                               NAMES
4988ad5802db   zhajili/petclinic-app:1.9     "java -Dspring.profi…"   16 hours ago   Up 16 hours   0.0.0.0:8080->8080/tcp              petclinic_application
d6a8c9b942a6   zhajili/petclinic-mysql:1.2   "docker-entrypoint.s…"   16 hours ago   Up 16 hours   0.0.0.0:3306->3306/tcp, 33060/tcp   petclinic_database

```
We can see that our container is listening to the port 8080 ,let's check logs from App Container ,from logs we can see that active profile is mysql  and Tomcat is initialized with port 8080.

```

zhajili$ docker logs -f 4988ad5802db


              |\      _,,,--,,_
             /,`.-'`'   ._  \-;;,_
  _______ __|,4-  ) )_   .;.(__`'-'__     ___ __    _ ___ _______
 |       | '---''(_/._)-'(_\_)   |   |   |   |  |  | |   |       |
 |    _  |    ___|_     _|       |   |   |   |   |_| |   |       | __ _ _
 |   |_| |   |___  |   | |       |   |   |   |       |   |       | \ \ \ \
 |    ___|    ___| |   | |      _|   |___|   |  _    |   |      _|  \ \ \ \
 |   |   |   |___  |   | |     |_|       |   | | |   |   |     |_    ) ) ) )
 |___|   |_______| |___| |_______|_______|___|_|  |__|___|_______|  / / / /
 ==================================================================/_/_/_/

:: Built with Spring Boot :: 2.7.3


2022-12-07 21:03:34.558  INFO 1 --- [           main] o.s.s.petclinic.PetClinicApplication     : Starting PetClinicApplication v2.7.3 using Java 17.0.5 on 4988ad5802db with PID 1 (/spring-petclinic.jar started by root in /)
2022-12-07 21:03:34.561  INFO 1 --- [           main] o.s.s.petclinic.PetClinicApplication     : The following 1 profile is active: "mysql"
2022-12-07 21:03:35.657  INFO 1 --- [           main] .s.d.r.c.RepositoryConfigurationDelegate : Bootstrapping Spring Data JPA repositories in DEFAULT mode.
2022-12-07 21:03:35.714  INFO 1 --- [           main] .s.d.r.c.RepositoryConfigurationDelegate : Finished Spring Data repository scanning in 48 ms. Found 2 JPA repository interfaces.
2022-12-07 21:03:36.422  INFO 1 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port(s): 8080 (http)
2022-12-07 21:03:36.431  INFO 1 --- [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2022-12-07 21:03:36.431  INFO 1 --- [           main] org.apache.catalina.core.StandardEngine  : Starting Servlet engine: [Apache Tomcat/9.0.65]
2022-12-07 21:03:36.506  INFO 1 --- [           main] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
2022-12-07 21:03:36.506  INFO 1 --- [           main] w.s.c.ServletWebServerApplicationContext : Root WebApplicationContext: initialization completed in 1881 ms
2022-12-07 21:03:37.029  INFO 1 --- [           main] org.ehcache.core.EhcacheManager          : Cache 'vets' created in EhcacheManager.
2022-12-07 21:03:37.040  INFO 1 --- [           main] org.ehcache.jsr107.Eh107CacheManager     : Registering Ehcache MBean javax.cache:type=CacheStatistics,CacheManager=urn.X-ehcache.jsr107-default-config,Cache=vets
2022-12-07 21:03:37.060  INFO 1 --- [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Starting...
2022-12-07 21:03:37.506  INFO 1 --- [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Start completed.
2022-12-07 21:03:37.696  INFO 1 --- [           main] o.hibernate.jpa.internal.util.LogHelper  : HHH000204: Processing PersistenceUnitInfo [name: default]
2022-12-07 21:03:37.757  INFO 1 --- [           main] org.hibernate.Version                    : HHH000412: Hibernate ORM core version 5.6.10.Final
2022-12-07 21:03:37.943  INFO 1 --- [           main] o.hibernate.annotations.common.Version   : HCANN000001: Hibernate Commons Annotations {5.1.2.Final}
2022-12-07 21:03:38.102  INFO 1 --- [           main] org.hibernate.dialect.Dialect            : HHH000400: Using dialect: org.hibernate.dialect.MySQL57Dialect
2022-12-07 21:03:39.183  INFO 1 --- [           main] o.h.e.t.j.p.i.JtaPlatformInitiator       : HHH000490: Using JtaPlatform implementation: [org.hibernate.engine.transaction.jta.platform.internal.NoJtaPlatform]
2022-12-07 21:03:39.192  INFO 1 --- [           main] j.LocalContainerEntityManagerFactoryBean : Initialized JPA EntityManagerFactory for persistence unit 'default'
2022-12-07 21:03:40.378  INFO 1 --- [           main] o.s.b.a.e.web.EndpointLinksResolver      : Exposing 13 endpoint(s) beneath base path '/actuator'
2022-12-07 21:03:40.438  INFO 1 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 8080 (http) with context path ''
2022-12-07 21:03:40.455  INFO 1 --- [           main] o.s.s.petclinic.PetClinicApplication     : Started PetClinicApplication in 6.341 seconds (JVM running for 6.759)


```

Now we will connect to the WEB GUI and try to add 3 new Pet Owner and reload our MySQL container in order to check if our data is persistent.

Screenshot from Spring Boot App

[![Screenshot-2022-12-08-at-14-19-00.png](https://i.postimg.cc/jjxZhmTL/Screenshot-2022-12-08-at-14-19-00.png)](https://postimg.cc/VJhqf7d8)

Screenshot from MySQL Database

[![Screenshot-2022-12-08-at-14-16-42.png](https://i.postimg.cc/XqQzWLx2/Screenshot-2022-12-08-at-14-16-42.png)](https://postimg.cc/0KKfdpTm)

Screenshots proves that our data is persistent and data is correct in MySQL DB.

## Subtask 3

Now our docker images are ready and we can upload them to any Docker registery ,it could be any DockerHub ,ECR and etc. We will use DockerHub ,we will need login credentials for this task.

```
zhajili$ docker push zhajili/petclinic-app:1.9
The push refers to repository [docker.io/zhajili/petclinic-app]
825032214888: Layer already exists 
5de4e99d2bf8: Layer already exists 
379214cfd00d: Layer already exists 
3a87162a073c: Layer already exists 
f4a670ac65b6: Layer already exists 
1.9: digest: sha256:a8ca9a4ae0e37cd2936a64226cd487291c081a8c23d0e78b84158fd1cd93352d size: 1372

zhajili$ docker push zhajili/petclinic-mysql:1.2
The push refers to repository [docker.io/zhajili/petclinic-mysql]
3cf6625cd685: Layer already exists 
cf37dcaf3ed2: Layer already exists 
6c86ba6052de: Layer already exists 
879c643e585a: Layer already exists 
c54c00448185: Layer already exists 
05eecf3be4fb: Layer already exists 
b5505228b682: Layer already exists 
2edbf91f443b: Layer already exists 
bc48ce258cb7: Layer already exists 
7adcfa30d264: Layer already exists 
a315c22b0b2f: Layer already exists 
e50a0c8c34c9: Layer already exists 
1.2: digest: sha256:58b9615fb1b24c1ab2efe264e666deef88b0642d76cb9c09e7690f607de1b16f size: 2825

```
Let's check from DockerHub

[![Screenshot-2022-12-08-at-14-24-39.png](https://i.postimg.cc/g2ZnT2Y7/Screenshot-2022-12-08-at-14-24-39.png)](https://postimg.cc/68BW7w4V)

We can see that we have our docker images with correct tag and they are already pulled 3 times.

## Subtask 4

Now we will need to build all previous tasks via CI tool Jenkins ,our Jenkins is already preconfigured and ready to use. We will have 2 different Jenkins Job which will build and upload docker container to the ECR and DockerHub.









