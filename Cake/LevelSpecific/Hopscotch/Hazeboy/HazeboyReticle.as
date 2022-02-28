class AHazeboyReticle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Hide();
	}

	void Show()
	{
		EnableActor(this);
	}

	void Hide()
	{
		DisableActor(this);
	}
}