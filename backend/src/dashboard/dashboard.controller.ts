import { Controller, Get, Query } from '@nestjs/common';
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
import { DashboardService } from './dashboard.service';
import { GetDashboardTodayQueryDto } from './dto/get-dashboard-today-query.dto';

@ApiTags('Dashboard')
@ApiBearerAuth()
@Controller('dashboard')
export class DashboardController {
  constructor(private readonly dashboardService: DashboardService) {}

  @Get('today')
  @ApiOperation({
    summary:
      'Get unified daily summary for ?date=YYYY-MM-DD in user timezone (tasks, habits, upcomingEvents, todayTasks, todayHabits)',
  })
  @ApiResponse({ status: 200, description: 'Daily dashboard summary' })
  async getToday(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: GetDashboardTodayQueryDto,
  ) {
    const summary = await this.dashboardService.getToday(user, query);
    return { data: summary };
  }
}
