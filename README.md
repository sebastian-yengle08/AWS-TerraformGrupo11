# AWS + Lambda Integration - Grupo 11

Procesador de fotos de perfil en AWS, desplegado con Terraform en tres entornos (DEV, QA y PROD). Un cliente sube una imagen y el sistema la recorta en círculo de 40x40 px y la guarda.

## Arquitectura

1. El cliente envía `POST /upload` a **API Gateway**.
2. API Gateway invoca a **upload-lambda**, que valida el archivo y lo guarda en **S3** en `uploads/`.
3. S3 notifica a una cola **SQS**, que dispara a **crop-lambda**.
4. **crop-lambda** lee el original, lo recorta a 40x40 con forma circular (PNG) y lo guarda en `processed/<nombre>_circular.png`.
5. Si un mensaje falla 3 veces, pasa a una **DLQ** y una alarma de **CloudWatch** avisa por correo (**SNS**).

Las Lambdas están en subredes privadas de una VPC y hablan con S3 y SQS por VPC Endpoints. La región es `us-east-1`.

## Estructura del repositorio

```
modules/
  network/     VPC, subredes, NAT, endpoints y security groups
  storage/     bucket S3 (cifrado, versionado, lifecycle)
  messaging/   SQS, DLQ, notificación de S3, SNS y alarma
  compute/     roles IAM, Lambdas y trigger de SQS
  api/         API Gateway HTTP API
envs/
  dev/  qa/  prod/    cada uno con su estado y sus valores (.tfvars)
src/
  upload-lambda/      código de la Lambda de subida
  crop-lambda/        código de la Lambda de recorte
```

Los tres entornos usan los mismos módulos y solo cambian sus valores:

| Entorno | CIDR de la VPC | Límite de peticiones |
|---|---|---|
| dev | 10.0.0.0/16 | 100 |
| qa | 10.1.0.0/16 | 1000 |
| prod | 10.2.0.0/16 | 10000 |

## Requisitos

- Terraform 1.5 o superior
- AWS CLI v2 con un profile llamado `customprofile` (`aws configure --profile customprofile`, región `us-east-1`)
- Node.js 20 y npm

## Desplegar un entorno

Los comandos son para PowerShell. Reemplaza `dev` por `qa` o `prod` según el entorno.

```powershell
# 1. Dependencias de las Lambdas (una vez)
cd src\upload-lambda
npm ci --omit=dev
cd ..\crop-lambda
npm ci --omit=dev --os=linux --cpu=x64
cd ..\..

# 2. Despliegue
cd envs\dev
terraform init
terraform apply "-var-file=dev.tfvars" -var "alarm_email=TU_CORREO"
```

## Probar

```powershell
$api = (terraform output -raw api_url).TrimEnd('/')
$bucket = terraform output -raw bucket_name
curl.exe -i -F "file=@C:\ruta\foto.png" "$api/upload"
```

Debe responder `HTTP 200` con un JSON que incluye la `key` (`uploads/<uuid>.png`). Pasados unos 30 segundos:

```powershell
aws s3 ls "s3://$bucket/uploads/" --profile customprofile --region us-east-1
aws s3 ls "s3://$bucket/processed/" --profile customprofile --region us-east-1
```

En `processed/` debe aparecer `<uuid>_circular.png`, un PNG de 40x40.

Respuestas posibles: `200` correcto, `400` sin archivo o formato inválido, `413` más de 4 MB, `415` tipo no permitido (solo JPG, PNG, GIF y WebP).

## Destruir

```powershell
terraform destroy "-var-file=dev.tfvars" -var "alarm_email=TU_CORREO"
```

Puede tardar hasta unos 20 minutos, porque las interfaces de red de las Lambdas tardan en liberarse. Para comprobar que no queda nada cobrando:

```powershell
aws ec2 describe-nat-gateways --region us-east-1 --profile customprofile --query "NatGateways[?State!='deleted'].[NatGatewayId,State]" --output text
aws ec2 describe-addresses --region us-east-1 --profile customprofile --query "Addresses[].[PublicIp,AllocationId]" --output text
aws ec2 describe-vpc-endpoints --region us-east-1 --profile customprofile --query "VpcEndpoints[].[VpcEndpointId,State]" --output text
```

Las tres deben salir vacías.

## Costos

Cobra por hora, aunque no se use: 2 NAT Gateways (~$0.045/h c/u), 2 Elastic IP (~$0.005/h c/u) y el endpoint de interfaz de SQS (~$0.01/h por zona, en 2 zonas). Son unos **$0.12/h por entorno**. El endpoint de S3 (Gateway) es gratis. Lambda, SQS, SNS, API Gateway, S3 y CloudWatch cobran por uso y, con el volumen de las pruebas, son centavos.

## Equipo y Pull Requests

| Integrante | Módulo | PR |
|---|---|---|
| Sebastián | network | #1 |
| Chars | base de entornos y storage | #2 |
| Said | messaging | #3 |
| Gabriel | api y upload-lambda | #4 |
| Yessica | compute y crop-lambda | #5 |

Cada módulo se desarrolló en su propia rama, con Pull Request y revisión cruzada de otro integrante.
