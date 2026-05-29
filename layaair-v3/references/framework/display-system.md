# 显示系统 — LayaAir 3.x

> 📖 LayaAir 3.x 的 2D 和 3D 显示对象体系。

---

## 1. 2D 显示对象

### Sprite（精灵）— 所有 2D 节点的基类
```typescript
// 创建 Sprite
let sp = new Laya.Sprite();
Laya.stage.addChild(sp);

// 位置与变换
sp.pos(100, 200);
sp.size(200, 100);
sp.anchorX = 0.5;
sp.anchorY = 0.5;
sp.rotation = 45;
sp.scale(2, 2);
sp.alpha = 0.8;
sp.visible = true;

// 加载图片
sp.loadImage("atlas/comp/image.png");

// 通过 texture
Laya.loader.load("img.png").then(() => {
    sp.texture = Laya.loader.getRes("img.png");
});

// 渲染优化
sp.zIndex = 10;                  // 渲染排序
sp.cacheAs = "bitmap";           // 静态缓存
sp.drawCallOptimize = true;      // 3.3+ 动态合批

// 鼠标交互
sp.mouseEnabled = true;
sp.hitTestPrior = true;          // 优先检测自身
```

### 节点操作
```typescript
// 添加子节点
parent.addChild(child);
parent.addChildAt(child, 0);
parent.addChildren(a, b, c);

// 查找节点
let c = parent.getChildByName("hero") as Laya.Sprite;
let c2 = parent.getChildAt(0);
let idx = parent.getChildIndex(child);

// 修改层级
parent.setChildIndex(child, 0);
parent.replaceChild(newChild, oldChild);

// 移除节点
parent.removeChild(child);
child.removeSelf();
parent.removeChildByName("hero");
parent.removeChildAt(0);
parent.removeChildren(0, 5);

// 包含关系
parent.contains(child);       // 是否包含
parent.isAncestorOf(child);   // 是否祖先

// 属性
parent.numChildren;            // 子节点数量
child.parent;                  // 父节点

// 销毁
node.destroy(true);            // true = 递归销毁子节点
```

### Text（基础文本）
```typescript
let txt = new Laya.Text();
Laya.stage.addChild(txt);
txt.text = "Hello LayaAir 3.x";
txt.font = "Arial";
txt.fontSize = 50;
txt.color = "#ffffff";
txt.bold = true;
txt.italic = true;
txt.underline = true;
txt.align = "center";     // left | center | right
txt.valign = "middle";    // top | middle | bottom
txt.wordWrap = true;
txt.leading = 10;         // 行间距
txt.padding = [10, 10, 10, 10]; // 上右下左

// 溢出模式
txt.overflow = "visible";   // visible | hidden | scroll | shrink | ellipsis

// 描边
txt.stroke = 2;
txt.strokeColor = "#000000";

// 模板变量
txt.text = "第{n=1}页";
txt.setVar("n", 2);

// UBB 语法支持
txt.text = "[b]粗体[/b] [color=#FF0000]红色[/color] [size=60]大字[/size]";
txt.text = "[img]res/icon.png[/img]";  // 内嵌图片
```

### Image（图像组件）
```typescript
let img = new Laya.Image();
img.skin = "res/icon.png";
img.sizeGrid = "30,30,30,30";  // 九宫格
Laya.stage.addChild(img);
```

### 绘图 API
```typescript
let sp = new Laya.Sprite();
let g = sp.graphics;

// 矩形
g.drawRect(0, 0, 200, 100, "#FF0000", "#000000", 2);

// 圆形
g.drawCircle(100, 100, 50, "#00FF00");

// 线条
g.drawLine(0, 0, 200, 200, "#0000FF", 3);

// 多边形
g.drawPoly(100, 100, [0,0, 100,0, 50,80], "#FFFF00");

// 清除
g.clear();

Laya.stage.addChild(sp);
```

---

## 2. 3D 显示对象

### Sprite3D（3D 精灵）
```typescript
// 创建 3D 精灵
let sp3d = new Laya.Sprite3D("myCube");
scene3d.addChild(sp3d);

// Transform
sp3d.transform.position = new Laya.Vector3(0, 1, 0);
sp3d.transform.localPosition = new Laya.Vector3(0, 1, 0);
sp3d.transform.rotation = new Laya.Quaternion(0, 0, 0, 1);
sp3d.transform.localRotationEuler = new Laya.Vector3(0, 45, 0);
sp3d.transform.localScale = new Laya.Vector3(1, 1, 1);

// 世界变换
sp3d.transform.translate(new Laya.Vector3(0, 0, 1));
sp3d.transform.rotate(new Laya.Vector3(0, 1, 0), 10);
sp3d.transform.lookAt(targetPos, Laya.Vector3.Up);

// 前方向
let forward = new Laya.Vector3();
sp3d.transform.getForward(forward);

// 添加组件
let meshRenderer = sp3d.addComponent(Laya.MeshRenderer);
let script = sp3d.addComponent(MyScript);

// 获取组件
let comp = sp3d.getComponent(MyScript);

// 激活/隐藏
sp3d.active = true;
```

