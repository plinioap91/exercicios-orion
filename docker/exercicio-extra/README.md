# Desafio Extra — FastAPI, PostgreSQL e Adminer

## Objetivo e arquitetura

Executar uma stack independente para cadastrar e consultar tarefas, administrar o banco pela interface web e preservar dados após recriar os contêineres.
```text
localhost:8003 → api (FastAPI/Uvicorn) ─┐
                                     ├→ db:5432 (PostgreSQL) → postgres_data
localhost:8083 → adminer ──────────────┘
```

Os três serviços usam a rede bridge `app_network`. O projeto Compose `orion-exercicio-extra` gera a rede `orion-exercicio-extra_app_network` e o volume `orion-exercicio-extra_postgres_data`, isolados dos outros exercícios. O PostgreSQL não publica a porta `5432` no host. Não sobrescreva o nome do projeto com `-p` ou `COMPOSE_PROJECT_NAME` ao seguir este roteiro.

| Serviço   | Imagem                             | Acesso                              |
| :-------- | :--------------------------------- | :---------------------------------- |
| `api`     | Build local com `python:3.12-slim` | `http://localhost:8003/docs`        |
| `db`      | `postgres:16-alpine`               | Hostname `db`, porta interna `5432` |
| `adminer` | `adminer:6.3.0` oficial            | `http://localhost:8083`             |

## Estrutura
```text
docker/exercicio-extra/
├── src/app.py           # Healthcheck, conexão e endpoints de tarefas
├── requirements.txt    # Dependências Python com versões fixadas
├── Dockerfile          # Imagem customizada da API
├── docker-compose.yml  # Três serviços, rede, volume e healthchecks
├── .env.example        # Valores demonstrativos
├── .gitignore
├── .dockerignore
└── README.md
```

## Preparação e execução

Requisitos: Docker Engine em execução, Docker Compose v2 ou superior, portas `8003` e `8083` livres e acesso à internet para baixar imagens e dependências. Os testes usam Bash, `curl` e Python 3. Os comandos usam `sudo` porque a conta utilizada nos testes não tinha acesso direto ao daemon Docker; quem já possuir permissão pode omiti-lo.
```bash
cd ~/projetos/exercicios-orion/docker/exercicio-extra
if [ ! -f .env ]; then cp .env.example .env; fi
sudo docker compose config --quiet
sudo docker compose up -d --build --wait --wait-timeout 120
sudo docker compose ps
```

O `.env` é ignorado pelo Git e excluído do contexto de build. Somente `.env.example` contém configurações versionáveis, todas demonstrativas:

| Variável  | Exemplo            | Destino                   |
| :-------- | :----------------- | :------------------------ |
| `DB_USER` | `orion_demo`       | API e `POSTGRES_USER`     |
| `DB_PASS` | `senha_demo_local` | API e `POSTGRES_PASSWORD` |
| `DB_NAME` | `orion_tasks`      | API e `POSTGRES_DB`       |

`DB_HOST=db` é definido diretamente no ambiente da API. O Compose exige as demais variáveis e as fornece aos serviços. Não é necessário instalar `python-dotenv`. O comando `docker compose config` imprime valores resolvidos, inclusive a senha. Evite compartilhar essa saída se utilizar credenciais reais. Para validar a configuração sem criar `.env` nem acessar o daemon:
```bash
docker compose --env-file .env.example config
```

`up --wait` aguarda os três serviços saudáveis. O banco usa `pg_isready` via TCP; a API e o Adminer dependem de `db` com `condition: service_healthy`. O healthcheck da API acessa `/health`, que executa `SELECT 1` no PostgreSQL. O healthcheck do Adminer consulta sua página HTTP; a autenticação no banco é validada separadamente.

## Endpoints e teste inicial

| Método | Rota      | Resultado esperado                                                                             |
| :----- | :-------- | :--------------------------------------------------------------------------------------------- |
| `GET`  | `/health` | HTTP 200 com `{"status":"ok","database":"ok"}`; HTTP 503 se a conexão/consulta ao banco falhar |
| `POST` | `/tasks`  | Recebe `{"title":"Estudar Docker"}` e retorna `id` e `title`, HTTP 201                         |
| `GET`  | `/tasks`  | Lista as tarefas ordenadas por `id`, HTTP 200                                                  |

