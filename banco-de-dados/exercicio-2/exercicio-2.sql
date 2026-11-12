-- 1. Listar alunos e seus respectivos cursos
SELECT
    a.nome AS aluno,
    c.nome_curso AS curso
FROM alunos AS a
INNER JOIN cursos AS c ON a.curso_id = c.id
ORDER BY a.id;

-- 2. Filtrar alunos de Desenvolvimento Web
SELECT
    a.nome AS aluno,
    c.nome_curso AS curso
FROM alunos AS a
INNER JOIN cursos AS c ON a.curso_id = c.id
WHERE c.nome_curso = 'Desenvolvimento Web'
ORDER BY a.id;

-- 3. Transferir Maria para Ciência de Dados
UPDATE alunos
SET curso_id = 2
WHERE id = 2;

-- 4. Confirmar a alteração usando JOIN
SELECT
    a.nome AS aluno,
    c.nome_curso AS curso
FROM alunos AS a
INNER JOIN cursos AS c ON a.curso_id = c.id
WHERE a.id = 2;

-- 5. Extra: identificar cursos sem alunos
SELECT
    c.id,
    c.nome_curso
FROM cursos AS c
LEFT JOIN alunos AS a ON a.curso_id = c.id
WHERE a.id IS NULL;