### Camera（3D 摄像机）
```typescript
// 创建
let cameraNode = new Laya.Sprite3D("Camera");
let camera = cameraNode.addComponent(Laya.Camera);
scene3d.addChild(cameraNode);

// 投影模式
camera.orthographic = false;  // 透视投影
camera.fieldOfView = 60;      // FOV
camera.nearPlane = 0.3;
camera.farPlane = 1000;

// 正交投影
camera.orthographic = true;
camera.orthographicVerticalSize = 10;

// 清除标记
camera.clearFlag = Laya.CameraClearFlags.SolidColor;
camera.clearColor = new Laya.Color(0.2, 0.2, 0.2, 1);

// 视口
camera.viewport = new Laya.Viewport(0, 0, Laya.stage.width, Laya.stage.height);

// 射线检测
let point = new Laya.Vector2(Laya.stage.mouseX, Laya.stage.mouseY);
let ray = new Laya.Ray(new Laya.Vector3(), new Laya.Vector3());
camera.viewportPointToRay(point, ray);
scene3d.physicsSimulation.rayCastAll(ray, outs);

// 图层管理
camera.removeAllLayers();
camera.addLayer(1);

// lookAt
camera.transform.lookAt(new Laya.Vector3(0, 0, 0), new Laya.Vector3(0, 1, 0));

// 渲染到纹理
let renderTarget = new Laya.RenderTexture(512, 512);
camera.renderTarget = renderTarget;
```

### Light（灯光）
```typescript
// 方向光
let dirNode = new Laya.Sprite3D("DirLight");
let dirLight = dirNode.addComponent(Laya.DirectionLightCom);
dirLight.color = new Laya.Color(1, 1, 1, 1);
dirLight.intensity = 1.0;
dirLight.shadowMode = Laya.ShadowMode.SoftLow;
dirLight.shadowDistance = 50;
dirLight.shadowResolution = 1024;
scene3d.addChild(dirNode);

// 点光源
let pointNode = new Laya.Sprite3D("PointLight");
let pointLight = pointNode.addComponent(Laya.PointLightCom);
pointLight.color = new Laya.Color(1, 0.5, 0, 1);
pointLight.range = 5.0;
pointLight.intensity = 2.0;
scene3d.addChild(pointNode);

// 聚光灯
let spotNode = new Laya.Sprite3D("SpotLight");
let spotLight = spotNode.addComponent(Laya.SpotLightCom);
spotLight.range = 10;
spotLight.spotAngle = 30;
scene3d.addChild(spotNode);
```

### Material（材质）
```typescript
// PBR 材质
let mat = new Laya.PBRStandardMaterial();
mat.albedoColor = new Laya.Color(1, 0, 0, 1);
mat.metallic = 0.8;
mat.smoothness = 0.6;
mat.albedoTexture = tex;

// 应用材质
meshRenderer.material = mat;

// Unlit 材质
let unlitMat = new Laya.UnlitMaterial();
unlitMat.albedoColor = new Laya.Color(0, 1, 0, 1);
```

---

## 3. 常用数学类

```typescript
// Vector2/3/4
let v2 = new Laya.Vector2(1, 2);
let v3 = new Laya.Vector3(1, 2, 3);
let v4 = new Laya.Vector4(1, 2, 3, 4);

// Vector3 运算
Laya.Vector3.add(a, b, out);
Laya.Vector3.subtract(a, b, out);
Laya.Vector3.scale(a, 2, out);
Laya.Vector3.normalize(a, out);
Laya.Vector3.dot(a, b);
Laya.Vector3.cross(a, b, out);
Laya.Vector3.distance(a, b);
Laya.Vector3.lerp(a, b, t, out);

// 常用常量
Laya.Vector3.Zero;   // (0, 0, 0)
Laya.Vector3.One;    // (1, 1, 1)
Laya.Vector3.Up;     // (0, 1, 0)

// Quaternion
let q = new Laya.Quaternion();
Laya.Quaternion.createFromEuler(0, 45, 0, q);

// Color
let color = new Laya.Color(1, 0, 0, 1); // RGBA 0~1
```
