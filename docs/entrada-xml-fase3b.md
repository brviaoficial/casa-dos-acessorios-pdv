# Fase 3B — entrada de XML (proposta técnica, não ativada)

## Implementado nesta branch
- Migração SQL proposta em `sql/proposta-entrada-xml-teste.sql`, sem aplicação no Supabase.
- Chave de NF-e única para bloquear importações repetidas, inclusive tentativas concorrentes.
- Uma transação única para inserir registro de importação e aumentar quantidades de produtos já cadastrados.
- Erros desfazem toda a transação; sessão autenticada e administrador exigidos.
- Valida quantidade positiva inteira e rejeita referência duplicada a produto no mesmo lote.

## Bloqueios antes de uso
1. Conferir no banco o tipo da coluna `produtos.id`, campos `ativo` e `quantidade`, e assinatura/RLS de `eh_administrador()`.
2. Validar no servidor a autenticidade, destinatário, autorização e chave do XML original. **A função não faz isso** e jamais deve ser oferecida como importação fiscal segura de produção.
3. Implementar cadastro assistido de itens desconhecidos com NCM, EAN, preço, código do fornecedor e revisão do administrador; sem criação automática silenciosa.
4. Definir tratamento de divergências, itens repetidos, unidade comercial versus unidade do estoque e devoluções/estornos.
5. Integrar UI somente após revisão da migração e teste em banco isolado.

## Testes obrigatórios em Supabase TESTE
- Entrada correta: estoque incrementado uma única vez e importação registrada.
- Reenvio da mesma chave: falha sem movimentação adicional.
- Duas sessões concorrentes com mesma chave: apenas uma aplica a entrada.
- Item inexistente, inativo, duplicado, quantidade fracionária/nula/negativa: nenhuma alteração.
- Erro após primeiro item: rollback de todas as quantidades e registro.
- Funcionário sem perfil administrativo e acesso anônimo: acesso negado.
- Repetição após falha de conexão: consultar chave antes de tentar novamente.

**Não executar em produção nem publicar botão de importação real antes desses testes.**
