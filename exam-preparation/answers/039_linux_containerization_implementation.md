# Опишите реализацию контейнеризации в Linux

## Краткий ответ

Контейнеризация в Linux реализована через механизмы ядра: namespaces (изоляция ресурсов), cgroups (ограничение ресурсов), capabilities (управление привилегиями), seccomp (фильтрация системных вызовов) и union file systems (слоистая файловая система). Контейнер — это изолированный процесс, использующий общее ядро хоста, но имеющий собственное представление системных ресурсов.

## Развёрнутый ответ

Контейнеризация в Linux основана на нескольких ключевых технологиях ядра, которые обеспечивают изоляцию и управление ресурсами. Контейнер в Linux — это не отдельная сущность в ядре, а комбинация различных механизмов изоляции, применённых к процессу.

### 1. Linux Namespaces (Пространства имён)

Namespaces обеспечивают изоляцию глобальных системных ресурсов, создавая виртуальные экземпляры этих ресурсов для каждого контейнера.

**Типы namespaces:**

**PID Namespace (Process ID)**
- Изолирует идентификаторы процессов
- Процесс в контейнере имеет PID 1, но в хосте — другой PID
- Процессы в контейнере не видят процессы хоста и других контейнеров
- Иерархическая структура: родительский namespace видит дочерние

```bash
# Создание процесса в новом PID namespace
unshare --pid --fork --mount-proc /bin/bash
# В новом shell команда 'ps' покажет только процессы этого namespace
```

**Network Namespace (NET)**
- Изолирует сетевой стек: интерфейсы, IP-адреса, таблицы маршрутизации, firewall-правила
- Каждый контейнер имеет виртуальный сетевой интерфейс
- Связь через veth (virtual ethernet) пары и bridge

```bash
# Создание network namespace
ip netns add container1
ip netns exec container1 ip link list
```

**Mount Namespace (MNT)**
- Изолирует точки монтирования файловой системы
- Контейнер видит только свою файловую систему
- Позволяет монтировать volumes без влияния на хост

**UTS Namespace (UNIX Time-Sharing)**
- Изолирует hostname и domain name
- Контейнер может иметь собственное имя хоста
```bash
unshare --uts /bin/bash
hostname container1
```

**IPC Namespace (Inter-Process Communication)**
- Изолирует ресурсы IPC: очереди сообщений, семафоры, разделяемую память
- Процессы в разных IPC namespace не могут взаимодействовать через IPC

**User Namespace**
- Изолирует идентификаторы пользователей и групп
- Процесс может быть root внутри контейнера, но обычным пользователем на хосте
- Улучшает безопасность через user remapping

```bash
# Создание user namespace
unshare --user --map-root-user /bin/bash
id  # Покажет uid=0 (root) внутри namespace
```

**Cgroup Namespace**
- Изолирует представление cgroups
- Контейнер видит только свои cgroup-ограничения

**Time Namespace** (с Linux 5.6)
- Изолирует системное время
- Используется для тестирования и эмуляции

### 2. Control Groups (cgroups)

Cgroups ограничивают и учитывают использование ресурсов группами процессов.

**Основные контроллеры cgroups:**

**CPU контроллер**
- Ограничение процессорного времени
- CPU shares (относительное распределение)
- CPU quota и period (абсолютное ограничение)

```bash
# Docker пример
docker run -d --cpus="1.5" nginx  # Ограничение 1.5 CPU cores
docker run -d --cpu-shares=512 nginx  # Относительный приоритет
```

**Memory контроллер**
- Ограничение использования RAM
- Swap ограничение
- OOM (Out of Memory) контроль

```bash
docker run -d --memory="512m" --memory-swap="1g" nginx
```

**Block I/O контроллер**
- Ограничение пропускной способности дисковых операций
- Приоритизация I/O операций

```bash
docker run -d --device-read-bps /dev/sda:1mb nginx
```

**Network контроллер**
- Приоритизация сетевого трафика
- Ограничение bandwidth

**Иерархия cgroups:**
```
/sys/fs/cgroup/
├── cpu/
│   └── docker/
│       └── <container-id>/
│           ├── cpu.shares
│           ├── cpu.cfs_quota_us
│           └── cpu.cfs_period_us
├── memory/
│   └── docker/
│       └── <container-id>/
│           ├── memory.limit_in_bytes
│           └── memory.usage_in_bytes
└── ...
```

**cgroups v2 (unified hierarchy)**
- Единая иерархия для всех контроллеров
- Улучшенная изоляция
- Более строгие правила наследования

### 3. Linux Capabilities

Capabilities разделяют привилегии root на гранулярные разрешения.

