import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
    )

    const authHeader = req.headers.get('Authorization')!
    const { data: { user } } = await supabase.auth.getUser(authHeader)
    if (!user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const { haul_id, lat, lng } = await req.json()

    // Verify hauler owns this haul
    const { data: haul, error: haulErr } = await supabase
      .from('hauls')
      .select('*')
      .eq('id', haul_id)
      .eq('hauler_id', user.id)
      .single()
    if (haulErr || !haul) {
      return new Response(JSON.stringify({ error: 'Haul not found' }), { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const { data, error } = await supabase
      .from('tracking_events')
      .insert({
        haul_id,
        position: `POINT(${lng} ${lat})`,
      })
      .select()
      .single()
    if (error) throw error

    return new Response(JSON.stringify({ tracking_event: data }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})
