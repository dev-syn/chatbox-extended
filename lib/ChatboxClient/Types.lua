export type Map<K,V> = {[K]: V};
export type Dictionary<T> = Map<string,T>;

type t = {[number]: string | TextLabel}

export type ChatboxExtended = {
    ChatStyling: any,
    ActiveChannel: string?,
    Messages: Dictionary<{TextLabel}>,
    Init: () -> (),
    UI: ScreenGui,
    Background: Frame,
    ChatField: TextBox,
    ChatList: ScrollingFrame,
    ChatListLayout: UIListLayout
};

return true;