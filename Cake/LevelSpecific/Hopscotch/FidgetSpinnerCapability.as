import Cake.LevelSpecific.Hopscotch.FidgetSpinner;
import Vino.PlayerHealth.PlayerHealthStatics;

class UFidgetSpinnerCapability : UHazeCapability
{

	AFidgetSpinner FidgetSpinner;
	AHazePlayerCharacter Player;

	UPROPERTY()
	UCurveFloat Curve;

	UPROPERTY()
	float DirectionMultiplier;
	default DirectionMultiplier = 1000.f;

	UPROPERTY()
	float SpinRateMultiplier;
	default SpinRateMultiplier = 1000.f;	

	UPROPERTY()
    TSubclassOf<UPlayerDeathEffect> DeathEffect;	
	
	float ZForceMultiplier;
	float Gravity;
	float CurveTimer;
	float MinCurveTime;
	float MaxCurveTime;
	float SpinRate;
	bool bWasLaunched;
	bool bFidgetSpinnerWasDestroyed;

	default CapabilityTags.Add(n"Example");
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	FHazeAcceleratedRotator AcceleratedRot; 
	FRotator AccelRot;
	FRotator RotationLastTick;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"PlayerOnFidgetSpinner"))
        	return EHazeNetworkActivation::ActivateFromControl;

		else
        	return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"PlayerOnFidgetSpinner"))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FidgetSpinner = Cast<AFidgetSpinner>(GetAttributeObject(n"FidgetSpinner"));
		FidgetSpinner.EnableInteractionCollision(false);

		ZForceMultiplier = GetAttributeValue(n"ZForceMultiplier");
		Gravity = GetAttributeValue(n"Gravity");

		Curve.GetTimeRange(MinCurveTime, MaxCurveTime);

		Player.AttachToActor(FidgetSpinner);

		Owner.BlockCapabilities(n"Movement", this);
        Owner.BlockCapabilities(n"Collision", this);
        Owner.BlockCapabilities(n"Interaction", this);
        Owner.BlockCapabilities(n"TotemMovement", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		FidgetSpinner.EnableInteractionCollision(true);
		FidgetSpinner.PlayerHoppedOffFidgetSpinner();
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		ResetValues();

		Owner.UnblockCapabilities(n"Movement", this);
        Owner.UnblockCapabilities(n"Collision", this);
        Owner.UnblockCapabilities(n"Interaction", this);
        Owner.UnblockCapabilities(n"TotemMovement", this);

		if (bFidgetSpinnerWasDestroyed)
			FidgetSpinner.DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (WasActionStarted(ActionNames::PrimaryLevelAbility) && !IsActioning(n"FidgetShouldSpin"))
			Player.SetCapabilityActionState(n"PlayerOnFidgetSpinner", EHazeActionState::Inactive);
		
		if (IsPlayerDead(Player))
		{
			Player.SetCapabilityActionState(n"PlayerOnFidgetSpinner", EHazeActionState::Inactive);
			bFidgetSpinnerWasDestroyed = true;
		}

		if (IsActioning(n"FidgetShouldSpin"))
		{
			SpinFidgetSpinner();
		
			if (!bWasLaunched)
				LaunchFidgetSpinner();

			else
				FidgetSpinnerGoingDown(DeltaTime);
		}

	}

	void LaunchFidgetSpinner()
	{
		float FidgetSpinnerZForce;

		FidgetSpinnerZForce = Curve.GetFloatValue(CurveTimer);
		CurveTimer += FidgetSpinner.ActorDeltaSeconds;		

		if (CurveTimer <= MaxCurveTime)
		{
			FHitResult Hit;
			FidgetSpinner.AddActorWorldOffset(FVector(0, 0, FidgetSpinnerZForce * ZForceMultiplier) * FidgetSpinner.ActorDeltaSeconds, true, Hit, false);
		}

		else 
			bWasLaunched = true;
	}

	void FidgetSpinnerGoingDown(float DeltaTime)
	{
		FHitResult Hit;
		FVector StickDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
		StickDirection = StickDirection * DirectionMultiplier;
		FidgetSpinner.AddActorWorldOffset(FVector(StickDirection.X, StickDirection.Y, -Gravity) * FidgetSpinner.ActorDeltaSeconds, true, Hit, false);

		TiltFidgetSpinner(StickDirection, DeltaTime);
		
		if (Hit.bBlockingHit)
		{
			if (FidgetSpinner.LandedOnLandingpad())
			{
				Player.SetCapabilityActionState(n"PlayerOnFidgetSpinner", EHazeActionState::Inactive);
				FidgetSpinner.DestroyFidgetSpinner(false);
			} else 
			{
				Player.SetCapabilityActionState(n"PlayerOnFidgetSpinner", EHazeActionState::Inactive);
				FidgetSpinner.DestroyFidgetSpinner(true);
				KillPlayer(Player, DeathEffect);
			}
		}
	}

	void TiltFidgetSpinner(FVector StickDirection, float DeltaTime)
	{
		FVector Direction = FVector(FidgetSpinner.GetActorLocation() - FVector(FidgetSpinner.GetActorLocation() + FVector(StickDirection.X, StickDirection.Y, 0.f) * 5000.f));
		Direction.Normalize();

		float YDot;
		if (FMath::IsNearlyZero(StickDirection.Y, 0.05f))
			YDot = 0.f;

		else
			YDot = Direction.DotProduct(-FidgetSpinner.GetActorRightVector());
			YDot *= 30.f;

		float XDot;
		if (FMath::IsNearlyZero(StickDirection.X, 0.05f))
			XDot = 0.f;

		else
			XDot = Direction.DotProduct(FidgetSpinner.GetActorForwardVector());
			XDot *= 30.f;

		FRotator FidgetRotation;
		FidgetRotation = FMath::RInterpTo(RotationLastTick, FRotator(XDot, 0.f, YDot), DeltaTime, 5.f);
		FidgetSpinner.SetActorRotation(FRotator(FidgetRotation.Pitch, FidgetSpinner.ActorRotation.Yaw, FidgetRotation.Roll));

		RotationLastTick = FidgetRotation;
	}

	void SpinFidgetSpinner()
	{
		SpinRate = SpinRateMultiplier * Curve.GetFloatValue(CurveTimer) * FidgetSpinner.ActorDeltaSeconds;
		FidgetSpinner.AddActorLocalRotation(FRotator(0.f, SpinRate, 0.f));
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagRemoved(FName Tag)
	{

	}

	void ResetValues()
	{
		bWasLaunched = false;
		CurveTimer = 0.f;
	}
}