# NI Linux DKMS 드라이버 설치 문제 해결 스크립트

RHEL 9, Rocky Linux 9, AlmaLinux 9 등 최신 Enterprise Linux 계열 배포판에서 National Instruments (NI) 드라이버 (예: NI-DAQmx)를 설치할 때 발생하는 DKMS 커널 모듈 빌드 오류를 해결하기 위한 스크립트입니다.

## 문제 현상

NI 드라이버 설치 과정 중 아래와 같은 DKMS 오류가 발생하며 커널 모듈 등록 및 빌드에 실패합니다.

```
dkms.conf: Error! Unsupported NO_WEAK_MODULES value '1'
Error! Bad conf file.
File: /usr/src/nikal-25.3.0f132/dkms.conf does not represent a valid dkms.conf file.
```

`sudo dkms status` 명령어를 실행해도 아무런 내용이 출력되지 않습니다.

## 원인

NI에서 제공하는 일부 드라이버의 DKMS 설정 파일(`dkms.conf`)에 포함된 `NO_WEAK_MODULES` 지시어가 최신 DKMS 버전에서 더 이상 지원되지 않아 발생하는 호환성 문제입니다.

## 해결 방법

`fix-ni-dkms.sh` 스크립트는 이 문제를 자동으로 해결합니다. 스크립트는 다음 세 가지 작업을 순차적으로 수행합니다.

1.  시스템에 설치된 모든 NI 드라이버 소스에서 문제가 되는 `dkms.conf` 파일을 찾아 호환되지 않는 라인을 자동으로 제거합니다.
2.  수정된 설정 파일을 바탕으로 모든 NI 드라이버 모듈을 DKMS에 수동으로 등록(`dkms add`)합니다.
3.  등록된 모든 모듈을 현재 커널에 맞게 빌드하고 설치(`dkms autoinstall`)합니다.

## 사용법

1.  **NI 드라이버 우선 설치**: National Instruments 웹사이트에서 받은 드라이버를 먼저 시스템에 설치합니다. 위와 같은 DKMS 오류가 발생해도 무시하고 설치를 완료합니다.

2.  **스크립트 다운로드**: 이 저장소를 클론하거나 `fix-ni-dkms.sh` 파일을 다운로드합니다.
    ```bash
    # git clone https://github.com/opercjy/ni_linux_driver_dkms.git
    # cd your-repo-directory
    ```

3.  **실행 권한 부여**: 스크립트에 실행 권한을 추가합니다.
    ```bash
    chmod +x fix-ni-dkms.sh
    ```

4.  **스크립트 실행**: `sudo`를 사용하여 스크립트를 실행합니다.
    ```bash
    sudo ./fix-ni-dkms.sh
    ```

## 최종 확인

스크립트가 실행되면 **3단계**에서 각 모듈이 빌드되고 설치되는 과정이 출력됩니다. 아래와 같은 로그가 반복적으로 나타나면 정상적으로 진행되고 있는 것입니다.

```
Autoinstall of module nikal/25.3.0f132 for kernel 5.14.0-570.28.1.el9_6.x86_64 (x86_64)
Deprecated feature: CLEAN (/var/lib/dkms/nikal/25.3.0f132/source/dkms.conf)
Building module(s)... done.
Signing module /var/lib/dkms/nikal/25.3.0f132/build/nikal.ko
Installing /lib/modules/5.14.0-570.28.1.el9_6.x86_64/extra/nikal.ko.xz
Adding linked weak modules...
Running depmod.... done.
```
* `Deprecated feature: CLEAN` 경고는 무시해도 괜찮은 메시지입니다.
* `Building module(s)... done.` 과 `Installing...` 메시지가 나타나면 성공적으로 빌드된 것입니다.

---

모든 과정이 끝난 후, 스크립트 마지막에 `dkms status` 명령어의 결과가 출력됩니다. 아래와 같이 설치된 NI 모듈들이 `installed` 상태로 표시되면 모든 문제가 완벽하게 해결된 것입니다. ✅

```
ni1045tr/25.3.0f212, 5.14.0-570.28.1.el9_6.x86_64, x86_64: installed
nibds/25.3.0f134, 5.14.0-570.28.1.el9_6.x86_64, x86_64: installed
nicartenumk/25.3.0f289, 5.14.0-570.28.1.el9_6.x86_64, x86_64: installed
nicdcck/25.3.0f289, 5.14.0-570.28.1.el9_6.x86_64, x86_64: installed
nicdrk/25.3.0f289, 5.14.0-570.28.1.el9_6.x86_64, x86_64: installed
nichenumk/25.3.0f289, 5.14.0-570.28.1.el9_6.x86_64, x86_64: installed
nicmmk/25.3.0f211, 5.14.0-570.28.1.el9_6.x86_64, x86_64: installed
nicntdrk/25.3.0f215, 5.14.0-570.28.1.el9_6.x86_64, x86_64: installed
nicpciek/25.3.0f210, 5.14.0-570.28.1.el9_6.x86_64, x86_64: installed
nidimk/25.3.0f177, 5.14.0-570.28.1.el9_6.x86_64, x86_64: installed
nikal/25.3.0f132, 5.14.0-570.28.1.el9_6.x86_64, x86_64: installed
nimdbgk/25.3.0f142, 5.14.0-570.28.1.el9_6.x86_64, x86_64: installed
nimxik/25.3.0f214, 5.14.0-570.28.1.el9_6.x86_64, x86_64: installed
niorbk/25.3.0f141, 5.14.0-570.28.1.el9_6.x86_64, x86_64: installed
nipalk/25.3.0f141, 5.14.0-570.28.1.el9_6.x86_64, x86_64: installed
... (기타 모든 NI 모듈)
```
