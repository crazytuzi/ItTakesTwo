import Cake.LevelSpecific.SnowGlobe.SnowFolk.SnowFolkSplineFollower;

const FStatID STAT_SnowFolkMovement(n"SnowFolkMovement");

UFUNCTION(Category = "SnowFolkManager")
void ActivateSnowFolkWithActivationLevel(FName ManagerTag, ESnowFolkActivationLevel Level)
{
	TArray<ASnowFolkMovementManager> Managers;
	GetAllActorsOfClass(Managers);

	for(auto Manager : Managers)
	{
		if (Manager.ManagerTag != ManagerTag)
			continue;

		for(auto Folk : Manager.Snowfolk)
		{
			if (Folk.ActivationLevel != Level)
				continue;

			Folk.ActivateSnowfolk();
		}
	}
}

class ASnowFolkMovementManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(Category = "Folk")
	FName ManagerTag;

	UPROPERTY(Category = "Folk", EditConst)
	TArray<ASnowfolkSplineFollower> Snowfolk;

	UFUNCTION(CallInEditor, Category = "Folk")
	void FillSnowfolkList()
	{
		TArray<ASnowfolkSplineFollower> SnowfolkInOtherLevel;

		GetAllActorsOfClass(Snowfolk);
		for(auto Folk : Snowfolk)
		{
			if (Folk.Level != Level)
			{
				Print("Snowfolk '" + Folk + "' is not placed in the same level as movement manager", 10, FLinearColor::Red);
				SnowfolkInOtherLevel.Add(Folk);
			}
		}

		for(auto Folk : SnowfolkInOtherLevel)
		{
			Snowfolk.Remove(Folk);
		}
	}

	int MoveIndex = 0;
	int MoveResolution = 1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
#if TEST
		FScopeCycleCounter EntryCounter(STAT_SnowFolkMovement);
#endif

		for(int i=0; i<Snowfolk.Num(); ++i)
		{
			auto Folk = Snowfolk[i];
			if (Folk == nullptr)
				continue;

			PerformMove(Folk, DeltaTime);
		}

		MoveIndex++;
	}

	void PerformMove(ASnowfolkSplineFollower Folk, float DeltaTime)
	{
		if (Folk.IsActorBeingDestroyed())
			return;

		if (!Folk.bIsSnowfolkActivated)
			return;

		if (!Folk.bCanMove)
			return;

		if (Folk.bIsRecovering)
			return;

		if (Folk.bIsHit)
			return;
			
		if (Folk.bIsDown)
			return;

		if (Folk.bMovementIsBlocked)
			return;

		Folk.MovementComp.Move(DeltaTime);
	}
}