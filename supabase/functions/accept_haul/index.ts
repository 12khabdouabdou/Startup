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

    // Verify this is a hauler
    const { data: profile } = await supabase.from('profiles').select('role,verification_status').eq('id', user.id).single()
    if (profile?.role !== 'hauler') {
      return new Response(JSON.stringify({ error: 'Only haulers can accept hauls' }), { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }
    if (profile?.verification_status !== 'approved') {
      return new Response(JSON.stringify({ error: 'Hauler not approved' }), { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // Check if haul is still open
    const { data: haul, error: haulErr } = await supabase
      .from('hauls')
      .select('*')
      .eq('id', haul_id)
      .eq('status', 'open')
      .single()
    if (haulErr || !haul) {
      return new Response(JSON.stringify({ error: 'Haul not available' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // Update haul status
    const { data: updated, error } = await supabase
      .from('hauls')
      .update({ hauler_id: user.id, status: 'accepted' })
      .eq('id', haul_id)
      .select()
      .single()
    if (error) throw error

    // Update waste post status
    await supabase.from('waste_posts').update({ status: 'in_transit' }).eq('id', haul.waste_post_id)

    return new Response(JSON.stringify({ haul: updated }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})
