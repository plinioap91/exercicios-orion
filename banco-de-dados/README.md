# Banco de Dados — Orion Bootcamp 2026

Implementação de quatro exercícios com **PostgreSQL** e **MongoDB**, incluindo ambientes Docker independentes de desenvolvimento (DEV) e produção (PROD).

O projeto utiliza o `docker-compose.yml` fornecido na atividade e duas configurações adicionais para DEV/PROD. Os exercícios SQL e MongoDB são executados explicitamente, sem inicialização automática de dados de exemplo.

## Escopo

| Exercício | Implementação | Resultado com os dados de exemplo |
|---|---|---|
| [1 — SQL básico](exercicio-1/exercicio-1.sql) | Tabelas `cursos` e `alunos`, PK, FK, `INSERT` e `SELECT` | Três cursos, quatro alunos e integridade referencial |
| [2 — Consultas SQL](exercicio-2/exercicio-2.sql) | `INNER JOIN`, `WHERE`, `UPDATE` e `LEFT JOIN` | Relação aluno/curso e transferência de Maria para Ciência de Dados |
| [3 — MongoDB](exercicio-3/exercicio-3.js) | Coleção `posts`, `insertOne()` e `find()` | Dois documentos; apenas um contém o array `tags` |
| [4 — MongoDB e DEV/PROD](exercicio-4/exercicio-4.js) | `updateOne()`, comentários aninhados, filtros por tag e autor | Atualização do post e consultas aos dados aninhados |

Os requisitos de infraestrutura do Exercício 4 estão implementados em `docker-compose.dev.yml`, `docker-compose.prod.yml`, `Dockerfile.dev`, `Dockerfile.prod` e `.dockerignore`.

## Estrutura

```text
banco-de-dados/
├── exercicio-1/
│   ├── exercicio-1.sql
│   └── evidencias/
├── exercicio-2/
│   ├── exercicio-2.sql
│   └── evidencias/
├── exercicio-3/
│   ├── exercicio-3.js
│   └── evidencias/
├── exercicio-4/
│   ├── exercicio-4.js
│   └── evidencias/
├── evidencias/
├── docker-compose.yml
├── docker-compose.dev.yml
├── docker-compose.prod.yml
├── Dockerfile.dev
├── Dockerfile.prod
├── .dockerignore
├── .env.example
├── .gitignore
└── README.md
```

## Infraestrutura

| Ambiente | Projeto Compose | PostgreSQL no host | MongoDB no host | Scripts MongoDB |
|---|---|---|---|---|
| Original | Nome padrão do Compose | `5432` | `27017` | Execução pela entrada padrão |
| DEV | `orion-banco-dev` | `127.0.0.1:5433` | `127.0.0.1:27018` | Montagem dos diretórios em modo somente leitura |
| PROD | `orion-banco-prod` | `127.0.0.1:5434` | `127.0.0.1:27019` | Scripts incorporados à imagem durante o build |

As portas internas permanecem `5432` (PostgreSQL) e `27017` (MongoDB). As redes e os volumes são isolados por projeto Compose. Os ambientes DEV/PROD não compartilham volumes com o Compose original nem entre si.

O PostgreSQL utiliza `postgres:16-alpine`. Nos novos ambientes, o MongoDB utiliza a imagem oficial `mongo:8.0`, preservando seu entrypoint. Os Dockerfiles não instalam dependências adicionais. Em PROD, o contexto do build é restringido pelo `.dockerignore`, e apenas os scripts dos exercícios 3 e 4 são incorporados à imagem. A configuração não utiliza Alpine para MongoDB nem alega redução de tamanho que não tenha sido medida.

**Persistência:** o ambiente PROD não monta código-fonte do host, mas mantém volumes nomeados para os dados dos bancos. Essa separação permite atualizar a imagem sem eliminar os registros armazenados.

As configurações DEV/PROD foram validadas sequencialmente no computador de desenvolvimento para limitar o consumo de recursos. As portas e os projetos são distintos; **a execução simultânea dos dois ambientes não fez parte dos testes registrados**.

## Configuração

Requisitos: Docker Engine, Docker Compose com suporte a `--wait`, Bash e acesso autorizado ao daemon Docker. Os comandos a seguir partem do diretório `banco-de-dados/` e usam `docker compose`; em instalações que exigem privilégios adicionais, execute-os com `sudo`.

```bash
cd banco-de-dados
test -f .env || cp .env.example .env
chmod 600 .env
```

O `.env` contém as variáveis `POSTGRES_PASSWORD`, `MONGO_ROOT_PASSWORD` e as portas externas dos ambientes. As senhas de exemplo devem ser substituídas por credenciais locais. O arquivo `.env` é ignorado pelo Git; `.env.example` não contém credenciais reais.

As senhas são utilizadas na inicialização de volumes novos. Modificar o `.env` posteriormente não altera automaticamente as credenciais já armazenadas nos bancos. O Compose original utiliza sua própria configuração, independente dessas variáveis.

A validação da configuração não requer a inicialização dos serviços:

```bash
docker compose -f docker-compose.dev.yml config --quiet
docker compose -f docker-compose.prod.yml config --quiet
```

