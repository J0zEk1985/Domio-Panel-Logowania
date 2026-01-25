import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

/**
 * Edge Function: create-worker
 * Creates simplified worker accounts in Hub database
 * 
 * Accepts: slug, pin, firstName, lastName, orgId
 * Returns: userId, email
 */

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://cleaning.domio.com.pl',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

interface CreateWorkerRequest {
  slug: string
  pin: string
  firstName: string
  lastName: string
  orgId: string
}

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get environment variables
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!supabaseUrl || !serviceRoleKey) {
      console.error('[create-worker] Missing environment variables')
      return new Response(
        JSON.stringify({ error: 'Server configuration error' }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Create admin client with service role key
    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    })

    // Parse request body
    const body: CreateWorkerRequest = await req.json()

    // Validate required fields
    if (!body.slug || !body.pin || !body.firstName || !body.lastName || !body.orgId) {
      console.error('[create-worker] Missing required fields:', body)
      return new Response(
        JSON.stringify({ error: 'Missing required fields: slug, pin, firstName, lastName, orgId' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Generate technical email
    const technicalEmail = `${body.slug.toLowerCase()}@staff.domio.com.pl`
    const fullName = `${body.firstName} ${body.lastName}`

    console.log(`[create-worker] Creating worker account for: ${technicalEmail}`)

    // Attempt to create auth user (idempotent approach)
    const { data: authUser, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: technicalEmail,
      password: body.pin,
      email_confirm: true,
      user_metadata: {
        firstName: body.firstName,
        lastName: body.lastName,
        is_simplified: true,
      },
    })

    let userId: string
    let isNewUser = false // Track if we just created the user (for cleanup on error)

    // Handle existing user case (idempotent behavior)
    if (authError) {
      const errorMessage = authError.message?.toLowerCase() || ''
      
      // Check if user already exists (common error messages)
      if (
        errorMessage.includes('already registered') ||
        errorMessage.includes('user already exists') ||
        errorMessage.includes('already exists')
      ) {
        console.log(`[create-worker] User ${technicalEmail} already exists, fetching ID from profiles`)
        
        // Fetch existing user ID from profiles table
        const { data: existingProfile, error: profileFetchError } = await supabaseAdmin
          .from('profiles')
          .select('id')
          .eq('email', technicalEmail)
          .single()

        if (profileFetchError || !existingProfile?.id) {
          console.error('[create-worker] Error fetching existing profile:', profileFetchError)
          return new Response(
            JSON.stringify({ 
              error: 'User exists but profile not found',
              details: profileFetchError?.message || 'Profile lookup failed'
            }),
            {
              status: 500,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            }
          )
        }

        userId = existingProfile.id
        isNewUser = false // User already existed
        console.log(`[create-worker] Found existing user ID: ${userId}`)
      } else {
        // Other error - not related to existing user
        console.error('[create-worker] Error creating auth user:', authError)
        return new Response(
          JSON.stringify({ 
            error: 'Failed to create user account',
            details: authError.message 
          }),
          {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        )
      }
    } else if (!authUser?.user) {
      console.error('[create-worker] Auth user creation returned no user data')
      return new Response(
        JSON.stringify({ 
          error: 'Failed to create user account',
          details: 'No user data returned'
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    } else {
      userId = authUser.user.id
      isNewUser = true // User was just created
      console.log(`[create-worker] Auth user created successfully: ${userId}`)
    }

    // Upsert profile in Hub database
    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .upsert({
        id: userId,
        full_name: fullName,
        email: technicalEmail,
        accepted_terms_at: new Date().toISOString(),
        terms_version: '1.0',
        account_type: 'simplified',
        is_first_login: true,
        preferences: {
          firstName: body.firstName,
          lastName: body.lastName,
          orgId: body.orgId,
          is_simplified: true,
        },
      }, {
        onConflict: 'id',
      })

    if (profileError) {
      console.error('[create-worker] Error upserting profile:', profileError)
      
      // Only attempt to clean up auth user if we just created it (idempotent behavior)
      if (isNewUser) {
        await supabaseAdmin.auth.admin.deleteUser(userId)
        console.log(`[create-worker] Cleaned up auth user ${userId} due to profile creation failure`)
      }

      return new Response(
        JSON.stringify({ 
          error: 'Failed to create user profile',
          details: profileError.message 
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    console.log(`[create-worker] Profile created successfully for user: ${userId}`)

    // Return success response
    return new Response(
      JSON.stringify({
        userId,
        email: technicalEmail,
        message: 'Worker account created successfully',
      }),
      {
        status: 201,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )

  } catch (error) {
    console.error('[create-worker] Unexpected error:', error)
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        details: error instanceof Error ? error.message : 'Unknown error'
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})
