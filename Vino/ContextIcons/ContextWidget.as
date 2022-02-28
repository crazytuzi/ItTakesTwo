class UContextWidget : UHazeUserWidget
{
	UFUNCTION()
	void RemoveContextWidget()
	{
		Player.RemoveWidget(this);
	}
}