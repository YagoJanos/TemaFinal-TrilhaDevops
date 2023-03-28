# Tema Final de Devops

## Preparação

1. Clone esse repositório.

2. Crie uma keypair no console da AWS.

3. Instale o AWS CLI e digite no terminal ``` aws configue ```, digite suas credenciais e escolha a região east-1.

4. Nos arquivos Packer (.pkr.hcl), preencha o campo profile com o nome de sua credencial aws presente em ~/.aws/credentials e preencha ssh_keypair_name e ssh_private_key_file com o nome da sua keypair e a localização dela respectivamente.

5. Nos arquivos Terraform (.tf), preencha o campo **"default"** no bloco **variable "SECURITY_GROUP"** com a id do seu security group, exceto no arquivo do network load balancer pois o mesmo não se associa a um security group.

6. Nos arquivos Terraform (.tf), preencha o campo **"keyname"** nos blocos **"aws_instance"** e **"aws_launch_configuration"** com a sua key da AWS (arquivo .pem).

7. Certifique-se de ter o Jenkins, o Packer e o Terraform instalados em sua máquina.

8. Entre no Jenkins, vá em "Manage Jenkins" -> "Configure System" -> "Global Properties", marque "Environment variables" e adicione as seguintes variáveis:

* Name = AWS_CONFIG_FILE  |  Value = caminho absoluto até o seu arquivo config presente na pasta .aws

* Name = AWS_SHARED_CREDENTIALS_FILE  |  Value = caminho absoluto até o seu arquivo credentials presente na pasta .aws

* Name = PROJECT_PATH  |  Value = caminho absoluto até o repositório clonado

9. Crie Jobs no Jenkins:

* "Create a job" -> Digite o nome do job no campo "Enter an item name" -> clique em  "Pipeline -> Vá para a seção "Pipeline" -> Escolha "Pipeline Script from SCM"

* Em **SCM** escolha **"Git"**

* Em **Repository URL** você deve digitar: **https://github.com/YagoJanos/TemaFinal-TrilhaDevops.git**

* Em **Branch Specifier** você deve digitar **/\*main**

* Em **Script Path** você deverá colocar o caminho do Jenkinsfile para o job específico.

### A seguir, sugestões de nomes para os jobs e os caminhos respectivos de cada Jenkinsfile:


| Nome do Job                    | Caminho do Jenkinsfile                              |
| ------------------------------ | ----------------------------------------------------|
| Bake calculator AMI            | jenkins/bake/calc/Jenkinsfile                       |
| Bake Redis AMI                 | jenkins/bake/redis/Jenkinsfile                      |
| Bake ELK AMI                   | jenkins/bake/elk/Jenkinsfile                        |
| Deploy calculator instance     | jenkins/deploy/instance/calc/Jenkinsfile            |
| Deploy calculator LB           | jenkins/deploy/lb/calc/Jenkinsfile                  |
| Deploy Redis instance          | jenkins/deploy/instance/redis/Jenkinsfile           |
| Deploy Redis LB                | jenkins/deploy/lb/redis/Jenkinsfile                 |
| Deploy ELK instance            | jenkins/deploy/instance/elk/Jenkinsfile             |
| Destroy calculator instance    | jenkins/destroy/instance/calc/Jenkinsfile           |
| Destroy calculator LB          | jenkins/destroy/lb/calc/Jenkinsfile                 |
| Destroy Redis instance         | jenkins/destroy/instance/redis/Jenkinsfile          |
| Destroy Redis LB               | jenkins/destroy/lb/redis/Jenkinsfile                |
| Destroy ELK instance           | jenkins/destroy/instance/elk/Jenkinsfile            |


## Execução

1. Primeiro executo o job **Deploy Redis LB** para criar o ***Network Load Balancer*** do Redis.

2. Agora pegue o DNS obtido como output e insira no arquivo main.go no campo Addr mantendo a porta 6379:

```
redisClient = redis.NewClient(&redis.Options{
                Addr: "InsiraAqui:6379",
                DB:   0,
                DialTimeout: 1 \* time.Second,
                ReadTimeout: 5 \* time.Second,
                WriteTimeout: 1 \* time.Second,
        })
```


3. Execute o job para criar o ***Classic Load Balancer*** da calculadora: **Deploy calculator LB**. Esse dns será usado posteriormente para enviar requisições de cálculos para a calculadora.

4. Execute os jobs para fazer os bakes das imagens: **Bake calculator AMI, Bake Redis AMI, Bake ELK AMI.**

5. Execute o restanto dos jobs de Deploy.

6. Espere um tempo até o sistema estar pronto.

## Utilização

1. Para efetuar operações acesse:

| Operação      | URL                                             |
| ------------- | ----------------------------------------------- |
| Soma          | DNS-LoadBalancer-Calculadora:8080/1/+/2          |
| Subtração     | DNS-LoadBalancer-Calculadora:8080/3/-/2          |
| Divisão       | DNS-LoadBalancer-Calculadora:8080/4/div/2        |
| Multiplicação | DNS-LoadBalancer-Calculadora:8080/2/\*/4          |
| Histórico     | DNS-LoadBalancer-Calculadora:8080/history        |

