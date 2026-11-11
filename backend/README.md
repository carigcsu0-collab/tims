# TIMS API Backend

Laravel backend for the TIMS (Tool & Inventory Management System) Flutter application.

## Portainer deployment on a local server

The included `compose.yaml` is for a **standalone Docker environment** in
Portainer. It builds the API from the Git repository and connects to an
**existing MySQL server**; it does not create or manage the database. The
image serves only the `public` directory using Apache, disables Laravel debug
mode, writes application logs to the container log, and stores Laravel's
`storage` directory in a named Docker volume.

> **Before production use:** this application currently allows public
> registration, and its authenticated routes do not enforce role-based
> authorization. In particular, a registered user can access user-management
> endpoints. Email verification and password-reset endpoints are not complete.
> HTTPS and Docker do not fix these application-level issues. Restrict access
> to trusted users and address authorization and authentication before
> exposing the API to untrusted users.

### Prepare the server and repository

1. Install Docker and Portainer on the server. Create an empty MySQL database
   and a dedicated MySQL user with the permissions needed to run migrations and
   use the database. Allow connections from the Docker host/network in MySQL
   and the firewall. `127.0.0.1` inside the API container refers to the
   container, not the database server.
2. Push this project to GitHub. From the repository root, confirm that neither
   `.env` file, `backend/vendor`, runtime logs, nor cached configuration is
   tracked before pushing. Check with:

   ```sh
   git ls-files -- .env backend/.env backend/vendor backend/storage backend/bootstrap/cache
   ```

   `.gitignore` does not remove files already tracked or erase secrets from Git history.
   If secrets were previously committed, rotate them and clean the history
   before sharing the repository.
3. Generate one Laravel key on a trusted machine with OpenSSL:

   ```sh
   echo "base64:$(openssl rand -base64 32)"
   ```

   Save it securely. Use the same key across redeployments and backups;
   changing it can make previously encrypted data unreadable.

### Create the stack

1. In Portainer, create a stack using the **Repository** build method. Select
   the GitHub repository and branch, and set the compose path to
   `backend/compose.yaml`. Configure Git credentials in Portainer if the
   repository is private. The Portainer server must be able to build images and
   reach the image registries and Composer package sources.
2. In the stack's **Environment variables** section, add these values (do not
   commit real values to Git):

   | Variable | Value |
   | --- | --- |
   | `APP_KEY` | The generated `base64:...` key |
   | `APP_URL` | Public HTTPS origin, for example `https://api.example.com` |
   | `DB_HOST` | Hostname or reachable IP of the existing MySQL server |
   | `DB_PORT` | MySQL port; defaults to `3306` |
   | `DB_DATABASE` | Database name |
   | `DB_USERNAME` | Dedicated MySQL username |
   | `DB_PASSWORD` | Database user's password |
   | `API_PORT` | Host port for the API; defaults to `8080` |
   | `API_BIND_ADDRESS` | Host interface to bind; defaults to `127.0.0.1` |
   | `TRUSTED_PROXIES` | Optional comma-separated proxy IP addresses or CIDR ranges as seen by Laravel |
   | `APP_TIMEZONE` | Defaults to `Asia/Manila` |
   | `LOG_LEVEL` | Defaults to `warning` |

   Portainer stack variables and container environment variables are not a
   dedicated secret store: restrict Portainer and Docker access, and use strong
   unique credentials. Verify Portainer preserves special characters in
   passwords, especially `$`, when configuring stack variables.
3. Deploy the stack. The API listens on `127.0.0.1:8080` on the Docker host by
   default. Configure your existing reverse proxy to terminate HTTPS and
   forward to that address. If the proxy runs in a separate container or on a
   different host, its `127.0.0.1` is not the Docker host: set
   `API_BIND_ADDRESS` to a host address reachable by the proxy and restrict
   access to that port with a firewall. Do not expose the HTTP port publicly.
   Configure the proxy to send the appropriate `X-Forwarded-*` headers and
   set `TRUSTED_PROXIES` to its actual source IP or narrowly scoped CIDR as
   seen by the container (Docker NAT may change it). Without this setting,
   Laravel does not trust forwarded scheme or client IP headers. Do not use
   `*` or trust networks that untrusted clients can access.
4. Back up the database, then open a console for the API container in
   Portainer and run:

   ```sh
   php artisan migrate --force
   ```

   Migrations are deliberately not run automatically during startup or
   redeployment. Do **not** run the default seeder in production: it creates
   sample data and accounts with known passwords. Provision authorized users
   using a secure, separately controlled process.
5. Verify the container is healthy and request `https://YOUR_API_HOST/up` and
   an actual API endpoint. `/up` checks that Laravel responds; it does **not**
   prove database connectivity, so also check a database-backed endpoint or
   run `php artisan migrate:status` in the container. API routes start at
   `/api/v1`.

### Operations

- To update, back up first, update the Git reference in Portainer and redeploy
  with image rebuilding enabled. Run any new migrations explicitly. Avoid
  running migrations concurrently from multiple deployments.
- Back up and test restoring both MySQL and the stack's `api-storage` volume.
  Keep the application key and deployment configuration securely backed up
  separately. Do not remove the volume when redeploying.
