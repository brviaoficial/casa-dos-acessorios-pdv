-- FASE 3E: PROPOSTA DE TESTE. NÃO EXECUTAR SEM REVISAR NO SUPABASE.
-- Cadastra SOMENTE duas peças fictícias, ambas com quantidade inicial ZERO.
-- Não registra NF-e real, não importa estoque nem modifica produtos existentes.
-- Requer public.produtos (campos: nome, codigo, codigo_barras, categoria,
-- localizacao, preco_custo, preco_venda, quantidade, estoque_minimo, ativo).
-- Requer public.eh_administrador() testada para usuário autenticado.
CREATE OR REPLACE FUNCTION public.cadastrar_produtos_xml_ficticios_teste(
    p_itens jsonb
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
    v_item jsonb;
    v_codigo text;
    v_nome text;
    v_categoria text;
    v_localizacao text;
    v_preco numeric;
    v_custo numeric;
    v_ids jsonb := '[]'::jsonb;
    v_codes text[] := ARRAY[]::text[];
    v_count integer := 0;
    v_id uuid;
BEGIN
    IF auth.uid() IS NULL OR NOT public.eh_administrador() THEN
        RAISE EXCEPTION 'Acesso não autorizado';
    END IF;
    IF p_itens IS NULL OR jsonb_typeof(p_itens) <> 'array'
        OR jsonb_array_length(p_itens) <> 2 THEN
        RAISE EXCEPTION 'Teste exige exatamente duas peças fictícias';
    END IF;
    -- Serializa tentativas simultâneas deste teste, além da chave única da tabela.
    PERFORM pg_catalog.pg_advisory_xact_lock(312025, 3);
    FOR v_item IN SELECT value FROM jsonb_array_elements(p_itens) LOOP
        IF jsonb_typeof(v_item) <> 'object' THEN
            RAISE EXCEPTION 'Item inválido';
        END IF;
        v_codigo := nullif(btrim(v_item->>'codigo'), '');
        v_nome := nullif(btrim(v_item->>'nome'), '');
        v_categoria := nullif(btrim(v_item->>'categoria'), '');
        v_localizacao := nullif(btrim(v_item->>'localizacao'), '');
        IF v_codigo IS NULL OR v_nome IS NULL OR v_categoria IS NULL
           OR v_localizacao IS NULL THEN
            RAISE EXCEPTION 'Campos obrigatórios ausentes';
        END IF;
        IF length(v_categoria)>160 OR length(v_localizacao)>160 THEN
            RAISE EXCEPTION 'Categoria/localização muito longa';
        END IF;
        -- Nunca aceitar GTIN, quantidade ou parâmetros arbitrários na versão fictícia.
        IF v_item->>'codigo_barras' NOT IN ('', 'SEM GTIN')
           AND v_item->>'codigo_barras' IS NOT NULL THEN
            RAISE EXCEPTION 'Código de barras deve estar vazio neste teste';
        END IF;
        IF v_item ? 'quantidade' AND v_item->>'quantidade' <> '0' THEN
            RAISE EXCEPTION 'Estoque inicial deve ser zero';
        END IF;
        IF v_codigo = ANY(v_codes) THEN
            RAISE EXCEPTION 'Código repetido na solicitação';
        END IF;
        v_codes := array_append(v_codes, v_codigo);

        IF v_codigo = 'CALOTA-ARO14' THEN
            IF v_nome <> 'CALOTA ARO 14 - MODELO TESTE' THEN
                RAISE EXCEPTION 'Nome da calota não corresponde ao teste';
            END IF;
            v_custo := 18.50;
        ELSIF v_codigo = 'PRESILHA-TESTE' THEN
            IF v_nome <> 'PRESILHA AUTOMOTIVA - MODELO TESTE' THEN
                RAISE EXCEPTION 'Nome da presilha não corresponde ao teste';
            END IF;
            v_custo := 0.75;
        ELSE
            RAISE EXCEPTION 'Código não autorizado para teste: %', v_codigo;
        END IF;
        IF (v_item->>'preco_venda') IS NULL OR
            (v_item->>'preco_venda') !~ '^[0-9]{1,6}([.][0-9]{1,2})?$' THEN
            RAISE EXCEPTION 'Preço de venda inválido';
        END IF;
        v_preco := (v_item->>'preco_venda')::numeric;
        IF v_preco <= 0 THEN RAISE EXCEPTION 'Preço de venda inválido'; END IF;

        IF EXISTS(SELECT 1 FROM public.produtos WHERE codigo = v_codigo) THEN
            RAISE EXCEPTION 'Produto já cadastrado: %',v_codigo;
        END IF;
        INSERT INTO public.produtos
            (nome,codigo,codigo_barras,categoria,localizacao,preco_custo,
             preco_venda,quantidade,estoque_minimo,ativo)
        VALUES
            (v_nome,v_codigo,NULL,v_categoria,v_localizacao,v_custo,
             v_preco,0,0,true)
        RETURNING id INTO v_id;
        v_ids := v_ids || jsonb_build_object('id',v_id,'codigo',v_codigo);
        v_count := v_count + 1;
    END LOOP;
    IF v_count<>2 OR NOT(v_codes @> ARRAY['CALOTA-ARO14','PRESILHA-TESTE']::text[]) THEN
        RAISE EXCEPTION 'É obrigatório informar as duas peças do teste';
    END IF;
    RETURN jsonb_build_object('total',v_count,'produtos',v_ids);
END;
$$;
REVOKE ALL ON FUNCTION public.cadastrar_produtos_xml_ficticios_teste(jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.cadastrar_produtos_xml_ficticios_teste(jsonb) TO authenticated;

-- IMPORTANTE: antes da execução, conferir regras RLS e se não há outros
-- campos NOT NULL/triggers ou privilégios diferentes no banco atual.
-- A instalação não cadastra produtos. O cadastro só ocorre em chamada RPC
-- autenticada, após revisão e autorização explícita do administrador.
