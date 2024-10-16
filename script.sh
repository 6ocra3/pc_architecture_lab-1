#!/usr/bin/env bash

# Справка по скрипту
case "$1" in
    -h)
        cat << HELP
script.sh — утилита для создания резервных копий
Использование:
  ./script.sh <directory> <size_limit_mb> [files_count]
HELP
        exit 0
        ;;
esac

# Проверка аргументов
if [ "$#" -lt 2 ]; then
    echo "ERROR: Not enough arguments. Usage: $0 <directory> <size_limit_mb> [files_count]"
    exit 1
fi

# Определение переменных
source_folder="$1"
limit_size=$(($2 * 1024 * 1024))  # Лимит в байтах
files_to_backup="${3:-5}"  # По умолчанию архивируем 5 файлов
output_directory="$HOME/safe_storage/backup"

# Проверка существования директории
if [ ! -d "$source_folder" ]; then
    echo "ERROR: directory $source_folder not found."
    exit 1
fi

# Создание директории назначения
[ ! -d "$output_directory" ] && mkdir -p "$output_directory"

# Вычисление размера директории
dir_size_bytes=$(find "$source_folder" -type f -exec stat --format="%s" {} \; | awk '{s+=$1} END {print s}')

# Если директория пуста, присвоить значение 0
if [ -z "$dir_size_bytes" ]; then
    dir_size_bytes=0
fi

echo "Current size of $source_folder: $(( dir_size_bytes / (1024 * 1024) )) MB"

# Проверка, превышает ли размер лимит
if (( dir_size_bytes > limit_size )); then
    echo "Folder size exceeds limit. Archiving $files_to_backup old files..."

    # Поиск и архивирование старых файлов
    files_to_archive=$(find "$source_folder" -type f -printf "%T@ %p\n" | sort -n | head -n "$files_to_backup" | cut -d' ' -f2)

    if [ -n "$files_to_archive" ]; then
        archive_name="$output_directory/backup_$(date +%Y%m%d_%H%M%S).tar.gz"
        tar -czf "$archive_name" $files_to_archive

        if [ $? -eq 0 ]; then
            echo "Backup created: $archive_name"
            echo "Deleting old files..."
            for file in $files_to_archive; do
                rm "$file" && echo "Deleted: $file"
            done
        else
            echo "ERROR: Failed to create backup."
            exit 1
        fi
    else
        echo "No files to archive."
    fi
else
    echo "Folder size is within the limit. No need to archive."
fi
