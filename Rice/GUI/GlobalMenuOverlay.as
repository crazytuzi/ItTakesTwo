class UGlobalMenuOverlayWidget : UHazeUserWidget
{
	UPROPERTY()
	TSubclassOf<UHazeUserWidget> DebugInfoWidget;

	UFUNCTION(BlueprintOverride)
	void OnAdded()
	{
		SetWidgetZOrderInLayer(9001);

#if TEST
		if(DebugInfoWidget.IsValid())
		{
			auto InfoWidget = Widget::AddFullscreenWidget(DebugInfoWidget, EHazeWidgetLayer::Dev);	
			InfoWidget.SetWidgetPersistent(true);
		}
#endif
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float Timer)
	{
	}
}