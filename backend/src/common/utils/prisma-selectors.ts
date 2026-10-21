/**
 * Shared Prisma selectors (`04-architecture-security-testing.md` §12.1).
 *
 * Reminder summaries travel with task, agenda, and dashboard payloads so the
 * client can cancel the matching local Android alarm with the same
 * deterministic notification id.
 */
export const REMINDER_SUMMARY_SELECT = {
  select: { id: true, status: true },
};

export const REMINDER_SUMMARY_INCLUDE = {
  reminders: REMINDER_SUMMARY_SELECT,
};
