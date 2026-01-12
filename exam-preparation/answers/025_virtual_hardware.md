# Опишите виртуальные аппаратные средства

## Краткий ответ
Виртуальные аппаратные средства (Virtual Hardware) - это программная эмуляция физических компонентов компьютера, создаваемая гипервизором для виртуальных машин. Включает виртуальные процессоры (vCPU), виртуальную память (vRAM), виртуальные диски, сетевые адаптеры, графические карты, USB контроллеры и другие устройства. Гостевая ОС воспринимает виртуальное оборудование как реальное, а гипервизор транслирует операции с виртуальными устройствами в операции с физическим оборудованием, обеспечивая изоляцию, гибкость, портативность и эффективное использование ресурсов.

## Развёрнутый ответ

### Определение и архитектура

**Виртуальные аппаратные средства** представляют собой абстрактный слой между гостевой операционной системой и физическим оборудованием, создаваемый гипервизором. Этот слой эмулирует полнофункциональный компьютер со всеми необходимыми компонентами.

### Архитектура виртуального оборудования

```
┌─────────────────────────────────────────────────┐
│         Guest Operating System                  │
├─────────────────────────────────────────────────┤
│         Virtual Hardware Layer                  │
│  ┌──────────┬──────────┬──────────┬──────────┐ │
│  │  vCPU    │  vRAM    │ vDisk    │  vNIC    │ │
│  └────┬─────┴────┬─────┴────┬─────┴────┬─────┘ │
└───────┼──────────┼──────────┼──────────┼───────┘
        │          │          │          │
        ↓          ↓          ↓          ↓
┌─────────────────────────────────────────────────┐
│         Hypervisor (VMM)                        │
│  - Resource Management                          │
│  - Hardware Abstraction                         │
│  - Scheduling & Allocation                      │
└───────┬──────────┬──────────┬──────────┬───────┘
        │          │          │          │
        ↓          ↓          ↓          ↓
┌─────────────────────────────────────────────────┐
│         Physical Hardware                       │
│  ┌──────────┬──────────┬──────────┬──────────┐ │
│  │   CPU    │   RAM    │  Disk    │   NIC    │ │
│  └──────────┴──────────┴──────────┴──────────┘ │
└─────────────────────────────────────────────────┘
```

### 1. Виртуальный процессор (vCPU)

#### Определение и принцип работы

**Virtual CPU (vCPU)** - это программная абстракция физического процессора, предоставляемая виртуальной машине.

**Характеристики vCPU:**
- Представляет собой execution context (регистры, instruction pointer)
- Планируется гипервизором на физических CPU cores
- Может иметь различное число ядер (1, 2, 4, 8, 16+)
- Поддерживает CPU features (SSE, AVX, AES-NI)

#### Типы виртуализации CPU

**Полная виртуализация:**
```
Binary Translation (старый подход):
- Гипервизор перехватывает привилегированные инструкции
- Транслирует их в безопасные операции
- Высокий overhead (20-40%)

Hardware-assisted (Intel VT-x, AMD-V):
- Процессор поддерживает виртуализацию аппаратно
- VMX root mode (hypervisor) и VMX non-root mode (guest)
- Минимальный overhead (2-5%)
```

**Паравиртуализация:**
- Гостевая ОС модифицирована и знает о виртуализации
- Использует hypercalls вместо привилегированных инструкций
- Высокая производительность
- Примеры: Xen PV, старые Linux kernels

**Гибридная виртуализация:**
- Комбинация hardware-assisted и паравиртуализации
- KVM с virtio
- VMware с VMXNET3
- Лучшая производительность

#### CPU Scheduling

**Алгоритмы планирования:**

**Proportional Share:**
```
Распределение CPU time на основе shares:
VM1: 2000 shares → 50% CPU time
VM2: 1000 shares → 25% CPU time
VM3: 1000 shares → 25% CPU time

При idle одной ВМ:
Неиспользуемое время перераспределяется пропорционально
```

**Reservations:**
```
Гарантированные ресурсы:
VM1: reservation 2 GHz → гарантированно получит
VM2: reservation 1 GHz

Даже при перегрузке хоста reservations гарантированы
```

**Limits:**
```
Максимальное ограничение:
VM1: limit 4 GHz → не получит больше даже при наличии
```

#### CPU Features

**Exposed features:**
```
Виртуальные CPU могут поддерживать:
- SSE, SSE2, SSE3, SSE4 (SIMD инструкции)
- AVX, AVX2, AVX-512 (Advanced Vector Extensions)
- AES-NI (аппаратное ускорение шифрования)
- VT-d/AMD-Vi (IOMMU для passthrough)
- RDRAND (аппаратный генератор случайных чисел)
```

**CPU Masking:**
- Скрытие определенных CPU features
- Обеспечение совместимости при миграции
- Unified CPU feature set в кластере

