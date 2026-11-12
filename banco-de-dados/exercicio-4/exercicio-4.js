// Executar com mongosh, depois do Exercício 3, no mesmo ambiente.
const banco = db.getSiblingDB("orion_db");
const filtro = { titulo: "Schema Flexível", autor: "Maria Santos" };

// Não criar posts implicitamente nem escolher um documento arbitrário duplicado.
if (banco.posts.countDocuments(filtro) !== 1) {
    throw new Error("Esperado exatamente um post 'Schema Flexível' de Maria Santos. Confira o Exercício 3 antes de continuar.");
}

const post = banco.posts.findOne(filtro);
if (post.comentarios !== undefined && !Array.isArray(post.comentarios)) {
    throw new Error("O campo comentarios existente precisa ser um array; nenhum dado foi alterado.");
}

// $addToSet cria o array se ausente, preserva comentários existentes e evita
// repetir estes mesmos documentos em novas execuções. Não usar upsert.
const resultado = banco.posts.updateOne(
    { _id: post._id },
    {
        $addToSet: {
            comentarios: {
                $each: [
                    { autor: "João Silva", texto: "Ótimo exemplo de schema flexível!" },
                    { autor: "Ana Souza", texto: "O array permite organizar os comentários no próprio post." }
                ]
            }
        }
    }
);
if (resultado.matchedCount !== 1) {
    throw new Error("O post não foi encontrado durante a atualização.");
}

print("Resultado da atualização (modifiedCount pode ser 0 na reexecução):");
printjson(resultado);

print("Posts com a tag nosql:");
banco.posts.find({ tags: "nosql" }).forEach(printjson);

print("Posts de Maria Santos:");
banco.posts.find({ autor: "Maria Santos" }).forEach(printjson);

// Consulta adicional por um campo de documento aninhado.
print("Posts com comentários de João Silva:");
banco.posts.find({ "comentarios.autor": "João Silva" }).forEach(printjson);
