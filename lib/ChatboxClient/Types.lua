export type Map<K,V> = {[K]: V};
export type Dictionary<T> = Map<string,T>;

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