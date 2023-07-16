import SwiftUI

private struct ConfirmationDialogModifier<Item, Result, Actions: View, Message: View>: ViewModifier {
    @State private var ids: [UUID] = []

    @ObservedObject var queryableState: QueryableState<Item, Result>
    var title: String
    @ViewBuilder var actions: (_ item: Item, _ query: QueryResolver<Result>) -> Actions
    @ViewBuilder var message: (_ item: Item) -> Message

    func body(content: Content) -> some View {
        content
            .background {
                if let initialItemContainer = queryableState.itemContainer {
                    ZStack {
                        StableItemContainerView(itemContainer: initialItemContainer) { itemContainer in
                            Color.clear
                                .confirmationDialog(
                                    title,
                                    isPresented: .constant(true)
                                ) {
                                    actions(itemContainer.item, itemContainer.resolver)
                                } message: {
                                    message(itemContainer.item)
                                        .onDisappear {
                                            if let id = ids.first {
                                                queryableState.autoCancelContinuation(id: id, reason: .presentationEnded)
                                                ids.removeFirst()
                                            }
                                        }
                                }
                        }
                        .onAppear { ids.append(initialItemContainer.id) }
                    }
                    .id(initialItemContainer.id)
                }
            }
    }
}

public extension View {
    
    /// Shows a confirmation dialog controlled by a ``Queryable/Queryable``.
    @MainActor
    func queryableConfirmationDialog<Item, Result, Actions: View, Message: View>(
        controlledBy queryable: Trigger<Item, Result>,
        title: String,
        @ViewBuilder actions: @escaping (_ item: Item, _ query: QueryResolver<Result>) -> Actions,
        @ViewBuilder message: @escaping (_ item: Item) -> Message
    ) -> some View {
        modifier(ConfirmationDialogModifier(queryableState: queryable.queryableState, title: title, actions: actions, message: message))
    }
    
    @MainActor
    func queryableConfirmationDialog<Result, Actions: View, Message: View>(
        controlledBy queryable: Trigger<Void, Result>,
        title: String,
        @ViewBuilder actions: @escaping (_ query: QueryResolver<Result>) -> Actions,
        @ViewBuilder message: @escaping () -> Message
    ) -> some View {
        modifier(
            ConfirmationDialogModifier(queryableState: queryable.queryableState, title: title) { _, query in
                actions(query)
            } message: { _ in
                message()
            }
        )
    }

    @MainActor
    func queryableConfirmationDialog<Item, Result, Actions: View, Message: View>(
        controlledBy queryableState: QueryableState<Item, Result>,
        title: String,
        @ViewBuilder actions: @escaping (_ item: Item, _ query: QueryResolver<Result>) -> Actions,
        @ViewBuilder message: @escaping (_ item: Item) -> Message
    ) -> some View {
        modifier(ConfirmationDialogModifier(queryableState: queryableState, title: title, actions: actions, message: message))
    }

    @MainActor
    func queryableConfirmationDialog<Result, Actions: View, Message: View>(
        controlledBy queryableState: QueryableState<Void, Result>,
        title: String,
        @ViewBuilder actions: @escaping (_ query: QueryResolver<Result>) -> Actions,
        @ViewBuilder message: @escaping () -> Message
    ) -> some View {
        modifier(
            ConfirmationDialogModifier(queryableState: queryableState, title: title) { _, query in
                actions(query)
            } message: { _ in
                message()
            }
        )
    }
}
