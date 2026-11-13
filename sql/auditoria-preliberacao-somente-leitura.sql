-- CASA DOS ACESSORIOS | AUDITORIA PRE-LIBERACAO | SOMENTE LEITURA
-- Execute no SQL Editor do Supabase, com permissao para consultar catalogos.
-- NAO executa DDL/DML e NAO consulta senhas, tokens nem dados de clientes.
-- O retorno de RLS/politicas nao substitui teste real com usuarios distintos.

-- 1. Tabelas criticas e status da seguranca por linha (RLS).
SELECT
  c.relname AS tabela,
  c.relrowsecurity AS rls_ativado,
  c.relforcerowsecurity AS rls_forcado,
  CASE WHEN c.relkind = 'p' THEN 'particionada' ELSE 'comum' END AS tipo
FROM pg_catalog.pg_class c
JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relkind IN ('r','p')
  AND c.relname IN (
    'produtos','vendas','itens_venda','caixas','movimentacoes_caixa',
    'movimentacoes_estoque','garagens','clientes','fiados',
    'xml_empresa_destinataria_config','xml_entradas_fase3f_teste'
  )
ORDER BY c.relname;

-- 2. Politicas de RLS existentes (sem exibir linhas de dados).
SELECT
  schemaname, tablename, policyname, roles, cmd,
  qual, with_check
FROM pg_catalog.pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
    'produtos','vendas','itens_venda','caixas','movimentacoes_caixa',
    'movimentacoes_estoque','garagens','clientes','fiados',
    'xml_empresa_destinataria_config'
  )
ORDER BY tablename, policyname;

-- 3. Permissoes concedidas diretamente a anon e authenticated
-- (revise especialmente INSERT/UPDATE/DELETE em tabelas financeiras).
SELECT table_name, grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND grantee IN ('anon','authenticated')
  AND table_name IN (
    'produtos','vendas','itens_venda','caixas','movimentacoes_caixa',
    'movimentacoes_estoque','garagens','clientes','fiados',
    'xml_empresa_destinataria_config'
  )
ORDER BY table_name, grantee, privilege_type;

-- 4. Funcoes de teste e funcoes administrativas que merecem revisao.
SELECT
  p.proname AS funcao,
  pg_catalog.pg_get_function_identity_arguments(p.oid) AS argumentos,
  p.prosecdef AS security_definer,
  pg_catalog.pg_get_userbyid(p.proowner) AS proprietario
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND (
    p.proname ILIKE '%teste%'
    OR p.proname ILIKE '%caixa%'
    OR p.proname ILIKE '%venda%'
    OR p.proname ILIKE '%fiado%'
  )
ORDER BY p.proname;
