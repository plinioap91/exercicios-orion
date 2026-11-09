# Exercício 3 — Boas Práticas + Múltiplos Ambientes

## Visão geral

O exercício demonstra a execução de uma API de tarefas com FastAPI e PostgreSQL em dois ambientes Docker: desenvolvimento (`dev`) e produção (`prod`). Cada ambiente possui configuração Compose própria, imagem da API e recursos isolados. Todos os arquivos necessários estão neste diretório; a execução não depende dos Exercícios 1 e 2.

A configuração de desenvolvimento utiliza um volume do código-fonte e recarregamento automático. A configuração de produção usa imagem otimizada, com código incorporado e sem volume de código-fonte. Por decisão técnica, também não utiliza live reload. O PostgreSQL mantém um volume de dados em cada ambiente, preservando a persistência implementada no Exercício 2.

## Arquitetura e estrutura

| Configuração    | Desenvolvimento                       | Produção                               |
| :-------------- | :------------------------------------ | :------------------------------------- |
| Arquivo Compose | `docker-compose.dev.yml`              | `docker-compose.prod.yml`              |
| Projeto         | `orion-exercicio-3-dev`               | `orion-exercicio-3-prod`               |
| Build target    | `dev`                                 | `prod`                                 |
| HTTP no host    | `localhost:8001`                      | `localhost:8002`                       |
| Código da API   | `./src:/app:ro`                       | Copiado para `/app` no build           |
| Reload          | Automático para arquivos Python       | Desativado                             |
| Usuário da API  | Padrão da imagem                      | `appuser`, UID 10001                   |
| Volume de dados | `orion-exercicio-3-dev_postgres_data` | `orion-exercicio-3-prod_postgres_data` |

O cliente acessa a API pela porta publicada no host. Internamente, a API utiliza a porta `8000` e se conecta ao PostgreSQL pelo hostname `db:5432`. A porta do banco não é publicada no host. Os projetos Compose usam nomes, redes e volumes distintos; podem ser executados separadamente ou simultaneamente nas portas definidas. Para preservar o isolamento documentado, não combine os dois arquivos Compose em uma mesma execução nem substitua seus nomes de projeto.
```text
docker/exercicio-3/
├── src/
│   └── app.py
├── requirements.txt
├── Dockerfile
├── docker-compose.dev.yml
├── docker-compose.prod.yml
├── .env.example
├── .gitignore
├── .dockerignore
└── README.md
```

A API disponibiliza `POST /tasks` (HTTP 201) e `GET /tasks` (HTTP 200), com campos `id` e `title`. O título aceita de 1 a 200 caracteres após remover os espaços das extremidades; entradas inválidas retornam HTTP 422. A tabela é criada, quando necessário, na inicialização da API. A aplicação utiliza SQL parametrizado e gerenciamento de conexões e transações. A documentação interativa está disponível em `/docs`.

## Validação realizada

Os resultados abaixo foram obtidos no Linux Mint durante a execução dos ambientes em 08/11/2026:

| Verificação | Resultado |
| --- | --- |
| Configuração e build de desenvolvimento | Aprovados |
| API e PostgreSQL em desenvolvimento | Ambos `healthy` |
| `GET /tasks` em desenvolvimento | HTTP 200, antes e depois do reload |
| Live reload | Alteração em `src/app.py` detectada pelo Uvicorn (`StatReload`), com reinicialização automática |
| Configuração e build de produção | Aprovados |
| API e PostgreSQL em produção | Ambos `healthy` |
| `GET /tasks` em produção | HTTP 200 |
| Inspeção do contêiner de produção | Usuário `appuser`, comando sem `--reload` e nenhum mount na API |
| Cadastro e consulta em produção | Registro criado e recuperado com sucesso |
| Persistência em produção | Mesmo registro recuperado após `docker compose down` e recriação dos contêineres |
| Encerramento dos serviços | Realizado sem remoção de volumes |

Os comandos a seguir também permitem reproduzir verificações adicionais. **Não foram executados integralmente nesta validação** o roteiro automatizado de inserção/consulta com rejeição de título vazio, o teste de persistência no ambiente de desenvolvimento e o teste de alteração temporária do título do OpenAPI. A verificação de live reload já foi comprovada por atualização do arquivo e pelos logs.

## Preparação e validação da configuração

**Pré-requisitos:** Docker Engine acessível, Docker Compose v2 ou superior, Bash, Python 3 e portas `8001` e `8002` livres. O primeiro build precisa de acesso à internet.

