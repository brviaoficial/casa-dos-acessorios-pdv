-- Casa dos Acessórios — teste CONTROLADO de uma entrada fictícia.
-- Substitui a versão proposta anteriormente, que era ampla demais.
-- Requer a tabela xml_entradas_teste já criada e a função eh_administrador().
-- Não executar antes de revisar no Supabase. A execução instala a função;
-- NÃO movimenta estoque até que a função seja chamada explicitamente.
CREATE OR REPLACE FUNCTION public.registrar_entrada_xml_teste(
    p_chave_nfe text, p_itens jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_id uuid;
    v_produto uuid;
    v_estoque integer;
BEGIN
    IF auth.uid() IS NULL OR NOT public.eh_administrador() THEN
        RAISE EXCEPTION 'Acesso não autorizado';
    END IF;
    IF p_chave_nfe IS NULL OR p_chave_nfe !~ '^[0-9]{44}$' THEN
        RAISE EXCEPTION 'Chave da nota inválida';
    END IF;
    IF p_itens IS NULL
       OR jsonb_typeof(p_itens) IS DISTINCT FROM 'array'
       OR jsonb_array_length(p_itens) <> 1 THEN
        RAISE EXCEPTION 'Informe exatamente um item';
    END IF;
    IF jsonb_typeof(p_itens->0) IS DISTINCT FROM 'object'
       OR (p_itens->0->>'quantidade') IS DISTINCT FROM '3' THEN
        RAISE EXCEPTION 'Teste limitado a 3 unidades';
    END IF;

    SELECT id, quantidade INTO STRICT v_produto, v_estoque
    FROM public.produtos
    WHERE codigo = 'TESTE-XML-001'
      AND nome = 'TESTE XML - CALOTA FICTICIA'
      AND ativo IS TRUE
    FOR UPDATE;

    IF p_itens->0->>'produto_id' IS DISTINCT FROM v_produto::text THEN
        RAISE EXCEPTION 'Produto não autorizado para teste';
    END IF;
    -- A trava da linha impede duas entradas simultâneas. Mesmo usando
    -- outra chave fictícia, o teste só pode passar de 0 para 3 uma vez.
    IF COALESCE(v_estoque, 0) <> 0 THEN
        RAISE EXCEPTION 'Estoque de teste já movimentado; não repetir';
    END IF;

    INSERT INTO public.xml_entradas_teste(chave_nfe, usuario_id, itens)
    VALUES (p_chave_nfe, auth.uid(), p_itens)
    RETURNING id INTO v_id;

    UPDATE public.produtos
    SET quantidade = 3
    WHERE id = v_produto;
    RETURN v_id;
END;
$$;
REVOKE ALL ON FUNCTION public.registrar_entrada_xml_teste(text,jsonb)
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.registrar_entrada_xml_teste(text,jsonb)
TO authenticated;

-- O teste usa chave fictícia, não verifica autenticidade/autorização de NF-e.
-- NÃO usar para notas fiscais ou produtos reais.
