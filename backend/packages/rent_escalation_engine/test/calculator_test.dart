import 'package:propos_rent_escalation_engine/propos_rent_escalation_engine.dart';
import 'package:test/test.dart';

void main() {
  const calc = RentCalculator();
  final start = DateTime.utc(2026, 1, 1);

  group('FixedRateRule', () {
    test('合同第 1 年月租等于基准', () {
      const rule = FixedRateRule(percent: 0.05);
      expect(calc.calculateRentForMonth(
        rule: rule, baseMonthlyRent: 10000,
        contractStart: start, targetMonth: DateTime.utc(2026, 6),
      ), equals(10000));
    });

    test('合同第 2 年月租上涨 5%', () {
      const rule = FixedRateRule(percent: 0.05);
      final amount = calc.calculateRentForMonth(
        rule: rule, baseMonthlyRent: 10000,
        contractStart: start, targetMonth: DateTime.utc(2027, 1),
      );
      expect(amount, closeTo(10500, 0.01));
    });

    test('合同第 3 年月租复利上涨两次', () {
      const rule = FixedRateRule(percent: 0.05);
      final amount = calc.calculateRentForMonth(
        rule: rule, baseMonthlyRent: 10000,
        contractStart: start, targetMonth: DateTime.utc(2028, 1),
      );
      expect(amount, closeTo(11025, 0.01));
    });
  });

  group('FixedAmountRule', () {
    test('第 1 月等于基准租金', () {
      const rule = FixedAmountRule(incrementPerMonth: 200);
      expect(calc.calculateRentForMonth(
        rule: rule, baseMonthlyRent: 5000,
        contractStart: start, targetMonth: DateTime.utc(2026, 1),
      ), equals(5000));
    });

    test('第 13 月第二年起开始递增一次', () {
      const rule = FixedAmountRule(incrementPerMonth: 200);
      final amount = calc.calculateRentForMonth(
        rule: rule, baseMonthlyRent: 5000,
        contractStart: start, targetMonth: DateTime.utc(2027, 1),
      );
      expect(amount, equals(5200));
    });

    test('每 2 年递增：第 25 月完成第二次递增', () {
      const rule = FixedAmountRule(incrementPerMonth: 300, intervalYears: 2);
      final amount = calc.calculateRentForMonth(
        rule: rule, baseMonthlyRent: 5000,
        contractStart: start, targetMonth: DateTime.utc(2028, 1),
      );
      expect(amount, equals(5300));
    });
  });

  group('CpiLinkedRule', () {
    test('第 1 年无 CPI 调整', () {
      const rule = CpiLinkedRule(cpiByYear: {1: 1.03, 2: 1.05});
      expect(calc.calculateRentForMonth(
        rule: rule, baseMonthlyRent: 10000,
        contractStart: start, targetMonth: DateTime.utc(2026, 6),
      ), equals(10000));
    });

    test('第 2 年按 CPI[1]=1.03 调整', () {
      const rule = CpiLinkedRule(cpiByYear: {1: 1.03, 2: 1.05});
      expect(calc.calculateRentForMonth(
        rule: rule, baseMonthlyRent: 10000,
        contractStart: start, targetMonth: DateTime.utc(2027, 1),
      ), closeTo(10300, 0.01));
    });

    test('第 3 年按 CPI[1]*CPI[2] 复合调整', () {
      const rule = CpiLinkedRule(cpiByYear: {1: 1.03, 2: 1.05});
      expect(calc.calculateRentForMonth(
        rule: rule, baseMonthlyRent: 10000,
        contractStart: start, targetMonth: DateTime.utc(2028, 1),
      ), closeTo(10815, 0.01));
    });
  });

  group('EveryNYearsRule', () {
    test('每 2 年涨 10%：第 1 年无变化', () {
      const rule = EveryNYearsRule(intervalYears: 2, percent: 0.10);
      expect(calc.calculateRentForMonth(
        rule: rule, baseMonthlyRent: 10000,
        contractStart: start, targetMonth: DateTime.utc(2026, 1),
      ), equals(10000));
    });

    test('每 2 年涨 10%：第 2 年月 13 仍无变化（未满2年）', () {
      const rule = EveryNYearsRule(intervalYears: 2, percent: 0.10);
      expect(calc.calculateRentForMonth(
        rule: rule, baseMonthlyRent: 10000,
        contractStart: start, targetMonth: DateTime.utc(2027, 1),
      ), equals(10000));
    });

    test('每 2 年涨 10%：第 3 年月 25 涨一次', () {
      const rule = EveryNYearsRule(intervalYears: 2, percent: 0.10);
      expect(calc.calculateRentForMonth(
        rule: rule, baseMonthlyRent: 10000,
        contractStart: start, targetMonth: DateTime.utc(2028, 1),
      ), closeTo(11000, 0.01));
    });
  });

  group('PostRenovationRule', () {
    test('免租期内月租为 0', () {
      const rule = PostRenovationRule(freeRentMonths: 2, baseMonthlyRent: 8000);
      expect(calc.calculateRentForMonth(
        rule: rule, baseMonthlyRent: 8000,
        contractStart: start, targetMonth: DateTime.utc(2026, 2),
      ), equals(0));
    });

    test('免租期后月租等于基准', () {
      const rule = PostRenovationRule(freeRentMonths: 2, baseMonthlyRent: 8000);
      expect(calc.calculateRentForMonth(
        rule: rule, baseMonthlyRent: 8000,
        contractStart: start, targetMonth: DateTime.utc(2026, 3),
      ), equals(8000));
    });

    test('免租期后嵌套固定比例递增', () {
      const rule = PostRenovationRule(
        freeRentMonths: 2,
        baseMonthlyRent: 8000,
        followUpRule: FixedRateRule(percent: 0.05),
      );
      // 第 15 月 = 免租后第 13 月 → 固定比例第 2 年 → 8000 * 1.05
      expect(calc.calculateRentForMonth(
        rule: rule, baseMonthlyRent: 8000,
        contractStart: start, targetMonth: DateTime.utc(2027, 3),
      ), closeTo(8400, 0.01));
    });
  });

  group('SteppedRule', () {
    const rule = SteppedRule(steps: [
      StepSegment(startMonth: 0, monthlyRent: 5000),
      StepSegment(startMonth: 12, monthlyRent: 6000),
      StepSegment(startMonth: 24, monthlyRent: 7000),
    ]);

    test('第一阶段（month 12）月租 = 5000', () {
      expect(calc.calculateRentForMonth(
        rule: rule, baseMonthlyRent: 5000,
        contractStart: start, targetMonth: DateTime.utc(2026, 12),
      ), equals(5000));
    });

    test('第二阶段起始（month 13）月租跳至 6000', () {
      expect(calc.calculateRentForMonth(
        rule: rule, baseMonthlyRent: 5000,
        contractStart: start, targetMonth: DateTime.utc(2027, 1),
      ), equals(6000));
    });

    test('第三阶段起始（month 25）月租跳至 7000', () {
      expect(calc.calculateRentForMonth(
        rule: rule, baseMonthlyRent: 5000,
        contractStart: start, targetMonth: DateTime.utc(2028, 1),
      ), equals(7000));
    });

    test('单步阶梯（仅一个 StepSegment）全程返回固定月租', () {
      const single = SteppedRule(steps: [
        StepSegment(startMonth: 0, monthlyRent: 9000),
      ]);
      // 第 1 月、第 24 月均应返回 9000
      expect(calc.calculateRentForMonth(
        rule: single, baseMonthlyRent: 0,
        contractStart: start, targetMonth: DateTime.utc(2026, 1),
      ), equals(9000));
      expect(calc.calculateRentForMonth(
        rule: single, baseMonthlyRent: 0,
        contractStart: start, targetMonth: DateTime.utc(2027, 12),
      ), equals(9000));
    });
  });

  group('compute 多阶段聚合', () {
    test('第1~24月固定比例5% + 第25月起CPI挂钩(1.03)', () {
      const phases = [
        FixedRatePhase(
            startMonth: 1, endMonth: 24, rule: FixedRateRule(percent: 0.05)),
        CpiLinkedPhase(
            startMonth: 25, rule: CpiLinkedRule(cpiByYear: {1: 1.03})),
      ];
      // 阶段1 第1月：无递增
      expect(calc.compute(
        phases: phases, baseMonthlyRent: 10000,
        contractStart: start, targetMonth: DateTime.utc(2026, 1),
      ), equals(10000));
      // 阶段1 第13月：固定5%上浮
      expect(calc.compute(
        phases: phases, baseMonthlyRent: 10000,
        contractStart: start, targetMonth: DateTime.utc(2027, 1),
      ), closeTo(10500, 0.01));
      // 阶段2 第25月：CPI阶段phase内第1月，year1无调整
      expect(calc.compute(
        phases: phases, baseMonthlyRent: 10000,
        contractStart: start, targetMonth: DateTime.utc(2028, 1),
      ), equals(10000));
      // 阶段2 第37月：CPI phase内第13月，year2，CPI 1.03
      expect(calc.compute(
        phases: phases, baseMonthlyRent: 10000,
        contractStart: start, targetMonth: DateTime.utc(2029, 1),
      ), closeTo(10300, 0.01));
    });

    // 跨阶段组合：第1~12月固定金额 + 第13月起阶梯式
    test('第1~12月固定金额基准 + 第13月起阶梯式（FixedAmount→Stepped）', () {
      const phases = [
        FixedAmountPhase(
          startMonth: 1,
          endMonth: 12,
          rule: FixedAmountRule(incrementPerMonth: 500),
        ),
        SteppedPhase(
          startMonth: 13,
          rule: SteppedRule(steps: [
            StepSegment(startMonth: 0, monthlyRent: 12000),
            StepSegment(startMonth: 12, monthlyRent: 15000),
          ]),
        ),
      ];
      // 阶段1 month 1：phaseIdx=1, intervals=0 → 10000+0=10000
      expect(calc.compute(
        phases: phases, baseMonthlyRent: 10000,
        contractStart: start, targetMonth: DateTime.utc(2026, 1),
      ), equals(10000));
      // 阶段1 month 12：phaseIdx=12, intervals=(12-1)/12=0 → 10000
      expect(calc.compute(
        phases: phases, baseMonthlyRent: 10000,
        contractStart: start, targetMonth: DateTime.utc(2026, 12),
      ), equals(10000));
      // 阶段2 month 13：phaseIdx=1, step[0]=12000
      expect(calc.compute(
        phases: phases, baseMonthlyRent: 10000,
        contractStart: start, targetMonth: DateTime.utc(2027, 1),
      ), equals(12000));
      // 阶段2 month 25：phaseIdx=13, step[12]=15000
      expect(calc.compute(
        phases: phases, baseMonthlyRent: 10000,
        contractStart: start, targetMonth: DateTime.utc(2028, 1),
      ), equals(15000));
    });

    // 边界：目标月不在任何阶段 → 回退 baseMonthlyRent
    test('目标月超出所有阶段范围 → 回退基准月租', () {
      const phases = [
        FixedRatePhase(
            startMonth: 1, endMonth: 12, rule: FixedRateRule(percent: 0.05)),
      ];
      expect(calc.compute(
        phases: phases, baseMonthlyRent: 8888,
        contractStart: start, targetMonth: DateTime.utc(2027, 2), // month 14，超出 endMonth:12
      ), equals(8888));
    });
  });

  group('EscalationType DB 映射', () {
    test('fromDbValue 正确映射全部 6 种 DB 枚举值', () {
      expect(EscalationType.fromDbValue('fixed_rate'),             EscalationType.fixedRate);
      expect(EscalationType.fromDbValue('fixed_amount'),           EscalationType.fixedAmount);
      expect(EscalationType.fromDbValue('step'),                   EscalationType.stepped);
      expect(EscalationType.fromDbValue('cpi'),                    EscalationType.cpiLinked);
      expect(EscalationType.fromDbValue('periodic'),               EscalationType.everyNYears);
      expect(EscalationType.fromDbValue('base_after_free_period'), EscalationType.postRenovation);
    });

    test('toDbValue 正确反向映射全部 6 种', () {
      expect(EscalationType.fixedRate.toDbValue(),      'fixed_rate');
      expect(EscalationType.fixedAmount.toDbValue(),    'fixed_amount');
      expect(EscalationType.stepped.toDbValue(),        'step');
      expect(EscalationType.cpiLinked.toDbValue(),      'cpi');
      expect(EscalationType.everyNYears.toDbValue(),    'periodic');
      expect(EscalationType.postRenovation.toDbValue(), 'base_after_free_period');
    });

    test('fromDbValue 未知值抛出 ArgumentError', () {
      expect(
        () => EscalationType.fromDbValue('unknown_type'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromDbValue → toDbValue 往返一致', () {
      const dbValues = [
        'fixed_rate', 'fixed_amount', 'step', 'cpi', 'periodic', 'base_after_free_period',
      ];
      for (final v in dbValues) {
        expect(EscalationType.fromDbValue(v).toDbValue(), v,
            reason: '$v 往返映射应一致');
      }
    });
  });
}