2. Para acessar o Kibana acesse: ***IPV4-Instancia-ELK:5601***

## Funcionamento

Esse tema foi construído da seguinte forma:

### ***Calculadora***:

* A calculadora utiliza a biblioteca Gorilla Mux que fornece um roteador que é usado para criar rotas para manipular solicitações HTTP de entrada.

* Há um Autoscaling Group que garante que sempre haja uma instância da calculadora funcionando.

* Associado ao Autoscaling Group há um Classic Load Balancer que faz HealthCheck em **:8080/health**, uma rota implementada na calculadora.

* A calculadora foi configurada para registrar logs de operações e erros em um arquivo chamado **calculator.log** (que será enviado pelo Filebeat ao Elasticsearch).

* A calculadora conta com um cliente apm que envia tracing para um APM-Server, dessa forma contemplando o pilar de Tracing da Observabilidade.

* A calculadora foi configurada para registrar logs de operações e erros do cliente apm em um arquivo chamado **apm.log** (que será enviado pelo Filebeat ao Elasticsearch).

* A calculadora conta com um cliente redis que envia um registro de cada operação para o servidor Redis, sendo também capaz de recuperar o histórico das operações.

* A instância da calculadora conta com o Filebeat e com o Metricbeat que enviam respectivamente logs e métricas do sistema operacional e da aplicação da calculadora para o Elasticsearch, assim contemplando os outros dois pilares da observabilidade.

* Há um serviço do systemd chamado calculator.service que é responsável por manter a calculadora sempre funcionando após o boot da máquina EC2, reiniciando a aplicação sempre que houver falhas eventuais. Esse serviço também determina a variável de ambiente responsável por direcionar os dados do apm para o endereço correto do APM-Server.

* O Filebeat e o Metricbeat foram configurados para configurar automaticamente índices no Elasticsearch e dashboards no Kibana com o comando "filebeat setup" e "metricbeat setup" acompanhados de variáveis que determinam os endereços do Elasticsearch e do Kibana:
``` filebeat setup -E setup.kibana.host=http://172.31.16.8:5601 -E output.elasticsearch.hosts=["http://172.31.16.8:9200"] ```
``` metricbeat setup -E setup.kibana.host=http://172.31.16.8:5601 -E output.elasticsearch.hosts=["http://172.31.16.8:9200"] ```

Esses dois comandos são executados uma vez a cada 10 segundos até que sejam bem sucedidos pela primeira vez, depois nunca mais sendo executados até o fim do ciclo de vida da instância EC2. Isso é garantido por serviços do systemd chamados **metricbeat-setup.service** e **filebeat-setup.service** em conjunto com os bash scripts **metricbeat-setup.sh** e **filebeat-setup.sh**.

Obs: 172.31.16.8 é o ipv4 privado fixado para a instância do ELK.

### ***Redis***:

* **Importante**: A instância Redis foi configurada por meio do arquivo redis.conf para receber requisições de todos os hosts, por isso é importante que o security group dessa instância possua inbound rules permitindo requisições apenas do security group da calculadora. Há um malware na internet que fica ouvindo instâncias com a porta 6379 (porta do redis) abertas a fim de criar tarefas maliciosas no cron.

* O serviço do Redis foi habilitado para iniciar com o boot do sistema.

* O Redis foi configurado com logrotate diário em que são mantidos até 7 arquivos de log rotacionados, quando o oitavo arquivo é criado, o mais antigo é eliminado.

* A rotação não será executada caso o arquivo rotacionado estiver vazio.

* O arquivo rotacionado é comprimido com o programa gzip.

* Foi criado um servidor com o socat que escuta na rota 8081/redis-health para nos permitir checar a saúde do redis sem ter que instalar o Redis em nossa máquina local.

* Há um Autoscaling Group assegurando que sempre haja uma instância do Redis em execução.

* Há um Network Load Balancer associado ao Redis. A escolha do Network Load Balancer se deu pelo fato de outros tipos de load balancer não serem capazes de surportar o protocolo RESP utilizado pelo Redis.

### ***ELK***:

* Há um minikube executando em uma instância EC2.

* Um serviço foi criado para executar o cluster do minikube sempre que a instância der boot.

* O minikube executa um deployment do Kibana, um deployment do APM-Server e um statefulset do Elasticsearch.

* Nodeports e ClusterIPs foram criados para permitir a comunicação dos pods com o exterior e com outros pods.

* É criado um Persistent Volume para persistir os dados do Elasticsearch no armazenamento subjacente.

* Não há um Autoscaling Group para a instância EC2 em questão, pois a mesma contem um banco de dados.

* IPV4 privado da instância foi fixado pelo arquivo do terraform.

* O tráfego entre interfaces de Rede é habilitado nessa instância

* Regras do iptables foram criadas para direcionar o tráfego da instância para o minikube, uma vez que se encontra em uma interface de rede diferente por utilizar o driver do docker.
