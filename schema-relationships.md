# TURFMAPP Database Schema Relationships

## Core Entity Relationships

### Projects → Boards → Lists → Cards
```
project (1) ─────→ (∞) board
                       board (1) ─────→ (∞) list
                       board (1) ─────→ (∞) card
                                          card (1) ─────→ (∞) task
                                          card (1) ─────→ (∞) attachment
                                          card (1) ─────→ (∞) action
```

### User Relationships
```
user_account (1) ─────→ (∞) project_manager (∞) ←───── (1) project
user_account (1) ─────→ (∞) board_membership (∞) ←───── (1) board
user_account (1) ─────→ (∞) card_membership (∞) ←────── (1) card
user_account (1) ─────→ (∞) card_subscription (∞) ←──── (1) card
user_account (1) ─────→ (∞) session
user_account (1) ─────→ (∞) notification
user_account (1) ─────→ (∞) identity_provider_user
```

### Card Relationships
```
card (1) ─────→ (∞) card_label (∞) ←───── (1) label
card (1) ─────→ (∞) task
card (1) ─────→ (∞) attachment
card (1) ─────→ (∞) action
card (1) ─────→ (∞) notification
card (1) ─────→ (∞) card_membership
card (1) ─────→ (∞) card_subscription
```

## Table Descriptions

### Primary Tables

**project**
- Root entity for organizing work
- Contains boards

**board**
- Belongs to a project
- Contains lists and cards
- Has board_membership for access control

**list**
- Belongs to a board
- Represents columns/stages (e.g., "To Do", "In Progress", "Done")

**card**
- Belongs to a board (can move between lists)
- Main work item with 21 columns including:
  - Basic: name, description, position
  - Dates: due_date, start_date, end_date, created_at, updated_at
  - Progress: is_due_date_completed, percent_complete, is_blocked
  - Metrics: estimated_hours, actual_hours, complexity, priority
  - Media: cover_attachment_id
  - Timer: stopwatch

**task**
- Checklist items within a card
- Has position for ordering

**attachment**
- Files attached to cards
- Stores image metadata as JSONB

### User & Access Control

**user_account**
- System users (16 columns)
- Fields: email, username, name, password, is_admin, language, avatar, etc.

**project_manager**
- Many-to-many: users who can manage projects

**board_membership**
- Many-to-many: users who can access boards
- Has role and can_comment permissions

**card_membership**
- Many-to-many: users assigned to cards

**card_subscription**
- Users subscribed to card notifications
- can be permanent or temporary

**session**
- User authentication sessions
- Stores access_token for API access

**identity_provider_user**
- SSO/OIDC user mappings

### Activity & Organization

**label**
- Color-coded tags for cards
- Belongs to a board
- Many-to-many with cards via card_label

**action**
- Activity log for cards
- Stores event data as JSONB
- Types tracked via 'type' field

**notification**
- User notifications from card actions
- Has is_read status

**archive**
- Soft delete storage
- Stores original_record as JSON
- Can restore deleted items

### System Tables

**migration**
- Database schema version tracking

**migration_lock**
- Prevents concurrent migrations

## Key Features

### ID Generation
- Uses custom `next_id()` function
- Generates Twitter Snowflake-style IDs
- Format: timestamp + shard + sequence
- Ensures distributed, time-ordered unique IDs

### Timestamps
- Most tables have created_at and updated_at
- Type: timestamp without time zone

### Indexing Strategy
- Primary keys on all tables
- Foreign key indexes for joins
- Unique constraints on relationships
- Custom indexes on:
  - position fields (for ordering)
  - type fields (for filtering)
  - user_id fields (for user queries)
  - card_id/board_id (for hierarchy)

### JSONB Fields
- action.data - stores action metadata
- attachment.image - stores image dimensions/metadata
- Allows flexible schema evolution
