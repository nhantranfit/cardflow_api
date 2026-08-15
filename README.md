# CardFlow API

I built this as a Rails API assignment for a gift-card style backend: admins manage brands/products/clients, clients issue and cancel cards, both can pull simple reports.

Stack is Ruby **3.1**, Rails **7.1** (API-only), PostgreSQL, JWT, Pundit, ActiveModelSerializers, RSpec. I stuck to normal Rails stuff and avoided inventing extra tables where the domain already lives on `Card`.

## Who does what

There’s one `User` model with `admin` / `client`.

- **Admin** — brands, products, clients, assign which products a client can sell, reports filtered by brand/client.
- **Client** — browse their assigned catalog, issue a card, cancel it, report on their own spending/cancellations.

Important rule (confirmed with the brief):

`purchase_amount = product.price * client.payout_rate`

That number is stored on the card when it’s issued. If price or payout rate changes later, old cards keep the old amount.

Card status is just `issued` or `cancelled`.

## Setup

You’ll want Ruby 3.1.0 specifically (I hit gem build issues on newer Bundler/psych with this pin). Postgres running locally.

```bash
bundle install
bin/rails db:setup   # migrate + seed
bin/rails s
bundle exec rspec    # when you want tests
```

Seed logins (password for all: `password123`):

- `admin@example.com` — admin
- `client1@example.com` — payout 0.8
- `client2@example.com` — payout 0.75
- `client3@example.com` — payout 0.9

`db:seed` also drops in a few brands/products and wires client access so you can hit issue-card without setting everything up by hand.

## Auth

```http
POST /api/v1/auth/login
{ "email": "...", "password": "..." }
```

You get a JWT. Then:

```http
Authorization: Bearer <token>
```

`GET /api/v1/auth/me` returns the current user. No/bad token → 401.

## API (quick map)

Base: `/api/v1`

**Brands** (admin): `GET/POST /brands`, `PATCH|PUT/DELETE /brands/:id`  
Body: `{ "brand": { "name", "description", "status" } }` — status `active`/`inactive`.

**Products**

- Admin CRUD: `/products`
- Client `GET /products` is their catalog only (assigned + active). Optional filters: `brand_id`, `search`, `status`.

Body: `{ "product": { "brand_id", "name", "price", "status" } }`

**Clients** (admin): `GET/POST /clients`, `PATCH|PUT/DELETE /clients/:id`  
Clients need a `payout_rate` (0–1).

**Assign catalog** (admin)

- `POST /clients/:client_id/products` — pass `product_id`
- `DELETE /clients/:client_id/products/:product_id`

**Cards** (client)

- `GET /cards` — own cards
- `POST /cards` — issue:

```json
{ "card": { "product_id": 123 } }
```

Don’t send amount / status / activation_number — server fills those in (access check, active product, amount snapshot, unique activation number).

- `PATCH /cards/:id/cancel` — owner only, and only if still `issued`.

**Reports** — `GET /reports` for both roles, same JSON shape:

```json
{
  "reports": [
    {
      "date": "...",
      "operation": "Issued",
      "client": "client1@example.com",
      "brand_name": "NIKE",
      "product_name": "Nike Gift Card 100",
      "amount": 80.0
    }
  ]
}
```

Query params:

- `status=spending` → issued only  
- `status=cancellations` → cancelled only  
- omit → both  

Admin can also pass `brand_id` and/or `client_id`. Client params for those are ignored (scope is always the logged-in client). Use `/brands` and `/clients` to pick IDs.

Errors are the usual: 403 authz, 404 missing, 422 validation.

## Typical flow

1. Admin logs in → create brand → product → client → assign product to client.  
2. Client logs in → `GET /products` → `POST /cards` with a `product_id` they can access.  
3. Later `PATCH /cards/:id/cancel` if needed.  
4. `GET /reports` (client: own ops; admin: filter by brand/client).

## Action logs

Mutating actions (and successful login) write an `ActionLog` row via a small service. That’s for accountability. There’s no “list audit logs” endpoint yet — data is in the DB if you want to inspect it.

## Layout

```text
app/controllers/api/v1/   thin controllers
app/models/
app/policies/             Pundit
app/queries/              catalog + reports
app/services/             IssueCard, ActionLogService, JWT
app/serializers/
spec/
```

I only pulled a service object out for issuing a card (access + amount + activation + create). Reports are just queries over `Card`; no separate report table.
