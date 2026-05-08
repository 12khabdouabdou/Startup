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

    const { haul_id } = await req.json()

    // Verify hauler owns this haul and status is in_transit
    const { data: haul, error: haulErr } = await supabase
      .from('hauls')
      .select('*,waste_posts!inner(price,commission_rate,developer_id)')
      .eq('id', haul_id)
      .eq('hauler_id', user.id)
      .eq('status', 'in_transit')
      .single()
    if (haulErr || !haul) {
      return new Response(JSON.stringify({ error: 'Haul not found or invalid status' }), { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // Update waste post and haul status
    await supabase.from('waste_posts').update({ status: 'delivered' }).eq('id', haul.waste_post_id)
    const { data: updated, error } = await supabase
      .from('hauls')
      .update({ status: 'delivered', delivery_confirmed_at: new Date().toISOString() })
      .eq('id', haul_id)
      .select()
      .single()
    if (error) throw error

    return new Response(JSON.stringify({ haul: updated }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})