Execute os blocos na mesma sessão Bash, a partir da pasta do exercício. Quando o usuário não tiver permissão direta para acessar o daemon Docker, use `sudo` nos comandos `docker`/`docker compose`; os comandos Python e `curl` não precisam dessa permissão. Em caso de falha, consulte os logs antes de prosseguir.
```bash
cd ~/projetos/exercicios-orion/docker/exercicio-3
if [ ! -f .env ]; then cp .env.example .env; fi
docker compose -f docker-compose.dev.yml config
docker compose -f docker-compose.prod.yml config
docker compose -f docker-compose.dev.yml build
docker compose -f docker-compose.prod.yml build
```

`DB_USER`, `DB_PASS` e `DB_NAME` são obrigatórias e alimentam os dois bancos isolados com valores demonstrativos iguais. `DB_HOST=db` é fixado no ambiente de cada API. `DEV_PORT` e `PROD_PORT` permitem escolher outras portas livres e distintas; adapte as URLs dos testes se alterar esses valores. O `.env` é ignorado pelo Git e pelo contexto de build. Apenas `.env.example` deve ser versionado. **Atenção:** `docker compose config` exibe as variáveis resolvidas, inclusive a senha; não compartilhe sua saída se estiver usando credenciais reais.

Sem criar `.env` e sem acessar o daemon, é possível validar com:
```bash
docker compose --env-file .env.example -f docker-compose.dev.yml config
docker compose --env-file .env.example -f docker-compose.prod.yml config
```

## Função para testar a API

A função abaixo cadastra uma tarefa, verifica a consulta e testa a rejeição de um título vazio. Retorna o ID da tarefa para o teste de persistência. Com um ID como segundo argumento, consulta o mesmo registro sem criar outro. Falhas nas verificações geram erro.
```bash
testar_api() {
  if [ "$#" -eq 2 ] && [ -z "$2" ]; then
    echo "ID ausente: execute a insercao com sucesso antes de testar persistencia." >&2
    return 1
  fi
  API_URL="$1" TASK_ID="${2:-}" python3 - <<'PY'
import json
import os
from urllib.error import HTTPError
from urllib.request import Request, urlopen

url = os.environ["API_URL"] + "/tasks"
title = "Estudar 'Docker' no Orion"
task_id = os.environ["TASK_ID"]
if not task_id:
    request = Request(url, data=json.dumps({"title": title}).encode(),
                      headers={"Content-Type": "application/json"}, method="POST")
    with urlopen(request, timeout=10) as response:
        assert response.status == 201, response.status
        task = json.load(response)
        assert task["title"] == title, task
        assert isinstance(task["id"], int), task
        task_id = task["id"]
with urlopen(url, timeout=10) as response:
    assert response.status == 200, response.status
    tasks = json.load(response)
assert any(t["id"] == int(task_id) and t["title"] == title for t in tasks), tasks
invalid = Request(url, data=b'{"title":"   "}',
                  headers={"Content-Type": "application/json"}, method="POST")
try:
    with urlopen(invalid, timeout=10) as response:
        raise AssertionError(f"Titulo vazio foi aceito: {response.status}")
except HTTPError as error:
    assert error.code == 422, error.code
print(task_id)
PY
}
```

## Desenvolvimento

Para iniciar o ambiente de desenvolvimento em primeiro plano, conforme o enunciado:
```bash
docker compose -f docker-compose.dev.yml up
```

Para executar os testes, inicie em segundo plano com `--wait`, que aguarda os healthchecks. Não use os dois modos de inicialização simultaneamente:
```bash
docker compose -f docker-compose.dev.yml up -d --wait --wait-timeout 120
docker compose -f docker-compose.dev.yml ps
DEV_TASK_ID=$(testar_api http://localhost:8001)
docker compose -f docker-compose.dev.yml logs --no-color --tail=100 api db
```

Ambos os serviços devem estar saudáveis. O banco usa `pg_isready` via TCP; a API só inicia após `db` estar saudável e seu healthcheck consulta `/tasks`, incluindo o acesso ao PostgreSQL.

### Comprovar live reload

