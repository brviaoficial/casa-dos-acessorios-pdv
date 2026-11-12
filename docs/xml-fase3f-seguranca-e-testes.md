# Fase 3F — Entrada fictícia de estoque (proposta)

## Objetivo
Com os dois produtos já cadastrados pela Fase 3E em quantidade zero:
- CALOTA-ARO14: de 0 para 20 unidades.
- PRESILHA-TESTE: de 0 para 100 unidades.

Nenhuma entrada real de NF-e é autorizada. A função não aceita parâmetros arbitrários nem documentos fiscais externos; usa uma identificação interna fixa de teste.

## Salvaguardas
- JWT autenticado + `eh_administrador()` verificado no banco.
- Produtos localizados por códigos fixos, nomes esperados, ativos e **quantidade exatamente zero**, com lock de linhas.
- Registro idempotente exclusivo da Fase 3F em `xml_entradas_fase3f_teste`, chave constante e PK.
- Se qualquer verificação ou escrita falhar, a transação inteira é revertida.
- A tabela histórica `xml_entradas_teste` e o antigo teste de +3 unidades **não são reutilizados**.
- `SECURITY DEFINER` requer revisão de ownership/permissões antes da instalação.
- Não existe ainda botão para execução nem aprovação para importar NF-e de verdade.

## Sequência de validação antes da instalação
1. Confirmar no Supabase a quantidade ATUAL de ambas as peças e seus nomes, ativo e códigos.
2. Conferir que a tabela `xml_entradas_fase3f_teste` não existe de um ensaio anterior; se existir, não apagar nem limpar automaticamente.
3. Revisar funções, permissões do usuário criador, índices de unicidade, triggers e RLS no ambiente de teste.
4. Instalar apenas a DDL, checar que o estoque não mudou.
5. Preparar uma interface administrativa que exija confirmação e vinculação ao XML fictício; somente depois considerar chamada RPC.
6. Após chamada única, conferir as duas quantidades + o registro da chave em consulta direta; tentar segunda chamada e confirmar bloqueio, sem nova alteração.
7. Se houver erro de rede, **consultar o banco antes de repetir**.

## Limites atuais
Esta RPC não autentica autorização fiscal da NF-e, não examina CNPJ do destinatário, não compara o XML enviado com arquivo assinado nem oferece importação de notas reais. Não utilizar para produção real. A integração fiscal completa exige uma arquitetura distinta.
