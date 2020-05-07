[![Pod Platform](https://img.shields.io/cocoapods/p/StoryContent)](https://cocoapods.org/pods/StoryContent)
[![Pod License](https://img.shields.io/cocoapods/l/StoryContent)](https://github.com/storyclm/story-content-ios/blob/master/LICENSE)
[![Cocoapods](https://img.shields.io/cocoapods/v/StoryContent)](https://cocoapods.org/pods/StoryContent)

# story-content-ios #

### Установка

#### CocoaPods

[CocoaPods](https://cocoapods.org) менеджер зависимостей для Cocoa проектов.
Чтобы интегрировать StoryContent в ваш проект с помощью CocoaPods, укажите его в своем `Podfile`:

```ruby
pod 'StoryContent', '~> 0.4.0'
```

#### Вручную

Если вы предпочитаете не использовать менеджеров зависимостей CocoaPods, вы можете добавить StoryContent.framework в свой проект вручную.

### StoryContent

StoryContent состоит из следующих модулей:

* SCLMAuthService - аутентификация
* SCLMSyncService - доступ к RESTful API StoryCLM
* SCLMSyncManager - менеджер синхронизации
* SCLMBridge - мост

### Настройка

Для работы с StoryContent необходимо установить SCLMAuthService и SCLMSyncService с данными из AuthCredentials.plist

```swift
SCLMAuthService.shared.setClientId(clientId)
SCLMAuthService.shared.setClientSecret(clientSecret)
SCLMAuthService.shared.setAppId(appId)
SCLMAuthService.shared.setAppSecret(appSecret)
SCLMAuthService.shared.setAuthEndpoint(authEndpoint)
```

### Логин

Для авторизации от имени пользователя необходимо вызвать следующий метод

```swift
SCLMAuthService.shared.login(username: username, password: password, success: {
    success()
}) { (error) in
    failure(error)
}
```

При успешной аутентификации будет получен token, который в дальнейшем будет использован SCLMSyncService для доступа к RESTful API

Для авторизации от имени приложения необходимо вызвать следующий метод

```swift
func authAsApplication(clientId: String,
                       secret: String,
                       username: String,
                       password: String,
                       success: @escaping (SCLMToken?) -> Void,
                       failure: @escaping (Error) -> Void) {}
```

Для авторизации от имени клиента необходимо вызвать следующий метод

```swift
func authAsService(clientId: String,
                   secret: String,
                   success: @escaping (SCLMToken?) -> Void,
                   failure: @escaping (Error) -> Void) {}
```

### Синхронизация Клиентов

После успешного логина необходим выполнить синхронизацию клиентов

```swift
SCLMSyncManager.shared.synchronizeClients { (error) in

}
```

Данный метод загрузит всех доступных клиентов и презентации для каждого клиента

### Доступ к данным

Доступ к данным предоставляет NSFetchedResultsController<NSFetchRequestResult> 

Можно использовать существующий NSFetchedResultsController с sectionNameKeyPath: "client.name"
```swift
var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> {
    return SCLMSyncManager.shared.fetchedResultsController
}
```

Можно инициализировать свой
```swift
public lazy var fetchedResultsController: NSFetchedResultsController = { () -> NSFetchedResultsController<NSFetchRequestResult> in
    
    let fetchResult = self.fetchRequest(for: Presentation.entityName(), batchSize: 100, sortKey: "client.name", context: syncManager.context)
    let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchResult, managedObjectContext: syncManager.context, sectionNameKeyPath: "client.name", cacheName: nil)
    
    do {
        try fetchedResultsController.performFetch()
    } catch {
        print("FetchedResultsController performFetch error")
    }
    
    return fetchedResultsController
}()
```

или так
```swift
public lazy var fetchedResultsControllerSectionLess: NSFetchedResultsController = { () -> NSFetchedResultsController<NSFetchRequestResult> in
    
    let fetchResult = self.fetchRequest(for: Presentation.entityName(), batchSize: 100, sortKey: "client.name", context: syncManager.context)
    let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchResult, managedObjectContext: syncManager.context, sectionNameKeyPath: nil, cacheName: nil)
    
    do {
        try fetchedResultsController.performFetch()
    } catch {
        print("FetchedResultsController performFetch error")
    }
    
    return fetchedResultsController
}()
```


По умолчанию количество Клиентов (Client) - это количество секций для UITableViewDataSource или UICollectionViewDataSource

```swift
func numberOfSections(in collectionView: UICollectionView) -> Int {
    
    if let sections = viewModel.fetchedResultsController.sections {
        return sections.count
    }
    return 0
}
```

Количество объектов секции (Presentation) - это презентации Клиентов.

```swift
func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    
    if let sections = viewModel.fetchedResultsController.sections {
        if sections.count > section {
            return sections[section].numberOfObjects
        }
    }
    return 0
}
```

Доступ к презентации осуществляется через

```swift
let presentation = fetchedResultsController.object(at: indexPath) as! Presentation
```

### Синхронизация презентаций

При синхронизации клиентов синхронизируются только модели презентаций. Для синхронизации контента презентации необходимо вызвать

```swift
SCLMSyncManager.shared.synchronizePresentation(presentation, completionHandler: { (error) in
    completionHandler(error)
}) { (progress) in
    progressHandler(progress)
}
```

Для восстановления прогреса синхронизации при обновлении данных необходимо воспользоваться следующими инструментами:

```swift
let presentationSynchronizingNow = SCLMSyncManager.shared.isPresentationSynchronizingNow(presentation: presentation)
```

Если контент загружается в настоящий момент, то метод SCLMSyncManager.shared.isPresentationSynchronizingNow вернет объект, у которого есть следующие свойства

```swift
public weak var downloadRequest: DownloadRequest?
public var progress = Progress() {
    didSet {
        progressHandler?(presentationId.intValue, progress)
    }
}
public var progressHandler: ((_ presentationId: Int?, _ progress: Progress) -> Void)?
public var completionHandler: ((_ presentationId: Int?) -> Void)?
```

Соответственно, для downloadRequest может быть вызван cancel() для отмены, progress - передает текущий прогресс, progressHandler и completionHandler можно использовать для упраления процессом и обновления интерфейса

Для удаления контента необходимо вызвать

```swift
SyncManager.shared.deletePresentationContentPackage(presentation)
```

Для обновления презентации необходимо вызвать

```swift
SCLMSyncManager.shared.updatePresentation(presentation) { (error) in
    completionHandler(error)
}
```

### Аналитика

Аналитика реализована в библиотеке StoryIot, подключение которой осуществляется через CocoaPods

```swift
pod 'StoryIoT', :git => 'https://github.com/storyclm/story-iot-ios.git', :tag => ‘develop’
```

SLSessionsSyncManager инициализируется в AppDelegate через

```swift
SLSessionsSyncManager.shared.startTimer()
```

и слушает все события добавленные в хранилище моста и при обнаружении отправляет их на сервер.

При инициализации создается 
```swift
storyIoT = StoryIoT(credentials: SC)
```
который непосредственно отвечает за отправку сообщений

Для успешной инициализации StoryIoT необходимы реквизиты доступа
```swift
endpoint=
hub=
key=
secret=
expiration=
```

### Мост

StoryContent позволяет разработчикам создавать контент (презентации) с функционалом, сопоставимым с функционалом и надежностью промышленных приложений, используя только веб-технологии, такие как HTML, CSS, и JavaScript, а также используя технологию StoryBridge.

StoryBridge - это технология, разработанная Breffi,  позволяющая вызывать функции нативного кода клиентского приложения из контента с высокой степенью надежности и асинхронности. 

Принципиально, StoryBridge состоит из двух частей:

- SCLMBridgeModule модуль, который реализован на стороне нативного кода и является частью клиентского приложения;
- storyclm.js - библиотека, встраиваемая в контент.

storyclm.js - это библиотека, предоставляющая доступ к системным функциям (API) платформы Story из контента. Библиотека должна использоваться в HTML5 приложениях для Story. В других CLM системах, а также без Story данная библиотека работать не будет.

Основная задача библиотеки посылать сообщения в StoryBridge и обрабатывать входящие сообщения. Это часть технологии StoryBridge  на стороне контента. Web приложение вызывает методы библиотеки, которая в свою очередь создает команду и посылает в нативную часть StoryBridge, после выполнения, клиентское приложение, используя мост, отправляет результат (команду) в WebView, где эту команду и данные перехватывает библиотека, которая в свою очередь вызывает callback. Таким образом, результат работы нативного кода возвращается в Web приложение. Web приложению не важно какой операционной системе принадлежит WebView, оно просто оперирует методами библиотеки. Тем самым приложение может одинаково работать на всех клиентах StoryContent независимо от операционной системы. Библиотека отвечает за взаимодействие на стороне Web приложения и является его частью. Библиотека имеет единую реализацию под все операционные системы.

SCLMBridgeModule - это часть технологии StoryBridge на стороне нативного кода, которая умеет принимать сообщения от WebView и контента,  находить и запускать модули-обработчики и возвращать результат работы обратно в WebView. Данный модуль управляет процессом по доставке сообщений и отвечает за надежную их обработку.

#### Существующие модули и их протоколы

##### SCLMBridgeBaseModule

```swift
public protocol SCLMBridgeBaseModuleProtocol: class {
    func goToSlide(_ slide: Slide, with data: Any)
    func getNavigationData() -> Any
}
```

##### SCLMBridgePresentationModule

```swift
public protocol SCLMBridgePresentationModuleProtocol: class {
    typealias SlideName = String
    
    func openPresentation(_ presentation: Presentation, with slideName: String?, and data: Any?)
    func getPreviousSlide() -> Slide?
    func getNextSlide() -> Slide?
    func getCurrentSlideName() -> String?
    func getBackForwardList() -> [SlideName]?
    func getBackForwardPresList() -> [Presentation]?
    func closePresentation(mode: ClosePresentationMode)
}
```

##### SCLMBridgeUIModule

```swift
public protocol SCLMBridgeUIModuleProtocol: class {
    func hideCloseBtn()
    func hideSystemBtns()
}
```

##### SCLMBridgeHTTPModule

```swift
// обрабатывает комманды
let commands = [command.httpget,
                command.httppost,
                command.httpput,
                command.httpdelete]
```

##### SCLMBridgeSessionsModule

```swift
public protocol SCLMBridgeSessionsModuleProtocol: class {
    func setSessionComplete()
}
```

##### SCLMBridgeCustomEventsModule

```swift
public protocol SCLMBridgeCustomEventsModuleProtocol: class {
    func setEventKey(_ key: String, and value: Any)
}
```

##### SCLMBridgeMediaFilesModule

```swift
public protocol SCLMBridgeMediaFilesModuleProtocol: class {
    func openMediaFile(_ fileName: String)
    func openMediaLibrary()
    func showMediaLibraryBtn()
    func hideMediaLibraryBtn()
}
```

##### SCLMBridgeMapModule

```swift
public protocol SCLMBridgeMapModuleProtocol: class {
    func hideMapBtn()
    func showMapBtn()
}
```

Для добавления модуля необходимо реализовать протокол добавляемого модуля.

Пример реализации модуля SCLMBridgeMediaFilesModule
```swift

class PresentationViewController: UIViewController, SCLMBridgeMediaFilesModuleProtocol {

    // MARK: - SCLMBridgeMediaFilesModuleProtocol

    func openMediaFile(_ fileName: String) {
        DispatchQueue.main.async {
            let mediaVC = MediaViewController.get()
            mediaVC.inject(presentation: self.currentPresentation)
            mediaVC.inject(bridge: self.bridge)
            mediaVC.inject(mediaFileNameToOpenAtLaunch: fileName)
            self.present(mediaVC, animated: true, completion: nil)
        }
    }

    func openMediaLibrary() {
        DispatchQueue.main.async {
            let mediaVC = MediaViewController.get()
            mediaVC.inject(presentation: self.currentPresentation)
            mediaVC.inject(bridge: self.bridge)
            self.present(mediaVC, animated: true, completion: nil)
        }
    }

    func showMediaLibraryBtn() {
        mediaButton.show()
    }

    func hideMediaLibraryBtn() {
        mediaButton.hide()
    }
}

```

#### Создание собственного модуля для обработки команд

* Создаем класс модуля унаследовав его от `SCLMBridgeModule` и реализуем метод `execute`

```swift
import StoryContent

protocol CustomBridgeModuleDelegate: class {
    func customBridgeModuleDelegateCallback(command: String, params: Any)
}

class CustomBridgeModule: SCLMBridgeModule {

    struct Commands {
        static let command1 = "Mycommand1"
        static let command2 = "Mycommand2"

        static var allCommands: [String] {
            return [ command1, command2 ]
        }
    }

    weak var delegate: CustomBridgeModuleDelegate?

    override func execute(message: SCLMBridgeMessage, result: @escaping (SCLMBridgeResponse?) -> Void) {

        switch message.command {
        case Commands.command1:
            result(commandHandler1(guid: message.guid, command:message.command, data: message.data))
        case Commands.command2:
            result(commandHandler2(guid: message.guid, command:message.command, data: message.data))
        default:
            result(SCLMBridgeResponse(guid: message.guid, responseData: nil, errorCode: .failure, errorMessage: "unknown command"))
        }
    }

    private func commandHandler1(guid: String, command: String, data: Any) -> SCLMBridgeResponse {
        // get some job here
        delegate?.customBridgeModuleDelegateCallback(command: command, params: data)

        return SCLMBridgeResponse(guid: guid, responseData: nil, errorCode: ResponseStatus.success, errorMessage: nil)
    }

    private func commandHandler2(guid: String, command: String, data: Any) -> SCLMBridgeResponse {
        // get some job here
        delegate?.customBridgeModuleDelegateCallback(command: command, params: data)

        return SCLMBridgeResponse(guid: guid, responseData: nil, errorCode: ResponseStatus.success, errorMessage: nil)
    }
}
```

* Регистрируем новые команды и добавляем свой модуль в мост

```swift
if let bridge = self.bridge {
    let customBridgeModule = CustomBridgeModule(presenter: webView, session: bridge.sessions.session, presentation: currentPresentation, settings: nil, environments: nil, delegate: nil)
    customBridgeModule.delegate = self

    bridge.subscribe(module: customBridgeModule, toCommands: CustomBridgeModule.Commands.allCommands)
    bridge.addBridgeModule(customBridgeModule)
}
```
