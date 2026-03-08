# DiskPangPang 시행착오 기록

## 1. Swift 6 Concurrency — actor가 UI를 블로킹

### 문제
`DiskScanner`를 `actor`로 구현. `scan()` 메서드가 동기적으로 파일시스템을 순회하는데, actor 내부에서 `Task { @MainActor in }` 으로 progress를 보내도 MainActor가 실행될 기회가 없었음. actor의 직렬 실행 특성상 scan 루프가 끝날 때까지 다른 메서드가 실행 불가.

### 증상
- 스캔은 돌아가지만 (디버그 로그로 확인) UI 진행률이 0에서 안 올라감
- 스캔 완료 후에야 UI가 한번에 업데이트

### 해결
`actor` → `final class DiskScanner: Sendable`로 변경. 취소 플래그는 `OSAllocatedUnfairLock`으로 thread-safe 처리.
```swift
final class DiskScanner: Sendable {
    private let _isCancelled = OSAllocatedUnfairLock(initialState: false)
}
```

---

## 2. Task { @MainActor in } vs DispatchQueue.main.async

### 문제
`Task.detached` 내부에서 `Task { @MainActor in }` 으로 UI 업데이트를 보내도, @Observable 프로퍼티 변경이 SwiftUI에 반영되지 않음.

### 증상
- `state = .scanning(progress: ...)` 할당은 실행되지만 뷰가 리렌더되지 않음

### 해결
`DispatchQueue.main.async`로 변경하니 정상 동작.
```swift
scanTask = Task.detached(priority: .userInitiated) { @Sendable [weak self] in
    nonisolated(unsafe) let weakSelf = self
    let result = scannerRef.scan(url: url) { progress in
        DispatchQueue.main.async {
            weakSelf?.state = .scanning(progress: progress)
        }
    }
    DispatchQueue.main.async {
        weakSelf?.rootNode = result
        weakSelf?.state = .completed
    }
}
```

### 원인 추정
`@Observable`의 observation tracking이 `Task { @MainActor in }` 경로에서 정상적으로 willSet/didSet을 trigger하지 못한 것으로 보임. `DispatchQueue.main.async`는 RunLoop을 직접 통하므로 SwiftUI 업데이트가 확실히 발생.

---

## 3. Swift 6 Concurrency 에러 — self 캡처

### 문제
`Task.detached` 클로저에서 `[weak self]`를 캡처한 뒤 `guard let self`를 하면:
- `reference to captured var 'self' in concurrently-executing code`
- `initializer for conditional binding must have Optional type`

### 해결
`nonisolated(unsafe) let weakSelf = self` 패턴 사용.
```swift
scanTask = Task.detached { @Sendable [weak self] in
    nonisolated(unsafe) let weakSelf = self
    // weakSelf?.doSomething()
}
```

---

## 4. FDA (Full Disk Access) 권한이 매 빌드마다 초기화

### 문제
Debug 빌드는 코드 서명이 ad-hoc이라 빌드할 때마다 바이너리 해시가 변경 → macOS가 다른 앱으로 인식 → FDA 권한 재승인 필요.

### 해결
Release 빌드 + Developer ID 서명. `/Applications/`에 설치하여 안정적인 코드 서명 유지.
```bash
xcodebuild -project DiskPangPang.xcodeproj -scheme DiskPangPang -configuration Release \
  CODE_SIGN_IDENTITY="Developer ID Application: Unlimiting Studio (KMDVJDU523)" \
  CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM=KMDVJDU523 build
```

---

## 5. 스캔 퍼센티지 — 사전 카운트 vs 볼륨 기반 추정

### 문제 (첫 번째 시도)
스캔 전에 전체 파일 개수를 먼저 세려고 함 → 이 자체가 전체 스캔만큼 오래 걸림. 의미 없음.

### 해결
볼륨의 `총 용량 - 가용 용량 = 사용량`을 즉시 계산하고, 스캔하면서 읽은 파일 크기를 누적하여 퍼센티지 산출.
```swift
percentage = min(scannedSize / estimatedTotalSize * 100, 99.9)
```
홈 폴더 스캔 시 볼륨 전체 사용량 대비이므로 100%에 도달 안 할 수 있으나, 진행 감각은 충분.

---

## 6. NSWorkspace not in scope

### 문제
`PermissionService.swift`에서 `NSWorkspace.shared.open(url)` 사용 시 컴파일 에러.

### 해결
`import Foundation` → `import AppKit`으로 변경.

---

## 7. SwiftUI 중첩 @Observable 바인딩

### 문제
`@State private var appState = AppState()` 안에 `appState.collectorVM` (또 다른 @Observable)이 있을 때, `$appState.collectorVM.showDeleteConfirmation`으로 바인딩하면:
- `cannot assign to property: 'let' constant`

### 해결
`Bindable()` 래퍼 사용.
```swift
.sheet(isPresented: Bindable(appState.collectorVM).showDeleteConfirmation) { ... }
```

---

## 8. Picker와 Button 너비 불일치

### 문제
SwiftUI의 `Picker(.menu)` 스타일은 내부 너비를 자동 조정하여, 아래 Button과 너비가 안 맞음.

### 해결
`Picker` 대신 `Menu { ... } label: { ... }` 커스텀 구현. label에 `frame(maxWidth: .infinity)` 적용.

---

## 9. 볼륨 선택기에 홈 폴더가 기본값

### 문제
디스크 분석 앱인데 기본 선택이 홈 폴더(`NSHomeDirectory()`). 사용자는 "Macintosh HD" 같은 실제 디스크를 선택하고 싶어함.

### 해결
- `selectedVolume` 기본값을 `URL(fileURLWithPath: "/")`로 변경
- `loadVolumes()`에서 루트 볼륨(`/`) 필터링 제거
- `volumeLabel()`에서 `URLResourceKey.volumeNameKey`로 실제 볼륨 이름 + 용량 표시
- 결과: "Macintosh HD (494.38GB)"

---

## 10. 앱 배포 시 바이너리 교체 안 됨

### 문제
`cp -R`으로 `/Applications/DiskPangPang.app` 위에 덮어쓰기 시도 → 앱이 실행 중이면 바이너리가 실제로 교체되지 않는 경우 발생.

### 증상
- `strings` 명령으로 바이너리에 이전 문자열이 없음을 확인했는데도 UI에 이전 문자열 표시

### 해결
반드시 이 순서로:
1. `pkill -9` 완전 종료
2. `sleep 2` 대기
3. `rm -rf /Applications/DiskPangPang.app` 삭제
4. `cp -R` 새 빌드 복사
5. `open` 실행

---

## 11. OSAllocatedUnfairLock 컴파일 에러

### 문제
`OSAllocatedUnfairLock` 사용 시 `Cannot find 'OSAllocatedUnfairLock' in scope`.

### 해결
`import os` 추가.
