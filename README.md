# Exercícios — Orion Bootcamp 2026

Repositório de atividades práticas da trilha de **Engenharia de IA** do Orion Bootcamp 2026, com implementações em Docker, PostgreSQL e MongoDB.

## Atividades

### Docker

| Exercício | Escopo | Acesso local |
|---|---|---|
| [Exercício 1](docker/exercicio-1/README.md) | Aplicação HTTP com Flask, Dockerfile e Docker Compose | `localhost:3000` |
| [Exercício 2](docker/exercicio-2/README.md) | API FastAPI, PostgreSQL e persistência | `localhost:8000` |
| [Exercício 3](docker/exercicio-3/README.md) | Ambientes DEV/PROD, Dockerfile multi-stage e Compose | `localhost:8001` (DEV) e `localhost:8002` (PROD) |
| [Desafio Extra](docker/exercicio-extra/README.md) | API, PostgreSQL e Adminer | `localhost:8003` (API) e `localhost:8083` (Adminer) |

Cada exercício possui implementação e documentação próprias em `docker/`.

### Banco de Dados

| Exercício | Escopo | Implementação |
|---|---|---|
| 1 | PostgreSQL: tabelas, chaves primária e estrangeira, inserções e consultas | [SQL básico](banco-de-dados/exercicio-1/exercicio-1.sql) |
| 2 | PostgreSQL: `INNER JOIN`, `WHERE`, `UPDATE` e `LEFT JOIN` | [Consultas e atualização](banco-de-dados/exercicio-2/exercicio-2.sql) |
| 3 | MongoDB: coleção de posts, inserção e schema flexível | [Documentos e consultas](banco-de-dados/exercicio-3/exercicio-3.js) |
| 4 | MongoDB: comentários aninhados, filtros e ambientes Docker DEV/PROD | [Atualização e filtros](banco-de-dados/exercicio-4/exercicio-4.js) |

A [documentação de Banco de Dados](banco-de-dados/README.md) reúne arquitetura, configuração, execução, validações e [evidências](banco-de-dados/README.md).

## Estrutura

```text
exercicios-orion/
├── docker/
│   ├── exercicio-1/
│   ├── exercicio-2/
│   ├── exercicio-3/
│   └── exercicio-extra/
├── banco-de-dados/
│   ├── exercicio-1/
│   ├── exercicio-2/
│   ├── exercicio-3/
│   ├── exercicio-4/
│   ├── evidencias/
│   ├── docker-compose.yml
│   ├── docker-compose.dev.yml
│   ├── docker-compose.prod.yml
│   ├── Dockerfile.dev
│   ├── Dockerfile.prod
│   └── README.md
└── README.md
```

As capturas e os registros de execução de Banco de Dados estão distribuídos entre `banco-de-dados/evidencias/` e as subpastas `evidencias/` de cada exercício.

## Tecnologias

- Docker Engine e Docker Compose
- Python, Flask e FastAPI
- PostgreSQL 16
- MongoDB e `mongosh`
- Adminer
- Git e GitHub

## Execução

**Pré-requisitos:** Docker Engine em execução, Docker Compose disponível e portas locais correspondentes livres. Dependendo das permissões do sistema, os comandos Docker podem exigir `sudo`.

Na atividade Docker, cada exercício é executado a partir do seu diretório. Exemplo:

```bash
cd docker/exercicio-1
docker compose up -d --build
curl http://localhost:3000
docker compose down
```

Os demais procedimentos e as configurações específicas estão nos respectivos READMEs.

Em Banco de Dados, os ambientes original, DEV e PROD usam configurações distintas. O Compose original expõe PostgreSQL em `5432` e MongoDB em `27017`; DEV utiliza `5433`/`27018`, e PROD utiliza `5434`/`27019`. Os ambientes DEV e PROD possuem redes e volumes próprios.

```bash
cd banco-de-dados
test -f .env || cp .env.example .env
```

Após configurar as credenciais locais em `.env`, os comandos de inicialização e execução estão disponíveis no [README da atividade](banco-de-dados/README.md).

## Validação e evidências

Os exercícios de Banco de Dados foram executados com sucesso no ambiente original e nos ambientes DEV e PROD. As validações incluem criação e consulta de tabelas, `JOIN`, `UPDATE`, inserção e atualização de documentos MongoDB, filtros, construção das imagens e healthchecks.

A persistência no PROD foi confirmada após remover e recriar os contêineres **sem excluir os volumes**: permaneceram quatro alunos no PostgreSQL e dois posts no MongoDB. As capturas correspondentes estão versionadas em `banco-de-dados/`.

O [registro técnico das validações](banco-de-dados/README.md) distingue os testes efetivamente executados de verificações adicionais não realizadas.

## Versionamento e configuração

As atividades são organizadas em branches e pull requests. Os arquivos `.env` locais são excluídos do versionamento; exemplos de configuração são mantidos em `.env.example`.
