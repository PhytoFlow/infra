# PythoFlow - Cloud Infrastructure

### Estrutura de Pastas e Comentários

A seguir, está a estrutura de pastas do projeto PythoFlow IoT Irrigation System, com comentários explicativos para cada parte:

```
.
├── AmazonRootCA1.pem                 # Certificado raiz da Amazon para autenticação
├── credentials                       # Diretório para credenciais de acesso
├── .gitignore                        # Arquivos e diretórios a serem ignorados pelo Git
├── irrigation-compute                # Credenciais do serviço de computação
│   └── ...                           # Certificados e chaves para o serviço de computação
├── irrigation-gateway-*              # Credenciais para gateways de irrigação
│   └── ...                           # Certificados e chaves para cada gateway
├── lambda_functions                  # Funções Lambda do projeto
│   └── aggregate                     # Função de agregação de dados
│       ├── Dockerfile                # Configuração de contêiner Docker
│       ├── index.py                  # Código-fonte da função Lambda
│       ├── publish_ecr.sh            # Script de publicação no ECR
│       └── requirements.txt          # Dependências do Python
├── modules                           # Módulos Terraform
│   ├── compute                       # Módulo de recursos de computação
│   └── iot                           # Módulo de recursos IoT
├── .terraform                        # Arquivos de estado e cache do Terraform
├── .vscode                           # Configurações do Visual Studio Code
└── outros arquivos de configuração   # Arquivos de configuração do projeto
```

## Visão Geral

PythoFlow é uma solução em nuvem completa IoT para um sistema de irrigação. O projeto utiliza Terraform para implantar uma infraestrutura abrangente que inclui dispositivos IoT, agregação de dados e arquitetura de rede segura na AWS.

## Componentes da Arquitetura

### Dispositivos IoT

- Gateways ESP32 como dispositivos IoT;
- Instância única consumidora de dados IoT para processamento

### Redes

- VPC com sub-redes públicas e privadas
- Gateway de internet e tabelas de roteamento
- Balanceador de Carga de Rede (NLB) para comunicação MQTT
- Pontos de extremidade da VPC para S3 e IoT Core

### Armazenamento de Dados e Processamento

- Bucket S3 para dados brutos e agregados
- Função Lambda AWS para agregação de dados
- AWS Glue para catalogação e varredura de dados

### Segurança

- Políticas IoT para comunicação de dispositivos
- Secrets Manager para armazenar credenciais de dispositivo

## Pré-requisitos

Antes da implantação, certifique-se de ter:

- AWS CLI instalado e configurado
- Terraform instalado
- Credenciais da AWS com acesso a:
  - IAM
  - IoT
  - S3
  - Lambda
  - Docker (para implantação de função Lambda)

## Configuração

### Variáveis de Ambiente

Crie um arquivo `terraform.tfvars` com as seguintes variáveis:

```hcl
environment      = "dev"
iot_vpc_cidr     = "10.0.0.0/16"
private_subnet_cidrs = ["10.0.128.0/24", "10.0.129.0/24"]
aws_region       = "us-west-2"
number_of_gateways = 2
compute_sg_id    = "sg-0123456789abcdef0"
compute_private_rt_id = "rtb-0123456789abcdef0"
compute_vpc_cidr_block = "10.1.0.0/16"
compute_vpc_id   = "vpc-0123456789abcdef0"
```

Também será necessário criar um arquivo `credentials` com profile 'default' contendo as credenciais da AWS, tipicamente:

```
[default]
aws_access_key_id=
aws_secret_access_key=
aws_session_token=
```

## Implantação

A partir da pasta raiz:

### Inicializar Terraform

```bash
terraform init
```

### Planejar Infraestrutura

```bash
terraform plan
```

### Aplicar Infraestrutura

```bash
terraform apply
```

## Implantação da Função Lambda

### Configurar AWS CLI

Você pode criar um perfil chamado `academy` em `~/.aws/credentials` e fazer:

```bash
aws configure --profile academy
```

Ou modificar o conteúdo de `publish_ecr.sh` para usar suas credenciais temporárias da AWS.

### Configuração do Docker

Faça login na ECR:

```bash
aws ecr get-login-password --profile academy | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<region>.amazonaws.com
```

### Construir e Publicar Imagem Docker

Navegue até o diretório da função Lambda:

