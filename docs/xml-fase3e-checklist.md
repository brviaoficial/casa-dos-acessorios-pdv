# Fase 3E — Cadastro definitivo controlado (proposta não ativada)

## Escopo
Função proposta `cadastrar_produtos_xml_ficticios_teste(jsonb)`. Só aceita duas peças de teste do XML utilizado na Fase 3C:
- CALOTA-ARO14 / CALOTA ARO 14 - MODELO TESTE / custo R$ 18,50
- PRESILHA-TESTE / PRESILHA AUTOMOTIVA - MODELO TESTE / custo R$ 0,75

O cadastro grava **estoque inicial zero**. Não grava nota fiscal nem faz entrada de mercadorias. A função valida sessão administrativa, quantidade inicial, itens esperados, preços e códigos; grava as duas peças na mesma transação (rollback se uma falhar), e impede novas inserções com códigos já presentes.

## Atenção antes de qualquer execução
1. Conferir campos, defaults, restrições e RLS da tabela `produtos` no Supabase (somente estrutura, sem dados pessoais).
2. Revisar a função com um responsável técnico. É `SECURITY DEFINER` e, se for instalada, um administrador autenticado poderá gravar esses dois produtos.
3. Testar em banco isolado, com estoque zero, e confirmar tanto rollback quanto bloqueio de duplicidade.
4. Antes de integrar UI, validar no servidor origem fiscal, destinatário e autorização da NF-e, mapa fornecedor→código interno e conversões de unidade. **Esta função propositalmente não habilita isso.**

## Casos de teste de validação
- Usuário anônimo / funcionário sem perfil: negado.
- Dois produtos do XML fictício com categoria/localização e preços válidos: inserir 2, ambos com quantidade 0.
- Reenvio: falhar, sem criar novos registros.
- Código existente, item não permitido, nome modificado, preço inválido: falhar, sem alterações parciais.
- Duas sessões administradoras simultâneas: apenas uma operação efetivada.
- Erro de rede após envio: consultar os códigos antes de tentar novamente.
- Verificar que `xml_entradas_teste` e os produtos reais não foram modificados.

## Estado
Código preparado no GitHub para revisão. **Não execute o SQL de proposta no banco ainda e não faça merge até validar a compatibilidade.**
