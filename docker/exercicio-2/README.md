# Exercício 2 — Docker Compose com API e Banco de Dados

## Visão geral

Aplicação composta por uma API REST desenvolvida em Python com FastAPI e um banco de dados PostgreSQL, executados em contêineres independentes e integrados pelo Docker Compose.

A solução permite cadastrar e consultar tarefas, demonstrando a comunicação entre serviços, o uso de variáveis de ambiente e a persistência de dados por meio de um volume Docker.

## Arquitetura

```text
Cliente HTTP
     |
     | localhost:8000
     v
API (FastAPI / Uvicorn)
     |
     | db:5432
     v
PostgreSQL
     |
     v
Volume postgres_data
```

A API acessa o banco pelo hostname `db`, utilizando a rede interna criada pelo Docker Compose. A porta do PostgreSQL não é publicada no host, mantendo a comunicação com o banco restrita à rede dos serviços.

Os dados são armazenados em um volume nomeado, preservando os registros mesmo após a remoção e recriação dos contêineres.

## Tecnologias

- **Python 3.12:** linguagem utilizada na API.
- **FastAPI:** implementação dos endpoints HTTP.
- **Uvicorn:** servidor ASGI da aplicação.
- **Psycopg:** conexão e operações SQL no PostgreSQL.
- **PostgreSQL 16:** armazenamento relacional dos registros.
- **Docker:** construção e execução dos contêineres.
- **Docker Compose:** configuração e integração dos serviços.

As imagens base utilizadas são `python:3.12-slim` e `postgres:16-alpine`.

## Estrutura do projeto

```text
docker/exercicio-2/
├── app.py
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
├── .dockerignore
├── .gitignore
├── .env.example
└── README.md
```

| Arquivo | Responsabilidade |
|---|---|
| `app.py` | Conexão com o banco, inicialização da tabela e endpoints |
| `requirements.txt` | Dependências Python com versões fixadas |
| `Dockerfile` | Construção da imagem da API |
| `docker-compose.yml` | Serviços, variáveis, healthchecks e persistência |
| `.env.example` | Exemplo das variáveis de configuração |
| `.dockerignore` | Exclusão de arquivos desnecessários do contexto de build |
| `.gitignore` | Exclusão de arquivos locais e sensíveis do versionamento |
| `README.md` | Documentação de configuração, execução e validação |

## Configuração

### Pré-requisitos

- Docker Engine em execução.
- Docker Compose v2 ou superior.
- Porta `8000` disponível.
- Acesso à internet para obtenção das imagens e dependências.
- Python 3, Bash e `curl` para execução dos testes documentados.

### Variáveis de ambiente

A aplicação utiliza as seguintes variáveis:

| Variável | Finalidade |
|---|---|
| `DB_HOST` | Hostname do banco, configurado como `db` |
| `DB_USER` | Usuário de acesso ao PostgreSQL |
| `DB_PASS` | Senha de acesso ao PostgreSQL |
| `DB_NAME` | Nome do banco de dados |

O Compose utiliza essas variáveis para configurar a API e inicializar o PostgreSQL, por meio dos parâmetros `POSTGRES_USER`, `POSTGRES_PASSWORD` e `POSTGRES_DB`.

O arquivo `.env.example` contém valores demonstrativos. O arquivo `.env` é utilizado localmente e não deve ser versionado.

**Observação:** as variáveis de inicialização do PostgreSQL são aplicadas na criação de um banco com volume vazio. Alterar posteriormente o `.env` não modifica automaticamente usuários, senhas ou bancos já existentes no volume.

## Execução

A partir da raiz do repositório, acesse o diretório do exercício:

```bash
cd docker/exercicio-2
```

Crie o arquivo local de configuração, caso ainda não exista:

```bash
if [ ! -f .env ]; then
    cp .env.example .env
fi
```

Valide a configuração, construa a imagem e inicie os serviços:

```bash
docker compose config --quiet
docker compose build
docker compose up -d --wait --wait-timeout 120
docker compose ps
```

A opção `--wait` aguarda os serviços atingirem os estados esperados de execução e saúde.

O Compose configura a dependência da API em relação ao PostgreSQL utilizando `depends_on` com a condição `service_healthy`.

O banco possui healthcheck de disponibilidade. A API também possui healthcheck, que consulta `/tasks` e verifica indiretamente o acesso ao banco de dados.

**Permissões:** caso o usuário não possua acesso direto ao Docker Engine, os comandos Docker podem ser executados com `sudo`, conforme as permissões do ambiente.

Para consultar os logs:

```bash
docker compose logs --no-color --tail=100 api db
```

## Endpoints da API

A aplicação disponibiliza os seguintes endpoints:

| Método | Endpoint | Descrição |
|---|---|---|
| `POST` | `/tasks` | Cadastra uma tarefa no banco |
| `GET` | `/tasks` | Consulta as tarefas cadastradas |

### Cadastrar uma tarefa

```bash
curl --fail-with-body -i \
  -X POST http://localhost:8000/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Estudar Docker"}'
```

Resposta esperada para um cadastro bem-sucedido:

```json
{
  "id": 1,
  "title": "Estudar Docker"
}
```

**Status HTTP:** `201 Created`.

O ID é gerado pelo banco e pode variar conforme os registros existentes.

