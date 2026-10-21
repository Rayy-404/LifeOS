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
import { CreateReminderDto } from './dto/create-reminder.dto';
import { ListRemindersQueryDto } from './dto/list-reminders-query.dto';
import { UpdateReminderDto } from './dto/update-reminder.dto';
import { RemindersService } from './reminders.service';

@ApiTags('Reminders')
@ApiBearerAuth()
@Controller('reminders')
export class RemindersController {
  constructor(private readonly remindersService: RemindersService) {}

  @Get()
  @ApiOperation({
    summary:
      'List user reminders ordered by remindAt ASC with optional ?status= filter',
  })
  @ApiResponse({ status: 200, description: 'List of reminders' })
  async list(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: ListRemindersQueryDto,
  ) {
    const reminders = await this.remindersService.list(user, query);
    return { data: reminders };
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary:
      'Create a reminder for exactly one owned task or calendar event (XOR)',
  })
  @ApiResponse({ status: 201, description: 'Reminder created as SCHEDULED' })
  @ApiResponse({
    status: 400,
    description: 'XOR violation or remindAt not in the future',
  })
  @ApiResponse({ status: 404, description: 'Target task/event not found' })
  async create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateReminderDto,
  ) {
    const reminder = await this.remindersService.create(user, dto);
    return { data: reminder };
  }

  @Patch(':id')
  @ApiOperation({
    summary:
      'Update remindAt (future -> SCHEDULED) or status of an owned reminder',
  })
  @ApiResponse({ status: 200, description: 'Reminder updated' })
  @ApiResponse({ status: 400, description: 'Invalid remindAt' })
  @ApiResponse({ status: 404, description: 'Reminder not found' })
  async update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', new ParseUUIDPipe()) id: string,
    @Body() dto: UpdateReminderDto,
  ) {
    const reminder = await this.remindersService.update(user, id, dto);
    return { data: reminder };
  }

  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Delete an owned reminder' })
  @ApiResponse({ status: 200, description: 'Reminder deleted' })
  @ApiResponse({ status: 404, description: 'Reminder not found' })
  async remove(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', new ParseUUIDPipe()) id: string,
  ) {
    const result = await this.remindersService.remove(user, id);
    return { data: result };
  }
}
