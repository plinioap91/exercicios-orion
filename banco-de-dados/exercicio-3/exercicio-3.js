// Selecionar o banco de dados
const banco = db.getSiblingDB("orion_db");

// Criar a coleção de posts
banco.createCollection("posts");

// Inserir o primeiro post
banco.posts.insertOne({
    titulo: "Introdução ao MongoDB",
    autor: "João Silva",
    conteudo: "Primeiros conceitos de bancos NoSQL."
});

// Inserir o segundo post com um campo adicional
banco.posts.insertOne({
    titulo: "Schema Flexível",
    autor: "Maria Santos",
    conteudo: "Documentos podem ter estruturas diferentes.",
    tags: ["nosql", "flexivel"]
});

// Consultar todos os posts
banco.posts.find().forEach(printjson);