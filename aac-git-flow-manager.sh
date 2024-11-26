#!/bin/bash
# AAChibilyaev 2024 
# AAC Git Flow Manager Script

# Улучшенный скрипт Git Flow Менеджера Веток

# Немедленное завершение скрипта при ошибке любой команды
set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # Без цвета

# Проверка, что запущено в Git-репозитории
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo -e "${RED}Ошибка:${NC} это не Git-репозиторий. Инициализируйте репозиторий или перейдите в существующий."
  exit 1
fi

# Функция для отображения меню
show_menu() {
  echo -e "${BLUE}======================================================"
  echo -e "            Git Flow Менеджер Веток"
  echo -e "======================================================${NC}"
  echo -e "1. Создать основную инфраструктуру (main, develop)"
  echo -e "2. Создать ветку (feature, bugfix, release, hotfix, experiment)"
  echo -e "3. Переключиться на существующую ветку"
  echo -e "4. Слить ветки"
  echo -e "5. Пушить ветку в удалённый репозиторий"
  echo -e "6. Ребейз ветки"
  echo -e "7. Удалить локальную ветку"
  echo -e "8. Удалить неактуальные удалённые ветки"
  echo -e "9. Показать список веток"
  echo -e "10. Примерные команды Git Flow (подсказки)"
  echo -e "11. Сохранить незакоммиченные изменения в Stash"
  echo -e "12. Показать статус репозитория"
  echo -e "13. Показать логи коммитов"
  echo -e "14. Выйти"
}

# Функция для запроса ввода пользователя с проверкой
prompt() {
  local prompt_text="$1"
  local var
  read -p "$prompt_text" var
  echo "$var"
}

# Функция для проверки наличия незакоммиченных изменений
check_uncommitted_changes() {
  if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}Внимание:${NC} У вас есть незакоммиченные изменения."
    local choice=$(prompt "Хотите сохранить их? (y/n): ")
    if [[ "$choice" =~ ^[Yy]$ ]]; then
      local message=$(prompt "Введите сообщение коммита: ")
      git add .
      git commit -m "$message"
      echo -e "${GREEN}Изменения сохранены.${NC}"
    else
      choice=$(prompt "Хотите сохранить их в stash? (y/n): ")
      if [[ "$choice" =~ ^[Yy]$ ]]; then
        git stash
        echo -e "${GREEN}Изменения сохранены в stash.${NC}"
      else
        echo -e "${RED}Изменения не сохранены. Продолжаем без сохранения.${NC}"
      fi
    fi
  fi
}

# Создание инфраструктуры Git Flow
create_infrastructure() {
  echo -e "${YELLOW}Создание ветки main...${NC}"
  if git show-ref --verify --quiet refs/heads/main; then
    echo -e "${GREEN}Ветка 'main' уже существует.${NC}"
  else
    git checkout -b main
    echo -e "${GREEN}Ветка 'main' создана.${NC}"
  fi

  echo -e "${YELLOW}Создание ветки develop...${NC}"
  if git show-ref --verify --quiet refs/heads/develop; then
    echo -e "${GREEN}Ветка 'develop' уже существует.${NC}"
  else
    git checkout -b develop main
    echo -e "${GREEN}Ветка 'develop' создана из 'main'.${NC}"
  fi

  git checkout develop
  echo -e "${GREEN}Переключились на ветку 'develop'.${NC}"
}

# Создание ветки с префиксом
create_branch() {
  echo -e "${BLUE}Выберите тип ветки:"
  echo "1. feature"
  echo "2. bugfix"
  echo "3. release"
  echo "4. hotfix"
  echo "5. experiment"
  local branch_type_num=$(prompt "Введите номер: ")
  case $branch_type_num in
    1) prefix="feature"; base="develop" ;;
    2) prefix="bugfix"; base="develop" ;;
    3) prefix="release"; base="develop" ;;
    4) prefix="hotfix"; base="main" ;;
    5) prefix="experiment"; base="develop" ;;
    *) echo -e "${RED}Неверный выбор.${NC}"; return ;;
  esac
  local branch_name=$(prompt "Введите имя ветки: ")
  if [[ -z "$branch_name" ]]; then
    echo -e "${RED}Имя ветки не может быть пустым.${NC}"
    return
  fi
  if git show-ref --verify --quiet refs/heads/"$prefix/$branch_name"; then
    echo -e "${RED}Ветка '$prefix/$branch_name' уже существует.${NC}"
    return
  fi
  git checkout -b "$prefix/$branch_name" "$base"
  echo -e "${GREEN}Ветка '$prefix/$branch_name' создана из '$base'.${NC}"
}

