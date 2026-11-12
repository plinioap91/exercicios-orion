-- Criação da tabela de cursos
CREATE TABLE IF NOT EXISTS cursos (
    id INTEGER PRIMARY KEY,
    nome_curso VARCHAR(100) NOT NULL
);

-- Criação da tabela de alunos
CREATE TABLE IF NOT EXISTS alunos (
    id INTEGER PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    curso_id INTEGER NOT NULL,
    FOREIGN KEY (curso_id) REFERENCES cursos(id)
);

-- Inserção dos cursos
INSERT INTO cursos (id, nome_curso) VALUES
(1, 'Desenvolvimento Web'),
(2, 'Ciência de Dados'),
(3, 'Engenharia de IA')
ON CONFLICT (id) DO NOTHING;

-- Inserção dos alunos
INSERT INTO alunos (id, nome, email, curso_id) VALUES
(1, 'João Silva', 'joao@example.com', 1),
(2, 'Maria Santos', 'maria@example.com', 1),
(3, 'Ana Souza', 'ana@example.com', 2),
(4, 'Pedro Lima', 'pedro@example.com', 3)
ON CONFLICT (id) DO NOTHING;

-- Consultas de validação
SELECT * FROM cursos ORDER BY id;
SELECT * FROM alunos ORDER BY id;