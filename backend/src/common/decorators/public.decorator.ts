import { SetMetadata } from '@nestjs/common';

export const IS_PUBLIC_KEY = 'isPublic';

/**
 * Marks a route (or controller) as publicly accessible, bypassing the
 * global `JwtAuthGuard` (`03-technical-spec.md` Section 4.1).
 */
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
