import Cake.LevelSpecific.PlayRoom.SpaceStation.PlasmaBallTrack;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Peanuts.Network.RelativeCrumbLocationCalculator;

class APlasmaBallOnTrack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BallRoot;

	UPROPERTY(DefaultComponent, Attach = BallRoot)
	UStaticMeshComponent BallMesh;

	UPROPERTY()
	APlasmaBallTrack Track;

	UPROPERTY(DefaultComponent, Attach = BallMesh)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BallElectricityAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartBallRollingAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopBallRollingAudioEvent;

	UPROPERTY(meta = (MakeEditWidget))
	FVector EndLocation = FVector(-4000.f, 0.f, 0.f);

	UPROPERTY()
	bool bPreviewEndLocation = false;

	float MovementSpeed = 0.f;
	float MaxSpeed = 850.f;

	bool bRolling = true;
	bool bForwards = true;

	float BallVelocityAlpha = 0.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewEndLocation)
			BallRoot.SetRelativeLocation(EndLocation);
		else
			BallRoot.SetRelativeLocation(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (Track != nullptr)
			AttachToComponent(Track.TrackRoot, NAME_None, EAttachmentRule::KeepWorld);

		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"LandOnBall");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"LeaveBall");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);

		HazeAkComp.HazePostEvent(BallElectricityAudioEvent);
	}

	UFUNCTION(NotBlueprintCallable)
	void LandOnBall(AHazePlayerCharacter Player, FHitResult Hit)
	{
		UHazeCrumbComponent CrumbComp = UHazeCrumbComponent::Get(Player);
		CrumbComp.MakeCrumbsUseCustomWorldCalculator(URelativeCrumbLocationCalculator::StaticClass(), this, BallRoot);
	}

	UFUNCTION(NotBlueprintCallable)
	void LeaveBall(AHazePlayerCharacter Player)
	{
		UHazeCrumbComponent CrumbComp = UHazeCrumbComponent::Get(Player);
		CrumbComp.RemoveCustomWorldCalculator(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bRolling)
		{
			MovementSpeed += 200.f * DeltaTime;
			MovementSpeed = FMath::Clamp(MovementSpeed, 0.f, MaxSpeed);
			FVector Forward = bForwards ? -ActorForwardVector : ActorForwardVector;
			FVector BallDelta = Forward * MovementSpeed * DeltaTime;
			BallRoot.AddWorldOffset(BallDelta);
			float TargetRot = bForwards ? 85.f : -85.f;
			float CurrentRot = FMath::GetMappedRangeValueClamped(FVector2D(0.f, MaxSpeed), FVector2D(0.f, TargetRot), MovementSpeed);
			BallRoot.AddLocalRotation(FRotator(CurrentRot * DeltaTime, 0.f, 0.f));

			if (FMath::Abs(BallRoot.RelativeLocation.X) >= FMath::Abs(EndLocation.X) && bForwards)
			{
				ReachedEndPoint();
			}
			if (BallRoot.RelativeLocation.X >= 0.f && !bForwards)
			{
				ReachedEndPoint();
			}
		}

		BallVelocityAlpha = FMath::GetMappedRangeValueClamped(FVector2D(0.f, MaxSpeed), FVector2D(0.f, 1.f), MovementSpeed);
		if (!bRolling)
			BallVelocityAlpha = 0.f;
		HazeAkComp.SetRTPCValue("Rtpc_SpaceStation_Platform_PlasmaBallOnTrack_Velocity", BallVelocityAlpha);
	}

	UFUNCTION()
	void StartRolling()
	{
		MovementSpeed = 0.f;
		bForwards = !bForwards;
		bRolling = true;
		HazeAkComp.HazePostEvent(StartBallRollingAudioEvent);
	}

	void ReachedEndPoint()
	{
		bRolling = false;
		HazeAkComp.HazePostEvent(StopBallRollingAudioEvent);
		BP_ReachedEnd();
	}

	UFUNCTION(BlueprintEvent)
	void BP_ReachedEnd() {}

	UFUNCTION()
	void PrepareToRotateTrack()
	{
		System::SetTimer(this, n"RotateTrack", 1.f, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void RotateTrack()
	{
		Track.RotateTrack();
		System::SetTimer(this, n"StartRolling", 0.5f, false);
	}
}