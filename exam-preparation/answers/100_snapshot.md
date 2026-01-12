# Snapshot. Что такое, для чего используется?

## Краткий ответ

Snapshot (снимок) — это моментальная копия состояния системы, виртуальной машины, базы данных или файловой системы в определенный момент времени. Используется для резервного копирования, восстановления при сбоях, тестирования изменений с возможностью отката, клонирования окружений, и защиты данных. Snapshot сохраняет полное состояние системы, включая данные, конфигурацию и память (в случае VM).

## Развёрнутый ответ

### Определение и концепция

**Snapshot (снимок, моментальный снимок)** — это точечная копия состояния данных или системы в конкретный момент времени. Snapshot фиксирует состояние без создания полной физической копии данных, используя механизмы copy-on-write или другие оптимизационные техники.

### Типы Snapshots

#### 1. VM Snapshots (Снимки виртуальных машин)

**Описание:**
Сохранение полного состояния виртуальной машины, включая:
- Содержимое виртуальных дисков
- Состояние оперативной памяти (RAM)
- Настройки виртуального оборудования
- Состояние CPU и registers

**Платформы:**
- VMware vSphere — VM snapshots с memory state
- Hyper-V — Checkpoints (Production/Standard)
- VirtualBox — Snapshots для локальных VM
- KVM/QEMU — External и Internal snapshots
- Cloud providers — AWS EC2 snapshots, Azure VM snapshots

**Состав VM snapshot:**
```
VM Snapshot состоит из:
├── Disk state (файл .vmdk/.vhdx)
├── Memory state (файл .vmem/.vsv) [опционально]
├── VM configuration (файл .vmx/.xml)
└── Snapshot metadata
```

**Use cases:**
- Перед установкой обновлений ОС
- Перед патчингом security updates
- Для тестирования конфигураций
- Перед изменением critical settings
- Создание template VM

**Ограничения:**
- Impact на производительность (delta disks)
- Занимают дисковое пространство
- Чем больше snapshots, тем медленнее VM
- Не заменяют полноценный backup
- Snapshot chains могут быть fragile

#### 2. Storage Snapshots (Снимки хранилища)

**Описание:**
Моментальная копия состояния файловой системы или block storage.

**Технологии:**

**LVM Snapshots (Linux)**
- Logical Volume Manager snapshots
- Copy-on-Write механизм
- Быстрое создание snapshot
- Используются для consistent backups

**ZFS Snapshots**
- Copy-on-Write файловая система
- Мгновенное создание snapshots
- Minimal overhead
- Incremental sends для репликации
- Read-only snapshots

**Btrfs Snapshots**
- Copy-on-Write filesystem
- Writable snapshots (subvolumes)
- Snapshot и rollback support
- Используется в SUSE, некоторых дистрибутивах

**Storage Array Snapshots**
- NetApp WAFL snapshots
- Dell EMC snapshots
- Pure Storage FlashArray snapshots
- Hardware-accelerated

**Cloud Storage Snapshots**
- AWS EBS Snapshots — block storage snapshots
- Azure Managed Disk Snapshots
- Google Persistent Disk Snapshots
- Incremental snapshots для экономии

**Особенности:**
- Мгновенное создание (не копирует данные сразу)
- Copy-on-Write — данные копируются при изменении
- Minimal impact на производительность
- Space-efficient

#### 3. Database Snapshots (Снимки баз данных)

**Описание:**
Копия состояния базы данных в определенный момент времени.

**SQL Server Database Snapshots:**
- Read-only copy of database
- Share data pages с source database
- Copy-on-Write механизм
- Revert to snapshot возможен
- Используются для reporting, testing

**Oracle Flashback:**
- Point-in-time view of data
- Query as of timestamp
- Flashback database для восстановления
- Undo data based

**PostgreSQL:**
- pg_dump для логического snapshot
- Filesystem-level snapshots (LVM/ZFS)
- WAL archiving для point-in-time recovery
- Streaming replication snapshots

**MySQL:**
- Logical snapshots через mysqldump
- Physical snapshots через filesystem
- Percona XtraBackup для hot backups
- Snapshot от underlying storage

**MongoDB:**
- mongodump для logical backups
- Filesystem snapshots для physical
- Cloud Manager snapshots
- Oplog-based point-in-time recovery

**Use cases:**
- Point-in-time recovery (PITR)
- Reporting без нагрузки на production
- Testing database changes
- Data warehouse refresh
- Development environments

#### 4. Container и Kubernetes Snapshots

**Docker Image Layers:**
- Каждый layer — snapshot изменений
- Copy-on-Write файловая система
- Image — stack of read-only snapshots
- Container adds writable layer

**Kubernetes Volume Snapshots:**
- CSI VolumeSnapshot API
- Persistent Volume snapshots
- Backup и restore PVCs
- Clone volumes from snapshots

