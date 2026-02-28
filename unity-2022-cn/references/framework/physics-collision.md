# 物理引擎与碰撞检测详解

## 碰撞矩阵（谁能与谁碰撞）

### 3D 碰撞条件

| 情况 | 是否碰撞 | 是否触发 |
|------|---------|---------|
| Rigidbody + Collider vs Rigidbody + Collider | ✅ | - |
| Rigidbody + Collider vs Static Collider | ✅ | - |
| Kinematic Rigidbody + Collider vs Rigidbody + Collider | ✅ | - |
| Kinematic vs Kinematic | ❌ | ❌ |
| Kinematic vs Static | ❌ | ❌ |
| 任意 Collider(isTrigger) + 任一方有 Rigidbody | - | ✅ |

**核心规则**：碰撞检测至少需要一方有 Rigidbody。

---

## Rigidbody 详细配置

```csharp
Rigidbody rb = GetComponent<Rigidbody>();

// 基本属性
rb.mass = 1f;                    // 质量
rb.drag = 0f;                   // 空气阻力
rb.angularDrag = 0.05f;         // 角阻力
rb.useGravity = true;           // 使用重力
rb.isKinematic = false;         // 运动学（不受物理力影响，可影响其他）

// 约束
rb.constraints = RigidbodyConstraints.FreezeRotationX
               | RigidbodyConstraints.FreezeRotationZ;
rb.constraints = RigidbodyConstraints.FreezePosition;
rb.constraints = RigidbodyConstraints.FreezeAll;

// 碰撞检测模式
rb.collisionDetectionMode = CollisionDetectionMode.Continuous;  // 连续检测（防穿透）
// Discrete（默认）、Continuous、ContinuousDynamic、ContinuousSpeculative

// 插值（平滑运动）
rb.interpolation = RigidbodyInterpolation.Interpolate;

// 力的作用
rb.AddForce(Vector3.forward * 100f);                    // 力（持续）
rb.AddForce(Vector3.up * 300f, ForceMode.Impulse);      // 冲量
rb.AddForce(Vector3.forward * 5f, ForceMode.VelocityChange); // 速度变化（忽略质量）
rb.AddForce(Vector3.forward * 10f, ForceMode.Acceleration);  // 加速度（忽略质量）

rb.AddTorque(Vector3.up * 10f);                         // 扭矩
rb.AddExplosionForce(500f, explosionPos, 5f);            // 爆炸力

// 速度直接设置（谨慎使用）
rb.velocity = new Vector3(0, rb.velocity.y, moveSpeed);
rb.angularVelocity = Vector3.zero;
```

### ForceMode 对比

| ForceMode | 公式 | 说明 |
|-----------|------|------|
| Force | F = m × a | 持续力，考虑质量和 fixedDeltaTime |
| Impulse | F × dt = m × Δv | 瞬间冲量，考虑质量 |
| Acceleration | a | 加速度，不考虑质量 |
| VelocityChange | Δv | 直接改变速度，不考虑质量 |

---

## Collider 类型

### 3D Collider
| 类型 | 性能 | 用途 |
|------|------|------|
| BoxCollider | 最快 | 方形物体 |
| SphereCollider | 很快 | 球形/范围检测 |
| CapsuleCollider | 快 | 角色 |
| MeshCollider (Convex) | 中 | 复杂形状（凸包） |
| MeshCollider (Non-Convex) | 慢 | 精确碰撞（仅静态） |

### 2D Collider
| 类型 | 说明 |
|------|------|
| BoxCollider2D | 矩形 |
| CircleCollider2D | 圆形 |
| CapsuleCollider2D | 胶囊 |
| PolygonCollider2D | 多边形 |
| EdgeCollider2D | 边缘 |
| CompositeCollider2D | 复合 |

---

## 射线检测 (Raycasting) 进阶

```csharp
// LayerMask 使用
int layerMask = LayerMask.GetMask("Enemy", "Obstacle");
int ignoreLayer = ~LayerMask.GetMask("IgnoreRaycast");

// 射线可视化调试
Debug.DrawRay(origin, direction * distance, Color.red, duration: 2f);

// SphereCast（球形射线）
if (Physics.SphereCast(origin, radius, direction, out hit, maxDist))
{
    // 比 Raycast 更宽的检测范围
}

// BoxCast
if (Physics.BoxCast(center, halfExtents, direction, out hit, orientation, maxDist))
{
    // 方形射线
}

// CapsuleCast
if (Physics.CapsuleCast(point1, point2, radius, direction, out hit, maxDist))
{
    // 胶囊射线
}

// Overlap 系列（区域检测）
Collider[] results = Physics.OverlapSphere(center, radius, layerMask);
Collider[] boxResults = Physics.OverlapBox(center, halfExtents, rotation, layerMask);

// NonAlloc 版本（避免 GC）
private Collider[] overlapBuffer = new Collider[20];
int count = Physics.OverlapSphereNonAlloc(center, radius, overlapBuffer, layerMask);
for (int i = 0; i < count; i++)
{
    // 处理 overlapBuffer[i]
}
```

---

## 物理材质 (Physics Material)

```csharp
// 通过代码创建
PhysicMaterial mat = new PhysicMaterial();
mat.dynamicFriction = 0.6f;   // 动摩擦
mat.staticFriction = 0.6f;    // 静摩擦
mat.bounciness = 0.3f;        // 弹性
mat.frictionCombine = PhysicMaterialCombine.Average;
mat.bounceCombine = PhysicMaterialCombine.Maximum;

GetComponent<Collider>().material = mat;
```

---

## 关节 (Joints)

| 关节类型 | 说明 |
|---------|------|
| FixedJoint | 固定连接两个物体 |
| HingeJoint | 铰链（门、轮子） |
| SpringJoint | 弹簧连接 |
| CharacterJoint | 角色关节（布娃娃） |
| ConfigurableJoint | 完全可配置 |

---

## 物理最佳实践

1. **在 FixedUpdate 中操作 Rigidbody**，而非 Update
2. **使用 MovePosition/MoveRotation** 移动 Kinematic Rigidbody
3. **避免直接修改 Transform** 对有 Rigidbody 的物体
4. **使用 Continuous 碰撞检测** 防止高速物体穿透
5. **合理使用 Layer** 和碰撞矩阵优化性能
6. **使用 NonAlloc 版本** 的射线检测避免 GC
7. **静态碰撞体不要移动**，移动需添加 Rigidbody(Kinematic)
8. **Mesh Collider 尽量使用 Convex**，Non-Convex 仅用于静态物体
