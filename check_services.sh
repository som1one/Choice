#!/bin/bash
# Скрипт для проверки статуса и логов всех сервисов

echo "=== Проверка статуса всех сервисов ==="
systemctl status choice-auth choice-client choice-company choice-category choice-ordering choice-chat choice-review choice-file --no-pager -l

echo ""
echo "=== Логи сервисов с ошибками ==="
echo ""
echo "--- Client Service (8002) ---"
journalctl -u choice-client -n 30 --no-pager
echo ""
echo "--- Company Service (8003) ---"
journalctl -u choice-company -n 30 --no-pager
echo ""
echo "--- Ordering Service (8005) ---"
journalctl -u choice-ordering -n 30 --no-pager
echo ""
echo "--- Chat Service (8006) ---"
journalctl -u choice-chat -n 30 --no-pager
echo ""
echo "--- Review Service (8007) ---"
journalctl -u choice-review -n 30 --no-pager
echo ""
echo "--- File Service (8008) ---"
journalctl -u choice-file -n 30 --no-pager
