import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.Tilt.TiltComponent;
class ASilentRoomDescendingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	UCurveFloat DescendCurve;

	TArray<AHazePlayerCharacter> PlayerArray;

	float PlayerOnPlatformTimerMax = 4.f;
	float PlayerOnPlatformTimer = PlayerOnPlatformTimerMax;

	float GoingUpCooldownTimerMax = 1.5f;
	float GoingUpCooldownTimer = GoingUpCooldownTimerMax;

	FVector InitialMeshRelativeLocation = FVector::ZeroVector;

	bool bShouldTickTimer = false;
	bool bShouldTickCooldownTimer = false;
	bool bShouldDescendPlatform = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialMeshRelativeLocation = MeshRoot.RelativeLocation;

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
		if (bShouldTickTimer && bShouldDescendPlatform)
		{
			if (PlayerOnPlatformTimer <= 0.f)
			{
				PlayerOnPlatformTimer = 0.f;
				bShouldTickTimer = false;
			} else
			{
				PlayerOnPlatformTimer -= DeltaTime;
			}
		} 
		else if (bShouldTickTimer && !bShouldDescendPlatform)
		{
			if (PlayerOnPlatformTimer >= PlayerOnPlatformTimerMax)
			{
				PlayerOnPlatformTimer = PlayerOnPlatformTimerMax; 
			} else 
			{
				PlayerOnPlatformTimer += DeltaTime / 2;
			}
		}

		if (bShouldTickCooldownTimer)
		{
			GoingUpCooldownTimer -= DeltaTime;
			if (GoingUpCooldownTimer <= 0.f)
			{
				bShouldTickCooldownTimer = false;
				bShouldTickTimer = true;
				bShouldDescendPlatform = false;
			}
		}

		float ZLoc = FMath::FInterpTo(MeshRoot.RelativeLocation.Z, FMath::Lerp(-1850.f, 0.f, DescendCurve.GetFloatValue(PlayerOnPlatformTimer / PlayerOnPlatformTimerMax)), DeltaTime, 2.f);
		MeshRoot.SetRelativeLocation(FVector(InitialMeshRelativeLocation.X, InitialMeshRelativeLocation.Y, ZLoc));
	}

	UFUNCTION()
	void PlayerLandedOnActor(AHazePlayerCharacter Player, const FHitResult& Hit)
	{		
		PlayerArray.AddUnique(Player);
		bShouldTickTimer = true;
		bShouldDescendPlatform = true;
		GoingUpCooldownTimer =  GoingUpCooldownTimerMax;
	}

	UFUNCTION()
	void PlayerLeftActor(AHazePlayerCharacter Player)
	{
		PlayerArray.Remove(Player);

		if (PlayerArray.Num() == 0)
		{
			bShouldTickTimer = false;
			bShouldTickCooldownTimer = true;
		}
	}
}