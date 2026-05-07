# TypeScript 高级类型系统参考

> 本文件由 `code-guard-review-cn` 技能按需加载。
> 当 TypeScript 项目涉及泛型、条件类型、映射类型、模板字面量类型或工具类型时读取此文件。

---

## 目录

1. [泛型](#1-泛型-generics)
2. [条件类型](#2-条件类型-conditional-types)
3. [映射类型](#3-映射类型-mapped-types)
4. [模板字面量类型](#4-模板字面量类型-template-literal-types)
5. [内置工具类型速查](#5-内置工具类型速查)
6. [进阶设计模式](#6-进阶设计模式)
7. [类型推断技巧](#7-类型推断技巧)
8. [TypeScript 最佳实践](#8-typescript-最佳实践)

---

## 1. 泛型 (Generics)

创建可复用、类型灵活的组件，同时保持类型安全。

**基础泛型函数：**
```typescript
function identity<T>(value: T): T {
  return value;
}

const num = identity<number>(42);     // 类型: number
const auto = identity(true);          // 类型推断: boolean
```

**泛型约束：**
```typescript
interface HasLength {
  length: number;
}

function logLength<T extends HasLength>(item: T): T {
  console.log(item.length);
  return item;
}

logLength("hello");          // ✅ string 有 length
logLength([1, 2, 3]);        // ✅ 数组有 length
// logLength(42);            // ❌ number 无 length
```

**多类型参数与交叉类型：**
```typescript
function merge<T, U>(obj1: T, obj2: U): T & U {
  return { ...obj1, ...obj2 };
}
```

---

## 2. 条件类型 (Conditional Types)

创建依赖条件的类型，实现复杂的类型逻辑。

**基础条件类型：**
```typescript
type IsString<T> = T extends string ? true : false;

type A = IsString<string>;  // true
type B = IsString<number>;  // false
```

**使用 `infer` 提取类型：**
```typescript
type ReturnType<T> = T extends (...args: any[]) => infer R ? R : never;
type ElementType<T> = T extends (infer U)[] ? U : never;
type PromiseType<T> = T extends Promise<infer U> ? U : never;
type Parameters<T> = T extends (...args: infer P) => any ? P : never;
```

**分布式条件类型：**
```typescript
type ToArray<T> = T extends any ? T[] : never;
type StrOrNumArray = ToArray<string | number>;  // string[] | number[]
```

**嵌套条件类型：**
```typescript
type TypeName<T> =
  T extends string    ? "string" :
  T extends number    ? "number" :
  T extends boolean   ? "boolean" :
  T extends undefined ? "undefined" :
  T extends Function  ? "function" :
  "object";
```

---

## 3. 映射类型 (Mapped Types)

通过遍历已有类型的属性创建新类型。

**基础映射：**
```typescript
type Readonly<T> = { readonly [P in keyof T]: T[P] };
type Partial<T>  = { [P in keyof T]?: T[P] };
```

**键重映射 (Key Remapping)：**
```typescript
type Getters<T> = {
  [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K];
};

// { getName: () => string; getAge: () => number; }
type PersonGetters = Getters<{ name: string; age: number }>;
```

**按类型筛选属性：**
```typescript
type PickByType<T, U> = {
  [K in keyof T as T[K] extends U ? K : never]: T[K];
};

type OnlyNumbers = PickByType<{ id: number; name: string; age: number }, number>;
// { id: number; age: number; }
```

---

## 4. 模板字面量类型 (Template Literal Types)

基于字符串的类型，支持模式匹配和字符串变换。

```typescript
type EventName = "click" | "focus" | "blur";
type EventHandler = `on${Capitalize<EventName>}`;
// "onClick" | "onFocus" | "onBlur"

// 内置字符串操作
type U  = Uppercase<"hello">;       // "HELLO"
type L  = Lowercase<"HELLO">;       // "hello"
type C  = Capitalize<"john">;       // "John"
type UC = Uncapitalize<"John">;     // "john"
```

**嵌套路径类型：**
```typescript
type Path<T> = T extends object
  ? {
      [K in keyof T]: K extends string
        ? `${K}` | `${K}.${Path<T[K]>}`
        : never;
    }[keyof T]
  : never;

// "server" | "database" | "server.host" | "server.port" | "database.url"
type ConfigPath = Path<{
  server: { host: string; port: number };
  database: { url: string };
}>;
```

---

## 5. 内置工具类型速查

| 工具类型 | 作用 | 示例 |
|---------|------|------|
| `Partial<T>` | 所有属性变可选 | `Partial<User>` |
| `Required<T>` | 所有属性变必填 | `Required<PartialUser>` |
| `Readonly<T>` | 所有属性变只读 | `Readonly<User>` |
| `Pick<T, K>` | 选取指定属性 | `Pick<User, "name" \| "email">` |
| `Omit<T, K>` | 排除指定属性 | `Omit<User, "password">` |
| `Exclude<T, U>` | 从联合类型排除 | `Exclude<"a" \| "b", "a">` → `"b"` |
| `Extract<T, U>` | 从联合类型提取 | `Extract<"a" \| "b", "a">` → `"a"` |
| `NonNullable<T>` | 排除 null/undefined | `NonNullable<string \| null>` → `string` |
| `Record<K, T>` | 以 K 为键 T 为值的对象 | `Record<"home" \| "about", PageInfo>` |
| `ReturnType<T>` | 提取函数返回类型 | `ReturnType<typeof fn>` |
| `Parameters<T>` | 提取函数参数元组 | `Parameters<typeof fn>` |

---

## 6. 进阶设计模式

### 模式 1：类型安全的事件发射器

```typescript
type EventMap = {
  "user:created": { id: string; name: string };
  "user:updated": { id: string };
  "user:deleted": { id: string };
};

class TypedEventEmitter<T extends Record<string, any>> {
  private listeners: { [K in keyof T]?: Array<(data: T[K]) => void> } = {};

  on<K extends keyof T>(event: K, callback: (data: T[K]) => void): void {
    if (!this.listeners[event]) this.listeners[event] = [];
    this.listeners[event]!.push(callback);
  }

  emit<K extends keyof T>(event: K, data: T[K]): void {
    this.listeners[event]?.forEach((cb) => cb(data));
  }
}
```

### 模式 2：类型安全的 API 客户端

```typescript
type EndpointConfig = {
  "/users": {
    GET:  { response: User[] };
    POST: { body: { name: string; email: string }; response: User };
  };
  "/users/:id": {
    GET:    { params: { id: string }; response: User };
    PUT:    { params: { id: string }; body: Partial<User>; response: User };
    DELETE: { params: { id: string }; response: void };
  };
};

type ExtractParams<T>   = T extends { params: infer P }   ? P : never;
type ExtractBody<T>     = T extends { body: infer B }     ? B : never;
type ExtractResponse<T> = T extends { response: infer R } ? R : never;
```

### 模式 3：类型安全的建造者模式

```typescript
class Builder<T, S extends Partial<T> = {}> {
  private state = {} as S;

  set<K extends keyof T>(key: K, value: T[K]): Builder<T, S & Record<K, T[K]>> {
    (this.state as any)[key] = value;
    return this as any;
  }

  build(this: RequiredKeys<T> extends keyof S ? this : never): T {
    return this.state as unknown as T;
  }
}

type RequiredKeys<T> = {
  [K in keyof T]-?: {} extends Pick<T, K> ? never : K;
}[keyof T];
```

### 模式 4：深层递归类型

```typescript
type DeepReadonly<T> = {
  readonly [P in keyof T]: T[P] extends object
    ? T[P] extends Function ? T[P] : DeepReadonly<T[P]>
    : T[P];
};

type DeepPartial<T> = {
  [P in keyof T]?: T[P] extends object
    ? T[P] extends Array<infer U> ? Array<DeepPartial<U>> : DeepPartial<T[P]>
    : T[P];
};
```

### 模式 5：可辨识联合与状态机

```typescript
type AsyncState<T> =
  | { status: "loading" }
  | { status: "success"; data: T }
  | { status: "error"; error: string };

function handleState<T>(state: AsyncState<T>): void {
  switch (state.status) {
    case "success": console.log(state.data);  break; // 自动收窄为 T
    case "error":   console.log(state.error); break; // 自动收窄为 string
    case "loading": console.log("加载中...");  break;
  }
}
```

### 模式 6：品牌类型 (Branded Types)

```typescript
type Brand<T, B extends string> = T & { readonly __brand: B };

type UserId  = Brand<string, "UserId">;
type OrderId = Brand<string, "OrderId">;

function getUser(id: UserId): void { /* ... */ }

const userId = "abc" as UserId;
const orderId = "xyz" as OrderId;

getUser(userId);     // ✅
// getUser(orderId); // ❌ 类型不兼容
```

### 模式 7：类型安全的表单验证

```typescript
type ValidationRule<T> = {
  validate: (value: T) => boolean;
  message: string;
};

type FieldValidation<T> = {
  [K in keyof T]?: ValidationRule<T[K]>[];
};

type ValidationErrors<T> = {
  [K in keyof T]?: string[];
};

class FormValidator<T extends Record<string, any>> {
  constructor(private rules: FieldValidation<T>) {}

  validate(data: T): ValidationErrors<T> | null {
    const errors: ValidationErrors<T> = {};
    let hasErrors = false;

    for (const key in this.rules) {
      const fieldRules = this.rules[key];
      const value = data[key];

      if (fieldRules) {
        const fieldErrors: string[] = [];
        for (const rule of fieldRules) {
          if (!rule.validate(value)) fieldErrors.push(rule.message);
        }
        if (fieldErrors.length > 0) {
          errors[key] = fieldErrors;
          hasErrors = true;
        }
      }
    }

    return hasErrors ? errors : null;
  }
}
```

---

## 7. 类型推断技巧

### infer 关键字

```typescript
// 提取数组元素类型
type ElementType<T> = T extends (infer U)[] ? U : never;

// 提取 Promise 解析类型
type PromiseType<T> = T extends Promise<infer U> ? U : never;

// 提取函数参数类型
type Params<T> = T extends (...args: infer P) => any ? P : never;
```

### 类型守卫 (Type Guards)

```typescript
function isString(value: unknown): value is string {
  return typeof value === "string";
}

function isArrayOf<T>(
  value: unknown,
  guard: (item: unknown) => item is T,
): value is T[] {
  return Array.isArray(value) && value.every(guard);
}
```

### 断言函数 (Assertion Functions)

```typescript
function assertIsString(value: unknown): asserts value is string {
  if (typeof value !== "string") {
    throw new Error("不是字符串类型");
  }
}
```

### 类型测试

```typescript
// 类型相等性断言 — 用于验证工具类型行为
type AssertEqual<T, U> =
  [T] extends [U] ? [U] extends [T] ? true : false : false;

type Test1 = AssertEqual<string, string>;         // true
type Test2 = AssertEqual<string, number>;          // false
type Test3 = AssertEqual<string | number, string>; // false
```

---

## 8. TypeScript 最佳实践

1. **优先 `unknown` 而非 `any`**：强制进行类型检查，避免安全漏洞
2. **对象类型优先 `interface`**：更好的错误提示，支持声明合并
3. **联合/交叉/复杂类型用 `type`**：灵活性更强，支持更多类型运算
4. **充分利用类型推断**：让 TS 自动推断，减少冗余标注
5. **封装可复用工具类型**：构建项目级类型库，提高一致性
6. **使用 `as const` 保留字面量**：避免类型拓宽
7. **避免 `as` 断言**：优先使用类型守卫确保运行时安全
8. **复杂类型添加 JSDoc**：说明用途和约束
9. **不要过度工程化类型**：如果一个类型定义比它保护的代码还复杂，就该简化
10. **测试类型定义**：使用 `AssertEqual` 等辅助类型验证行为

---

## 9. this 指向问题

在回调、事件监听、定时器中，`this` 容易丢失指向。

**错误示例：**
```typescript
start() {
  this.TestFunction("直接调用函数");
  setTimeout(this.TestFunction, 1000, "延迟调用函数1");      // this → Window
  setTimeout(function () {
    this.TestFunction("延迟调用函数2");                       // TypeError
  }, 2000);
}

// 事件回调同理：第二个参数写 null 且未绑定 this
this.btn.on("click", null, this.TestFunction);               // this 丢失
```

**修复方案：**
```typescript
// 方案 1：.bind 绑定
setTimeout(this.TestFunction.bind(this), 1000, "延迟调用函数1");

// 方案 2：箭头函数固定 this
setTimeout(() => {
  this.TestFunction("延迟调用函数2");
}, 1000);
```

始终确保回调中的 `this` 指向当前实例：优先使用箭头函数，其次用 `.bind(this)`。
