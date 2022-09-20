# Getting started environment

Levantamiento de entorno CI-CD a través de docker compose.

## Requisitos:
- Maven 3.6.3
- Jenkins 2.332.1

## Herramientas utilizadas:
- Docker desktop 20.10.14
- Minikube v1.25.2
- Kubectl v4.5.4

## Estructura de archivos:
- <b>docker-compose.yml:</b>: definición de imágenes a utilizar para los componentes utilizados en el entorno de trabajo.
- <b>jenkins-account.yml:</b>: Recurso kubernetes para crear usuario que desplegará componentes.
- <b>docker-secret.yml:</b>: Recurso kubernetes para crear acceso a container registry.
- <b>Jenkinsfile.yml:</b> Definición de pipeline jenkins que utilizará los recursos configurados.
- <b>entrypoint.sh:</b> componentes a instalar en el contenedor jenkins al momento de levantarlo (maven, docker client, trivy)
- <b>html.tpl:</b> template html para reporte de vulnerabilidades generado por trivy.

## Instrucciones de uso
- instalar docker-desktop y kubectl
- Situarse en el directorio del proyecto y ejecutar docker compose mediante:
```
docker-compose up -d
```

Posteriormente es preciso realizar las conexiones respectivas a cada componente que será utilizado en el ciclo CI-CD. Se detallará el proceso a continuación.

### Docker
- Agregar contenedor jenkins a red de minikube mediante el siguiente comando:
```
docker network connect <network> <container>
```
<network> Equivale al nombre de la red creado por defecto para minikube, <container> equivale al nombre del contenedor donde se necuentra instalado jenkins.


