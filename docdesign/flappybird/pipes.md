```swift
import SwiftUI
import GameplayKit
import SpriteKit

// MARK: Top Pipe Entity
final class TopPipeEntity: GKEntity {

    init(textureName: String, size: CGSize, zIndex: CGFloat = 8) {
        super.init()
        
        let texture = AssetManager.shared.loadTexture(name: textureName, useAtlas: true)
        
        let render = RenderComponent(
            initialTexture: texture,
            size: size,
            zIndex: zIndex
        )
        render.sprite.setScale(globalScale)
        
        // Rotar 180º para la tubería superior
        render.sprite.zRotation = .pi
        
        addComponent(render)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Bottom Pipe Entity
final class BottomPipeEntity: GKEntity {

    init(textureName: String, size: CGSize, zIndex: CGFloat = 8) {
        super.init()
        
        let texture = AssetManager.shared.loadTexture(name: textureName, useAtlas: true)
        
        let render = RenderComponent(
            initialTexture: texture,
            size: size,
            zIndex: zIndex
        )
        render.sprite.setScale(globalScale)
        
        addComponent(render)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Pipe Scroll System
final class PipeScrollSystem: GKComponentSystem<PipeScrollComponent> {
    
    private let scene: SKScene
    
    init(scene: SKScene) {
        self.scene = scene
        super.init(componentClass: PipeScrollComponent.self)
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        for component in components {
            guard let render = component.entity?.component(ofType: RenderComponent.self) else { continue }
            
            // Mover hacia la izquierda
            let movement = CGFloat(seconds) * component.scrollSpeed
            render.sprite.position.x -= movement
            
            // Reposicionar cuando el pipe se sale completamente por la izquierda
            // Usar el tamaño de la escena del sistema
            if render.sprite.position.x < -component.pipeWidth {
                render.sprite.position.x = scene.size.width + component.pipeWidth
            }
        }
    }
}

// MARK: PipePair Entity
final class PipePairEntity: GKEntity {

    let topPipe: TopPipeEntity
    let bottomPipe: BottomPipeEntity
    private let scrollSpeed: CGFloat

    init(
        textureName: String,
        pipeSize: CGSize = CGSize(width: 32, height: 160),
        gap: CGFloat = 120,
        xPosition: CGFloat,
        centerY: CGFloat,
        scrollSpeed: CGFloat = 80
    ) {
        self.scrollSpeed = scrollSpeed
        topPipe = TopPipeEntity(textureName: textureName, size: pipeSize, zIndex: 8)
        bottomPipe = BottomPipeEntity(textureName: textureName, size: pipeSize, zIndex: 8)
        
        super.init()
        
        // Añadir hijas
        addChildEntity(topPipe)
        addChildEntity(bottomPipe)

        // Obtener sprites
        guard
            let topSprite = topPipe.component(ofType: RenderComponent.self)?.sprite,
            let bottomSprite = bottomPipe.component(ofType: RenderComponent.self)?.sprite
        else { return }
        
        // Configurar anchor points
        bottomSprite.anchorPoint = CGPoint(x: 0.5, y: 0)
        topSprite.anchorPoint = CGPoint(x: 0.5, y: 0)
        
        let halfGap = gap / 2
        let scaledPipeHeight = pipeSize.height * globalScale
        let scaledPipeWidth = pipeSize.width * globalScale
        
        bottomSprite.position = CGPoint(
            x: xPosition,
            y: centerY - scaledPipeHeight - halfGap
        )
        
        topSprite.position = CGPoint(
            x: xPosition,
            y: centerY + scaledPipeHeight + halfGap
        )
        
        // Añadir componentes de scroll simplificados
        // Ya no necesitamos resetPositionX en el componente
        let topScroll = PipeScrollComponent(
            scrollSpeed: scrollSpeed,
            pipeWidth: scaledPipeWidth
        )
        topPipe.addComponent(topScroll)
        
        let bottomScroll = PipeScrollComponent(
            scrollSpeed: scrollSpeed,
            pipeWidth: scaledPipeWidth
        )
        bottomPipe.addComponent(bottomScroll)
    }
    
    private func addChildEntity(_ entity: GKEntity) {
        if let _ = entity.component(ofType: RenderComponent.self) {
            // Las entidades hijas ya están configuradas
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Pipe Scroll Component
final class PipeScrollComponent: GKComponent {
    let scrollSpeed: CGFloat
    let pipeWidth: CGFloat
    
    init(scrollSpeed: CGFloat, pipeWidth: CGFloat) {
        self.scrollSpeed = scrollSpeed
        self.pipeWidth = pipeWidth
        super.init()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Bird Scene
class PipeScene: SKScene {

    private var entities: [GKEntity] = []
    private var animationSystem = AnimationSystem()
    private var groundScrollSystem: GroundScrollSystem!
    private var pipeScrollSystem: PipeScrollSystem! // Nuevo sistema
    private var lastUpdateTime: TimeInterval?
    
    override func didMove(to view: SKView) {
        backgroundColor = .cyan
        
        groundScrollSystem = GroundScrollSystem(scene: self)
        pipeScrollSystem = PipeScrollSystem(scene: self) // Inicializar sistema de pipes

        // ------------------------
        // 🌄 BACKGROUND
        // ------------------------
        let groundHeight: CGFloat = 48 * globalScale

        let background = BackgroundEntity(textureName: "background-1")
        entities.append(background)

        if let bgSprite = background.component(ofType: RenderComponent.self)?.sprite {
            bgSprite.anchorPoint = CGPoint(x: 0.5, y: 1.0)
            let bgHeight = bgSprite.size.height
            bgSprite.position = CGPoint(x: size.width / 2, y: groundHeight + bgHeight)
            addChild(bgSprite)
        }
        
        // ------------------------
        // 🐦 BIRD
        // ------------------------
        let bird = BirdEntity(textureName: "bird-1", framesCount: 4)
        entities.append(bird)

        // ------------------------
        // 🌱 GROUND (TRES TILES)
        // ------------------------
        let tileWidth: CGFloat = 160 * globalScale
        
        for i in 0..<3 {
            let ground = GroundEntity(textureName: "ground-1", tileWidth: 160)
            entities.append(ground)
            
            if let sprite = ground.component(ofType: RenderComponent.self)?.sprite {
                sprite.anchorPoint = CGPoint(x: 0.5, y: 1.0)
                sprite.position = CGPoint(
                    x: tileWidth / 2 + (tileWidth * CGFloat(i)),
                    y: sprite.size.height
                )
                addChild(sprite)
            }
            
            if let scroll = ground.component(ofType: GroundScrollComponent.self) {
                groundScrollSystem.addComponent(scroll)
            }
        }
        
        // ------------------------
        // 🚀 PIPES
        // ------------------------
        let pipes = PipePairEntity(
            textureName: "pipe-1",
            pipeSize: CGSize(width: 32, height: 320),
            gap: 24 * globalScale,
            xPosition: size.width, // Empezar desde la derecha
            centerY: (size.height / 2),
            scrollSpeed: 80 // Misma velocidad que el suelo
        )

        entities.append(pipes)
        entities.append(pipes.topPipe)
        entities.append(pipes.bottomPipe)

        // Añadir sprites y componentes de scroll al sistema
        if let topSprite = pipes.topPipe.component(ofType: RenderComponent.self)?.sprite {
            addChild(topSprite)
            if let scroll = pipes.topPipe.component(ofType: PipeScrollComponent.self) {
                pipeScrollSystem.addComponent(scroll)
            }
        }
        
        if let bottomSprite = pipes.bottomPipe.component(ofType: RenderComponent.self)?.sprite {
            addChild(bottomSprite)
            if let scroll = pipes.bottomPipe.component(ofType: PipeScrollComponent.self) {
                pipeScrollSystem.addComponent(scroll)
            }
        }
        
        animationSystem.startAnimations()
    }
    
    override func update(_ currentTime: TimeInterval) {
        let delta = currentTime - (lastUpdateTime ?? currentTime)
        lastUpdateTime = currentTime

        groundScrollSystem.update(deltaTime: delta)
        pipeScrollSystem.update(deltaTime: delta)
    }
}


// MARK PipeDemo
struct PipeDemo: View {
    @State private var stick: CGPoint = .zero
    
    var body: some View {
        GeometryReader { geometry in
            let sceneSize = CGSize(
                width: geometry.size.width,
                height: geometry.size.height
            )
            
            SpriteView(scene: createScene(size: sceneSize), options: [.allowsTransparency])
                .ignoresSafeArea()
        }
    }
    
    private func createScene(size: CGSize) -> PipeScene {
        let s = PipeScene(size: size)
        s.scaleMode = .aspectFill
        s.backgroundColor = .clear
        return s
    }
}

#Preview {
    PipeDemo()
}
```


