
-----

# NI 리눅스 드라이버 설치 및 이더넷 장비 설정 통합 가이드

## 개요

이 문서는 RHEL 9, Rocky Linux 9, AlmaLinux 9 등 최신 엔터프라이즈 리눅스 배포판에서 National Instruments (NI) 드라이버를 설치하고, 이더넷 기반의 cDAQ 장비를 설정할 때 발생하는 주요 문제들을 해결하기 위한 통합 가이드입니다.

이 가이드는 다음 두 가지 핵심 문제를 해결하는 데 중점을 둡니다.

1.  **DKMS 커널 모듈 빌드 오류**: `NO_WEAK_MODULES` 호환성 문제로 NI 드라이버 커널 모듈 빌드가 실패하는 현상
2.  **이더넷(cDAQ) 장비 연결 문제**: 방화벽, IP 설정, 장치 미등록으로 인해 NI 소프트웨어가 cDAQ를 인식하지 못하는 현상

초보자도 쉽게 따라 할 수 있도록 전체 과정을 단계별로 상세히 안내합니다.

-----

## 전체 해결 과정

아래의 6단계를 순서대로 진행하면 NI 드라이버 설치부터 cDAQ 장비 사용 준비까지 모든 과정을 완료할 수 있습니다.

### 1단계: NI 드라이버 다운로드 및 설치

가장 먼저 National Instruments 공식 웹사이트에서 사용하려는 드라이버(예: NI-DAQmx)를 다운로드하여 설치합니다.

1.  다운로드한 드라이버 설치 프로그램을 실행합니다.
2.  설치 과정 중 **DKMS 관련 오류** (`dkms.conf: Error!`, `Bad conf file` 등)가 발생하더라도 **무시하고 설치를 끝까지 완료**합니다. 이 오류는 3단계에서 스크립트로 해결할 것입니다.

### 2단계: 커널 헤더 및 개발 도구 설치 (중요)

DKMS가 커널 모듈을 빌드하려면 현재 실행 중인 커널 버전에 맞는 \*\*커널 헤더(kernel-devel)\*\*와 \*\*개발 도구(gcc, make 등)\*\*가 반드시 필요합니다.

터미널을 열고 아래 명령어를 실행하여 필수 패키지를 설치합니다.

```bash
sudo dnf install kernel-devel-$(uname -r) gcc make
```

  * `$(uname -r)`는 현재 커널 버전을 자동으로 입력해주는 명령어입니다.

-----

### 3단계: DKMS 빌드 오류 자동 해결

