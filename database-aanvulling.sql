-- Voer dit één keer uit in Supabase SQL Editor.
-- Bevestig een aanvraag en maak de planning aan in één transactie.
CREATE OR REPLACE FUNCTION public.bevestig_aanvraag(
  p_aanvraag uuid, p_werf uuid, p_werk text,
  p_begin date, p_eind date, p_beginuur time, p_einduur time,
  p_opmerkingen text, p_status text
) RETURNS void LANGUAGE plpgsql SECURITY INVOKER
SET search_path = '' AS $$
DECLARE k uuid;
BEGIN
  IF NOT public.is_beheerder() THEN RAISE EXCEPTION 'Geen toegang'; END IF;
  SELECT klant_id INTO k FROM public.aanvragen
    WHERE id = p_aanvraag AND status = 'Nieuw' FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Aanvraag is niet meer open'; END IF;
  INSERT INTO public.planning(klant_id, werf_id, werkzaamheden,
    begindatum, einddatum, beginuur, einduur, opmerkingen, status)
  VALUES(k, p_werf, p_werk, p_begin, p_eind, p_beginuur,
    p_einduur, p_opmerkingen, p_status);
  UPDATE public.aanvragen SET status='Bevestigd' WHERE id=p_aanvraag;
END; $$;
REVOKE ALL ON FUNCTION public.bevestig_aanvraag(uuid,uuid,text,date,date,time,time,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.bevestig_aanvraag(uuid,uuid,text,date,date,time,time,text,text) TO authenticated;

-- Expliciete rechten voor de bestaande RLS-beleidsregels.
GRANT SELECT, INSERT, UPDATE, DELETE ON public.klanten, public.profielen,
 public.werven, public.planning, public.aanvragen TO authenticated;
REVOKE ALL ON public.klanten, public.profielen, public.werven,
 public.planning, public.aanvragen FROM anon;
