-- CreateEnum
CREATE TYPE "TaskStatus" AS ENUM ('TODO', 'IN_PROGRESS', 'DONE');

-- CreateEnum
CREATE TYPE "Priority" AS ENUM ('LOW', 'MEDIUM', 'HIGH');

-- CreateEnum
CREATE TYPE "ReminderStatus" AS ENUM ('SCHEDULED', 'SENT', 'CANCELLED', 'FAILED');

-- CreateEnum
CREATE TYPE "ReminderChannel" AS ENUM ('LOCAL', 'PUSH');

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "email" VARCHAR(254) NOT NULL,
    "password_hash" TEXT NOT NULL,
    "name" VARCHAR(100) NOT NULL,
    "timezone" TEXT NOT NULL DEFAULT 'Asia/Jakarta',
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tasks" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "title" VARCHAR(200) NOT NULL,
    "description" TEXT,
    "status" "TaskStatus" NOT NULL DEFAULT 'TODO',
    "priority" "Priority" NOT NULL DEFAULT 'MEDIUM',
    "due_at" TIMESTAMPTZ(3),
    "completed_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "tasks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "habits" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "name" VARCHAR(120) NOT NULL,
    "description" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "active_days" INTEGER[] DEFAULT ARRAY[1, 2, 3, 4, 5, 6, 7]::INTEGER[],
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "habits_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "habit_logs" (
    "id" UUID NOT NULL,
    "habit_id" UUID NOT NULL,
    "log_date" DATE NOT NULL,
    "completed_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "habit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "calendar_events" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "title" VARCHAR(200) NOT NULL,
    "description" TEXT,
    "location" VARCHAR(300),
    "starts_at" TIMESTAMPTZ(3) NOT NULL,
    "ends_at" TIMESTAMPTZ(3) NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "calendar_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "reminders" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "task_id" UUID,
    "event_id" UUID,
    "remind_at" TIMESTAMPTZ(3) NOT NULL,
    "channel" "ReminderChannel" NOT NULL DEFAULT 'LOCAL',
    "status" "ReminderStatus" NOT NULL DEFAULT 'SCHEDULED',
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "reminders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "refresh_tokens" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "token_hash" TEXT NOT NULL,
    "expires_at" TIMESTAMPTZ(3) NOT NULL,
    "revoked_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "tasks_user_id_status_due_at_idx" ON "tasks"("user_id", "status", "due_at");

-- CreateIndex
CREATE INDEX "tasks_user_id_created_at_idx" ON "tasks"("user_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "tasks_id_user_id_key" ON "tasks"("id", "user_id");

-- CreateIndex
CREATE INDEX "habits_user_id_is_active_idx" ON "habits"("user_id", "is_active");

-- CreateIndex
CREATE INDEX "habit_logs_log_date_idx" ON "habit_logs"("log_date");

-- CreateIndex
CREATE UNIQUE INDEX "habit_logs_habit_id_log_date_key" ON "habit_logs"("habit_id", "log_date");

-- CreateIndex
CREATE INDEX "calendar_events_user_id_starts_at_idx" ON "calendar_events"("user_id", "starts_at");

-- CreateIndex
CREATE UNIQUE INDEX "calendar_events_id_user_id_key" ON "calendar_events"("id", "user_id");

-- CreateIndex
CREATE INDEX "reminders_user_id_status_remind_at_idx" ON "reminders"("user_id", "status", "remind_at");

-- CreateIndex
CREATE INDEX "reminders_task_id_idx" ON "reminders"("task_id");

-- CreateIndex
CREATE INDEX "reminders_event_id_idx" ON "reminders"("event_id");

-- CreateIndex
CREATE UNIQUE INDEX "refresh_tokens_token_hash_key" ON "refresh_tokens"("token_hash");

-- CreateIndex
CREATE INDEX "refresh_tokens_user_id_expires_at_idx" ON "refresh_tokens"("user_id", "expires_at");

-- AddForeignKey
ALTER TABLE "tasks" ADD CONSTRAINT "tasks_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "habits" ADD CONSTRAINT "habits_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "habit_logs" ADD CONSTRAINT "habit_logs_habit_id_fkey" FOREIGN KEY ("habit_id") REFERENCES "habits"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "calendar_events" ADD CONSTRAINT "calendar_events_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reminders" ADD CONSTRAINT "reminders_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reminders" ADD CONSTRAINT "reminders_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "tasks"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reminders" ADD CONSTRAINT "reminders_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "calendar_events"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- ============================================================================
-- Custom SQL Constraints Locked for Initial Migration (`03-technical-spec.md`)
-- ============================================================================

-- 1. Pastikan email selalu disimpan dalam lowercase
ALTER TABLE "users"
ADD CONSTRAINT "chk_users_email_lowercase"
CHECK ("email" = lower("email"));

-- 2. Pastikan ends_at > starts_at pada calendar_events
ALTER TABLE "calendar_events"
ADD CONSTRAINT "chk_calendar_events_time_order"
CHECK ("ends_at" > "starts_at");

-- 3. Pastikan Reminder terkait ke tepat satu: task_id ATAU event_id (XOR)
ALTER TABLE "reminders"
ADD CONSTRAINT "chk_reminders_target_xor"
CHECK (
  ("task_id" IS NOT NULL AND "event_id" IS NULL) OR
  ("task_id" IS NULL AND "event_id" IS NOT NULL)
);

-- 4. Pastikan target Reminder (task_id / event_id) wajib milik user_id yang sama
-- Menggunakan composite FK MATCH SIMPLE (aktif saat task_id/event_id IS NOT NULL)
ALTER TABLE "reminders"
DROP CONSTRAINT IF EXISTS "reminders_task_id_fkey",
DROP CONSTRAINT IF EXISTS "reminders_event_id_fkey",
ADD CONSTRAINT "fk_reminders_task_owner"
  FOREIGN KEY ("task_id", "user_id")
  REFERENCES "tasks"("id", "user_id")
  ON DELETE CASCADE,
ADD CONSTRAINT "fk_reminders_event_owner"
  FOREIGN KEY ("event_id", "user_id")
  REFERENCES "calendar_events"("id", "user_id")
  ON DELETE CASCADE;

-- 5. Pastikan active_days pada habits berisi 1..7, tidak kosong, dan TANPA duplikat
ALTER TABLE "habits"
ADD CONSTRAINT "chk_habits_active_days_range_and_unique"
CHECK (
  cardinality("active_days") BETWEEN 1 AND 7 AND
  "active_days" <@ ARRAY[1, 2, 3, 4, 5, 6, 7] AND
  cardinality(array_positions("active_days", 1)) <= 1 AND
  cardinality(array_positions("active_days", 2)) <= 1 AND
  cardinality(array_positions("active_days", 3)) <= 1 AND
  cardinality(array_positions("active_days", 4)) <= 1 AND
  cardinality(array_positions("active_days", 5)) <= 1 AND
  cardinality(array_positions("active_days", 6)) <= 1 AND
  cardinality(array_positions("active_days", 7)) <= 1
);
