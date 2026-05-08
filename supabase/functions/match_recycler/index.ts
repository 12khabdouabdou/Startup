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

    const { waste_post_id, accepted_price } = await req.json()

    // Verify recycler role
    const { data: profile } = await supabase.from('profiles').select('role').eq('id', user.id).single()
    if (profile?.role !== 'recycler') {
      return new Response(JSON.stringify({ error: 'Only recyclers can select waste' }), { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // Check if post is still available
    const { data: post, error: postErr } = await supabase
      .from('waste_posts')
      .select('*')
      .eq('id', waste_post_id)
      .eq('status', 'posted')
      .single()
    if (postErr || !post) {
      return new Response(JSON.stringify({ error: 'Waste post not available' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // Create selection
    const { data: selection, error: selErr } = await supabase
      .from('waste_selections')
      .insert({ waste_post_id, recycler_id: user.id, accepted_price })
      .select()
      .single()
    if (selErr) throw selErr

    // Update post status and price
    await supabase.from('waste_posts').update({ status: 'selected', price: accepted_price }).eq('id', waste_post_id)

    // Create haul
    const { data: haul } = await supabase
      .from('hauls')
      .insert({
        waste_post_id,
        recycler_id: user.id,
        status: 'open',
        pickup_location: post.location,
        delivery_location: post.location // Will be updated later
      })
      .select()
      .single()

    return new Response(JSON.stringify({ selection, haul }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})
