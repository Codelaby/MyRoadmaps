```swift
//
//  PipeEntity.swift
//  FlappyBirdSpriteKit
//
//  Created by Gerard Coll Roma on 18/11/25.
//

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

// MARK: - Pipe Spawner Component
final class PipeSpawnerComponent: GKComponent {
    
    let spawnInterval: TimeInterval
    let pipeTextureName: String
    let pipeSize: CGSize
    let minGap: CGFloat
    let maxGap: CGFloat
    let minCenterY: CGFloat
    let maxCenterY: CGFloat
    let scrollSpeed: CGFloat
    
    private var lastSpawnTime: TimeInterval = 0
    private var pipes: [PipePairEntity] = []
    
    init(
        spawnInterval: TimeInterval = 2.0,
        pipeTextureName: String = "pipe-1",
        pipeSize: CGSize = CGSize(width: 32, height: 320),
        minGap: CGFloat = 80,
        maxGap: CGFloat = 120,
        minCenterY: CGFloat = 150,
        maxCenterY: CGFloat = 250,
        scrollSpeed: CGFloat = 80
    ) {
        self.spawnInterval = spawnInterval
        self.pipeTextureName = pipeTextureName
        self.pipeSize = pipeSize
        self.minGap = minGap
        self.maxGap = maxGap
        self.minCenterY = minCenterY
        self.maxCenterY = maxCenterY
        self.scrollSpeed = scrollSpeed
        super.init()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(currentTime: TimeInterval, sceneSize: CGSize) -> PipePairEntity? {
        // Verificar si es tiempo de spawnear un nuevo pipe
        if currentTime - lastSpawnTime >= spawnInterval {
            lastSpawnTime = currentTime
            return spawnPipe(sceneSize: sceneSize)
        }
        return nil
    }
    
    private func spawnPipe(sceneSize: CGSize) -> PipePairEntity {
        // Generar valores aleatorios para variar los pipes
        let randomGap = CGFloat.random(in: minGap...maxGap)
        let randomCenterY = CGFloat.random(in: minCenterY...maxCenterY)
        
        let pipe = PipePairEntity(
            textureName: pipeTextureName,
            pipeSize: pipeSize,
            gap: randomGap,
            xPosition: sceneSize.width + (pipeSize.width * globalScale), // Empezar fuera de pantalla
            centerY: randomCenterY,
            scrollSpeed: scrollSpeed
        )
        
        pipes.append(pipe)
        return pipe
    }
    
    func cleanupPipes() {
        // Remover pipes que ya no son necesarios (opcional, para optimización)
        pipes.removeAll { pipe in
            // Verificar si ambos pipes están fuera de pantalla por la izquierda
            guard
                let topSprite = pipe.topPipe.component(ofType: RenderComponent.self)?.sprite,
                let bottomSprite = pipe.bottomPipe.component(ofType: RenderComponent.self)?.sprite
            else { return true }
            
            let isOffScreen = topSprite.position.x < -pipeSize.width * globalScale &&
                             bottomSprite.position.x < -pipeSize.width * globalScale
            
            if isOffScreen {
                topSprite.removeFromParent()
                bottomSprite.removeFromParent()
            }
            
            return isOffScreen
        }
    }
}

// MARK: - Pipe Spawner System
final class PipeSpawnerSystem: GKComponentSystem<PipeSpawnerComponent> {
    
    private let scene: SKScene
    private let pipeScrollSystem: PipeScrollSystem // Referencia al sistema de scroll
    private var lastCleanupTime: TimeInterval = 0
    private let cleanupInterval: TimeInterval = 5.0
    
    init(scene: SKScene, pipeScrollSystem: PipeScrollSystem) {
        self.scene = scene
        self.pipeScrollSystem = pipeScrollSystem
        super.init(componentClass: PipeSpawnerComponent.self)
    }
    
    func update(currentTime: TimeInterval) {
        for component in components {
            // Intentar spawnear un nuevo pipe
            if let newPipe = component.update(currentTime: currentTime, sceneSize: scene.size) {
                // Añadir el nuevo pipe a la escena y sistemas
                addPipeToScene(newPipe)
            }
            
            // Hacer cleanup periódicamente para optimizar
            if currentTime - lastCleanupTime >= cleanupInterval {
                component.cleanupPipes()
                lastCleanupTime = currentTime
            }
        }
    }
    
    private func addPipeToScene(_ pipe: PipePairEntity) {
        // Añadir sprites a la escena
        if let topSprite = pipe.topPipe.component(ofType: RenderComponent.self)?.sprite {
            scene.addChild(topSprite)
        }
        
        if let bottomSprite = pipe.bottomPipe.component(ofType: RenderComponent.self)?.sprite {
            scene.addChild(bottomSprite)
        }
        
        // AÑADIR: Componentes de scroll al sistema
        if let topScroll = pipe.topPipe.component(ofType: PipeScrollComponent.self) {
            pipeScrollSystem.addComponent(topScroll)
        }
        
        if let bottomScroll = pipe.bottomPipe.component(ofType: PipeScrollComponent.self) {
            pipeScrollSystem.addComponent(bottomScroll)
        }
    }
}



// MARK: PipePair Entity
final class PipePairEntity: GKEntity {

    let topPipe: TopPipeEntity
    let bottomPipe: BottomPipeEntity
    
    // Hacer pública la velocidad para que el spawner pueda acceder
    let scrollSpeed: CGFloat

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
        
        // Añadir componentes de scroll
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
    var shouldRemove: Bool = false
    
    init(scrollSpeed: CGFloat, pipeWidth: CGFloat) {
        self.scrollSpeed = scrollSpeed
        self.pipeWidth = pipeWidth
        super.init()
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
            
            // Marcar para eliminar cuando el pipe sale completamente de pantalla
            if render.sprite.position.x < -component.pipeWidth {
                component.shouldRemove = true
            }
        }
    }
    
    // Nuevo método para limpiar pipes marcados
    func removeMarkedPipes() -> [GKEntity] {
        var removedEntities: [GKEntity] = []
        
        // Filtrar componentes marcados para eliminar
        let componentsToRemove = components.filter { $0.shouldRemove }
        
        for component in componentsToRemove {
            if let entity = component.entity {
                removedEntities.append(entity)
                
                // Remover el sprite de la escena
                if let render = entity.component(ofType: RenderComponent.self) {
                    render.sprite.removeFromParent()
                }
                
                // Remover el componente del sistema
                removeComponent(component)
            }
        }
        
        return removedEntities
    }
}

// MARK: Bird Scene
class PipeScene: SKScene {

    private var entities: [GKEntity] = []
    private var animationSystem = AnimationSystem()
    private var groundScrollSystem: GroundScrollSystem!
    private var pipeScrollSystem: PipeScrollSystem!
    private var pipeSpawnerSystem: PipeSpawnerSystem!
    private var lastUpdateTime: TimeInterval?
    
    override func didMove(to view: SKView) {
        backgroundColor = .cyan
        
        groundScrollSystem = GroundScrollSystem(scene: self)
        pipeScrollSystem = PipeScrollSystem(scene: self)
        // IMPORTANTE: Pasar pipeScrollSystem al spawner
        pipeSpawnerSystem = PipeSpawnerSystem(scene: self, pipeScrollSystem: pipeScrollSystem)

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
        // 🚀 PIPE SPAWNER
        // ------------------------
        let pipeSpawner = GKEntity()
        let spawnerComponent = PipeSpawnerComponent(
            spawnInterval: 2.5, // Cada 2.5 segundos
            pipeTextureName: "pipe-1",
            pipeSize: CGSize(width: 32, height: 320),
            minGap: 20 * globalScale,   // Gap mínimo
            maxGap: 50 * globalScale,  // Gap máximo
            minCenterY: size.height * 0.3,  // 30% de la altura
            maxCenterY: size.height * 0.7,  // 70% de la altura
            scrollSpeed: 80
        )
        pipeSpawner.addComponent(spawnerComponent)
        entities.append(pipeSpawner)
        pipeSpawnerSystem.addComponent(spawnerComponent)
        
        animationSystem.startAnimations()
    }
    
    override func update(_ currentTime: TimeInterval) {
        let delta = currentTime - (lastUpdateTime ?? currentTime)
        lastUpdateTime = currentTime

        groundScrollSystem.update(deltaTime: delta)
        pipeScrollSystem.update(deltaTime: delta)
        pipeSpawnerSystem.update(currentTime: currentTime) // Actualizar spawner
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
            
            SpriteView(scene: createScene(size: sceneSize), options: [.allowsTransparency], debugOptions: [.showsDrawCount, .showsFPS, .showsNodeCount])
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


/*
 static let showsDrawCount: SpriteView.DebugOptions
 static let showsFPS: SpriteView.DebugOptions
 static let showsFields: SpriteView.DebugOptions
 static let showsNodeCount: SpriteView.DebugOptions
 static let showsPhysics: SpriteView.DebugOptions
 static let showsQuadCount: SpriteView.DebugOptions
 */

```