```bash
cd lambda_functions/aggregate
docker build -t <aws_account_id>.dkr.ecr.<region>.amazonaws.com/iot-data-aggregation-lambda:latest .
docker push <aws_account_id>.dkr.ecr.<region>.amazonaws.com/iot-data-aggregation-lambda:latest
```

Ou use o script fornecido:

```bash
./publish_ecr.sh
```

## Saídas

Após a implantação, o Terraform fornecerá saídas:
- ID e CIDR da VPC IoT
- Ponta de comunicação MQTT
- ID da conexão de peering da VPC
- Nome do bucket S3
- Comandos da AWS CLI para recuperar credenciais de dispositivo

## Configuração de Comunicação MQTT

### Estrutura de Tópicos MQTT

O sistema PythoFlow IoT Irrigation usa uma estrutura hierárquica de tópicos MQTT para comunicação:

#### Tópicos de Dados de Sensor

- `irrigation/sensors/+/data`: Publicar dados de sensor
  - `+` representa identificadores individuais de sensor
  - Usado por dispositivos de gateway para enviar leituras de sensor

#### Tópicos de Gateway

- `irrigation/gateway/status`: Atualizações de status do dispositivo gateway

#### Tópicos de Controle

- `irrigation/control/+/command`: Comandos de controle de dispositivo
  - `+` permite alvo específico de dispositivo ou grupo

#### Tópicos do Sistema

- `irrigation/system/updates`: Atualizações e configurações de sistema
- `irrigation/errors`: Relatórios de erros
- `irrigation/diagnostics`: Informações de diagnóstico

### Recuperação de Credenciais do Dispositivo

Após a implantação, recupere as credenciais do dispositivo usando os comandos de saída:

#### Credenciais do Gateway

Para isso, você deve executar os comandos de saída do terraform, respectivamente à seção do gateway. Isso gerará as chaves privadas, certificados e o nome do cliente (thing_name).

#### Credenciais do Serviço de Computação

O mesmo que o gateway, mas para o serviço de computação.

### Autenticação MQTT

Os dispositivos autenticam usando:

- Certificados X.509
- Nome do dispositivo IoT, ou client ID (`thing_name.txt`)
- Políticas do AWS IoT Core

### Políticas de Permissões

#### Política do Dispositivo Gateway

Permissões incluem:

- Conectar ao AWS IoT Core
- Publicar em:
  - Tópicos de dados de sensor
  - Tópicos de status do gateway
  - Tópicos de erro e diagnóstico
- Assinar e receber tópicos de controle e atualizações do sistema

#### Política do Serviço de Computação

Permissões incluem:

- Conectar ao AWS IoT Core
- Assinar e receber:
  - Tópicos de dados de sensor
  - Tópicos de status do gateway
  - Tópicos de erro e diagnóstico
- Publicar comandos de controle e tópicos de atualização do sistema

### Fluxo de Comunicação MQTT Exemplo

1. Conexão do Dispositivo Gateway
   - Conectar usando certificado atribuído
   - Publicar dados de sensor em `irrigation/sensors/{sensor_id}/data`
   - Enviar atualizações de status para `irrigation/gateway/status`

2. Serviço de Computação
   - Assinar tópicos de dados de sensor
   - Processar dados recebidos
   - Publicar comandos de controle em `irrigation/control/{device_id}/command`
   - Enviar atualizações de sistema para `irrigation/system/updates`

### Solução de Problemas de Conexão MQTT

- Verificar caminhos de certificado
- Verificar registro de dispositivo do AWS IoT Core
- Validar conectividade de rede
- Rever logs do CloudWatch para problemas de conexão

(... o resto do conteúdo anterior permanece o mesmo ...)

## Destruição

Para destruir todos os recursos implantados:

```bash
terraform destroy
```

Confirme a destruição digitando `yes` quando solicitado.

## Notas Importantes

### Segurança e Configuração

- Verifique IDs de grupos de segurança e configurações de peering da VPC
- Todos os recursos são criados na região AWS especificada
- Sempre destrua os recursos quando não forem mais necessários para evitar custos desnecessários

### Variáveis de Ambiente

- `SOURCE_BUCKET`
- `SOURCE_PREFIX`
- `DEST_BUCKET`
- `DEST_PREFIX`
- `INTERVAL_MINUTES`
- `GLUE_DATABASE`

## Monitoramento e Solução de Problemas

- Configure os Logs do CloudWatch para a função Lambda
- Ajuste as configurações de memória e tempo limite da função Lambda conforme necessário
