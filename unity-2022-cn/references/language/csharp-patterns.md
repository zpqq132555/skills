# C# 设计模式 — Unity 常用

## 1. 单例模式 (Singleton)

### MonoBehaviour 单例

```csharp
using UnityEngine;

public class GameManager : MonoBehaviour
{
    public static GameManager Instance { get; private set; }

    [SerializeField] private int score;

    private void Awake()
    {
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
            return;
        }
        Instance = this;
        DontDestroyOnLoad(gameObject);
    }

    private void OnDestroy()
    {
        if (Instance == this)
        {
            Instance = null;
        }
    }
}

// 使用
GameManager.Instance.AddScore(10);
```

### 泛型单例基类

```csharp
using UnityEngine;

public abstract class Singleton<T> : MonoBehaviour where T : Singleton<T>
{
    private static T instance;
    public static T Instance
    {
        get
        {
            if (instance == null)
            {
                instance = FindAnyObjectByType<T>();
                if (instance == null)
                {
                    var go = new GameObject(typeof(T).Name);
                    instance = go.AddComponent<T>();
                }
            }
            return instance;
        }
    }

    protected virtual void Awake()
    {
        if (instance != null && instance != this)
        {
            Destroy(gameObject);
            return;
        }
        instance = (T)this;
        DontDestroyOnLoad(gameObject);
    }

    protected virtual void OnDestroy()
    {
        if (instance == this) instance = null;
    }
}

// 使用
public class AudioManager : Singleton<AudioManager>
{
    protected override void Awake()
    {
        base.Awake();
        // 自己的初始化...
    }
}
```

### 纯 C# 单例（无 MonoBehaviour）

```csharp
public class DataManager
{
    private static readonly DataManager instance = new DataManager();
    public static DataManager Instance => instance;

    private DataManager() { }

    public void LoadData() { /* ... */ }
}
```

---

## 2. 观察者模式 (Observer)

### 基于 C# Event

```csharp
public static class EventBus
{
    public static event System.Action<int> OnScoreChanged;
    public static event System.Action<string, int> OnLevelComplete;
    public static event System.Action OnGameOver;

    public static void RaiseScoreChanged(int score) => OnScoreChanged?.Invoke(score);
    public static void RaiseLevelComplete(string name, int stars) => OnLevelComplete?.Invoke(name, stars);
    public static void RaiseGameOver() => OnGameOver?.Invoke();
}
```

### 泛型事件系统

```csharp
using System;
using System.Collections.Generic;

public static class EventManager
{
    private static readonly Dictionary<Type, Delegate> events = new();

    public static void Subscribe<T>(Action<T> handler)
    {
        Type key = typeof(T);
        if (events.TryGetValue(key, out var existing))
            events[key] = Delegate.Combine(existing, handler);
        else
            events[key] = handler;
    }

    public static void Unsubscribe<T>(Action<T> handler)
    {
        Type key = typeof(T);
        if (events.TryGetValue(key, out var existing))
        {
            var result = Delegate.Remove(existing, handler);
            if (result == null) events.Remove(key);
            else events[key] = result;
        }
    }

    public static void Publish<T>(T eventData)
    {
        if (events.TryGetValue(typeof(T), out var handler))
            (handler as Action<T>)?.Invoke(eventData);
    }
}

// 定义事件数据
public struct DamageEvent
{
    public GameObject target;
    public float damage;
    public Vector3 hitPoint;
}

// 使用
EventManager.Subscribe<DamageEvent>(OnDamage);
EventManager.Publish(new DamageEvent { target = obj, damage = 10 });
EventManager.Unsubscribe<DamageEvent>(OnDamage);
```

---

## 3. 状态机模式 (State Machine)

