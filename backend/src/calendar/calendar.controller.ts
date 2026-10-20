import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import {
  AuthenticatedUser,
  CurrentUser,
} from '../common/decorators/current-user.decorator';
import { CalendarService } from './calendar.service';
import { CreateCalendarEventDto } from './dto/create-calendar-event.dto';
import { ListCalendarEventsQueryDto } from './dto/list-calendar-events-query.dto';
import { UpdateCalendarEventDto } from './dto/update-calendar-event.dto';

@ApiTags('Calendar')
@ApiBearerAuth()
@Controller('calendar/events')
export class CalendarController {
  constructor(private readonly calendarService: CalendarService) {}

  @Get()
  @ApiOperation({
    summary:
      'Get combined agenda (overlapping events + tasks with deadlines) in range [from, to)',
  })
  @ApiResponse({ status: 200, description: 'Combined calendar agenda' })
  async listAgenda(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: ListCalendarEventsQueryDto,
  ) {
    const agenda = await this.calendarService.listAgenda(user, query);
    return { data: agenda };
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a scheduled calendar event (endsAt > startsAt)' })
  @ApiResponse({ status: 201, description: 'Calendar event created' })
  @ApiResponse({ status: 400, description: 'Invalid time range (endsAt <= startsAt)' })
  async create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateCalendarEventDto,
  ) {
    const event = await this.calendarService.create(user.id, dto);
    return { data: event };
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get calendar event details with associated reminders' })
  @ApiResponse({ status: 200, description: 'Calendar event details' })
  @ApiResponse({ status: 404, description: 'Calendar event not found' })
  async findOne(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', new ParseUUIDPipe()) id: string,
  ) {
    const event = await this.calendarService.findOne(user.id, id);
    return { data: event };
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a calendar event' })
  @ApiResponse({ status: 200, description: 'Calendar event updated' })
  @ApiResponse({ status: 400, description: 'Invalid time range' })
  @ApiResponse({ status: 404, description: 'Calendar event not found' })
  async update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', new ParseUUIDPipe()) id: string,
    @Body() dto: UpdateCalendarEventDto,
  ) {
    const event = await this.calendarService.update(user.id, id, dto);
    return { data: event };
  }

  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Delete a calendar event' })
  @ApiResponse({ status: 200, description: 'Calendar event deleted' })
  @ApiResponse({ status: 404, description: 'Calendar event not found' })
  async remove(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', new ParseUUIDPipe()) id: string,
  ) {
    const result = await this.calendarService.remove(user.id, id);
    return { data: result };
  }
}
