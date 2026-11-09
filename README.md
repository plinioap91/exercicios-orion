# Exercícios Docker — Orion Bootcamp 2026

Repositório de atividades práticas da trilha de **Engenharia de IA** do Orion Bootcamp 2026.

Os exercícios abordam a criação de imagens Docker, orquestração com Docker Compose, comunicação entre serviços, persistência de dados e configuração de ambientes de desenvolvimento e produção.

## Exercícios

| Exercício | Descrição | Acesso local |
|---|---|---|
| [Exercício 1](docker/exercicio-1/README.md) | Aplicação HTTP em Flask, Dockerfile e Docker Compose | `localhost:3000` |
| [Exercício 2](docker/exercicio-2/README.md) | API FastAPI com PostgreSQL e persistência de dados | `localhost:8000` |
| [Exercício 3](docker/exercicio-3/README.md) | Ambientes DEV e PROD com Dockerfile multi-stage e Compose | `localhost:8001` (DEV) e `localhost:8002` (PROD) |
| [Desafio Extra](docker/exercicio-extra/README.md) | Integração entre API, PostgreSQL e Adminer | `localhost:8003` (API) e `localhost:8083` (Adminer) |

## Estrutura do repositório

```text
exercicios-orion/
├── docker/
│   ├── exercicio-1/
│   ├── exercicio-2/
│   ├── exercicio-3/
│   └── exercicio-extra/
└── README.md
```

Cada diretório possui implementação independente e documentação específica com requisitos, comandos de execução, validação e encerramento.

## Tecnologias utilizadas

- Docker Engine e Docker Compose
- Python 3.12
- Flask e FastAPI
- PostgreSQL 16
- Adminer
- Git e GitHub

## Execução

**Pré-requisitos:** Docker Engine instalado e em execução, Docker Compose disponível e portas correspondentes livres.

Os comandos devem ser executados a partir do diretório do exercício escolhido. Como exemplo, para iniciar o Exercício 1:

```bash
cd docker/exercicio-1
docker compose up -d --build
curl http://localhost:3000
docker compose down
```

Em sistemas nos quais o usuário não possui acesso direto ao daemon Docker, os comandos Docker podem exigir `sudo`.

Nos Exercícios 2 e 3 e no Desafio Extra, copie o arquivo `.env.example` para `.env` antes de iniciar os serviços. As configurações e os procedimentos específicos estão descritos nos READMEs de cada exercício.

O Exercício 3 utiliza arquivos Compose distintos para DEV e PROD. Consulte sua documentação para selecionar o ambiente desejado.

## Validação

Durante o desenvolvimento, foram executados testes locais dos principais comportamentos:

- Build e inicialização dos contêineres.
- Disponibilidade das aplicações por HTTP.
- Comunicação entre API e PostgreSQL.
- Cadastro e consulta de tarefas.
- Persistência de dados após recriação de contêineres.
- Live reload no ambiente DEV do Exercício 3.
- Inspeção da configuração do ambiente PROD.
- Acesso ao PostgreSQL pelo Adminer no Desafio Extra.

Cada README apresenta os procedimentos de validação e distingue os testes realizados de verificações complementares.

## Organização

Os exercícios foram desenvolvidos de forma independente, com separação de código, configuração e documentação.

Arquivos `.env` utilizados localmente não são versionados. Os exemplos de configuração ficam disponíveis em `.env.example`.

A integração do código utiliza branches Git e pull requests, preservando a organização do fluxo de desenvolvimento.