#### CPU Hotplug

**Динамическое изменение:**
```
Добавление vCPU без перезагрузки ВМ:
1. VM работает с 2 vCPU
2. Администратор добавляет 2 vCPU
3. Гостевая ОС обнаруживает новые CPU
4. Online новых CPU
5. VM теперь использует 4 vCPU

Требования:
- Поддержка гостевой ОС
- Поддержка гипервизора
- Возможность только добавления (не удаления) в большинстве случаев
```

### 2. Виртуальная память (vRAM)

#### Управление памятью

**Memory allocation:**
```
Виртуальная машина видит:
- Continuous physical address space
- Например: 8 GB RAM (0x0 - 0x200000000)

Реальность:
- Память разбита на страницы (4KB, 2MB, 1GB)
- Страницы могут находиться в разных местах физической памяти
- Гипервизор управляет отображением (MMU virtualization)
```

#### Технологии оптимизации памяти

**Memory Overcommitment:**
```
Сценарий:
Physical host: 64 GB RAM
VM1: 16 GB
VM2: 16 GB
VM3: 16 GB
VM4: 16 GB
Итого allocated: 64 GB

Фактическое использование:
VM1: 8 GB (50% utilization)
VM2: 10 GB (62.5%)
VM3: 6 GB (37.5%)
VM4: 12 GB (75%)
Итого used: 36 GB

Можно добавить еще ВМ (overcommitment)
```

**Transparent Page Sharing (TPS):**
```
Принцип:
1. Несколько ВМ с одинаковой ОС (Windows Server)
2. Множество идентичных страниц памяти (OS kernel, DLLs)
3. Гипервизор обнаруживает идентичные страницы (hash)
4. Создает одну копию, остальные mapping на нее
5. Copy-on-Write при изменении

Экономия: до 30-50% для похожих ВМ
```

**Memory Ballooning:**
```
Процесс:
1. Хост нуждается в памяти для новой ВМ
2. Balloon driver в guest начинает аллоцировать память
3. Гостевая ОС думает, что память используется
4. Гипервизор отбирает эту память
5. Память доступна другим ВМ

Преимущество: гостевая ОС сама решает, что выгрузить
```

**Memory Compression:**
```
При нехватке памяти:
1. Гипервизор сжимает редко используемые страницы
2. Хранит сжатые данные в памяти
3. Декомпрессия при доступе

Compression ratio: обычно 2:1 - 4:1
Быстрее, чем swap на диск
```

**Swapping:**
```
Крайняя мера:
- Неиспользуемые страницы сбрасываются на диск
- Очень медленно (disk I/O)
- Сильное влияние на производительность
- Избегать в production
```

#### NUMA (Non-Uniform Memory Access)

**NUMA awareness:**
```
Современные серверы:
- Несколько CPU sockets
- Каждый socket имеет локальную память
- Доступ к локальной памяти быстрее

NUMA-aware планирование:
- vCPU планируется на одном NUMA node
- vRAM аллоцируется из локальной памяти этого node
- Избегается remote memory access

Производительность: +10-30% для memory-intensive приложений
```

#### Memory Hot-add

**Динамическое добавление памяти:**
```
Без перезагрузки ВМ:
1. VM работает с 8 GB RAM
2. Добавление 8 GB через гипервизор
3. Гостевая ОС обнаруживает новую память
4. Online новых memory blocks
5. VM использует 16 GB

Ограничения:
- Поддержка ОС (Linux: memory hotplug, Windows: ограничена)
- Maximum memory должен быть установлен заранее
```

### 3. Виртуальные диски

#### Типы виртуальных дисков

**Форматы дисков:**

**VMDK (VMware Virtual Disk):**
```
Характеристики:
- Проприетарный формат VMware
- Поддержка snapshots
- Thin и thick provisioning
- Поддержка split files (2GB chunks)
- Широкая совместимость
```

**VHD/VHDX (Virtual Hard Disk):**
```
Microsoft формат:
VHD (legacy):
- Максимум 2 TB
- Используется в Hyper-V, VirtualBox

VHDX (modern):
- Максимум 64 TB
- Улучшенная производительность
- Лучшая защита от corruption
- Hyper-V основной формат
```

**QCOW2 (QEMU Copy-On-Write):**
```
KVM/QEMU формат:
- Copy-on-write
- Compression
- Encryption
- Snapshots support
- Thin provisioning
- Backing files (дифференциальные диски)
```

**RAW:**
```
Простой формат:
- Прямой образ диска (dd)
- Нет overhead
- Максимальная производительность
- Нет advanced features (snapshots)
- Используется для production с high I/O
```

#### Provisioning типы

