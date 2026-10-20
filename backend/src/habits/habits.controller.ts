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
  Put,
  Query,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import {
  AuthenticatedUser,
  CurrentUser,
} from '../common/decorators/current-user.decorator';
import { CheckInHabitDto } from './dto/check-in-habit.dto';
import { CreateHabitDto } from './dto/create-habit.dto';
import { ListHabitLogsQueryDto } from './dto/list-habit-logs-query.dto';
import { ListHabitsQueryDto } from './dto/list-habits-query.dto';
import { UpdateHabitDto } from './dto/update-habit.dto';
import { HabitsService } from './habits.service';

@ApiTags('Habits')
@ApiBearerAuth()
@Controller('habits')
export class HabitsController {
  constructor(private readonly habitsService: HabitsService) {}

  @Get()
  @ApiOperation({
    summary:
      'List user habits with currentStreak, completedToday, and weeklyLogs',
  })
  @ApiResponse({ status: 200, description: 'List of habits with metrics' })
  async list(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: ListHabitsQueryDto,
  ) {
    const habits = await this.habitsService.list(user, query);
    return { data: habits };
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a new habit' })
  @ApiResponse({ status: 201, description: 'Habit created' })
  async create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateHabitDto,
  ) {
    const habit = await this.habitsService.create(user, dto);
    return { data: habit };
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get habit details with currentStreak' })
  @ApiResponse({ status: 200, description: 'Habit details' })
  @ApiResponse({ status: 404, description: 'Habit not found' })
  async findOne(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', new ParseUUIDPipe()) id: string,
  ) {
    const habit = await this.habitsService.findOne(user, id);
    return { data: habit };
  }

  @Patch(':id')
  @ApiOperation({
    summary: 'Update habit name, description, activeDays, or isActive',
  })
  @ApiResponse({ status: 200, description: 'Habit updated' })
  @ApiResponse({ status: 404, description: 'Habit not found' })
  async update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', new ParseUUIDPipe()) id: string,
    @Body() dto: UpdateHabitDto,
  ) {
    const habit = await this.habitsService.update(user, id, dto);
    return { data: habit };
  }

  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Delete a habit' })
  @ApiResponse({ status: 200, description: 'Habit deleted' })
  @ApiResponse({ status: 404, description: 'Habit not found' })
  async remove(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', new ParseUUIDPipe()) id: string,
  ) {
    const result = await this.habitsService.remove(user.id, id);
    return { data: result };
  }

  @Get(':id/logs')
  @ApiOperation({
    summary:
      'Get check-in history in range ?from=YYYY-MM-DD&to=YYYY-MM-DD ordered by logDate DESC',
  })
  @ApiResponse({ status: 200, description: 'Habit check-in logs' })
  @ApiResponse({ status: 404, description: 'Habit not found' })
  async getLogs(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', new ParseUUIDPipe()) id: string,
    @Query() query: ListHabitLogsQueryDto,
  ) {
    const logs = await this.habitsService.getLogs(user, id, query);
    return { data: logs };
  }

  @Put(':id/logs/:date')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Idempotently set habit check-in completion status for :date (YYYY-MM-DD)',
  })
  @ApiParam({
    name: 'date',
    example: '2026-10-18',
    description: 'Calendar date in YYYY-MM-DD format in user timezone',
  })
  @ApiResponse({
    status: 200,
    description: 'Habit check-in status updated and streak recalculated',
  })
  @ApiResponse({
    status: 400,
    description: 'Future date or invalid backfill range',
  })
  @ApiResponse({ status: 404, description: 'Habit not found' })
  async checkIn(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', new ParseUUIDPipe()) id: string,
    @Param('date') date: string,
    @Body() dto: CheckInHabitDto,
  ) {
    const result = await this.habitsService.checkIn(user, id, date, dto);
    return { data: result };
  }
}
