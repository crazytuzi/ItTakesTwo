import Cake.LevelSpecific.Basement.BasementBoss.ShadowWallShelter;

class AShadowWallShelterManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;
	default BillboardComp.RelativeScale3D = FVector(10.f, 10.f, 10.f);

	UPROPERTY()
	APostProcessVolume TargetPostProcessVolume;

	TArray<AShadowWallShelter> Shelters;

	bool bPlayersInShelter = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAllActorsOfClass(Shelters);
		for (AShadowWallShelter CurShelter : Shelters)
		{
			CurShelter.OnShelterEnter.AddUFunction(this, n"EnterShelter");
			CurShelter.OnShelterExit.AddUFunction(this, n"ExitShelter");
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterShelter()
	{
		bPlayersInShelter = true;
	}

	UFUNCTION(NotBlueprintCallable)
	void ExitShelter()
	{
		bPlayersInShelter = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		UpdatePostProcessWeight(DeltaTime);
	}

	void UpdatePostProcessWeight(float DeltaTime)
	{
		if (TargetPostProcessVolume == nullptr)
			return;

		float BlendWeightAdder = bPlayersInShelter ? 3 : -3;
		TargetPostProcessVolume.BlendWeight = Math::Saturate(TargetPostProcessVolume.BlendWeight + (DeltaTime * BlendWeightAdder));
	}
}