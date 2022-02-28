UCLASS(Abstract)
class AGardenGateKeeperGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent GateRoot;

	UPROPERTY(DefaultComponent, Attach = GateRoot)
	UStaticMeshComponent GateMesh;

	FHazeTimeLike MoveGateTimeLike;
	default MoveGateTimeLike.Duration = 0.25f;

	bool bPlayerTooClose = false;
	bool bGateClosed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveGateTimeLike.BindUpdate(this, n"UpdateMoveGate");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for (AHazePlayerCharacter CurPlayer : Game::GetPlayers())
		{
			float CurDistance = GetDistanceTo(CurPlayer);
			if (CurDistance < 1500.f)
			{
				bPlayerTooClose = true;
				return;
			}
		}

		bPlayerTooClose = false;
	}

	UFUNCTION()
	void UpdateMoveGate(float CurValue)
	{
		float CurRot = FMath::Lerp(-120.f, 0.f, CurValue);
		GateRoot.SetRelativeRotation(FRotator(0.f, CurRot, 0.f));
	}

	UFUNCTION()
	void CloseGate()
	{
		MoveGateTimeLike.Play();
		bGateClosed = true;
	}

	UFUNCTION()
	void OpenGate()
	{
		MoveGateTimeLike.Reverse();
		bGateClosed = false;
	}
}