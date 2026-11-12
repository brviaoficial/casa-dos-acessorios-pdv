# Fase 3D — cadastro definitivo assistido por XML

## Entregue nesta proposta
- Botão read-only para conferir códigos internos e EAN dos produtos novos no Supabase.
- Verificação de campos obrigatórios, duplicações internas ao lote e códigos já cadastrados.
- Nenhuma inserção, edição ou movimentação de estoque.

## Para habilitar a gravação definitiva
1. Validar XML NF-e autorizado, integridade, emitente, destinatário e chave no backend. A prévia no navegador **não comprova** validade da nota.
2. Tratar código de fornecedor versus código interno; não assumir equivalência. Conferir NCM, unidade (UN, CX, etc.), fator de conversão e preço de custo.
3. Criar RPC SECURITY DEFINER com autorização administrativa e search_path fixo, tipos verificados, limites de lote, bloqueio de duplicação e auditoria.
4. No banco, criar chave única para importação por chave de acesso; gravar o lote, os novos produtos e entradas num único procedimento transacional, sem entradas parciais.
5. Produtos novos devem ser cadastrados após confirmação explícita, com estoque inicial zero ou dentro da mesma transação fiscalmente validada; nunca lançar quantidade automaticamente usando apenas informação do fornecedor.
6. Cobrir concorrência com índice único e testes de duas sessões; prever idempotência e retorno consistente após erro de rede.
7. Conferir políticas RLS, triggers, privilégios e recuperação/estorno antes de produção.

## Testes
- XML de teste com 2 produtos novos: preencher campos, conferir códigos e garantir **zero writes**.
- Produto já cadastrado por código ou EAN: bloquear preparação.
- Mesmo código em duas linhas: bloquear.
- Falha de rede e sessão encerrada: bloquear.
- No futuro: teste transacional isolado, depois homologação com nota autorizada e aprovação do responsável fiscal.

**Esta PR não habilita cadastro definitivo.** A alteração é etapa segura preparatória, sujeita a revisão antes de merge.