- Inspect the container logs and health status in Portainer. The stack uses
  synchronous queues and does not start a queue worker or scheduler; if the
  application later needs either, deploy and monitor them separately.
- The default bind address assumes a reverse proxy on the same host. Use
  firewall rules and the proxy's access controls appropriate for your network.

## Local development

## Requirements

- PHP >= 8.4.1 for the current Composer lock file
- Composer
- MySQL >= 8.0
- Laravel 11.x

## Setup Instructions

1. **Install dependencies**
   ```bash
   composer install
   ```

2. **Configure environment**
   ```bash
   cp .env.example .env
   php artisan key:generate
   ```
   Update `.env` with your MySQL credentials:
   ```
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=tims
   DB_USERNAME=root
   DB_PASSWORD=your_password
   ```

3. **Run migrations**
   ```bash
   php artisan migrate
   ```

4. **Seed the database**
   ```bash
   php artisan db:seed
   ```

5. **Start the development server**
   ```bash
   php artisan serve
   ```
   The API will be available at `http://localhost:8000`

## API Structure

All API routes are prefixed with `/api/v1/`.

### Authentication
- `POST /auth/login` - Login
- `POST /auth/register` - Register
- `POST /auth/forgot-password` - Request password reset
- `POST /auth/reset-password` - Reset password
- `POST /auth/logout` - Logout (auth)
- `POST /auth/refresh` - Refresh token (auth)
- `GET /auth/me` - Current user (auth)

### Dashboard
- `GET /dashboard/stats` - Summary statistics
- `GET /dashboard/charts` - Chart data
- `GET /dashboard/recent-activity` - Recent stock movements

### Categories
- `GET/POST /categories` - List/Create
- `GET/PUT/DELETE /categories/{id}` - Show/Update/Delete

### Items
- `GET/POST /items` - List/Create
- `GET/PUT/DELETE /items/{id}` - Show/Update/Delete
- `GET /items/low-stock` - Low stock items
- `GET /items/search?q=` - Search items

### Suppliers
- `GET/POST /suppliers` - List/Create
- `GET/PUT/DELETE /suppliers/{id}` - Show/Update/Delete

### Purchase Requests
- `GET/POST /purchase-requests` - List/Create
- `GET/PUT/DELETE /purchase-requests/{id}` - Show/Update/Delete
- `POST /purchase-requests/{id}/approve` - Approve
- `POST /purchase-requests/{id}/reject` - Reject

### Purchase Orders
- `GET/POST /purchase-orders` - List/Create
- `GET/PUT/DELETE /purchase-orders/{id}` - Show/Update/Delete

### Receivings
- `GET/POST /receivings` - List/Create
- `GET/PUT/DELETE /receivings/{id}` - Show/Update/Delete

### Issuances
- `GET/POST /issuances` - List/Create
- `GET/PUT/DELETE /issuances/{id}` - Show/Update/Delete

### Borrowings
- `GET/POST /borrowings` - List/Create
- `GET/PUT/DELETE /borrowings/{id}` - Show/Update/Delete
- `POST /borrowings/{id}/approve` - Approve
- `POST /borrowings/{id}/reject` - Reject
- `POST /borrowings/{id}/return` - Return item

### Returns
- `GET/POST /returns` - List/Create
- `GET/PUT/DELETE /returns/{id}` - Show/Update/Delete

### Maintenance
- `GET/POST /maintenances` - List/Create
- `GET/PUT/DELETE /maintenances/{id}` - Show/Update/Delete
- `POST /maintenances/{id}/complete` - Complete maintenance

### Stock Movements
- `GET /stock-movements` - List with filters
- `GET /stock-movements/by-item?item_id=` - Movements for an item

### Reports
- `GET /reports/inventory` - Inventory report
- `GET /reports/procurement` - Procurement report
- `GET /reports/borrowing` - Borrowing report
- `GET /reports/maintenance` - Maintenance report
- `GET /reports/audit` - Audit trail report

### Notifications
- `GET /notifications` - List user notifications
- `PATCH /notifications/{id}` - Mark as read
- `POST /notifications/mark-all-read` - Mark all as read
- `DELETE /notifications/{id}` - Delete notification

### Users
- `GET/POST /users` - List/Create
- `GET/PUT/DELETE /users/{id}` - Show/Update/Delete

### Activity Logs
- `GET /activity-logs` - List with filters

### Profile
- `GET /profile` - Current user profile
- `PUT /profile` - Update profile
- `PUT /profile/update-password` - Change password

## Authentication

The API uses Laravel Sanctum for token-based authentication. Include the Bearer token in the Authorization header:

```
Authorization: Bearer <your_token>
```

## Development-only Seed Accounts

These are insecure sample credentials. Never use the default seeder in production.

| Role    | Email              | Password   |
|---------|--------------------|------------|
| Admin   | admin@tims.local   | password   |
| Manager | manager@tims.local | password   |
| Staff   | staff@tims.local   | password   |

## Project Structure

```
backend/
├── app/
│   ├── Http/Controllers/Api/    # API controllers
│   ├── Models/                   # Eloquent models
│   └── ...
├── database/
│   ├── migrations/               # Database schema
│   └── seeders/                  # Sample data
├── routes/
│   ├── api.php                   # API routes
│   └── web.php                   # Web routes
├── config/                       # Configuration files
└── .env                          # Environment variables
```
