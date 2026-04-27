# AI HANDOFF NOTES - NAIL POS PROJECT

## 📌 Project Context
- **Project Name:** Nail POS (Point of Sale system for Nail Salons).
- **Architecture:** 
  - **Backend:** NestJS, TypeORM, PostgreSQL.
  - **Frontend:** Flutter (Mobile/Tablet/Web), Riverpod for state management.
- **Key Concept:** **Multi-tenant isolation**. Every request must be filtered by `salonId`.

## ✅ What has been implemented (as of April 2026)

### 1. Backend (nail-pos-api)
- **Multi-tenancy:** Integrated `SalonAccessGuard` and `@CurrentUser` decorator. All controllers (Staffs, Services, Customers, Transactions) are isolated by `salonId`.
- **Shift Management:** Full module for opening/closing shifts, tracking `expected_ending_cash` vs `actual_ending_cash`, and logging `CashMovements` (Pay In/Out).
- **Transactions & Split Payments:** 
  - Updated `Transaction` entity to support `shift_id`, `discount_type`, `discount_value`, `tax_rate`.
  - Added `TransactionPayment` entity to support **Split Payments** (multiple payment methods per transaction).
- **Pagination:** Global pagination DTOs and helpers implemented.
- **Database:** Migrations created for all core POS features.

### 2. Frontend (nail-pos)
- **Shift Management UI:** Dedicated screen to manage work shifts, log cash movements, and reconcile cash at end of day.
- **Advanced Checkout Flow:** 
  - `PaymentCheckoutDialog`: A complex modal handling Split Payments, calculated Discounts (Fixed/%), Tips, and Taxes.
  - Integration with `ShiftsProvider` to ensure every transaction is linked to an active shift.
- **Receipt Rendering:** `BillScreen` updated to show detailed split payment breakdowns.
- **State Management:** Uses Riverpod `StateNotifier` for POS logic and Auth.

## 🚀 Pending Tasks (Roadmap)

### 1. Core POS (High Priority)
- [ ] **Tip Distribution per Staff:** Modify Transaction/Item logic to allow splitting tips among different staff members (nails salon standard).
- [ ] **Customer Stats Auto-update:** Implement a service or DB trigger to update `total_visits` and `total_spent` in the `Customer` entity whenever a transaction is completed.
- [ ] **Tax Settings:** Add a Salon Settings page to configure default tax rates.

### 2. Reports & Operations (Medium Priority)
- [ ] **Date Range Reports:** Enhance the Daily Report to support weekly/monthly/custom ranges.
- [ ] **Employee Payroll:** Logic to calculate commissions based on service prices and transaction data.
- [ ] **Inventory:** Basic tracking of supplies used per service.

## 🛠 Tech Stack Details for Next AI
- **Backend:** Look at `src/common/guards/salon-access.guard.ts` for security logic.
- **Frontend State:** `lib/features/pos/providers/pos_provider.dart` is the heart of the checkout logic.
- **API Endpoints:** Defined in `lib/core/api/api_endpoints.dart`.

---
*End of Handoff Notes. Ready for the next session.*