**Примеры capabilities:**
- `CAP_NET_BIND_SERVICE` — биндинг к привилегированным портам (<1024)
- `CAP_NET_ADMIN` — конфигурация сети
- `CAP_SYS_ADMIN` — различные административные операции
- `CAP_CHOWN` — изменение владельца файлов

**Использование в Docker:**
```bash
# Запуск без привилегий, но с возможностью биндинга к порту 80
docker run -d --cap-add=NET_BIND_SERVICE --cap-drop=ALL nginx

# Полные привилегии (небезопасно)
docker run -d --privileged nginx
```

### 4. Seccomp (Secure Computing Mode)

Seccomp фильтрует системные вызовы, доступные процессу.

**Режимы seccomp:**
- **strict mode**: разрешены только read, write, exit, sigreturn
- **filter mode**: кастомная фильтрация через BPF (Berkeley Packet Filter)

**Docker seccomp profile:**
```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "syscalls": [
    {
      "names": ["read", "write", "open", "close"],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

Блокирует потенциально опасные системные вызовы:
- `keyctl` — манипуляция ключами
- `add_key` — добавление ключей
- `ptrace` — отладка процессов

### 5. AppArmor и SELinux

Mandatory Access Control (MAC) системы для дополнительной безопасности.

**AppArmor (Ubuntu, Debian):**
```bash
# Проверка профиля контейнера
docker inspect <container> | grep AppArmorProfile
```

**SELinux (RHEL, CentOS, Fedora):**
- Контексты безопасности для контейнеров
- Политики для изоляции

### 6. Union File Systems

Обеспечивают эффективное хранение и использование образов через слои.

**Доступные драйверы:**

**OverlayFS** (рекомендуемый)
- Два слоя: lower (read-only) и upper (read-write)
- Эффективное использование inode
- Хорошая производительность

```
/var/lib/docker/overlay2/
├── <layer-id>/
│   ├── diff/     # Содержимое слоя
│   ├── link      # Символическая ссылка
│   └── work/     # Рабочая директория
```

**AUFS** (устаревший)
- Использовался в старых версиях Docker
- Не включён в mainline ядро

**Device Mapper**
- Block-level copy-on-write
- Используется в RHEL/CentOS 7

**Btrfs и ZFS**
- Файловые системы с нативной поддержкой снапшотов

### 7. Copy-on-Write (CoW)

Механизм оптимизации дискового пространства.

**Принцип работы:**
1. Все контейнеры разделяют read-only слои образа
2. При записи файл копируется в writable слой контейнера
3. Изменения видны только в этом контейнере

**Преимущества:**
- Экономия дискового пространства
- Быстрый старт контейнеров
- Эффективное использование кэша

### 8. Runtime реализации

**runC**
- Low-level container runtime
- Реализация OCI (Open Container Initiative) спецификации
- Используется Docker, containerd, CRI-O

**containerd**
- High-level container runtime
- Управление жизненным циклом контейнеров
- Используется Kubernetes

**CRI-O**
- Container runtime для Kubernetes
- Минималистичная реализация CRI (Container Runtime Interface)

### 9. Практический процесс создания контейнера

```bash
# 1. Создание namespaces
unshare --pid --net --mount --uts --ipc --user --fork

# 2. Настройка cgroups
echo $$ > /sys/fs/cgroup/memory/mycontainer/cgroup.procs
echo 536870912 > /sys/fs/cgroup/memory/mycontainer/memory.limit_in_bytes

# 3. Настройка filesystem с chroot/pivot_root
mount -t overlay overlay -o lowerdir=/image,upperdir=/container,workdir=/work /rootfs
chroot /rootfs /bin/bash

# 4. Применение capabilities и seccomp
capsh --drop=cap_sys_admin --

# 5. Запуск процесса приложения
exec /app/server
```

### 10. Отличия от виртуальных машин

**Контейнеры Linux:**
- Используют общее ядро хоста
- Изоляция на уровне процессов через namespace/cgroups
- Меньше накладных расходов
- Быстрый старт (миллисекунды-секунды)
- Меньший размер образов

**Виртуальные машины:**
- Полная изоляция с собственным ядром
- Гипервизор (KVM, Xen, VMware)
- Больше накладных расходов
- Медленный старт (минуты)
- Больший размер образов

## Источники

- Linux Kernel Documentation: namespaces, cgroups
- man pages: namespaces(7), cgroups(7), capabilities(7), seccomp(2)
- OCI (Open Container Initiative) Runtime Specification
- Docker Documentation: Storage drivers, Security
- containerd architecture documentation
- "Container Security" by Liz Rice
- "Linux Containers and Virtualization" by Shashank Mohan Jain
