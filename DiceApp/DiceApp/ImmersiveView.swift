//
//  ImmersiveView.swift
//  DiceApp
//
//  Created by Riolu on 4/10/26.
//

import SwiftUI
import RealityKit
import RealityKitContent

let diceMap = [
    [1,6],
    [4,3],
    [2,5],
]

struct ImmersiveView: View {
    var diceData: DiceDate
    @State var droppedDice = false
    
    var body: some View {
        RealityView { content, attachments in
            //충돌하는데 대상이 필요해서 바닥을 생성

            //MARK: -바닥생성
            let floor = ModelEntity(mesh:.generatePlane(width: 50, depth: 50), materials: [OcclusionMaterial()])
            floor.generateCollisionShapes(recursive: false)
            floor.components[PhysicsBodyComponent.self] = .init (
                massProperties: .default,
                mode: .static
            )

            content.add(floor)

            //MARK: - 주사위 로드&생성
            if let  diceModel = try? await Entity(named: "dice"),
                let dice = diceModel.children.first?.children.first,
               let enviroment = try? await EnvironmentResource(named: "studio"){
                dice.scale = [0.1, 0.1, 0.1] //다이스의 크기를 10분의 1로 줄이는거
                dice.position.y = 0.5
                dice.position.z = -1

                // MARK: 물리효과 적용
                //다이스가 충돌 모양을 생성하겟다 라는 뜻
                dice.generateCollisionShapes(recursive: false )

                //input 대상으로 설정 -> 드래그&드롭을 할 수 있게 해준다
                dice.components.set(InputTargetComponent())

                dice.components.set(ImageBasedLightComponent(source: .single(enviroment)))
                dice.components.set(ImageBasedLightReceiverComponent(imageBasedLight: dice))
                dice.components.set(GroundingShadowComponent(castsShadow: true))

                dice.components[PhysicsBodyComponent.self] = .init(
                    massProperties: .default,
                    material: .generate(staticFriction: 0.8, dynamicFriction: 0.5, restitution: 0.1),
                    mode: .dynamic
                )
                //현실 주사위처럼 퉁퉁 튀지않게 하기 위해서

                //주사위의 현재 운동 상태를 추적하는 컴포넌트
                dice.components[PhysicsMotionComponent.self] = .init()

                content.add(dice)

//                //MARK: - 주사위 위에 패널 추가
                if let panel = attachments.entity(for: "dicePanel") {
                    //항상 카메라를 향하게 (주사위가 회전해도 패널은 정면을 바라봄)
                    panel.components.set(BillboardComponent())
                    panel.scale = [2, 2, 2]
                    content.add(panel)

                    //패널이 드래그되지 않도록 (주사위만 드래그 가능하게)
                    panel.components.remove(InputTargetComponent.self)

                    //매 프레임마다 주사위 위치 따라가기
                    let _ = content.subscribe(to: SceneEvents.Update.self) { _ in
                        let dicePos = dice.position(relativeTo: nil)
                        //주사위 위쪽 15cm 지점에 패널 위치시킴
                        panel.setPosition(dicePos + SIMD3<Float>(0, 0.15, 0), relativeTo: nil)
                    }
                }

                let _ = content.subscribe(to: SceneEvents.Update.self) { event in //매 프레임마다 체크하는거
                    guard droppedDice else { return } //던지기 전에는 그냥 통과
                    guard let diceMotion = dice.components[PhysicsMotionComponent.self] else { return }
                    //PhysicsMotionComponent 없으면 통과.

                    //SIMD: x, y, z 세 값을 묶어서 한번에 계산하는 타입
                    if simd_length(diceMotion.linearVelocity) < 0.1 && simd_length(diceMotion.angularVelocity) < 0.1 {
                        let xDrection = dice.convert(direction: SIMD3(x: 1, y: 0, z: 0), to: nil)
                        let yDrection = dice.convert(direction: SIMD3(x: 0, y: 1, z: 0), to: nil)
                        let zDrection = dice.convert(direction: SIMD3(x: 0, y: 0, z: 1), to: nil)

                        let greatestDirection  = [
                            0: xDrection.y,
                            1: yDrection.y,
                            2: zDrection.y
                        ]
                            .sorted(by: { abs($0.1) > abs($1.1) })[0]

                        diceData.rolledNumber = diceMap[greatestDirection.key][greatestDirection.value > 0 ? 0 : 1]
                    }
                }
            }
        } attachments: {
            Attachment(id: "dicePanel") { //swiftUI뷰를 준비됏다라는 뜻
                DicePanelView(diceData: diceData)
            }
        }
        .gesture(dragGesture)
    }
    
    var dragGesture: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in 
                value.entity.position = value.convert(value.location3D, from: .local, to: value.entity.parent!)
                value.entity.components[PhysicsBodyComponent.self]?.mode = .kinematic //외부 힘 무시하고 정해진대로만 움직임
            }
            .onEnded { value in
                value.entity.components[PhysicsBodyComponent.self]?.mode = .dynamic
                
                if !droppedDice {
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                        droppedDice = true
                    }
                }
            }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView(diceData: DiceDate())

}
