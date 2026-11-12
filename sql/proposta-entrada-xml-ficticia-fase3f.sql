-- FASE 3F - PROPOSTA; NÃO EXECUTAR NO SUPABASE ANTES DA REVISÃO
-- APENAS os dois produtos TESTE cadastrados na Fase 3E.
-- Não é uma importação de NF-e real: a origem ainda não foi validada fiscalmente.
-- Instalar este SQL não movimenta estoque. A RPC, quando acionada por admin,
-- adicionará 20 unidades à CALOTA-ARO14 e 100 à PRESILHA-TESTE.
--
-- Tabela de idempotência específica deste ensaio (não reutiliza xml_entradas_teste
-- nem a chave fictícia 999... empregada no ensaio anterior).
CREATE TABLE IF NOT EXISTS public.xml_entradas_fase3f_teste (
    chave_teste text PRIMARY KEY,
    criado_em timestamptz NOT NULL DEFAULT now(),
    executado_por uuid NOT NULL
);
ALTER TABLE public.xml_entradas_fase3f_teste ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.xml_entradas_fase3f_teste FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.registrar_entrada_xml_fase3f_teste()
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
    v_chave constant text := 'FASE3F-NFE-FICTICIA-12345-SERIE1';
    v_calota_id uuid;
    v_presilha_id uuid;
    v_calota_nome text;
    v_presilha_nome text;
    v_calota_q integer;
    v_presilha_q integer;
    v_calota_ativo boolean;
    v_presilha_ativo boolean;
BEGIN
    IF auth.uid() IS NULL OR NOT public.eh_administrador() THEN
        RAISE EXCEPTION 'Acesso não autorizado';
    END IF;

    -- Trava de execução para este teste (a PK também bloqueia repetição).
    PERFORM pg_catalog.pg_advisory_xact_lock(312025, 6);
    IF EXISTS (
        SELECT 1 FROM public.xml_entradas_fase3f_teste
        WHERE chave_teste = v_chave
    ) THEN
        RAISE EXCEPTION 'Esta entrada fictícia já foi registrada';
    END IF;

    SELECT id,nome,quantidade,ativo
      INTO v_calota_id,v_calota_nome,v_calota_q,v_calota_ativo
      FROM public.produtos
     WHERE codigo='CALOTA-ARO14'
     FOR UPDATE;
    IF NOT FOUND OR v_calota_nome <> 'CALOTA ARO 14 - MODELO TESTE'
       OR v_calota_q IS DISTINCT FROM 0 OR v_calota_ativo IS DISTINCT FROM true THEN
        RAISE EXCEPTION 'Calota de teste ausente, alterada ou com estoque diferente de zero';
    END IF;

    SELECT id,nome,quantidade,ativo
      INTO v_presilha_id,v_presilha_nome,v_presilha_q,v_presilha_ativo
      FROM public.produtos
     WHERE codigo='PRESILHA-TESTE'
     FOR UPDATE;
    IF NOT FOUND OR v_presilha_nome <> 'PRESILHA AUTOMOTIVA - MODELO TESTE'
       OR v_presilha_q IS DISTINCT FROM 0 OR v_presilha_ativo IS DISTINCT FROM true THEN
        RAISE EXCEPTION 'Presilha de teste ausente, alterada ou com estoque diferente de zero';
    END IF;

    -- O INSERT e ambos os UPDATEs estão na mesma transação do PostgreSQL.
    INSERT INTO public.xml_entradas_fase3f_teste(chave_teste,executado_por)
    VALUES (v_chave,auth.uid());

    UPDATE public.produtos SET quantidade=20
    WHERE id=v_calota_id AND quantidade=0;
    IF NOT FOUND THEN RAISE EXCEPTION 'Falha ao atualizar calota fictícia'; END IF;

    UPDATE public.produtos SET quantidade=100
    WHERE id=v_presilha_id AND quantidade=0;
    IF NOT FOUND THEN RAISE EXCEPTION 'Falha ao atualizar presilha fictícia'; END IF;

    RETURN jsonb_build_object(
        'chave_teste',v_chave,
        'produtos',jsonb_build_array(
            jsonb_build_object('codigo','CALOTA-ARO14','anterior',0,'entrada',20,'atual',20),
            jsonb_build_object('codigo','PRESILHA-TESTE','anterior',0,'entrada',100,'atual',100)
        )
    );
END;
$$;

REVOKE ALL ON FUNCTION public.registrar_entrada_xml_fase3f_teste()
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.registrar_entrada_xml_fase3f_teste()
TO authenticated;

-- NÃO CHAMAR A RPC PELO SQL EDITOR COMO ADMIN DE BANCO:
-- exige JWT de administrador do PDV. Instalação e execução são passos separados.
