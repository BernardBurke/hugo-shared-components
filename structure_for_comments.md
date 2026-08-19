Done. The user identity flow is indeed the tricky part, but you have a few clean options depending on how your email-OTP gate works:

**If using Cloudflare Access (Zero Trust) with email OTP**

The email is in the `CF-Access-Authenticated-User-Email` header (or the JWT claims) that Access sends to your Worker. You can trust this completely—it's signed by Cloudflare. Your comment Worker just needs to verify the JWT and extract the email.

**If using a custom OTP Worker**

You'll need to maintain a session yourself. Common approaches:

| Approach | How it works | Trade-off |
|----------|--------------|-----------|
| **Signed cookie** | Verify OTP, set a `session` cookie with `email` + `exp` signed by a secret key | Simple, but requires cookie parsing in every Worker |
| **KV session store** | OTP success → write session token → KV, return token in cookie or header | Slightly more latency, easier to revoke |
| **D1 session table** | Same as KV but relational; good if you want to track login history | Same latency, more complex |

For your SSP stack, I'd lean toward **signed cookies** if you want minimal infrastructure, or **KV tokens** if you want explicit session control (logout, revoke, etc.).

**A practical pattern**

Your auth Worker (the one handling OTP) sets a cookie like:

```
session=<base64>.<signature>; HttpOnly; Secure; SameSite=Strict; Path=/; Max-Age=86400
```

Where the payload is `{"email":"user@example.com","exp":1234567890}` and the signature is HMAC-SHA256 with a secret.

Your comment Worker then:
1. Reads the cookie
2. Verifies the signature
3. Extracts the email
4. Writes to D1 with that email as `user_id`

**Edge case: email changes**

If a user changes their email, you have two comments tables with different `user_id` values. You can either:
- Accept it (comments are tied to email-at-time-of-writing)
- Add a `users` table with stable UUIDs, update the email there, and reference UUID in comments

For SSP, stable UUIDs are probably worth it. Your auth flow becomes: verify session → lookup or create user by email → get UUID → use UUID for all comment operations.

Want me to sketch the session cookie code or the D1 schema with user UUIDs?