**Example:**
```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: my-snapshot
spec:
  volumeSnapshotClassName: csi-hostpath-snapclass
  source:
    persistentVolumeClaimName: my-pvc
```

#### 5. Application-Level Snapshots

**Git Commits:**
- Каждый commit — snapshot состояния репозитория
- Lightweight — хранит только изменения
- Full history доступна
- Branching и merging на основе snapshots

**Redis RDB Snapshots:**
- Periodic snapshots в .rdb файл
- Point-in-time backup
- Compact binary format
- Restore при restart

**Elasticsearch Snapshots:**
- Repository-based snapshots
- Incremental backups
- Restore to same или different cluster
- S3/Azure/GCS support

### Механизмы реализации Snapshots

#### Copy-on-Write (COW)

**Принцип работы:**
1. При создании snapshot, данные не копируются
2. Snapshot указывает на оригинальные data blocks
3. При изменении данных, старые blocks копируются в snapshot
4. Новые данные пишутся в новые blocks
5. Snapshot сохраняет оригинальное состояние

**Преимущества:**
- Мгновенное создание snapshot
- Минимальное использование пространства изначально
- Эффективно для read-heavy workloads

**Недостатки:**
- Overhead при записи (копирование blocks)
- Производительность деградирует с количеством snapshots
- Сложность управления snapshot chains

**Используется в:**
- ZFS, Btrfs
- QEMU/KVM
- LVM
- Docker

#### Redirect-on-Write (ROW)

**Принцип работы:**
1. При создании snapshot фиксируется текущее состояние
2. При изменении данных новые данные пишутся в новые locations
3. Старые данные остаются на месте для snapshot
4. Metadata обновляется для указания на новые locations

**Преимущества:**
- Лучше write performance чем COW
- Меньше overhead при записи
- Эффективно для write-heavy workloads

**Недостатки:**
- Read может потребовать обращения к snapshot
- Fragmentation возможна

**Используется в:**
- NetApp WAFL
- Некоторые enterprise storage arrays

#### Incremental Snapshots

**Принцип:**
- Первый snapshot — full copy
- Последующие snapshots — только изменения (delta)
- Chain of snapshots

**Преимущества:**
- Экономия дискового пространства
- Быстрое создание последующих snapshots
- Эффективная передача по сети

**Недостатки:**
- Зависимость от chain (нельзя удалить промежуточные)
- Восстановление может требовать применения всех deltas
- Производительность деградирует с длиной chain

**Используется в:**
- AWS EBS Snapshots
- Azure Disk Snapshots
- VMware delta disks

### Применение Snapshots

#### 1. Backup и Recovery

**Описание:**
Snapshot как часть backup strategy для быстрого восстановления.

**Workflow:**
```
1. Create snapshot перед критическими операциями
2. Perform operations (updates, migrations)
3. If success → delete snapshot after verification
4. If failure → restore from snapshot
```

**Преимущества:**
- Быстрое восстановление (минуты vs часы)
- Minimal downtime
- Point-in-time recovery
- Frequent snapshots возможны (low overhead)

**Best practices:**
- Regular snapshot schedule
- Retention policy (не хранить слишком много)
- Test restore procedures
- Snapshots НЕ заменяют offsite backups
- Snapshot + backup to external storage

#### 2. Testing и Development

**Описание:**
Использование snapshots для создания test/dev окружений.

**Use cases:**
- Клонирование production данных для testing
- Testing patches перед production deployment
- Performance testing на реальных данных
- Developer environments с production-like data

**Workflow:**
```
Production DB → Snapshot → Restore to Test → Sanitize data → Test
```

**Преимущества:**
- Realistic test data
- Быстрое создание test environments
- Rollback test environment к начальному состоянию
- Параллельные test environments от одного snapshot

**Considerations:**
- Data privacy — sanitize sensitive data
- Resource consumption
- Snapshot frequency

#### 3. Disaster Recovery (DR)

**Описание:**
Snapshots как часть DR strategy.

**Approaches:**

**Local DR:**
- Snapshots на том же storage
- Fast recovery
- Защита от logical errors, accidental deletion
- НЕ защита от hardware failure storage

**Remote DR:**
- Snapshot replication на remote site
- Асинхронная репликация snapshots
- RPO (Recovery Point Objective) зависит от частоты snapshots
- RTO (Recovery Time Objective) зависит от restore speed

**Cloud DR:**
- Snapshots в cloud storage (S3, Azure Blob)
- Geographic redundancy
- Cost-effective long-term storage
- Slower restore но большая durability

**Example RPO/RTO:**
```
Snapshot every 4 hours → RPO = 4 hours (max data loss)
Restore time 15 minutes → RTO = 15 minutes (downtime)
```

#### 4. High Availability и Failover

**Описание:**
Использование snapshots для быстрого failover.

