import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
UCLASS(Abstract)
class AMusicTechWallLeaningTruss : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent TrussMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent ChimePipeRoot01;
	default ChimePipeRoot01.bAbsoluteRotation = true;

	UPROPERTY(DefaultComponent, Attach = ChimePipeRoot01)
	UStaticMeshComponent ChimePipeMesh01;

	UPROPERTY(DefaultComponent, Attach = ChimePipeMesh01)
	UBoxComponent ChimeCollision01;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent ChimePipeRoot02;
	default ChimePipeRoot02.bAbsoluteRotation = true;

	UPROPERTY(DefaultComponent, Attach = ChimePipeRoot02)
	UStaticMeshComponent ChimePipeMesh02;

	UPROPERTY(DefaultComponent, Attach = ChimePipeMesh02)
	UBoxComponent ChimeCollision02;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent ChimePipeRoot03;
	default ChimePipeRoot03.bAbsoluteRotation = true;

	UPROPERTY(DefaultComponent, Attach = ChimePipeRoot03)
	UStaticMeshComponent ChimePipeMesh03;

	UPROPERTY(DefaultComponent, Attach = ChimePipeMesh03)
	UBoxComponent ChimeCollision03;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent ChimePipeRoot04;
	default ChimePipeRoot04.bAbsoluteRotation = true;

	UPROPERTY(DefaultComponent, Attach = ChimePipeRoot04)
	UStaticMeshComponent ChimePipeMesh04;

	UPROPERTY(DefaultComponent, Attach = ChimePipeMesh04)
	UBoxComponent ChimeCollision04;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeAkComponent HazeAkComp;

	bool bMayOnActor = false;
	bool bCodyOnActor = false;
	float MeshRootRoll = 0.f;
	float RotationAddition = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"PlayerLandedOnActor");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"PlayerLeftActor");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bCodyOnActor)
		{
			if (ChimeCollision01.IsOverlappingActor(Game::GetCody()))
				RotationAddition = 5.f;
			else if (ChimeCollision02.IsOverlappingActor(Game::GetCody()))
				RotationAddition = 2.5f;
			else if (ChimeCollision04.IsOverlappingActor(Game::GetCody()))
				RotationAddition = -5.f;
		} else
		{
			RotationAddition = 0.f;
		}

		if (bMayOnActor)
		{
			FVector Direction = GetActorLocation() - Game::GetMay().GetActorLocation();
			float Dot = Direction.DotProduct(GetActorRightVector());
			float TargetMeshRootRoll = FMath::GetMappedRangeValueClamped(FVector2D(-1400.f, 1400.f), FVector2D(25.f, -25.f), Dot);

			MeshRootRoll = FMath::FInterpTo(MeshRoot.RelativeRotation.Roll, TargetMeshRootRoll + RotationAddition, DeltaTime, 2.f);
		} else 
		{
			MeshRootRoll = FMath::FInterpTo(MeshRoot.RelativeRotation.Roll, RotationAddition, DeltaTime, 0.5f);
		}

		MeshRoot.SetRelativeRotation(FRotator(0.f, 0.f, MeshRootRoll));

		float MeshRootRollNormalized = FMath::GetMappedRangeValueClamped(FVector2D(-20, 20), FVector2D(-1, 1), MeshRootRoll);
		HazeAkComp.SetRTPCValue("Rtpc_World_Music_Backstage_Platform_ChimeBridge_Roll", MeshRootRollNormalized);
	}

	UFUNCTION()
	void PlayerLandedOnActor(AHazePlayerCharacter Player, const FHitResult& Hit)
	{		
		PrintToScreen("Player: " + Player, 1.f);

		if (Player == Game::GetCody())
			bCodyOnActor = true;
		else if (Player == Game::GetMay())
			bMayOnActor = true;
	}

	UFUNCTION()
	void PlayerLeftActor(AHazePlayerCharacter Player)
	{
		if (Player == Game::GetCody())
			bCodyOnActor = false;
		else if (Player == Game::GetMay())
			bMayOnActor = false;
	}
}