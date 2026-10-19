import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { Response } from 'express';

/**
 * Standard API Error Format (`03-technical-spec.md` Section 4 & `04-architecture-security-testing.md` Section 13.1).
 * Never leaks raw Prisma stack traces or internal schema details to the client.
 */
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();

    let statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
    let code = 'INTERNAL_SERVER_ERROR';
    let message = 'An unexpected internal server error occurred';
    let details: Record<string, string[]> | undefined;

    if (exception instanceof HttpException) {
      statusCode = exception.getStatus();
      const res = exception.getResponse();

      if (typeof res === 'object' && res !== null) {
        const resObj = res as Record<string, unknown>;
        code =
            (typeof resObj.code === 'string' && resObj.code) ||
            this.defaultCodeForStatus(statusCode);
        if (typeof resObj.message === 'string') {
          message = resObj.message;
        } else if (Array.isArray(resObj.message)) {
          message = 'Request validation failed';
          details = this.formatValidationArray(resObj.message);
        }
        if (
          resObj.details &&
          typeof resObj.details === 'object' &&
          !Array.isArray(resObj.details)
        ) {
          details = resObj.details as Record<string, string[]>;
        }
      } else if (typeof res === 'string') {
        code = this.defaultCodeForStatus(statusCode);
        message = res;
      }
    } else if (exception instanceof Prisma.PrismaClientKnownRequestError) {
      if (exception.code === 'P2002') {
        statusCode = HttpStatus.CONFLICT;
        code = 'CONFLICT_ERROR';
        message = 'Resource already exists';
      } else if (exception.code === 'P2025' || exception.code === 'P2003') {
        statusCode = HttpStatus.NOT_FOUND;
        code = 'RESOURCE_NOT_FOUND';
        message = 'Requested resource was not found';
      } else {
        this.logger.error(
          `Prisma error ${exception.code}: ${exception.message}`,
        );
      }
    } else if (exception instanceof Error) {
      this.logger.error(exception.message, exception.stack);
    }

    response.status(statusCode).json({
      statusCode,
      code,
      message,
      ...(details ? { details } : {}),
    });
  }

  private defaultCodeForStatus(status: number): string {
    switch (status) {
      case HttpStatus.BAD_REQUEST:
        return 'VALIDATION_ERROR';
      case HttpStatus.UNAUTHORIZED:
        return 'UNAUTHORIZED';
      case HttpStatus.FORBIDDEN:
        return 'FORBIDDEN_RESOURCE';
      case HttpStatus.NOT_FOUND:
        return 'RESOURCE_NOT_FOUND';
      case HttpStatus.CONFLICT:
        return 'CONFLICT_ERROR';
      case HttpStatus.TOO_MANY_REQUESTS:
        return 'RATE_LIMIT_EXCEEDED';
      default:
        return 'INTERNAL_SERVER_ERROR';
    }
  }

  private formatValidationArray(messages: unknown[]): Record<string, string[]> {
    const grouped: Record<string, string[]> = {};
    for (const item of messages) {
      const text = String(item);
      const firstWord = text.split(' ')[0] || 'general';
      const field = firstWord.replace(/[^a-zA-Z0-9_]/g, '') || 'general';
      if (!grouped[field]) {
        grouped[field] = [];
      }
      grouped[field].push(text);
    }
    return grouped;
  }
}
