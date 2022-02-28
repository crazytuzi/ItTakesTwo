import Vino.ContextIcons.ContextWidget;

UFUNCTION()
UContextWidget CreateContextWidget(AHazePlayerCharacter Player, TSubclassOf<UContextWidget> WidgetClass, USceneComponent Component)
{
	UContextWidget Widget = Cast<UContextWidget>(Player.AddWidget(WidgetClass));
	Widget.OverrideWidgetPlayer(Player);
	Widget.AttachWidgetToComponent(Component);
	return Widget;
}