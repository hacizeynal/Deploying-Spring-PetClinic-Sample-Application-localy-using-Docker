
FROM mysql:5.7

ENV MYSQL_ROOT_PASSWORD=1234
COPY docker_mysql/user.sql /docker-entrypoint-initdb.d
EXPOSE 3306

# docker run -d --network petclinic-net -v /Users/zhajili/Documents/dockerVolumes/mysql-data:/var/lib/mysql -p 3306:3306 --name petclinic_database zhajili/petclinic-mysql:1.2 
