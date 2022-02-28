
class ABirdMomEgg : AHazeCharacter
{

	UPROPERTY()
	bool bAllEggs = false;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UHazeAkComponent HazeAkComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorHiddenInGame(true);
		SetActorEnableCollision(false);
	}

	UFUNCTION()
	void AllEggDelivered()
	{
		bAllEggs = true;
	}
	UFUNCTION()
	void UnHideEggs()
	{
		SetActorHiddenInGame(false);
		SetActorEnableCollision(true);
	}
}

