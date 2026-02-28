# 物理系统 — LayaAir 3.x

> 📖 LayaAir 3.x 支持 2D 物理（Box2D 2.4.1）和 3D 物理（Bullet/PhysX），均可在脚本中通过碰撞回调处理。

---

## 1. 2D 物理系统（Box2D）

### 核心组件
| 组件 | 说明 |
|------|------|
| `Laya.RigidBody` | 2D 刚体 |
| `Laya.BoxCollider` | 矩形碰撞体 |
| `Laya.CircleCollider` | 圆形碰撞体 |
| `Laya.PolygonCollider` | 多边形碰撞体 |
| `Laya.ChainCollider` | 链式碰撞体 |

### 刚体类型
| 类型 | 说明 |
|------|------|
| `dynamic` | 动态刚体（受力、重力影响） |
| `kinematic` | 运动学刚体（手动控制移动，不受力） |
| `static` | 静态刚体（不移动，如地面） |

### 刚体属性
```typescript
// RigidBody 关键属性
rigidBody.type = "dynamic";
rigidBody.gravityScale = 1.0;           // 重力缩放
rigidBody.angularVelocity = 0;          // 角速度
rigidBody.angularDamping = 0.1;         // 角阻尼
rigidBody.linearVelocity = { x: 0, y: 0 }; // 线速度
rigidBody.linearDamping = 0.1;          // 线性阻尼
rigidBody.bullet = false;               // 高速物体开启 CCD
rigidBody.allowSleep = true;            // 允许休眠
rigidBody.fixedRotation = false;        // 固定旋转
```

### 碰撞体属性
```typescript
collider.friction = 0.2;       // 摩擦系数（0~1）
collider.restitution = 0.5;    // 弹性恢复（0=无弹力, 1=完全弹力）
collider.density = 1.0;        // 密度
collider.isSensor = false;     // true=传感器（只触发事件不产生碰撞）
```

### 2D 关节
| 关节 | 说明 |
|------|------|
| `DistanceJoint` | 距离关节 |
| `RevoluteJoint` | 旋转关节（铰链） |
| `PrismaticJoint` | 移动关节 |
| `PulleyJoint` | 滑轮关节 |
| `MotorJoint` | 马达关节 |
| `GearJoint` | 齿轮关节 |
| `MouseJoint` | 鼠标关节 |
| `WeldJoint` | 焊接关节 |
| `WheelJoint` | 车轮关节 |
| `RopeJoint` | 绳索关节 |

### 2D 物理碰撞回调
```typescript
const { regClass } = Laya;

@regClass()
export class Physics2DScript extends Laya.Script {
    // Trigger（传感器模式，isSensor=true）
    onTriggerEnter(other: any, self?: any, contact?: any): void {
        console.log("触发器进入:", other);
    }
    onTriggerStay(other: any, self?: any, contact?: any): void { }
    onTriggerExit(other: any, self?: any, contact?: any): void {
        console.log("触发器离开");
    }

    // Collision（碰撞模式，isSensor=false）
    onCollisionEnter(other: any, self?: any, contact?: any): void {
        console.log("碰撞开始");
    }
    onCollisionStay(other: any, self?: any, contact?: any): void { }
    onCollisionExit(other: any, self?: any, contact?: any): void {
        console.log("碰撞结束");
    }
}
```

### 2D 物理分组过滤
```typescript
// category：自身所属分组（二进制位掩码），如 0x0001、0x0002
// mask：可以碰的分组掩码，如 0x0001 | 0x0004

// 玩家
rigidBody_player.category = 0x0001;
rigidBody_player.mask = 0x0002 | 0x0004; // 碰敌人和子弹

// 敌人
rigidBody_enemy.category = 0x0002;
rigidBody_enemy.mask = 0x0001 | 0x0004;  // 碰玩家和子弹
```

---

## 2. 3D 物理系统（Bullet / PhysX）

### 核心组件
| 组件 | 说明 |
|------|------|
| `Laya.Rigidbody3D` | 3D 刚体 |
| `Laya.PhysicsCollider` | 静态碰撞器 |
| `Laya.CharacterController` | 角色控制器 |

### 碰撞形状
| 形状 | 说明 |
|------|------|
| `BoxColliderShape` | 盒体 |
| `SphereColliderShape` | 球体 |
| `CapsuleColliderShape` | 胶囊体 |
| `ConeColliderShape` | 锥体 |
| `CylinderColliderShape` | 圆柱体 |
| `MeshColliderShape` | 网格（精确但性能低） |
| `CompoundColliderShape` | 复合形状 |
| `StaticPlaneColliderShape` | 无限平面 |

### 3D 刚体属性
```typescript
rigidbody3D.isKinematic = false;     // 运动学模式
rigidbody3D.mass = 1.0;             // 质量
rigidbody3D.gravity = new Laya.Vector3(0, -9.81, 0);
rigidbody3D.linearVelocity = new Laya.Vector3(0, 0, 0);
rigidbody3D.linearDamping = 0.0;
rigidbody3D.linearFactor = new Laya.Vector3(1, 1, 1);  // 约束轴
rigidbody3D.angularVelocity = new Laya.Vector3(0, 0, 0);
rigidbody3D.angularDamping = 0.0;
rigidbody3D.angularFactor = new Laya.Vector3(1, 1, 1);
```

### 3D 物理射线
```typescript
@regClass()
export class RaycastScript extends Laya.Script {
    @property({ type: Laya.Camera })
    public camera: Laya.Camera;

    onMouseClick(evt: Laya.Event): void {
        let point = new Laya.Vector2(evt.stageX, evt.stageY);
        let ray = new Laya.Ray(new Laya.Vector3(), new Laya.Vector3());
        this.camera.viewportPointToRay(point, ray);

        let outs: Laya.HitResult[] = [];
        let scene = this.owner.scene as Laya.Scene3D;
        if (scene.physicsSimulation.rayCastAll(ray, outs)) {
            for (let hit of outs) {
                console.log("命中:", hit.collider.owner.name);
                console.log("点:", hit.point);
                console.log("法线:", hit.normal);
            }
        }
    }
}
```

### 3D 碰撞回调
```typescript
@regClass()
export class Physics3DScript extends Laya.Script {
    onTriggerEnter(other: any, self?: any, contact?: any): void {
        console.log("3D 触发器进入:", other.owner.name);
    }
    onTriggerExit(other: any, self?: any, contact?: any): void {
        console.log("3D 触发器离开");
    }
    onCollisionEnter(other: any, self?: any, contact?: any): void {
        console.log("3D 碰撞开始:", other.owner.name);
    }
    onCollisionExit(other: any, self?: any, contact?: any): void {
        console.log("3D 碰撞结束");
    }
}
```

### 3D 约束
| 约束 | 说明 |
|------|------|
| `FixedConstraint` | 固定约束（焊接） |
| `HingeConstraint` | 铰链约束（门、轮） |
| `SpringConstraint` | 弹簧约束 |
| `ConfigurableConstraint` | 可配置约束（可模拟任意约束） |

### 角色控制器
```typescript
@regClass()
export class PlayerController extends Laya.Script {
    private _character: Laya.CharacterController;

    onAwake(): void {
        this._character = this.owner.getComponent(Laya.CharacterController);
    }

    onUpdate(): void {
        let moveDir = new Laya.Vector3(0, 0, 0);
        // 根据输入计算移动方向
        this._character.move(moveDir);
    }
}
```
