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
import { StatisticsRangeQueryDto } from './dto/statistics-range-query.dto';
import { WeeklyStatisticsQueryDto } from './dto/weekly-statistics-query.dto';
import { StatisticsService } from './statistics.service';

@ApiTags('Statistics')
@ApiBearerAuth()
@Controller('statistics')
export class StatisticsController {
  constructor(private readonly statisticsService: StatisticsService) {}

  @Get('overview')
  @ApiOperation({
    summary:
      'Get task completion and habit consistency aggregates for an inclusive date range',
  })
  @ApiResponse({ status: 200, description: 'Overview statistics' })
  async overview(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: StatisticsRangeQueryDto,
  ) {
    const result = await this.statisticsService.getOverview(user, query);
    return { data: result };
  }

  @Get('weekly')
  @ApiOperation({
    summary: 'Get seven daily task/habit trend points starting at weekStart',
  })
  @ApiResponse({ status: 200, description: 'Weekly trend statistics' })
  async weekly(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: WeeklyStatisticsQueryDto,
  ) {
    const result = await this.statisticsService.getWeekly(user, query);
    return { data: result };
  }
}
