#!/bin/bash

# DKMS에 추가되거나 설치된 모든 NI (National Instruments) 드라이버 모듈을
# 찾아 자동으로 삭제하는 스크립트입니다. (대소문자 무시)
#
# 이 스크립트는 반드시 root 권한으로 실행해야 합니다. (e.g., sudo ./remove-ni-dkms.sh)

# root 사용자인지 확인
if [ "$EUID" -ne 0 ]; then
  echo "오류: 이 스크립트는 반드시 root 권한으로 실행해야 합니다. (sudo ./remove-ni-dkms.sh)"
  exit 1
fi

echo "--- DKMS에 등록된 모든 NI 드라이버 모듈 삭제를 시작합니다 (대소문자 무시) ---"

# dkms status 결과에서 'ni'로 시작하는 모듈의 이름/버전만 추출하고,
# sort -u 명령으로 중복된 항목을 제거한 후 하나씩 삭제합니다.
dkms status | grep -i '^ni' | awk -F, '{print $1}' | sort -u | while read -r module; do
  if [ -n "$module" ]; then
    echo "==> 삭제 중: ${module}"
    # --all 옵션으로 모든 커널에서 해당 모듈을 삭제합니다.
    # || true를 추가하여 모듈이 없다는 오류가 발생해도 스크립트가 중단되지 않도록 합니다.
    dkms remove "${module}" --all || true
  fi
done

echo ""
echo "--- 작업 완료 후 최종 DKMS 상태를 확인합니다 ---"
dkms status
echo ""
echo "--- 모든 NI DKMS 모듈이 성공적으로 삭제되었습니다! ---"