**Thick Provisioning:**
```
Eager Zeroed Thick:
- Весь диск аллоцируется сразу
- Заполняется нулями при создании
- Лучшая производительность
- Максимальная надежность
- Долгое создание

Lazy Zeroed Thick:
- Весь диск аллоцируется сразу
- Заполняется нулями при первой записи
- Быстрое создание
- Немного медленнее при первой записи
```

**Thin Provisioning:**
```
Преимущества:
- Аллоцируется только используемое пространство
- Overcommitment storage
- Быстрое создание ВМ
- Экономия места

Недостатки:
- Slight performance overhead
- Риск переполнения хранилища
- Требует мониторинга

Пример:
Создан 100 GB thin disk
Используется 30 GB
На storage занято 30 GB
```

#### Виртуальные контроллеры

**IDE/ATA контроллеры:**
- Legacy поддержка
- Низкая производительность
- Максимум 4 диска
- Совместимость с любыми ОС

**SATA контроллеры:**
- Современный стандарт для десктопов
- AHCI support (hot-plug, NCQ)
- До 30 дисков
- Хорошая совместимость

**SCSI контроллеры:**
```
LSI Logic:
- Эмулированный SCSI
- Хорошая производительность
- Широкая поддержка ОС

LSI Logic SAS:
- Современный SAS контроллер
- Лучшая производительность
- Поддержка SSD

PVSCSI (VMware):
- Паравиртуализированный
- Максимальная производительность
- Требует VMware Tools
- IOPS: 300k+
```

**NVMe контроллеры:**
```
Виртуальный NVMe:
- Современный протокол для SSD
- Низкая latency
- Высокая пропускная способность
- IOPS: 1M+
- Требует современных ОС (Windows 10+, Linux 4.x+)
```

#### Снапшоты дисков

**Механизм snapshots:**
```
Работа снапшотов (Copy-on-Write):
1. Создается snapshot в момент времени T0
2. Базовый диск становится read-only
3. Создается delta/child диск для изменений
4. Запись идет в delta диск
5. Чтение: сначала delta, потом base

Snapshot chain:
Base ← Snapshot1 ← Snapshot2 ← Active

Проблемы:
- Performance degradation с длинной цепочкой
- Увеличение использования места
- Необходимость consolidation
```

### 4. Виртуальные сетевые адаптеры

#### Типы виртуальных NIC

**Эмулированные адаптеры:**

**E1000/E1000E:**
```
Intel PRO/1000 эмуляция:
- Широкая совместимость
- 1 Гбит/с
- Встроенная поддержка в большинстве ОС
- Средняя производительность
- Throughput: 500-900 Мбит/с
```

**RTL8139:**
```
Realtek адаптер:
- Legacy поддержка
- 100 Мбит/с
- Низкая производительность
- Используется редко
```

**Паравиртуализированные адаптеры:**

**VMXNET3 (VMware):**
```
Характеристики:
- Паравиртуализированный
- Требует VMware Tools
- Multi-queue support (8-16 queues)
- Jumbo frames (9000 MTU)
- Offloading (TSO, LRO, checksum)
- Throughput: 9-10 Гбит/с
- Latency: < 100 μs
```

**VirtIO-Net (KVM):**
```
Производительность:
- Multi-queue (до 256 queues)
- Vhost-net для kernel acceleration
- Offloading support
- Throughput: 10+ Гбит/с
- Zero-copy with vhost-net
```

**Synthetic Network Adapter (Hyper-V):**
```
Integration Services адаптер:
- Высокая производительность
- VMQ (Virtual Machine Queue)
- SR-IOV support
- RDMA capable
- Throughput: 10-40 Гбит/с
```

#### Расширенные функции

**SR-IOV (Single Root I/O Virtualization):**
```
Принцип:
1. Физический NIC разделяется на Virtual Functions (VF)
2. Каждая ВМ получает direct VF
3. Bypass виртуального коммутатора
4. Near bare-metal performance

Преимущества:
- Latency: < 10 μs
- Throughput: 10-40 Гбит/с линейно
- CPU offload

Недостатки:
- Ограниченная mobility (vMotion только с ограничениями)
- Зависимость от аппаратуры
- Нет фильтрации гипервизором
```

**DPDK (Data Plane Development Kit):**
- Userspace packet processing
- Poll-mode drivers
- Используется для NFV
- Throughput: 10-100 Гбит/с

### 5. Графические адаптеры

#### Виртуальная графика

**VGA/SVGA эмуляция:**
```
Базовая графика:
- 2D acceleration
- Низкое разрешение (1024x768 без Guest Tools)
- Минимальная память (16-32 MB)
- Совместимость с любыми ОС
```

**3D ускорение:**

**VMware SVGA 3D:**
- OpenGL 3.3 support
- DirectX 10 support
- Hardware acceleration на хосте
- Требует VMware Tools

**VirtualBox 3D:**
- OpenGL 3.0
- DirectX 9/11 (experimental)
- Guest Additions required