### Consultar tarefas

```bash
curl --fail-with-body -i \
  http://localhost:8000/tasks
```

**Status HTTP:** `200 OK`.

A resposta contém uma lista JSON com as tarefas cadastradas, ordenadas por ID. Quando não há registros, retorna uma lista vazia.

O campo `title` é obrigatório, aceita de 1 a 200 caracteres após a remoção de espaços nas extremidades e não permite valores compostos apenas por espaços. Entradas inválidas retornam HTTP `422`.

A documentação interativa da API está disponível em:

http://localhost:8000/docs

## Validação e persistência

### Testes funcionais realizados

A implementação foi validada por meio da execução dos serviços e de requisições HTTP à API.

| Verificação | Resultado |
|---|---|
| Construção da imagem da API | Concluída |
| Inicialização do PostgreSQL | Healthy |
| Inicialização da API | Healthy |
| Cadastro por `POST /tasks` | HTTP 201 |
| Consulta por `GET /tasks` | HTTP 200 |
| Remoção e recriação dos contêineres | Concluída |
| Preservação do volume PostgreSQL | Confirmada |
| Consulta dos dados após recriação | Registro preservado |

Durante os testes, foi cadastrada a tarefa `Teste de persistencia Docker`, com ID `1`. Após a execução de `docker compose down` e a recriação dos serviços, o registro permaneceu disponível na API.

### Reproduzir o teste de persistência

Com os serviços em execução, cadastre uma tarefa de teste e armazene seu ID na sessão atual do terminal:

```bash
TASK_ID=$(python3 - <<'PY'
import json
from urllib.request import Request, urlopen

request = Request(
    "http://127.0.0.1:8000/tasks",
    data=json.dumps({
        "title": "Validar persistencia do Orion"
    }).encode(),
    headers={"Content-Type": "application/json"},
    method="POST",
)

with urlopen(request, timeout=10) as response:
    assert response.status == 201
    task = json.load(response)
    assert task["title"] == "Validar persistencia do Orion"
    assert isinstance(task["id"], int)
    print(task["id"])
PY
)

export TASK_ID
echo "Tarefa cadastrada: $TASK_ID"
```

Defina uma função para confirmar que o registro continua disponível:

```bash
consultar_tarefa() {
    python3 - <<'PY'
import json
import os
from urllib.request import urlopen

task_id = int(os.environ["TASK_ID"])

with urlopen("http://127.0.0.1:8000/tasks", timeout=10) as response:
    assert response.status == 200
    tasks = json.load(response)

assert any(
    task["id"] == task_id
    and task["title"] == "Validar persistencia do Orion"
    for task in tasks
), tasks

print(f"OK: tarefa {task_id} encontrada no banco")
PY
}
```

Execute a primeira consulta:

```bash
consultar_tarefa
```

Remova e recrie os contêineres sem apagar os volumes:

```bash
docker compose down
docker compose up -d --wait --wait-timeout 120
```

Execute novamente a função, na mesma sessão do terminal:

```bash
consultar_tarefa
```

A confirmação da mesma tarefa, identificada pelo mesmo ID, demonstra que os dados permaneceram armazenados após a recriação dos contêineres.

### Encerramento

Para encerrar os serviços preservando os dados:

```bash
docker compose down
```

Para consultar o volume persistente:

```bash
docker volume ls \
  --filter label=com.docker.compose.project=exercicio-2
```

O Compose utiliza normalmente o nome `exercicio-2_postgres_data` para o volume declarado como `postgres_data`.

**Importante:** não utilize `docker compose down -v` durante o teste de persistência, pois essa opção remove os volumes gerenciados pelo projeto Compose.

## Decisões técnicas

A implementação prioriza uma estrutura simples, reproduzível e adequada aos requisitos do exercício.

- **Imagem da API:** utilização de `python:3.12-slim`, com instalação das dependências antes da cópia do código da aplicação, permitindo reutilização da camada de dependências em builds posteriores.
- **Banco de dados:** PostgreSQL 16 Alpine, com volume nomeado montado em `/var/lib/postgresql/data`.
- **Comunicação:** resolução interna do hostname `db` pela rede do Docker Compose, sem publicação da porta do banco no host.
- **Persistência:** armazenamento dos registros fora do ciclo de vida dos contêineres.
- **Inicialização:** uso de healthchecks e `depends_on` para coordenar a disponibilidade dos serviços.
- **Acesso aos dados:** Psycopg com consultas parametrizadas e gerenciamento das conexões e transações por requisição.
- **Estrutura do banco:** criação da tabela com `CREATE TABLE IF NOT EXISTS`, preservando registros previamente armazenados.
- **Validação:** Pydantic para validação das entradas e definição dos formatos de resposta.
- **Escopo:** utilização de SQL direto, sem ORM ou ferramenta de migração, considerando a simplicidade da aplicação.

## Referências

- [Docker Compose — Startup order](https://docs.docker.com/compose/how-tos/startup-order/)
- [Docker Hub — PostgreSQL](https://hub.docker.com/_/postgres)
- [FastAPI — Lifespan Events](https://fastapi.tiangolo.com/advanced/events/)
- [Psycopg — Basic Usage](https://www.psycopg.org/psycopg3/docs/basic/usage.html)