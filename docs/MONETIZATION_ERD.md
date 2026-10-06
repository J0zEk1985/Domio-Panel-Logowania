# DOMIO Monetization - Entity Relationship Diagram

## 📊 Database Schema Visualization

### Entity Relationship Diagram (ERD)

```mermaid
erDiagram
    organizations ||--o{ module_subscriptions : "purchaser"
    organizations ||--o{ module_access_grants : "has"
    
    communities ||--o{ module_subscriptions : "beneficiary"
    communities ||--o{ module_access_grants : "has"
    communities ||--o{ community_units : "contains"
    
    pricing_plans ||--o{ module_subscriptions : "defines"
    pricing_plans ||--o{ subscription_payment_intents : "used_by"
    
    module_subscriptions ||--o{ subscription_events : "logs"
    module_subscriptions ||--|{ module_access_grants : "grants"
    module_subscriptions ||--o| subscription_payment_intents : "fulfilled_by"
    
    profiles ||--o{ subscription_events : "triggers"
    profiles ||--o{ module_access_grants : "manually_granted_by"
    
    organizations {
        uuid id PK
        text name
        text slug
        text nip
        text address
    }
    
    communities {
        uuid id PK
        uuid org_id FK
        text name
        text nip
        text legal_name
    }
    
    community_units {
        uuid id PK
        uuid org_id FK
        uuid community_id FK
        uuid location_id FK
        text unit_number
        text kind "residential|technical"
    }
    
    pricing_plans {
        uuid id PK
        app_module module "home|developer_warranty|etc"
        text display_name
        boolean is_global
        boolean is_unit_based
        numeric price_per_unit
        numeric min_price
        numeric price_monthly
        numeric price_yearly
        boolean is_active
    }
    
    module_subscriptions {
        uuid id PK
        uuid purchaser_org_id FK
        uuid beneficiary_community_id FK
        uuid invoice_entity_community_id FK
        uuid plan_id FK
        app_module module
        subscription_status status
        integer paid_unit_count
        integer current_unit_count
        billing_interval billing_interval
        numeric amount_paid
        timestamptz purchased_at
        timestamptz activated_at
        timestamptz expires_at
        timestamptz blocked_at
        text blocked_reason
    }
    
    module_access_grants {
        uuid id PK
        uuid org_id FK
        uuid community_id FK
        app_module module
        boolean is_granted
        uuid granted_by_subscription_id FK
        boolean is_manual_grant
        text manual_grant_reason
        uuid manual_granted_by FK
        timestamptz granted_at
        timestamptz expires_at
        timestamptz revoked_at
    }
    
    subscription_events {
        uuid id PK
        uuid subscription_id FK
        text event_type
        jsonb event_data
        uuid triggered_by_user_id FK
        timestamptz triggered_at
    }
    
    subscription_payment_intents {
        uuid id PK
        uuid purchaser_org_id FK
        uuid beneficiary_community_id FK
        uuid plan_id FK
        uuid invoice_entity_community_id FK
        text invoice_entity_name
        text invoice_entity_nip
        jsonb invoice_entity_address
        integer unit_count
        numeric calculated_amount
        billing_interval billing_interval
        text status "pending|completed|failed|cancelled"
        text payment_method
        timestamptz payment_confirmed_at
        uuid subscription_id FK
        timestamptz fulfilled_at
        jsonb calculation_details
    }
    
    profiles {
        uuid id PK
        text email
        text full_name
    }
```

## 🔄 Data Flow Diagrams

### Purchase Flow (Home Module)

```mermaid
sequenceDiagram
    participant Admin as Administracja
    participant API as Backend API
    participant DB as Database
    participant Triggers as DB Triggers
    
    Admin->>API: Wybiera wspólnotę + plan home
    API->>DB: count_residential_units_for_community()
    DB-->>API: Liczba lokali (np. 50)
    API->>DB: calculate_unit_based_price(plan_id, 50)
    DB-->>API: Obliczona kwota (np. 125 PLN)
    API-->>Admin: Podsumowanie zamówienia
    
    Admin->>API: Potwierdza zakup
    API->>DB: INSERT subscription_payment_intents
    DB-->>API: payment_intent_id
    API-->>Admin: Przekierowanie do płatności
    
    Admin->>API: Płatność potwierdzona
    API->>DB: INSERT module_subscriptions (status: active)
    Triggers->>DB: sync_subscription_unit_count()
    Triggers->>DB: grant_module_access_on_activation()
    DB->>DB: INSERT module_access_grants
    Triggers->>DB: log_subscription_status_change()
    DB->>DB: INSERT subscription_events (type: created)
    DB->>DB: INSERT subscription_events (type: activated)
    
    DB-->>API: subscription_id
    API-->>Admin: Zakup zakończony sukcesem
```

### Auto-blocking Flow (Unit Threshold Exceeded)

```mermaid
sequenceDiagram
    participant User as Administrator
    participant API as Backend API
    participant DB as Database
    participant Trigger as check_home_subscription_threshold
    
    User->>API: Dodaje nowy lokal do wspólnoty
    API->>DB: INSERT community_units (kind: residential)
    
    Note over DB,Trigger: AFTER INSERT trigger fires
    
    Trigger->>DB: SELECT active home subscriptions for community
    Trigger->>DB: count_residential_units_for_community()
    DB-->>Trigger: current_units = 51
    
    Note over Trigger: paid_unit_count = 50<br/>current_unit_count = 51<br/>THRESHOLD EXCEEDED!
    
    Trigger->>DB: UPDATE module_subscriptions<br/>SET status = 'blocked_pending_payment'
    Trigger->>DB: UPDATE module_access_grants<br/>SET is_granted = false
    Trigger->>DB: INSERT subscription_events<br/>(type: unit_threshold_exceeded)
    
    Note over Trigger: TODO: Send notification to org admins
    
    DB-->>API: Success
    API-->>User: Lokal dodany (z ostrzeżeniem o blokadzie)
```