Evite publicar saída de configuração com segredos, arquivos `.env` e informações de autenticação.

## Execução

### Ambiente DEV

```bash
docker compose -f docker-compose.dev.yml up -d --build --wait
docker compose -f docker-compose.dev.yml ps
```

### Ambiente PROD

```bash
docker compose -f docker-compose.prod.yml up -d --build --wait
docker compose -f docker-compose.prod.yml ps
```

O comando de inicialização solicitado no enunciado também foi executado e validado:

```bash
docker compose -f docker-compose.prod.yml up -d
```

Em ambos os ambientes, o estado esperado é `healthy` para `db_postgres` e `db_mongo`. O DEV pode ser interrompido antes de iniciar o PROD, sem remover os volumes:

```bash
docker compose -f docker-compose.dev.yml stop
```

### Exercícios 1 e 2 — PostgreSQL

Os scripts devem ser executados nessa ordem sobre um banco preparado para os dados de exemplo. A variável abaixo seleciona o ambiente:

```bash
COMPOSE=docker-compose.dev.yml
```

Para o PROD, utilize `COMPOSE=docker-compose.prod.yml`.

```bash
docker compose -f "$COMPOSE" exec -T db_postgres \
  psql -X -v ON_ERROR_STOP=1 -U orion_user -d orion_db \
  < exercicio-1/exercicio-1.sql

docker compose -f "$COMPOSE" exec -T db_postgres \
  psql -X -v ON_ERROR_STOP=1 -U orion_user -d orion_db \
  < exercicio-2/exercicio-2.sql
```

O Exercício 1 cria duas tabelas relacionadas por chave estrangeira e insere três cursos e quatro alunos. O Exercício 2 relaciona os registros, filtra alunos de Desenvolvimento Web, altera o curso de Maria e consulta a atualização. O `LEFT JOIN` adicional identifica cursos sem alunos; com os dados fornecidos, retorna zero linhas.

### Exercícios 3 e 4 — MongoDB

O mesmo valor de `COMPOSE` seleciona os serviços MongoDB do DEV ou PROD. No primeiro uso de um banco novo, execute o Exercício 3 uma única vez:

```bash
docker compose -f "$COMPOSE" exec -T db_mongo \
  sh -lc 'mongosh --quiet \
  -u "$MONGO_INITDB_ROOT_USERNAME" \
  -p "$MONGO_INITDB_ROOT_PASSWORD" \
  --authenticationDatabase admin \
  --file /exercicios/exercicio-3/exercicio-3.js'
```

Em seguida, execute o Exercício 4:

```bash
docker compose -f "$COMPOSE" exec -T db_mongo \
  sh -lc 'mongosh --quiet \
  -u "$MONGO_INITDB_ROOT_USERNAME" \
  -p "$MONGO_INITDB_ROOT_PASSWORD" \
  --authenticationDatabase admin \
  --file /exercicios/exercicio-4/exercicio-4.js'
```

A autenticação utiliza as variáveis disponíveis dentro do contêiner, sem inserir os valores das senhas no comando. Os dois ambientes disponibilizam os scripts no mesmo caminho: em DEV, por montagem de leitura; em PROD, por `COPY` na imagem.

O Exercício 3 insere dois documentos com estruturas diferentes. O Exercício 4 localiza o post de Maria Santos, adiciona comentários com `$addToSet` e `$each` e consulta documentos por `tags`, `autor` e `comentarios.autor`.

No ambiente original, os scripts MongoDB são executados pela entrada padrão, pois não há montagem do diretório de exercícios no Compose fornecido.

## Validações realizadas

As verificações abaixo foram concluídas no ambiente local em **11 e 12/11/2026**.

| Verificação | Resultado |
|---|---|
| Exercício 1 — tabelas, dados e consultas | Aprovado no ambiente original, DEV e PROD: 3 cursos e 4 alunos |
| Exercício 1 — integridade de PK e FK | No ambiente original, inserções inválidas foram rejeitadas; IDs de teste não persistiram |
| Exercício 2 — `INNER JOIN`, filtro e `UPDATE` | Aprovado no ambiente original, DEV e PROD: `UPDATE 1` e Maria em Ciência de Dados |
| Exercício 3 — schema flexível | Aprovado no ambiente original, DEV e PROD: 2 posts, com `tags` apenas no segundo |
| Exercício 4 — atualização e filtros | Aprovado no ambiente original, DEV e PROD: `matchedCount: 1`, `modifiedCount: 1`, consultas corretas |
| Configurações DEV/PROD | `docker compose config --quiet` sem erros; `.env` excluído do Git |
| Build e inicialização DEV | Imagem MongoDB construída; PostgreSQL e MongoDB `healthy` |
| Build e inicialização PROD | Imagem MongoDB construída; PostgreSQL e MongoDB `healthy` |
| Inicialização PROD com `up -d` | Executada sem recriação desnecessária dos contêineres |
| Persistência PROD | Após `down` e `up -d --wait`, preservados 4 alunos e 2 posts |