O título aceita de 1 a 200 caracteres após remover espaços nas extremidades. Campos ausentes, títulos vazios ou maiores que o limite retornam HTTP 422.
```bash
curl --fail-with-body --include http://localhost:8003/health
curl --fail-with-body --include http://localhost:8003/tasks
curl --fail --output /dev/null --write-out 'Adminer HTTP %{http_code}\n' http://localhost:8083/
sudo docker compose logs --no-color --tail=100 api db adminer
```

## Escrita, leitura e persistência

Execute os blocos na mesma sessão Bash. Defina a função abaixo: sem argumento, ela insere uma tarefa; com um ID, apenas consulta o registro existente. Em ambos os casos, verifica `/health`, a leitura e a rejeição de um título vazio. Este é um roteiro complementar: a validação prática já realizada utilizou comandos diretos para criação, consulta e persistência. Se uma verificação falhar, investigue o resultado antes de prosseguir.
```bash
testar_api() {
  if [ "$#" -gt 0 ] && [ -z "$1" ]; then
    echo "ID ausente: conclua a insercao antes de testar persistencia." >&2
    return 1
  fi
  TASK_ID="${1:-}" python3 - <<'PY'
import json
import os
from urllib.error import HTTPError
from urllib.request import Request, urlopen

base = "http://localhost:8003"
with urlopen(base + "/health", timeout=10) as response:
    assert response.status == 200, response.status
    assert json.load(response) == {"status": "ok", "database": "ok"}
title = "Validar 'Docker' com Adminer"
task_id = os.environ["TASK_ID"]
if not task_id:
    request = Request(base + "/tasks", data=json.dumps({"title": title}).encode(),
                      headers={"Content-Type": "application/json"}, method="POST")
    with urlopen(request, timeout=10) as response:
        assert response.status == 201, response.status
        task = json.load(response)
        assert task["title"] == title, task
        assert isinstance(task["id"], int), task
        task_id = task["id"]
with urlopen(base + "/tasks", timeout=10) as response:
    assert response.status == 200, response.status
    tasks = json.load(response)
assert any(t["id"] == int(task_id) and t["title"] == title for t in tasks), tasks
invalid = Request(base + "/tasks", data=b'{"title":"   "}',
                  headers={"Content-Type": "application/json"}, method="POST")
try:
    with urlopen(invalid, timeout=10) as response:
        raise AssertionError(f"Titulo vazio aceito: {response.status}")
except HTTPError as error:
    assert error.code == 422, error.code
print(task_id)
PY
}

TASK_ID=$(testar_api) && echo "ID cadastrado e consultado: $TASK_ID"
```

Após confirmar a tarefa também no Adminer, remova e recrie os contêineres:
```bash
sudo docker compose down
sudo docker compose up -d --build --wait --wait-timeout 120
testar_api "$TASK_ID"
sudo docker compose ps
sudo docker compose logs --no-color --tail=100 api db adminer
```

A função deve imprimir o mesmo ID, comprovando a persistência do registro após recriar os contêineres. O teste não depende de tabela vazia nem de ID igual a 1.

## Acesso ao PostgreSQL pelo Adminer

Abra `http://localhost:8083` no navegador e preencha:

| Campo         | Valor com o `.env.example` |
| :------------ | :------------------------- |
| Sistema       | PostgreSQL                 |
| Servidor      | `db`                       |
| Usuário       | `orion_demo`               |
| Senha         | `senha_demo_local`         |
| Base de dados | `orion_tasks`              |

Se alterou o `.env`, utilize os valores correspondentes. A variável `ADMINER_DEFAULT_SERVER=db` preenche o servidor; ela não realiza login automático. O hostname `db` é resolvido na rede Docker. `localhost` no campo Servidor apontaria para o próprio contêiner do Adminer.

Entre, abra a tabela `tasks` no esquema `public` e consulte seus registros. Como alternativa, execute na área de comandos SQL:
```sql
SELECT id, title FROM tasks ORDER BY id;
```

Confira o ID e o título cadastrados pela API. Após o teste de persistência, autentique-se novamente se necessário e confirme o mesmo registro. A página de login responder HTTP 200 não comprova, por si só, a autenticação no PostgreSQL.