# Переключение на ветку
switch_branch() {
  check_uncommitted_changes
  echo -e "${BLUE}Доступные ветки:${NC}"
  local branches=($(git branch --all | grep -v '\->' | sed 's/^[ *]*//'))
  select branch_name in "${branches[@]}"; do
    if [ -n "$branch_name" ]; then
      git checkout "$branch_name"
      echo -e "${GREEN}Переключились на ветку '$branch_name'.${NC}"
      git status
      break
    else
      echo -e "${RED}Неверный выбор. Попробуйте ещё раз.${NC}"
    fi
  done
}

# Слияние веток
merge_branch() {
  check_uncommitted_changes
  echo -e "${BLUE}Доступные ветки:${NC}"
  local branches=($(git branch --all | grep -v '\->' | sed 's/^[ *]*//'))
  echo -e "${YELLOW}Выберите целевую ветку (target):${NC}"
  select target_branch in "${branches[@]}"; do
    if [ -n "$target_branch" ]; then
      break
    else
      echo -e "${RED}Неверный выбор. Попробуйте ещё раз.${NC}"
    fi
  done
  echo -e "${YELLOW}Выберите ветку, которую хотите слить (source):${NC}"
  select source_branch in "${branches[@]}"; do
    if [ -n "$source_branch" ]; then
      break
    else
      echo -e "${RED}Неверный выбор. Попробуйте ещё раз.${NC}"
    fi
  done
  git checkout "$target_branch"
  git merge --no-ff "$source_branch"
  echo -e "${GREEN}Ветка '$source_branch' успешно слита в '$target_branch'.${NC}"
}

# Пуш ветки
push_branch() {
  echo -e "${BLUE}Доступные ветки:${NC}"
  local branches=($(git branch | sed 's/^[ *]*//'))
  select branch_name in "${branches[@]}"; do
    if [ -n "$branch_name" ]; then
      git push -u origin "$branch_name"
      echo -e "${GREEN}Ветка '$branch_name' отправлена в удалённый репозиторий.${NC}"
      break
    else
      echo -e "${RED}Неверный выбор. Попробуйте ещё раз.${NC}"
    fi
  done
}

# Ребейз ветки
rebase_branch() {
  check_uncommitted_changes
  echo -e "${BLUE}Доступные ветки:${NC}"
  local branches=($(git branch | sed 's/^[ *]*//'))
  echo -e "${YELLOW}Выберите ветку для ребейза:${NC}"
  select branch_name in "${branches[@]}"; do
    if [ -n "$branch_name" ]; then
      break
    else
      echo -e "${RED}Неверный выбор. Попробуйте ещё раз.${NC}"
    fi
  done
  echo -e "${YELLOW}Выберите целевую ветку для ребейза:${NC}"
  select target_branch in "${branches[@]}"; do
    if [ -n "$target_branch" ]; then
      break
    else
      echo -e "${RED}Неверный выбор. Попробуйте ещё раз.${NC}"
    fi
  done
  git checkout "$branch_name"
  git rebase "$target_branch"
  echo -e "${GREEN}Ветка '$branch_name' успешно ребейзнута на '$target_branch'.${NC}"
}