**Verificações não registradas como concluídas:** reexecução efetiva do Exercício 4 com `modifiedCount: 0`, medição comparativa de tamanho das imagens, isolamento sob execução simultânea de DEV/PROD e persistência após recriação dos contêineres DEV. Essas verificações não são pressupostas pelos resultados apresentados.

### Consultas de verificação

PostgreSQL, no ambiente selecionado por `COMPOSE`:

```bash
docker compose -f "$COMPOSE" exec -T db_postgres \
  psql -X -U orion_user -d orion_db \
  -c 'SELECT COUNT(*) AS total_alunos FROM alunos;'
```

MongoDB:

```bash
docker compose -f "$COMPOSE" exec -T db_mongo \
  sh -lc 'mongosh --quiet \
  -u "$MONGO_INITDB_ROOT_USERNAME" \
  -p "$MONGO_INITDB_ROOT_PASSWORD" \
  --authenticationDatabase admin \
  --eval "db.getSiblingDB(\"orion_db\").posts.countDocuments({})"'
```

Os dados de exemplo resultam em quatro alunos e dois posts. A consulta de contagem é somente leitura.

### Persistência no PROD

A persistência foi testada removendo e recriando os contêineres PROD, sem excluir volumes:

```bash
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d --wait
```

Após a recriação, as consultas de contagem retornaram **4 alunos** no PostgreSQL e **2 posts** no MongoDB. Os testes estão documentados nas [evidências de infraestrutura](evidencias/). Os volumes `orion-banco-prod_postgres_data`, `orion-banco-prod_mongo_data` e `orion-banco-prod_mongo_config` são independentes dos volumes DEV e do ambiente original.

Para interromper serviços sem excluir dados:

```bash
docker compose -f docker-compose.dev.yml stop
docker compose -f docker-compose.prod.yml stop
```

Não utilizar `down -v` nem remover os volumes para realizar os procedimentos de validação.

## Evidências

As evidências foram coletadas durante a execução local e armazenadas em arquivos versionáveis, organizados por exercício e infraestrutura. Arquivos `.txt` identificados como transcrições registram saídas reais do terminal; não são capturas de tela.

| Escopo | Evidências |
|---|---|
| Infraestrutura DEV | [Build e serviços saudáveis](evidencias/01-dev-build-servicos-saudaveis.png) |
| Infraestrutura PROD | [Build e serviços saudáveis](evidencias/02-prod-build-servicos-saudaveis.png) · [Inicialização via `up -d`](evidencias/03-prod-compose-up.png) · [Recriação dos contêineres](evidencias/04-prod-recriacao-containers.png) |
| Persistência PROD | [PostgreSQL](evidencias/05-prod-persistencia-postgresql.png) · [MongoDB](evidencias/06-prod-persistencia-mongodb.png) |
| Exercício 1 | [Dados PostgreSQL](exercicio-1/evidencias/01-registros-postgresql.png) · [IDs inválidos ausentes](exercicio-1/evidencias/02-confirmacao-sem-ids-invalidos.png) · [Registros PROD](exercicio-1/evidencias/02-postgresql-prod-registros.png) · [Transcrição PK/FK](exercicio-1/evidencias/03-testes-pk-fk-transcricao.txt) |
| Exercício 2 | [Transcrição de consultas](exercicio-2/evidencias/01-consultas-sql-transcricao.txt) · [JOINs e UPDATE no PROD](exercicio-2/evidencias/02-postgresql-prod-joins-update.png) |
| Exercício 3 | [Schema flexível](exercicio-3/evidencias/01-schema-flexivel-mongodb.png) · [Schema flexível no PROD](exercicio-3/evidencias/02-mongodb-prod-schema-flexivel.png) |
| Exercício 4 | [Atualização e filtro por tag](exercicio-4/evidencias/01-atualizacao-e-consulta-por-tag.png) · [Autor e comentários](exercicio-4/evidencias/02-consulta-por-autor-e-comentarios.png) · [Atualização no PROD](exercicio-4/evidencias/03-mongodb-prod-atualizacao-e-filtro.png) · [Comentários no PROD](exercicio-4/evidencias/04-mongodb-prod-consulta-comentarios.png) |

## Comportamento de reexecução

| Arquivo | Comportamento |
|---|---|
| `exercicio-1.sql` | `IF NOT EXISTS` e `ON CONFLICT DO NOTHING` permitem reexecutar a carga de exemplo sem duplicar IDs; não corrigem estruturas preexistentes divergentes |
| `exercicio-2.sql` | `UPDATE` mantém a matrícula de Maria em Ciência de Dados; execuções posteriores já encontram os dados modificados |
| `exercicio-3.js` | Não é idempotente: repetir `insertOne()` gera novos posts, podendo duplicar documentos |
| `exercicio-4.js` | Exige exatamente um post correspondente e usa `$addToSet` para evitar inserir novamente comentários de exemplo idênticos; a reexecução sem alterações é prevista pelo código, não validada separadamente |

As validações e scripts utilizam dados de demonstração. Os ambientes PROD definidos aqui representam uma configuração isolada de execução para a atividade, não uma implantação pública com gerenciamento externo de segredos, TLS ou alta disponibilidade.