## Código montado e decisões técnicas

- `./src:/app:ro` monta somente o código, com leitura no contêiner. Edições no host são detectadas pelo `--reload` do Uvicorn sem rebuild. Mudanças em `requirements.txt` exigem novo build.
- A API roda como `appuser`, UID 10001. `src/` precisa estar legível e acessível a esse usuário; as permissões usuais de diretório `755` e arquivo `644` atendem.
- As dependências são instaladas antes da cópia do código, favorecendo o cache de build. A distribuição binária do Psycopg dispensa compiladores na imagem.
- A tabela é criada com `CREATE TABLE IF NOT EXISTS`. Inserções usam parâmetros SQL; os contextos de conexão confirmam a transação no sucesso, desfazem em caso de erro e fecham a conexão. A falha de saúde retorna uma mensagem genérica, sem expor detalhes da conexão.

Para verificar a identidade da API e observar recarregamentos:
```bash
sudo docker compose exec -T api id -u
sudo docker compose logs --follow api
```

O UID esperado é `10001`. Ao editar e salvar `src/app.py`, os logs devem indicar reload. `Ctrl+C` encerra apenas o acompanhamento dos logs.

## Encerramento

Ao terminar, inclusive se algum teste falhar:
```bash
sudo docker compose down
sudo docker compose ps -a
sudo docker volume ls --filter label=com.docker.compose.project=orion-exercicio-extra
```

`down` sem `-v` remove os contêineres e a rede, preservando o volume nomeado. A lista de contêineres deve ficar vazia e o volume deve permanecer. Não use `down -v` durante os testes de persistência. Mantenha o nome do projeto para reutilizar os dados. Alterar as variáveis no `.env` não modifica usuários, senhas ou bancos já inicializados em um volume existente.

## Validações realizadas

Os testes manuais abaixo foram executados no Linux Mint em 08/11/2026 (horário de Brasília):

| Verificação | Resultado observado |
| :-- | :-- |
| Configuração e build Compose | `config --quiet` sem erros; imagem da API construída |
| Inicialização dos três serviços | `api`, `db` e `adminer` em estado `healthy` |
| `GET /health` | HTTP 200; `{"status":"ok","database":"ok"}` |
| `GET /tasks` | HTTP 200 |
| Página inicial do Adminer | HTTP 200 na porta `8083` |
| Escrita pela API | `POST /tasks`: HTTP 201; tarefa `id=1`, título `Validar desafio extra Docker` |
| Consulta pela API | `GET /tasks`: HTTP 200; mesma tarefa recuperada |
| Acesso via Adminer | Login PostgreSQL efetuado; tabela `public.tasks` exibiu o registro de ID `1` |
| Persistência de dados | Mesmo registro recuperado após `docker compose down` e recriação dos três contêineres |
| Encerramento | Três contêineres e rede removidos, sem usar `-v` |

As seguintes verificações estáticas foram informadas pelo Codex durante a implementação:

- `docker compose --env-file .env.example config` e inspeção da configuração resolvida: serviços, portas, variáveis, dependências, healthchecks, rede e volume.
- Rejeição da configuração quando faltam variáveis obrigatórias.
- Sintaxe de `src/app.py` e dos blocos Bash/Python deste README.
- Inspeção do Dockerfile: usuário sem root, reload e ordem das camadas.
- Regras de exclusão de `.env` e caches, permissões de leitura do código e formatação dos arquivos.

O acesso ao daemon Docker estava indisponível no ambiente do Codex; por isso, os testes de execução foram realizados manualmente no terminal do VS Code. **Não foram executados integralmente** o roteiro automatizado da função `testar_api`, o teste de entrada inválida (HTTP 422), a simulação de indisponibilidade do banco (HTTP 503) nem a comprovação de live reload neste Desafio Extra. Esses comandos e comportamentos permanecem documentados como verificações complementares, não como resultados já confirmados.

Referências: [imagem oficial Adminer](https://hub.docker.com/_/adminer), [imagem oficial PostgreSQL](https://hub.docker.com/_/postgres) e [dependências saudáveis no Compose](https://docs.docker.com/compose/how-tos/startup-order/).