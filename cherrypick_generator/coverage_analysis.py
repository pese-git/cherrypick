#!/usr/bin/env python3
"""
Анализ покрытия тестами для CherryPick Generator
"""

import re
import os

def analyze_lcov_file(lcov_path):
    """Анализирует LCOV файл и возвращает статистику покрытия"""
    
    if not os.path.exists(lcov_path):
        print(f"❌ LCOV файл не найден: {lcov_path}")
        return
    
    with open(lcov_path, 'r') as f:
        content = f.read()
    
    # Разбиваем на секции по файлам
    file_sections = content.split('SF:')[1:]  # Убираем первую пустую секцию
    
    total_lines = 0
    total_hit = 0
    files_coverage = {}
    
    for section in file_sections:
        lines = section.strip().split('\n')
        if not lines:
            continue
            
        file_path = lines[0]
        file_name = os.path.basename(file_path)
        
        # Подсчитываем строки
        da_lines = [line for line in lines if line.startswith('DA:')]
        
        file_total = len(da_lines)
        file_hit = 0
        
        for da_line in da_lines:
            # DA:line_number,hit_count
            parts = da_line.split(',')
            if len(parts) >= 2:
                hit_count = int(parts[1])
                if hit_count > 0:
                    file_hit += 1
        
        if file_total > 0:
            coverage_percent = (file_hit / file_total) * 100
            files_coverage[file_name] = {
                'total': file_total,
                'hit': file_hit,
                'percent': coverage_percent
            }
            
            total_lines += file_total
            total_hit += file_hit
    
    # Общая статистика
    overall_percent = (total_hit / total_lines) * 100 if total_lines > 0 else 0
    
    print("📊 АНАЛИЗ ПОКРЫТИЯ ТЕСТАМИ CHERRYPICK GENERATOR")
    print("=" * 60)
    
    print(f"\n🎯 ОБЩАЯ СТАТИСТИКА:")
    print(f"   Всего строк кода: {total_lines}")
    print(f"   Покрыто тестами: {total_hit}")
    print(f"   Общее покрытие: {overall_percent:.1f}%")
    
    print(f"\n📁 ПОКРЫТИЕ ПО ФАЙЛАМ:")
    
    # Сортируем по проценту покрытия
    sorted_files = sorted(files_coverage.items(), key=lambda x: x[1]['percent'], reverse=True)
    
    for file_name, stats in sorted_files:
        percent = stats['percent']
        hit = stats['hit']
        total = stats['total']
        
        # Эмодзи в зависимости от покрытия
        if percent >= 80:
            emoji = "✅"
        elif percent >= 50:
            emoji = "🟡"
        else:
            emoji = "❌"
            
        print(f"   {emoji} {file_name:<25} {hit:>3}/{total:<3} ({percent:>5.1f}%)")
    
    print(f"\n🏆 РЕЙТИНГ КОМПОНЕНТОВ:")
    
    # Группируем по типам компонентов
    core_files = ['bind_spec.dart', 'bind_parameters_spec.dart', 'generated_class.dart']
    utils_files = ['metadata_utils.dart']
    generator_files = ['module_generator.dart', 'inject_generator.dart']
    
    def calculate_group_coverage(file_list):
        group_total = sum(files_coverage.get(f, {}).get('total', 0) for f in file_list)
        group_hit = sum(files_coverage.get(f, {}).get('hit', 0) for f in file_list)
        return (group_hit / group_total * 100) if group_total > 0 else 0
    
    core_coverage = calculate_group_coverage(core_files)
    utils_coverage = calculate_group_coverage(utils_files)
    generators_coverage = calculate_group_coverage(generator_files)
    
    print(f"   🔧 Core Components:  {core_coverage:>5.1f}%")
    print(f"   🛠️  Utils:           {utils_coverage:>5.1f}%") 
    print(f"   ⚙️  Generators:      {generators_coverage:>5.1f}%")
    
    print(f"\n📈 РЕКОМЕНДАЦИИ:")
    
    # Файлы с низким покрытием
    low_coverage = [(f, s) for f, s in files_coverage.items() if s['percent'] < 50]
    if low_coverage:
        print("   🎯 Приоритет для улучшения:")
        for file_name, stats in sorted(low_coverage, key=lambda x: x[1]['percent']):
            print(f"      • {file_name} ({stats['percent']:.1f}%)")
    
    # Файлы без покрытия
    zero_coverage = [(f, s) for f, s in files_coverage.items() if s['percent'] == 0]
    if zero_coverage:
        print("   ❗ Требуют срочного внимания:")
        for file_name, stats in zero_coverage:
            print(f"      • {file_name} (0% покрытия)")
    
    print(f"\n✨ ДОСТИЖЕНИЯ:")
    high_coverage = [(f, s) for f, s in files_coverage.items() if s['percent'] >= 80]
    if high_coverage:
        print("   🏅 Отлично протестированы:")
        for file_name, stats in sorted(high_coverage, key=lambda x: x[1]['percent'], reverse=True):
            print(f"      • {file_name} ({stats['percent']:.1f}%)")
    
    return files_coverage, overall_percent

if __name__ == "__main__":
    lcov_path = "coverage/lcov.info"
    analyze_lcov_file(lcov_path)