이제 NI 드라이버의 DKMS 호환성 문제를 해결할 차례입니다. `fix-ni-dkms.sh` 스크립트가 이 과정을 자동으로 처리해 줍니다. (스크립트 출처: [opercjy/ni\_linux\_driver\_dkms](https://www.google.com/search?q=https://github.com/opercjy/ni_linux_driver_dkms))

1.  **스크립트 다운로드**

    ```bash
    git clone https://github.com/opercjy/ni_linux_driver_dkms.git
    cd ni_linux_driver_dkms
    ```

2.  **실행 권한 부여**

    ```bash
    chmod +x fix-ni-dkms.sh
    ```

3.  **스크립트 실행**

    ```bash
    sudo ./fix-ni-dkms.sh
    ```

스크립트가 실행되면서 NI 커널 모듈이 빌드되고 설치되는 로그가 출력됩니다. 마지막에 `dkms status` 결과가 `installed` 상태로 표시되면 성공입니다.

-----

### 4단계: 이더넷 장비 네트워크 설정

이제 소프트웨어 설치가 끝났으니 하드웨어(cDAQ)를 설정할 차례입니다.

#### 4-1. 물리적 연결 및 IP 주소 확인

컴퓨터와 cDAQ 장비를 **동일한 네트워크** 계층에 있도록 이더넷 케이블(랜선) 연결합니다.  cDAQ 장비는 기본적으로 DHCP 모드로 설정되어 공유기로부터 IP 주소를 자동으로 할당받습니다. 공유기 설정 페이지 등에서 cDAQ에 할당된 IP 주소(예: `192.168.0.105`)를 확인합니다.

`ping <cDAQ의 IP>` 명령어로 연결을 테스트해 볼 수 있습니다.

#### 4-2. 방화벽 설정

리눅스의 방화벽은 NI 장비와의 통신을 차단할 수 있습니다. 아래 명령어를 실행하여 NI 통신에 필요한 포트를 영구적으로 열어줍니다.

```bash
#!/bin/bash
# 이 내용을 쉘 스크립트 파일(예: open_ni_ports.sh)로 저장하여 실행하세요.

PORTS_TCP=(80 3580 5353 31415)
PORTS_UDP=(5353 7865 8473)

echo "NI DAQmx 관련 TCP 포트를 영구적으로 추가합니다..."
for port in "${PORTS_TCP[@]}"; do
    sudo firewall-cmd --permanent --add-port=${port}/tcp
done

echo "NI DAQmx 관련 UDP 포트를 영구적으로 추가합니다..."
for port in "${PORTS_UDP[@]}"; do
    sudo firewall-cmd --permanent --add-port=${port}/udp
done

echo "방화벽 규칙을 다시 로드하여 적용합니다..."
sudo firewall-cmd --reload

echo "완료되었습니다. 현재 적용된 방화벽 규칙 목록:"
sudo firewall-cmd --list-all
```

#### 4-3. 고정 IP 설정 (선택 사항)

매번 IP가 바뀌는 것이 불편하다면 고정 IP를 설정하는 것이 좋습니다. 사용하는 운영체제(OS)에 따라 여러 가지 방법이 있습니다.

  * **Windows에서 설정하는 방법**

      * **방법 1: 웹 브라우저 이용 (가장 보편적)**

        1.  웹 브라우저를 열고 주소창에 cDAQ의 현재 IP 주소를 입력하여 설정 페이지에 접속합니다.
        2.  `Network Configuration` (네트워크 설정) 탭으로 이동합니다.
        3.  `DHCP`를 \*\*`Static` (고정)\*\*으로 변경하고, 원하는 IP 주소, 서브넷 마스크, 게이트웨이 정보를 입력한 후 저장합니다. 장치가 새 IP로 재부팅됩니다.

      * **방법 2: NI MAX (Measurement & Automation Explorer) 이용**

        1.  NI MAX를 실행합니다.
        2.  왼쪽 패널의 `내 시스템` » `디바이스와 인터페이스` » `네트워크 디바이스` 항목에서 cDAQ 장비를 찾습니다.
        3.  장치를 마우스 오른쪽 버튼으로 클릭하고 `네트워크 설정`을 선택합니다.
        4.  나타나는 창에서 `고정`을 선택하고 IP 정보를 입력한 후 저장합니다.

  * **Linux에서 설정하는 방법**

      * **방법 1: 웹 브라우저 이용**
        Windows에서와 동일하게 웹 브라우저로 장치의 IP 주소에 접속하여 설정할 수 있습니다. 다만, 일부 구형 장비의 웹 페이지는 Silverlight 기술을 사용하여 최신 리눅스 브라우저와 호환성 문제가 있을 수 있습니다.
      * **방법 2: `ni-hwcfg-utility` 이용 (GUI)**
        1.  터미널에 `sudo ni-hwcfg-utility`를 입력하여 실행합니다.
        2.  네트워크 장치를 선택하고, 네트워크 설정을 변경하는 메뉴로 이동하여 고정 IP 정보를 입력합니다.
      * **방법 3: 터미널 명령어 이용 (고급 사용자용)**
        ```bash
        # 아래 명령어는 NI-DAQmx 버전에 따라 지원되지 않을 수 있습니다.
        sudo nidaqmxconfig --set-net-settings <장치이름> --ip-mode static --ip-addr <고정IP> ...
        ```
        **주의**: 이 명령어는 특정 버전의 `nidaqmxconfig`에서만 지원됩니다. 명령어가 실패할 경우, 다른 방법을 사용해야 합니다.

-----

### 5단계: 시스템에 장비 등록 및 최종 확인

네트워크 설정이 끝난 장비를 NI-DAQmx 시스템에 공식적으로 등록합니다.

1.  **터미널에서 장치 추가** (고정 IP를 설정했다면 **새 IP**로 추가)

    ```bash
    sudo nidaqmxconfig --add-net-dev <cDAQ의_IP_주소>
    ```

2.  **장치 예약(reserve)/에약 해제 (unreserve) 및 리셋 (reset)** (모듈 인식을 위해)

    ```bash
    # 장치 이름은 'nilsdev'로 확인 가능 (예: cDAQ9189-2189707)
    sudo nidaqmxconfig --reserve <장치이름>
    sudo nidaqmxconfig --reset <장치이름>
    sudo nidaqmxconfig --unreserve <장치이름>
    ```

3.  **최종 확인**

    ```bash
    nilsdev
    ```

    명령어 결과에 cDAQ 섀시와 모든 모듈이 `[Not Present]` 표시 없이 나타나면 모든 설정이 성공적으로 완료된 것입니다.

-----

## 문제 해결 및 추가 도구

### NI DKMS 모듈 전체 삭제

드라이버 설치를 처음부터 다시 시작하고 싶을 때, 시스템에 등록된 모든 NI DKMS 모듈을 깨끗하게 삭제할 수 있습니다. `remove-ni-dkms.sh` 스크립트를 사용합니다.

1.  **실행 권한 부여**
    ```bash
    chmod +x remove-ni-dkms.sh
    ```
2.  **스크립트 실행**
    ```bash
    sudo ./remove-ni-dkms.sh
    ```

### 주요 터미널 명령어 요약

| 명령어 | 설명 |
| :--- | :--- |
| `nilsdev` | 시스템에 등록된 모든 NI 장치와 모듈 목록을 보여줍니다. |
| `nidaqmxconfig --add-net-dev <IP>` | 지정된 IP 주소의 네트워크 장치를 시스템에 추가합니다. |
| `nidaqmxconfig --del-net-dev <이름>` | 지정된 이름의 장치를 시스템 설정에서 삭제합니다. |
| `nidaqmxconfig --reserve <이름>` | 장치의 제어권을 독점적으로 가져옵니다. (설정 변경 시 필요) |
| `nidaqmxconfig --unreserve <이름>` | 장치의 제어권을 반납하여 다른 시스템도 접근하게 합니다. |
| `nidaqmxconfig --reset <이름>` | 장치를 리셋하여 하드웨어 정보를 다시 읽어옵니다. |

-----

이 가이드가 리눅스 환경에서 NI 하드웨어를 설정하는 데 도움이 되기를 바랍니다.
