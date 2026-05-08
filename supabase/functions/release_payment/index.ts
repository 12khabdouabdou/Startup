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
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    const { haul_id, amount } = await req.json()

    // Fetch haul with related data
    const { data: haul, error: haulErr } = await supabase
      .from('hauls')
      .select('*,waste_posts!inner(price,commission_rate,developer_id)')
      .eq('id', haul_id)
      .eq('status', 'delivered')
      .single()
    if (haulErr || !haul) {
      return new Response(JSON.stringify({ error: 'Haul not found or not delivered' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const price = amount || haul.waste_posts.price || 0
    const commissionRate = haul.waste_posts.commission_rate || 0.10
    const platformCommission = price * commissionRate
    const developerShare = (price - platformCommission) * 0.6
    const haulerShare = (price - platformCommission) * 0.4

    // Record payment
    const { data: payment, error } = await supabase
      .from('payments')
      .insert({
        haul_id,
        payer_id: haul.recycler_id,
        amount: price,
        platform_commission: platformCommission,
        developer_share: developerShare,
        hauler_share: haulerShare,
        status: 'pending',
      })
      .select()
      .single()
    if (error) throw error

    // Mark haul as paid
    await supabase.from('hauls').update({ status: 'paid' }).eq('id', haul_id)

    return new Response(JSON.stringify({ payment }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})
