# System Flowchart

## ADDIE 모델 기반 적응형 학습 튜터 시스템 흐름도

```mermaid
flowchart TD
    Start([사용자 Query]) --> StateCheck{상태 체크}

    %% 준비 안됨 경로
    StateCheck -->|준비 안됨| Analyst[Analyst Agent<br/>정보 수집]
    Analyst --> ProfileUpdate[프로파일 업데이트]

    %% 백그라운드 Web Search (subject 추출 시)
    ProfileUpdate --> SubjectCheck{subject<br/>추출됨?}
    SubjectCheck -->|추출됨| WebSearch[Web Search<br/>백그라운드 실행]
    SubjectCheck -->|미추출| MandatoryCheck
    WebSearch -.병렬 실행.-> ResourceCache[(자료 캐시<br/>학습자료+교수설계이론)]
    WebSearch --> MandatoryCheck

    MandatoryCheck{필수 정보<br/>완성?}
    MandatoryCheck -->|완성| DesignStart[Syllabus Designer<br/>커리큘럼 생성]
    MandatoryCheck -->|미완성| Response1([응답 반환])

    %% 준비됨 경로
    StateCheck -->|준비됨| IntentClassifier[Intent Classifier<br/>의도 분류]

    IntentClassifier -->|inClass| Tutor[Tutor Agent<br/>스트리밍 수업]
    Tutor --> Response2([응답 반환])

    IntentClassifier -->|outOfClass| Feedback[Feedback Agent<br/>피드백 처리]
    Feedback --> RedesignCheck{재설계<br/>필요?}
    RedesignCheck -->|필요| DesignStart
    RedesignCheck -->|불필요| ProfileUpdate2[프로파일 업데이트<br/>level/tone만]
    ProfileUpdate2 --> Response3([응답 반환])

    %% 설계 시 캐시 활용
    ResourceCache -.활용.-> DesignStart

    %% 설계 완료 후 자동 수업 시작
    DesignStart --> DesignComplete[설계 완료]
    DesignComplete -->|자동 실행| Tutor

    %% 스타일링
    classDef decisionStyle fill:#FFE6E6,stroke:#FF6B6B,stroke-width:2px
    classDef processStyle fill:#E6F3FF,stroke:#4A90E2,stroke-width:2px
    classDef stateStyle fill:#E6FFE6,stroke:#52C41A,stroke-width:2px
    classDef backgroundStyle fill:#FFF4E6,stroke:#FF9800,stroke-width:2px,stroke-dasharray: 5 5
    classDef cacheStyle fill:#E8EAF6,stroke:#3F51B5,stroke-width:2px

    class StateCheck,MandatoryCheck,RedesignCheck,SubjectCheck decisionStyle
    class Analyst,IntentClassifier,Tutor,Feedback,DesignStart processStyle
    class Start,Response1,Response2,Response3,ProfileUpdate,ProfileUpdate2,DesignComplete stateStyle
    class WebSearch backgroundStyle
    class ResourceCache cacheStyle
```

## 주요 특징

### 백그라운드 Web Search (새로 추가)
- **실행 시점**: Analyst Agent가 `subject`(학습 주제)를 추출하는 즉시
- **병렬 처리**: 사용자 응답과 병렬로 실행되어 대기 시간 최소화
- **수집 데이터**:
  - 학습 자료 (관련 문서, 튜토리얼 등)
  - 적합한 교수설계이론 (주제별 최적 교수법)
- **활용**: Syllabus Designer가 커리큘럼 생성 시 캐시된 자료 활용

### 노드 타입 설명
- 🔴 **빨간 다이아몬드**: 의사결정 노드 (조건 분기)
- 🔵 **파란 사각형**: 프로세스 노드 (Agent 실행)
- 🟢 **초록 둥근 사각형**: 상태 노드 (입력/출력/상태 변경)
- 🟠 **주황 점선 사각형**: 백그라운드 프로세스 (비동기)
- 🟣 **보라 원통**: 캐시/저장소 (데이터 저장)

### 화살표 타입
- **실선 화살표** (→): 일반적인 동기 흐름
- **점선 화살표** (-.->): 백그라운드/비동기 흐름
```