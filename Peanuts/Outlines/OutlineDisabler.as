import Peanuts.Outlines.Outlines;

class AOutlineDisabler : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;

	UFUNCTION()
	void DisableOutline(AHazePlayerCharacter Player)
	{
		Player.DisableOutlineByInstigator(this);
	}

	UFUNCTION()
	void EnableOutline(AHazePlayerCharacter Player)
	{
		Player.EnableOutlineByInstigator(this);
	}
}