**VirtIO-GPU:**
- 3D acceleration через Virgil
- OpenGL support
- Используется в KVM

#### GPU Passthrough

**PCI Passthrough:**
```
Прямое назначение GPU:
- Физическая видеокарта передается ВМ
- Full native performance
- Поддержка CUDA, OpenCL
- CAD, gaming, ML workloads

Требования:
- VT-d / AMD-Vi (IOMMU)
- GPU поддержка
- UEFI firmware ВМ
- Невозможность sharing между ВМ
```

**vGPU (NVIDIA GRID/vGPU):**
```
Виртуальные GPU:
- Один физический GPU → несколько vGPU
- Каждая ВМ получает dedicated vGPU
- Full DirectX, OpenGL, CUDA support
- Profiles: 1GB, 2GB, 4GB, 8GB vRAM

Use cases:
- VDI (Virtual Desktop Infrastructure)
- CAD workstations
- GPU computing
```

### 6. Другие виртуальные устройства

#### USB контроллеры

**Типы:**
- USB 1.1 (UHCI/OHCI)
- USB 2.0 (EHCI) - до 480 Мбит/с
- USB 3.0/3.1 (xHCI) - до 10 Гбит/с

**USB Passthrough:**
```
Режимы:
1. USB device filter - автоматическое подключение к ВМ
2. Manual connect - подключение по требованию
3. USB over network - удаленное USB

Ограничения:
- Performance зависит от типа контроллера
- Не все устройства совместимы
- Проблемы с некоторыми security keys
```

#### Аудио устройства

**Эмулируемые:**
- AC'97 (Audio Codec '97)
- Intel HD Audio
- SoundBlaster 16 (legacy)

**Особенности:**
- Обычно достаточно для базовых нужд
- Latency может быть проблемой для профессиональной работы

#### Serial/Parallel порты

**COM ports:**
- Виртуальные serial ports
- Pipe to file или network socket
- Используется для консольного доступа
- Logging и debugging

**LPT ports:**
- Legacy поддержка
- Редко используется

#### TPM (Trusted Platform Module)

**Virtual TPM:**
```
Функции:
- Secure boot
- Disk encryption (BitLocker)
- Credential storage
- Platform attestation

Реализация:
- vTPM 2.0 в современных гипервизорах
- Каждой ВМ свой vTPM
- Backup и migration поддержка
```

### 7. Конфигурация виртуального оборудования

#### VM Configuration Files

**VMware (.vmx):**
```
Пример vmx файла:
config.version = "8"
virtualHW.version = "14"
memSize = "8192"
numvcpus = "4"
scsi0.present = "TRUE"
scsi0.virtualDev = "lsilogic"
ethernet0.present = "TRUE"
ethernet0.virtualDev = "vmxnet3"
```

**VirtualBox (.vbox):**
```xml
<Machine>
  <Hardware>
    <CPU count="4"/>
    <Memory RAMSize="8192"/>
    <Display VRAMSize="128"/>
    <Network>
      <Adapter type="82540EM"/>
    </Network>
  </Hardware>
</Machine>
```

**libvirt (domain XML):**
```xml
<domain type='kvm'>
  <vcpu placement='static'>4</vcpu>
  <memory unit='GiB'>8</memory>
  <devices>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
    </disk>
    <interface type='network'>
      <model type='virtio'/>
    </interface>
  </devices>
</domain>
```

#### Hardware Compatibility

**Version compatibility:**
```
VMware hardware versions:
- v14: ESXi 6.5
- v15: ESXi 6.7
- v17: ESXi 7.0
- v19: ESXi 7.0 Update 2
- v20: ESXi 8.0

Newer versions:
- Больше возможностей (NVMe, больше RAM/CPU)
- Лучшая производительность
- Обратная несовместимость с старыми хостами
```

### Сравнительная таблица производительности

| Компонент | Emulated | Paravirtualized | SR-IOV/Passthrough |
|-----------|----------|-----------------|-------------------|
| CPU | N/A | 95-98% | 99-100% |
| Memory | 90-95% | 95-98% | 98-100% |
| Disk (IOPS) | 5k-50k | 50k-500k | 500k-1M+ |
| Network (Gbps) | 0.5-1 | 5-10 | 10-100 |
| GPU | Software | N/A | 95-100% |
| Overhead | High (20-40%) | Low (2-5%) | Minimal (<2%) |

## Источники
- VMware Virtual Hardware Documentation
- VirtualBox Virtual Hardware Guide
- KVM/QEMU Virtual Devices
- Microsoft Hyper-V Virtual Hardware
- Intel VT-x Technical Specification
- AMD-V Architecture Reference
- SR-IOV Specification (PCI-SIG)
- VirtIO Specification
- NVIDIA vGPU Documentation
- TPM 2.0 Specification