### Access Check Flow

```mermaid
flowchart TD
    A[Request: has_module_access?] --> B{Check module_access_grants}
    B -->|Found active grant| C{Check expires_at}
    C -->|Not expired| D[✅ Access GRANTED]
    C -->|Expired| E[❌ Access DENIED]
    B -->|No grant found| E
    
    E --> F{Check is_manual_grant?}
    F -->|Yes| G[Check manual_grant_reason]
    F -->|No| H[Check subscription status]
    
    H --> I{Status = active?}
    I -->|Yes| D
    I -->|No| J[❌ Access DENIED<br/>Reason: Subscription not active]
```

## 🏗️ Table Dependencies

```mermaid
graph TD
    organizations[organizations]
    communities[communities]
    pricing_plans[pricing_plans]
    profiles[profiles]
    
    organizations --> communities
    organizations --> subscriptions[module_subscriptions]
    communities --> subscriptions
    communities --> units[community_units]
    pricing_plans --> subscriptions
    
    subscriptions --> grants[module_access_grants]
    subscriptions --> events[subscription_events]
    subscriptions --> payments[subscription_payment_intents]
    
    profiles --> events
    profiles --> grants
    
    style subscriptions fill:#f9f,stroke:#333,stroke-width:4px
    style grants fill:#bbf,stroke:#333,stroke-width:2px
```

## 🔐 Security & RLS Flow

```mermaid
flowchart LR
    A[User Request] --> B{Authenticated?}
    B -->|No| C[❌ 403 Forbidden]
    B -->|Yes| D{Check RLS Policy}
    
    D --> E{is_org_member?}
    E -->|Yes| F[✅ Allow SELECT]
    E -->|No| G{is_admin?}
    
    G -->|Yes| H[✅ Allow INSERT/UPDATE]
    G -->|No| I[❌ 403 Forbidden]
    
    F --> J{Row matches org_id?}
    J -->|Yes| K[✅ Return Data]
    J -->|No| L[❌ No Rows Returned]
```

## 📈 State Machine: Subscription Status

```mermaid
stateDiagram-v2
    [*] --> pending: CREATE payment_intent
    pending --> active: Payment confirmed
    pending --> failed: Payment failed
    pending --> cancelled: User cancelled
    
    active --> blocked_pending_payment: Unit threshold exceeded
    active --> expired: expires_at reached
    active --> cancelled: Admin cancelled
    active --> suspended: Admin suspended
    
    blocked_pending_payment --> active: Payment upgraded
    blocked_pending_payment --> expired: Grace period ended
    blocked_pending_payment --> cancelled: Admin cancelled
    
    suspended --> active: Admin reactivated
    
    expired --> [*]
    failed --> [*]
    cancelled --> [*]
    
    note right of active
        Grant created in
        module_access_grants
    end note
    
    note right of blocked_pending_payment
        Grant revoked
        Notification sent
    end note
```

## 🧩 Module Types & Scopes

```mermaid
mindmap
  root((Modules))
    home
      Per-community
      Unit-based pricing
      Residential units only
      Auto-blocking
    developer_warranty
      Org-wide global
      Flat monthly/yearly
      All communities
      No unit tracking
    fleet
      Org-wide global
      Flat pricing
      Optional
    admin
      Core module
      Always available
      No pricing
    cleaning
      Core module
      Always available
      No pricing
    maintenance
      Core module
      Always available
      No pricing
```

## 💰 Pricing Calculation Logic

```mermaid
flowchart TD
    A[Start: Calculate Price] --> B{Plan Type?}
    
    B -->|Unit-based| C[Get unit count]
    C --> D[Count residential units]
    D --> E[Formula: price_per_unit × unit_count]
    E --> F{Result < min_price?}
    F -->|Yes| G[Return min_price]
    F -->|No| H[Return calculated price]
    
    B -->|Flat rate| I{Billing interval?}
    I -->|Monthly| J[Return price_monthly]
    I -->|Yearly| K[Return price_yearly]
    I -->|One-time| L[Return one_time_price]
    
    G --> M[Round to 2 decimals]
    H --> M
    J --> M
    K --> M
    L --> M
    
    M --> N[End: Return Price]
    
    style E fill:#afa
    style G fill:#faa
    style H fill:#afa
```

## 🔔 Event Logging Flow

```mermaid
flowchart LR
    A[Subscription Change] --> B{Trigger Type}
    
    B -->|INSERT| C[Log 'created']
    B -->|UPDATE status| D[Log status change]
    B -->|Unit threshold| E[Log 'unit_threshold_exceeded']
    
    C --> F[subscription_events table]
    D --> F
    E --> F
    
    F --> G{Notification needed?}
    G -->|Yes| H[Send notification]
    G -->|No| I[End]
    H --> I
    
    style F fill:#bbf
    style H fill:#fbb
```

---

## 📝 Diagram Legend

| Symbol | Meaning |
|--------|---------|
| PK | Primary Key |
| FK | Foreign Key |
| ⚡ | Trigger |
| 🔒 | RLS Protected |
| 📊 | Indexed |
| 🔄 | Auto-updated |

---

**Generated:** 2026-10-06  
**Version:** 1.0  
**Tool:** Mermaid Diagrams