### Jenkins
- Una vez instalado es necesario configurar los siguientes plugins en jenkins
  - SonarQube Scanner for Jenkins
  - Kubernetes plugin
  - JUnit Plugin: este plugin no esta disponible desde el buscador. Se debe descargar e instalar. Se encuentra disponible en la siguiente url: [JUnit plugin](https://plugins.jenkins.io/junit/)
  - Slack notification plugin.

### SonarQube
- Obtener token desde el menú <b>administration > security</b>
- Seleccionar usuario y copiar token.
- Dirigirse a jenkins a menú <b>panel de control > credentials > system > global credentials > add credentials </b>
- Crear credencial en la que el campo kind sea de tipo <b>text</b>
- Agregar credencial. <br /><br />
  ![Crendetials sonarqube](./img/credentials-sonarqube.png?raw=true "Credentials")<br /><br />
- Configurar sonarqube en el siguiente menú <b>administrar lenkins > configurar el sistema </b> <br />
  <br />![Global configurations sonarqube](./img/configuracion-sonarqube.png?raw=true "Configuration sonarqube") <br /><br />
- Configurar sonarqube en el siguiente menú <b>administrar lenkins > Global tool configuration </b> <br />
  <br />![Configuración sonarqube](./img/global-configuration-sonarqube.png?raw=true "Global configurations sonarqube")<br /><br />

### Nexus
- Crear repositorio docker de tipo hosted.
- seleccionar conector http
- seleccionar <b>Enable docker V1 API</b>
- Confirmar.<br /> <br />![Add repository nexus](./img/nexus-create-repository.png?raw=true "Add repository nexus")<br /><br />
- Dirigirse a jenkins a menú <b>panel de control > credentials > system > global credentials > add credentials </b>
- Crear credencial en la que el campo kind sea de tipo <b>Username with password</b>
- Agregar credencial. <br /><br />
- Agregar credenciales nexus.<br /> <br />![Credentials nexus](./img/nexus-credentials.png?raw=true "Credentials nexus")<br /><br />
<b>Observación : </b>La configuración se realiza en el pipeline incorporado en este proyecto (JenkinsFile.yml)

- Verificar la IP de la máquina cliente. a través del siguiente comando.
```
wsl -d docker-desktop
ifconfig
```
- Se debe activar la configuración para autenticación insegura, en la que se debe incorporar la ip obtenida en el punto anterior. Para esto se debe modificar la siguiente opción en docker-desktop. <br /><br />
  ![Docker insecure registry](./img/docker-insecure-registry.png?raw=true "Docker insecure registry")<br /><br />
- Reiniciar el servicio.
- Mediante el siguiente comando comprobar que el registro se agrego con éxito:
```
docker info
```
![Docker insecure registry](./img/docker-info-insecure-registry.png?raw=true "Docker info insecure registry")<br /><br />


### K8s
- Iniciar minikube en modo inseguro mediante el siguiente comando:
```
  minikube start --insecure-registry "172.22.119.181:8000"
```
- Obtener token de usuario a traves del siguiente comando:
- Crear usuario mediante el script <b>jenkins-account.yml</b> el cual contiene la configuración del usuario que se conectara a kubernetes, mediante el siguiente comando:
<b>Observación:</b> La razón por la que se utiliza el modo inseguro se debe a que se está trabajando con una versión local de nexus.
```
kubectl apply -f jenkins-account.yanl
```
- obtener id de secret asociado al nuevo usuario a través del siguiente comando.
```
kubectl serviceaccount jenkins -o yaml
```
![Kubernetes service account secret](./img/kubernetes-service-account-secret.png?raw=true "Kubernetes account secret")<br /><br />
En este caso corresponde a el valor <b>jenkins-token-pm5dp</b>.
- Desplegar contenido de secret mediante el siguiente comando utilizando el id obtenido en el punto anterior.
```
kubectl describe secrets/jenkins-token-pm5dp
```
Copiar el contenido del token y pegarlo al crear la nueva credencial en jenkins, en la cual su campo kind debe ser de tipo <b>text</b><br /><br />
![Kubernetes credentials](./img/kubernetes-credentials.png?raw=true "kubernetes credentials")<br /><br />
- Configurar plugin. Para esto es necesario obtener certificado de kubernetes mediante el siguiente comando:
```
kubectl config view
```
![Kubernetes certificate](./img/kubernetes-certificate.png?raw=true "kubernetes certificate")<br /><br />

- Acceder al siguiente menú <b>administrar lenkins > configurar el sistema > apartado cloud </b> <br />
- Ingresar contenido según lo indicado a continuación: <br></br>
![Kubernetes certificate](./img/kubernetes-configuration-certificate.png?raw=true "kubernetes certificate")<br /><br />
<b>Observación : </b> la url de kubernetes debe coincidir con la ip generada para minikube, la cual hay que considerar cambia de puerto cada vez que se detiene el servicio. Para obtener dicha IP se debe ejecutar el siguiente comando:
```
minikube ssh
#ya dentro de la instancia ejecutar un ping segun lo señalado
ping host.minikube.internal
```
- Esto desplegará lo siguiente:<br /><br />
 ![Kubernetes URL](./img/kubernetes-url.png?raw=true "kubernetes URL")<br /><br />
- La IP obtenida anteriormente debe ser utilizada en el pipelina para ejecutar los recursos que corresponda.
- Para conectar kubernetes con nexus. Para esto es necesario obtener el contenido del <b>config.json</b> tal como se señala a continuación:
```
minikube ssh
docker login <ip-container-registry>:<port> 
#acceder a contenido config.json
cat ./docker/config.json
```
- Obtener archivo y codificar a base64, luego pegar el contenido en el archivo <b> docker-secret.yaml</b><br /> <br />
![Kubernetes docker secret](./img/kubernetes-docker-secret.png?raw=true "kubernetes docker secret")<br /><br />

### Slack
- acceder a cuenta y obtener token [api jenkins](https://api.slack.com/) 
- Si la cuenta no existe crearla.
- Copiar token generado
- La aplicación debe contener los siguientes permisos: <br /><br />
![slack permissions](./img/slack-permissions.png?raw=true "slack permissions")<br /><br />
- Se debe crear un canal previamente en slack en el que llegarán las notificaciones
- Agregar aplicación jenkins en slack <br /><br />
![slack application](./img/slack-application.png?raw=true "slack application")<br /><br />
- Asignar aplicación a canal <br /><br />
![slack application channel](./img/slack-application-channel.png?raw=true "slack application channel" )<br /><br />
- Dirigirse a jenkins a menú <b>panel de control > credentials > system > global credentials > add credentials </b>
- Crear credencial en la que el campo kind sea de tipo <b>text</b>
- Agregar credencial. <br /><br />  
![slack credentials](./img/slack-credentials.png?raw=true "slack credentials" )<br /><br />
- Acceder al siguiente menú <b>administrar lenkins > configurar el sistema > apartado slack </b> <br /><br />
![slack configuration](./img/slack-credentials.png?raw=true "slack configuration" )<br /><br />

## Referencias
- [Jenkins documentation](https://www.jenkins.io/doc/)
- [Trivy documentation](https://aquasecurity.github.io/trivy/v0.18.3/)
- [Kubernetes documentation](https://kubernetes.io/es/docs/home/)
- [Minikube documentation](https://minikube.sigs.k8s.io/docs/)
- [Docker documentation](https://docs.docker.com/)
- [SonarQube documentationm](https://docs.sonarqube.org/latest/)
- [Nexus documentation](https://help.sonatype.com/repomanager3)