```csharp
// 状态接口
public interface IState
{
    void Enter();
    void Update();
    void Exit();
}

// 状态机
public class StateMachine
{
    private IState currentState;

    public void ChangeState(IState newState)
    {
        currentState?.Exit();
        currentState = newState;
        currentState?.Enter();
    }

    public void Update()
    {
        currentState?.Update();
    }
}

// 具体状态
public class IdleState : IState
{
    private readonly PlayerController player;

    public IdleState(PlayerController player) { this.player = player; }

    public void Enter() { player.Animator.Play("Idle"); }
    public void Update()
    {
        if (Input.GetAxis("Horizontal") != 0)
            player.StateMachine.ChangeState(new RunState(player));
    }
    public void Exit() { }
}

// 在 PlayerController 中使用
public class PlayerController : MonoBehaviour
{
    public Animator Animator { get; private set; }
    public StateMachine StateMachine { get; private set; }

    private void Awake()
    {
        Animator = GetComponent<Animator>();
        StateMachine = new StateMachine();
    }

    private void Start()
    {
        StateMachine.ChangeState(new IdleState(this));
    }

    private void Update()
    {
        StateMachine.Update();
    }
}
```

---

## 4. 命令模式 (Command)

```csharp
public interface ICommand
{
    void Execute();
    void Undo();
}

public class MoveCommand : ICommand
{
    private readonly Transform transform;
    private readonly Vector3 direction;
    private Vector3 previousPosition;

    public MoveCommand(Transform t, Vector3 dir)
    {
        transform = t;
        direction = dir;
    }

    public void Execute()
    {
        previousPosition = transform.position;
        transform.position += direction;
    }

    public void Undo()
    {
        transform.position = previousPosition;
    }
}

// 命令管理器
public class CommandManager
{
    private readonly Stack<ICommand> undoStack = new();
    private readonly Stack<ICommand> redoStack = new();

    public void Execute(ICommand cmd)
    {
        cmd.Execute();
        undoStack.Push(cmd);
        redoStack.Clear();
    }

    public void Undo()
    {
        if (undoStack.Count > 0)
        {
            var cmd = undoStack.Pop();
            cmd.Undo();
            redoStack.Push(cmd);
        }
    }

    public void Redo()
    {
        if (redoStack.Count > 0)
        {
            var cmd = redoStack.Pop();
            cmd.Execute();
            undoStack.Push(cmd);
        }
    }
}
```

---

## 5. 工厂模式 (Factory)

```csharp
public enum EnemyType { Goblin, Skeleton, Dragon }

public class EnemyFactory : MonoBehaviour
{
    [SerializeField] private GameObject goblinPrefab;
    [SerializeField] private GameObject skeletonPrefab;
    [SerializeField] private GameObject dragonPrefab;

    public GameObject Create(EnemyType type, Vector3 position)
    {
        GameObject prefab = type switch
        {
            EnemyType.Goblin => goblinPrefab,
            EnemyType.Skeleton => skeletonPrefab,
            EnemyType.Dragon => dragonPrefab,
            _ => throw new System.ArgumentException($"Unknown type: {type}")
        };

        return Instantiate(prefab, position, Quaternion.identity);
    }
}
```

---

## 6. 服务定位器 (Service Locator)

```csharp
public static class ServiceLocator
{
    private static readonly Dictionary<Type, object> services = new();

    public static void Register<T>(T service) where T : class
    {
        services[typeof(T)] = service;
    }

    public static T Get<T>() where T : class
    {
        if (services.TryGetValue(typeof(T), out var service))
            return service as T;
        throw new InvalidOperationException($"Service {typeof(T)} not registered");
    }

    public static bool TryGet<T>(out T service) where T : class
    {
        if (services.TryGetValue(typeof(T), out var obj))
        {
            service = obj as T;
            return true;
        }
        service = null;
        return false;
    }

    public static void Clear() => services.Clear();
}

// 注册
ServiceLocator.Register<IAudioService>(new AudioService());
ServiceLocator.Register<ISaveService>(new SaveService());

// 获取
var audio = ServiceLocator.Get<IAudioService>();
```