# Удаление локальной ветки
delete_branch() {
  echo -e "${BLUE}Доступные локальные ветки:${NC}"
  local branches=($(git branch | sed 's/^[ *]*//'))
  select branch_name in "${branches[@]}"; do
    if [ -n "$branch_name" ]; then
      if [ "$branch_name" == "main" ] || [ "$branch_name" == "develop" ]; then
        echo -e "${RED}Нельзя удалить защищённую ветку '$branch_name'.${NC}"
        return
      fi
      local confirm=$(prompt "Вы уверены, что хотите удалить ветку '$branch_name'? (y/n): ")
      if [[ "$confirm" =~ ^[Yy]$ ]]; then
        git branch -d "$branch_name"
        echo -e "${GREEN}Ветка '$branch_name' удалена.${NC}"
      else
        echo -e "${YELLOW}Удаление отменено.${NC}"
      fi
      break
    else
      echo -e "${RED}Неверный выбор. Попробуйте ещё раз.${NC}"
    fi
  done
}

# Очистка удалённых веток
cleanup_branches() {
  echo -e "${YELLOW}Очистка удалённых неактуальных веток...${NC}"
  git remote prune origin
  echo -e "${GREEN}Неактуальные удалённые ветки удалены.${NC}"
}

# Показать список веток
show_branches() {
  echo -e "${BLUE}Список локальных веток:${NC}"
  git branch
  echo -e "${BLUE}Список удалённых веток:${NC}"
  git branch -r
}

# Подсказки по Git Flow
show_gitflow_tips() {
  echo -e "${YELLOW}======================================================"
  echo -e "Примерные команды Git Flow:"
  echo -e "------------------------------------------------------${NC}"
  echo -e "${GREEN}1. Создание фичи:"
  echo -e "${NC}   git checkout -b feature/add-user-authentication develop"
  echo -e "${GREEN}------------------------------------------------------"
  echo -e "2. Подготовка к релизу:"
  echo -e "${NC}   git checkout -b release/v1.0.0 develop"
  echo -e "   git checkout main"
  echo -e "   git merge --no-ff release/v1.0.0"
  echo -e "   git tag -a v1.0.0 -m 'Release v1.0.0'"
  echo -e "   git push origin main --tags"
  echo -e "${GREEN}------------------------------------------------------"
  echo -e "3. Срочный багфикс:"
  echo -e "${NC}   git checkout -b hotfix/fix-critical-bug main"
  echo -e "   [исправьте баг]"
  echo -e "   git commit -am 'Fix critical bug'"
  echo -e "   git checkout main"
  echo -e "   git merge --no-ff hotfix/fix-critical-bug"
  echo -e "   git checkout develop"
  echo -e "   git merge --no-ff hotfix/fix-critical-bug"
  echo -e "   git branch -d hotfix/fix-critical-bug"
  echo -e "   git push origin main develop"
  echo -e "${YELLOW}======================================================${NC}"
}

# Сохранение изменений в stash
stash_changes() {
  if ! git diff-index --quiet HEAD --; then
    git stash
    echo -e "${GREEN}Изменения сохранены в stash.${NC}"
  else
    echo -e "${YELLOW}Нет незакоммиченных изменений для сохранения в stash.${NC}"
  fi
}

# Показать статус репозитория
show_status() {
  git status
}

# Показать логи коммитов
show_logs() {
  git log --oneline --graph --all --decorate
}

# Основной цикл программы
while true; do
  show_menu
  choice=$(prompt "Выберите действие (1-14): ")
  case $choice in
    1)
      create_infrastructure
      ;;
    2)
      create_branch
      ;;
    3)
      switch_branch
      ;;
    4)
      merge_branch
      ;;
    5)
      push_branch
      ;;
    6)
      rebase_branch
      ;;
    7)
      delete_branch
      ;;
    8)
      cleanup_branches
      ;;
    9)
      show_branches
      ;;
    10)
      show_gitflow_tips
      ;;
    11)
      stash_changes
      ;;
    12)
      show_status
      ;;
    13)
      show_logs
      ;;
    14)
      echo -e "${GREEN}Выход из программы. До свидания!${NC}"
      exit 0
      ;;
    *)
      echo -e "${RED}Неверный ввод. Попробуйте ещё раз.${NC}"
      ;;
  esac
done
