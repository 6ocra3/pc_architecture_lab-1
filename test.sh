#!/usr/bin/env bash

# Параметры
source_folder="./logs"
output_directory="./archives"
file_size_mb=1024

# Функция очистки данных перед запуском тестов
reset_folders() {
    echo
    echo "Clearing old data in $source_folder and $output_directory..."
    rm -rf "$source_folder" "$output_directory"
    mkdir -p "$source_folder" "$output_directory"
}

# Генерация тестовых файлов в /logs
create_test_files() {
    local total_size_mb="$1"
    local num_files=$((total_size_mb / file_size_mb))
    echo "Creating $num_files files of $file_size_mb MB in folder $source_folder..."

    for i in $(seq 1 "$num_files"); do
        # Создание файла заданного размера
        fallocate -l "${file_size_mb}M" "$source_folder/testfile_$i.log"
        # Короткая пауза, чтобы изменить временную метку
        sleep 0.1
    done
}

# Функция для выполнения тестов и проверки
execute_test_case() {
    local limit_size="$1"
    local files_to_backup="${2:-3}"
    echo "Test: limit_size = $limit_size MB, archive $files_to_backup files"

    # Запуск основного скрипта для архивации
    ./script.sh "$source_folder" "$limit_size" "$files_to_backup"
    
    # Проверка количества архивированных и оставшихся файлов
    local files_archived=$(tar -tzf "$output_directory"/*.tar.gz 2> /dev/null | wc -l)
    local remaining_files=$(ls "$source_folder" | wc -l)

    echo "Files in archive: $files_archived"
    echo "Remain in folder: $remaining_files"
}

    # Очищаем папки для корректной работы тестов
    reset_folders

    # Тест 1
    echo "Test 1.0: Folder size > limit_size"
    create_test_files $((6 * 1024))
    execute_test_case $((5 * 1024)) 4
    reset_folders
    echo
    echo

    # Тест 2 
    echo "Test 2.0: Folder size < limit_size"
    create_test_files $((6 * 1024))
    execute_test_case $((7 * 1024)) 2
    reset_folders
    echo
    echo
	
    # Тест 3
    echo "Test 3.0: Folder size = limit_size"
    create_test_files $((6 * 1024))
    execute_test_case $((6 * 1024 + 1))
    reset_folders
    echo
    echo

    # Тест 4
    echo "Test 4.0: No arguments"
    create_test_files $((6 * 1024))
    execute_test_case $((3 * 1024))
    reset_folders
    echo
    echo

    # Тест 5
    echo "Test 5.0: Files to archive > files in folder (quantity)"
    create_test_files $((6 * 1024))
    execute_test_case $((5 * 1024)) 10
    reset_folders
    echo
    echo

    # Тест 6
    echo "Test 6.0: Empty folder"
    execute_test_case $((6 * 1024)) 2
    reset_folders
    echo
    echo
