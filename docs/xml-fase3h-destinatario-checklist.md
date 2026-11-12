# Fase 3H — Identificação da empresa destinatária

## Escopo da primeira entrega
Proposta de tabela privada `xml_empresa_destinataria_config` (uma única linha) e RPC `conferir_destinatario_xml_previa(text)` para verificar se o CNPJ indicado no XML coincide com o CNPJ configurado da empresa. Resposta da RPC contém apenas status e booleano, não retorna o CNPJ armazenado. Administração autenticada obrigatória.

**Não ativado:** SQL não executado; nenhum cadastro foi feito; não há botão novo no PDV e a importação fiscal real permanece bloqueada.

## Segurança e limitações
- Configurar o CNPJ apenas pelo Supabase/serviço privado após confirmá-lo com documento fiscal da loja. Nunca colocar o CNPJ em HTML, constantes do JavaScript, parâmetros de URL ou commits.
- Proteger a tabela com RLS ativado, sem política de leitura direta para anon/authenticated, e privilégios revogados. Revisar o proprietário da função SECURITY DEFINER e os privilégios efectivos antes de instalar.
- A função compara o número **enviado pelo cliente**. Um cliente pode mentir: a confirmação não autentica XML e não permite importação real. A validação de nota e destinatário precisará ocorrer por backend que verifica o próprio arquivo e a autorização da SEFAZ, não dados enviados isoladamente pelo navegador.
- Validar o CNPJ da configuração (dígitos verificadores, matriz/filial, empresa destinatária correta). O CHECK da tabela verifica apenas o formato. Eventuais regras de filial dependem do cadastro da loja.
- Não reutilizar RPCs/testes fictícios das Fases 3E e 3F como importação real.
- Não divulgar credenciais Supabase: usar apenas chave publicável no navegador; chave service role somente em servidor seguro.

## Testes antes de qualquer mudança real
1. Inspecionar estrutura, triggers, RLS, owners e permissões do Supabase.
2. Revisar a DDL em banco isolado; confirmar que instalar a função não altera produtos nem estoque.
3. Confirmar retorno `Acesso não autorizado` a usuários sem permissão e não autenticados.
4. Com a configuração vazia, retorno `empresa_nao_configurada`.
5. Em banco isolado com CNPJ fictício válido configurado, confirmar `cnpj_igual_ao_configurado` e `destinatario_divergente`.
6. Garantir que o retorno e logs não exponham o CNPJ configurado.
7. Separar em outra etapa a integração UI somente leitura e mais tarde a validação fiscal no servidor.

## Entregas futuras para importação real
Verificar assinatura digital, status atual na SEFAZ/eventos, CNPJ destinatário e fornecedor, chave NF-e repetida, CFOP, diferenças de unidade comercial/tributável, itens/GTIN e mapeamento código do fornecedor vs SKU da loja. Movimentar estoque só por transação atômica autorizada no backend, com auditoria e prevenção de repetição.