O teste adicional abaixo altera temporariamente o título do OpenAPI em `src/app.py`, aguarda a atualização da resposta HTTP e restaura o arquivo em `finally`. Não modifica rotas nem reconstrói a imagem. Execute com DEV ativo e sem editar o arquivo simultaneamente:
```bash
python3 - <<'PY'
import json
import time
from pathlib import Path
from urllib.error import URLError
from urllib.request import urlopen

path = Path("src/app.py")
original = path.read_text()
old = "Orion — API de tarefas"
new = old + " (reload)"
assert f'title="{old}"' in original

def wait_title(expected):
    for _ in range(40):
        try:
            with urlopen("http://localhost:8001/openapi.json", timeout=2) as response:
                if json.load(response)["info"]["title"] == expected:
                    return
        except (URLError, TimeoutError, ConnectionError):
            pass
        time.sleep(0.5)
    raise AssertionError(f"Reload nao confirmado para: {expected}")

wait_title(old)
try:
    path.write_text(original.replace(f'title="{old}"', f'title="{new}"', 1))
    wait_title(new)
finally:
    path.write_text(original)
    wait_title(old)
print("OK: alteracao e restauracao detectadas por live reload")
PY
docker compose -f docker-compose.dev.yml logs --no-color --tail=100 api
```

Os logs devem mostrar o recarregamento. O mount é somente leitura para o contêiner, mas as edições feitas no host ficam visíveis. O Uvicorn usa a verificação nativa de alterações em `*.py`, sem precisar de `watchfiles`.

Confira persistência ao recriar os contêineres e encerre dev:
```bash
docker compose -f docker-compose.dev.yml down
docker compose -f docker-compose.dev.yml up -d --wait --wait-timeout 120
testar_api http://localhost:8001 "$DEV_TASK_ID"
docker compose -f docker-compose.dev.yml down
docker compose -f docker-compose.dev.yml ps -a
```

## Produção

Pode ser iniciada diretamente, sem iniciar dev. Em primeiro plano:
```bash
docker compose -f docker-compose.prod.yml up
```

Alternativa em segundo plano para validar a stack:
```bash
docker compose -f docker-compose.prod.yml up -d --wait --wait-timeout 120
docker compose -f docker-compose.prod.yml ps
PROD_TASK_ID=$(testar_api http://localhost:8002)
docker compose -f docker-compose.prod.yml logs --no-color --tail=100 api db
```

Verifique no contêiner real a ausência de mounts e de reload:
```bash
PROD_API_ID=$(docker compose -f docker-compose.prod.yml ps -q api)
docker inspect "$PROD_API_ID" --format '{{json .Mounts}}'
docker inspect "$PROD_API_ID" --format '{{json .Config.Cmd}}'
docker compose -f docker-compose.prod.yml exec -T api id -u
```

Os resultados esperados são `[]` nos mounts da API, comando Uvicorn sem `--reload` e UID `10001`. O banco continua com seu volume de dados. Para atualizar o código em produção, refaça a imagem e recrie a API com `docker compose -f docker-compose.prod.yml up -d --build --wait --wait-timeout 120`.

Confira persistência e encerre prod:
```bash
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d --wait --wait-timeout 120
testar_api http://localhost:8002 "$PROD_TASK_ID"
docker compose -f docker-compose.prod.yml logs --no-color --tail=100 api db
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml ps -a
```

## Encerramento e volumes

Mesmo se um teste falhar, encerre os projetos com os comandos correspondentes:
```bash
docker compose -f docker-compose.dev.yml down
docker compose -f docker-compose.prod.yml down
docker volume ls --filter label=com.docker.compose.project=orion-exercicio-3-dev
docker volume ls --filter label=com.docker.compose.project=orion-exercicio-3-prod
```

`down` preserva os volumes. Não use `down -v` durante os testes de persistência. Mantenha os nomes dos projetos para reutilizar os dados. Alterar `DB_USER`, `DB_PASS` ou `DB_NAME` não modifica usuários, senhas ou bancos já inicializados em um volume existente.

## Decisões de build

O estágio `base` instala as dependências antes de copiar o código, permitindo reutilizar a camada quando somente `src/` muda. Os estágios `dev` e `prod` derivam de `base`, sem dependência da imagem de desenvolvimento no build de produção. O reload nativo do Uvicorn dispensa ferramentas adicionais; Psycopg binário evita compiladores, e `--no-cache-dir` evita armazenar o cache do pip na imagem. O `.dockerignore` exclui configurações locais, credenciais e caches.

Em produção, executar o servidor sem live reload e com usuário não privilegiado são decisões técnicas de otimização e segurança. O ambiente de produção não monta o código-fonte, mas conserva um volume nomeado para os dados do PostgreSQL, como continuidade do requisito de persistência do Exercício 2.

## Referências

- [Docker — Multi-stage builds](https://docs.docker.com/build/building/multi-stage/)
- [Docker Compose — Nomes de projetos](https://docs.docker.com/reference/compose-file/version-and-name/)
- [Uvicorn — Configurações de execução](https://uvicorn.dev/settings/)