**Scenarios:**
- Failover на replica из snapshot
- Testing failover procedures
- Blue-green deployments с snapshots
- Canary deployments на snapshot-based clones

#### 5. Compliance и Auditing

**Описание:**
Snapshots для соответствия regulatory requirements.

**Requirements:**
- Point-in-time records для audit
- Immutable snapshots для compliance
- Long-term retention (years)
- Быстрый access для audit requests

**Industries:**
- Financial services (SOX, PCI DSS)
- Healthcare (HIPAA)
- Government (GDPR, др.)

### Best Practices для работы со Snapshots

#### 1. Snapshot Management

**Планирование:**
- Определите snapshot schedule (hourly, daily, weekly)
- Установите retention policy
- Balance между protection и storage costs
- Автоматизируйте создание и удаление

**Naming convention:**
```
<resource>-<date>-<time>-<purpose>
vm-web01-20250113-1200-pre-update
db-prod-20250113-daily
```

#### 2. Performance Considerations

**Минимизация impact:**
- Создавайте snapshots в low-traffic periods
- Ограничьте количество active snapshots
- Регулярно удаляйте старые snapshots
- Мониторьте производительность после snapshot creation

**Snapshot chains:**
- Избегайте длинных chains (consolidate)
- Максимум 3-5 snapshots в chain
- Regular consolidation/merge

#### 3. Storage Management

**Capacity planning:**
- Мониторьте рост snapshot storage
- Учитывайте change rate данных
- Reserved space для snapshots
- Alerts при достижении thresholds

**Example calculation:**
```
Database size: 1 TB
Daily change rate: 5% (50 GB)
Daily snapshots, 7 days retention

Storage needed:
Day 1: 50 GB
Day 2: 50 GB
...
Day 7: 50 GB
Total: ~350 GB (plus overhead)
```

#### 4. Security

**Защита snapshots:**
- Access control для snapshots
- Encryption at rest
- Encryption in transit (для replication)
- Immutable snapshots для compliance
- Audit logging доступа к snapshots

#### 5. Testing

**Регулярное тестирование:**
- Периодически restore from snapshots
- Verify data integrity
- Measure restore time (RTO)
- Document restore procedures
- Automated testing где возможно

#### 6. Monitoring и Alerting

**Мониторинг:**
- Snapshot creation success/failure
- Storage consumption
- Snapshot age (retention policy compliance)
- Performance impact
- Restore test results

**Alerts:**
- Failed snapshot creation
- Storage capacity warnings
- Retention policy violations
- Performance degradation

### Ограничения и недостатки Snapshots

**1. Не полноценная замена backup:**
- Snapshots на том же storage как source
- Уязвимы к hardware failure, disasters
- Требуют offsite backups для полной защиты

**2. Performance impact:**
- Copy-on-Write overhead при записи
- Degradation с количеством snapshots
- Snapshot creation может spike I/O

**3. Storage consumption:**
- Занимают дисковое пространство
- Рост с change rate данных
- Может быть неожиданным

**4. Complexity:**
- Snapshot chains сложны в управлении
- Риск corruption при неправильном удалении
- Требуют понимания для правильного использования

**5. Consistency challenges:**
- Application-consistent snapshots сложнее
- Crash-consistent может требовать recovery
- Database snapshots требуют quiescing

**6. Limitations:**
- Нельзя snapshot running critical applications без подготовки
- Некоторые изменения трудно отследить (scattered writes)
- Snapshot delete может быть долгой операцией

### Инструменты и технологии

**Virtualization:**
- VMware vSphere/ESXi
- Microsoft Hyper-V
- Citrix Hypervisor
- Proxmox VE
- oVirt/RHEV

**Cloud:**
- AWS EC2 Snapshots, EBS Snapshots
- Azure VM Snapshots, Managed Disk Snapshots
- Google Cloud Persistent Disk Snapshots
- DigitalOcean Droplet Snapshots

**Storage:**
- NetApp ONTAP
- Dell EMC PowerStore
- Pure Storage
- HPE 3PAR

**Filesystems:**
- ZFS
- Btrfs
- LVM
- Windows VSS (Volume Shadow Copy Service)

**Databases:**
- SQL Server Database Snapshots
- Oracle Flashback
- PostgreSQL PITR
- MongoDB Cloud Manager

**Containers:**
- Docker layered images
- Kubernetes CSI Snapshots
- Container registries (images as snapshots)

## Источники

Информация основана на:
- Документация VMware vSphere о VM snapshots
- AWS EBS Snapshots documentation
- ZFS и Btrfs filesystem documentation
- Microsoft SQL Server Database Snapshots guide
- Kubernetes CSI Snapshot design
- NetApp WAFL технология
- Best practices от enterprise storage vendors
- "Backup & Recovery" by W. Curtis Preston
- Oracle Database Backup and Recovery User's Guide
