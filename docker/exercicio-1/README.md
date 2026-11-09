# Exercício 1 — Dockerfile + Compose: Hello Container

## Objetivo

Empacotar uma aplicação HTTP simples em Python com Docker e executá-la com
Docker Compose. Ao acessar `http://localhost:3000`, a aplicação retorna status
HTTP `200` e o corpo exato `Hello from Docker!`, sem quebra de linha no final.

## Estrutura

```text
docker/exercicio-1/
├── app.py              # Aplicação Flask com a rota GET /
├── requirements.txt    # Dependência Python
├── Dockerfile          # Construção da imagem
├── docker-compose.yml  # Serviço e publicação da porta
├── .dockerignore       # Arquivos excluídos do contexto de build
└── README.md           # Instruções do exercício
```

## Execução

Pré-requisitos: Docker Engine em execução, Docker Compose disponível pelo
comando `docker compose`, permissão de acesso ao Docker e porta `3000` livre.
O primeiro build precisa de acesso à internet para baixar a imagem e as
dependências. Os testes abaixo também usam `curl` e `python3` no host.

A partir da raiz do repositório:

```bash
cd docker/exercicio-1
docker compose config
docker compose up --build -d
docker compose ps
```

Abra `http://localhost:3000` no navegador.

## Teste

Confira o status HTTP, os cabeçalhos e o corpo da resposta:

```bash
curl --fail --include http://localhost:3000
```

Para verificar automaticamente o status, o tipo de conteúdo e o corpo exato,
incluindo a ausência de uma quebra de linha:

```bash
python3 - <<'PY'
from urllib.request import urlopen

with urlopen("http://localhost:3000", timeout=5) as response:
    assert response.status == 200, response.status
    assert response.headers.get_content_type() == "text/plain"
    body = response.read()
    assert body == b"Hello from Docker!", repr(body)
print("OK: HTTP 200 e corpo exato Hello from Docker!")
PY
```

Consulte os logs para verificar as requisições e eventuais erros:

```bash
docker compose logs --no-color app
```

O Flask exibe um aviso de que seu servidor é destinado a desenvolvimento.
Esse servidor é suficiente para este exercício didático; uma implantação em
produção exige um servidor WSGI apropriado.

## Encerramento

Após os testes, inclusive se algum deles falhar, remova os contêineres e a rede
criados pelo Compose:

```bash
docker compose down
docker compose ps -a
```

O último comando deve mostrar a lista de serviços sem contêineres.

## Decisões técnicas

- `python:3.12-slim` é uma imagem oficial de Python com base reduzida.
- Flask mantém a rota HTTP simples; sua versão está fixada em `requirements.txt`.
- A resposta usa `text/plain` e não acrescenta HTML nem quebra de linha.
- A aplicação escuta em `0.0.0.0:3000` para aceitar conexões pela interface de
  rede do contêiner. O Compose publica a porta com `3000:3000`.
- As dependências são copiadas e instaladas antes do código, permitindo que o
  Docker reutilize essa camada quando apenas a aplicação mudar.
- `.dockerignore` exclui ambientes virtuais, caches e arquivos locais do build.
