import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;
import Cake.LevelSpecific.Music.Cymbal.CymbalMovementInfo;

struct FNetCymbalHitInfo
{
	FVector DeltaMovement;
	FVector HitLocation;
	UCymbalImpactComponent ImpactComponent;
	UPrimitiveComponent HitComponent;
}

UCLASS(abstract)
class UCymbalMovementBaseCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default CapabilityTags.Add(n"Cymbal");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 10;

	//FVector ForwardDirection;

	ACymbal Cymbal;
	UCymbalComponent CymbalComp;
	AHazePlayerCharacter OwningPlayer;
	UCymbalSettings Settings;

	UHazeCrumbComponent PlayerCrumbComp;

	float Acceleration = 1.0f;
	float HitDistanceMinimum = 200.0f;	// How close to the target we considered it being a "hit".

	FCymbalMovement CymbalMovement;
	FRotator CurrentRotation;
	FHazeAcceleratedVector AcceleratedLocation;
	FHazeAcceleratedVector OffsetVector;
	FHazeAcceleratedVector LastOffsetVector;

	protected TArray<AActor> IgnoreActors;

	FHitResult Hit;

	bool bReturnToOwner = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Cymbal = Cast<ACymbal>(Owner);
		OwningPlayer = Cast<AHazePlayerCharacter>(Cymbal.Owner);
		CymbalComp = UCymbalComponent::Get(OwningPlayer);
		Settings = UCymbalSettings::GetSettings(Owner);
		PlayerCrumbComp = UHazeCrumbComponent::Get(Cymbal.Owner);

		IgnoreActors.Add(Game::Cody);
		IgnoreActors.Add(Game::May);
		IgnoreActors.Add(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ValidationParams) const
	{
		return CymbalComp.bStartMoving;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		//ForwardDirection = Cymbal.StartDirection;
		CymbalComp.DetachCymbalFromPlayer();
		Acceleration = 0.0f;
		CymbalComp.bStartMoving = false;
		Cymbal.SetActorRotation(FRotator::ZeroRotator);
		Cymbal.CymbalMesh.RelativeRotation = FRotator(-90.0f, 0.0f, 0.0f);
		Cymbal.StartLocation = Cymbal.ActorCenterLocation;
		Cymbal.bIsMoving = true;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& Params)
	{
		if(IsPlayerDead(OwningPlayer))
		{
			Params.AddActionState(n"PlayerDead");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Cymbal.SetTrailVisibility(false);
		Cymbal.AutoAimTarget = nullptr;

		if(IsPlayerDead(OwningPlayer))
		{
			CymbalComp.AttachCymbalToBack();
		}

		Cymbal.bIsMoving = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Spin it
		Cymbal.CymbalMesh.AddRelativeRotation(FRotator(0.0f, 0.0f, Cymbal.RotationSpeed * DeltaTime));

		// Force feedback
		float DistanceToPlayer = Cymbal.GetDistanceTo(OwningPlayer);
		float DistanceAlpha = DistanceToPlayer/Settings.MovementDistanceMaximum;
		float ForceFeedbackMultiplier = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.f), FVector2D(0.7f, 0.05f), DistanceAlpha);
		OwningPlayer.SetFrameForceFeedback(ForceFeedbackMultiplier, 0.f);
	}

	USceneComponent GetAutoAimTargetComponent() const property
	{
		return Cymbal.AutoAimTarget;
	}

	// We are testing to see if the movement caused us to move through the target location here, or if we are close enough.
	bool HitTargetLocation(FVector TargetLocation, FVector DeltaMovement) const
	{
		// Check if we will pass through the auto aim target
		const FVector NewCymbalLocation = CymbalLocation + DeltaMovement;
		const FVector PreviousDirection = (TargetLocation - CymbalLocation).GetSafeNormal();
		const FVector NextDirection = (TargetLocation - NewCymbalLocation).GetSafeNormal();
		const float DirectionDot = NextDirection.DotProduct(PreviousDirection);

		const bool bCloseEnough = TargetLocation.DistSquared(NewCymbalLocation) < FMath::Square(HitDistanceMinimum);
		const bool bPassedThrough = DirectionDot < 0.0f;

		return bCloseEnough || bPassedThrough;
	}

	void MoveCymbal(float DeltaTime, FCymbalMovementOutput Output)
	{
		CurrentRotation = FQuat::Slerp(CurrentRotation.Quaternion(), Output.Rotation.Quaternion(), DeltaTime * 3.0f).Rotator();
		AcceleratedLocation.AccelerateTo(Output.Location + OffsetVector.Value + LastOffsetVector.Value, 0.15f, DeltaTime);
		
		FVector Dir = (CymbalMovement.TargetLocation - CymbalMovement.StartLocation).GetSafeNormal();
		FVector TraceDir = Dir;
		const float TraceLength = 400.0f;
		const float AngleRotation = 40.0f;
		TraceDir = TraceDir.RotateAngleAxis(AngleRotation, FVector::UpVector);
		//System::DrawDebugArrow(AcceleratedLocation.Value, AcceleratedLocation.Value + TraceDir * 600.0f, 10.0f, FLinearColor::Red, 0, 10.0f);

		Hit.Reset();
		const FVector StartTraceLoc = Output.Location + OffsetVector.Value + LastOffsetVector.Value;
		const FVector EndTraceLoc = StartTraceLoc + TraceDir * (TraceLength + OffsetVector.Value.Size());
		System::LineTraceSingle(StartTraceLoc, EndTraceLoc, ETraceTypeQuery::Visibility, false, IgnoreActors, EDrawDebugTrace::None, Hit, false);
		//PrintToScreen("Length: " + OffsetVector.Value.Size());

		const float AlphaCurrent = CymbalMovement.AlphaCurrent;
		const bool bCloseToHome = CymbalMovement.AlphaCurrent > 0.75f;

		if(Hit.bBlockingHit && !bCloseToHome)
		{
			const float AngleFraction = AngleRotation / 90.0f;
			FVector OffsDir = Dir.RotateAngleAxis(-90.0f, FVector::UpVector) * ((TraceLength - Hit.Distance));
			OffsetVector.AccelerateTo(OffsDir, 0.6f, DeltaTime);
		}
		else
		{
			OffsetVector.AccelerateTo(FVector::ZeroVector, 0.6f, DeltaTime);
		}

		if(bReturnToOwner)
		{
			LastOffsetVector.AccelerateTo(FVector::ZeroVector, (bCloseToHome ? 0.25f : 1.75f), DeltaTime);
		}

		Cymbal.SetActorLocationAndRotation(AcceleratedLocation.Value, CurrentRotation);
	}

	void PlayCymbalHitSound()
	{
		OwningPlayer.SetCapabilityActionState(n"AudioOnCymbalHit", EHazeActionState::ActiveForOneFrame);
	}

	void OnCymbalHit_Net(FHitResult Hit, FVector DeltaMovement)
	{
		UCymbalImpactComponent CymbalImpact = UCymbalImpactComponent::Get(Hit.Actor);

		if(CymbalImpact != nullptr)
		{
			FNetCymbalHitInfo HitInfo;
			HitInfo.DeltaMovement = DeltaMovement;
			HitInfo.HitLocation = Hit.ImpactPoint;
			HitInfo.ImpactComponent = CymbalImpact;
			HitInfo.HitComponent = Hit.Component;
			NetHandleHit(HitInfo);
		}
	}

	UFUNCTION(NetFunction)
	private void NetHandleHit(FNetCymbalHitInfo NetHitInfo)
	{
		FCymbalHitInfo HitInfo;
		HitInfo.HitLocation = NetHitInfo.HitLocation;
		HitInfo.HitComponent = NetHitInfo.HitComponent;

		HitInfo.DeltaMovement = Owner.ActorRotation.Vector();
		HitInfo.Owner = Owner;
		HitInfo.Instigator = Cast<AHazeActor>(Cymbal.Owner);
		HitInfo.bAutoAimHit = false;
		NetHitInfo.ImpactComponent.CymbalHit(HitInfo);
	}

	UFUNCTION()
	private void HandleCrumb_Impact(FHazeDelegateCrumbData CrumbParams)
	{
		FCymbalHitInfo HitInfo;
		HitInfo.HitLocation = CrumbParams.GetVector(n"HitLocation");
		HitInfo.HitComponent = Cast<UPrimitiveComponent>(CrumbParams.GetObject(n"HitComponent"));
		UCymbalImpactComponent CymbalImpactComponent = Cast<UCymbalImpactComponent>(CrumbParams.GetObject(n"CymbalImpactComponent"));

		HitInfo.DeltaMovement = CrumbParams.GetVector(n"DeltaMovement");
		HitInfo.Owner = Owner;
		HitInfo.Instigator = Cast<AHazeActor>(Cymbal.Owner);
		HitInfo.bAutoAimHit = true;
		Cymbal.bReturnToOwner = true;
		Acceleration = -1.0f;
		CymbalImpactComponent.CymbalHit(HitInfo);
		Cymbal.HitLocation = Cymbal.ActorCenterLocation;
		PlayCymbalHitSound();
	}

	FVector GetCymbalLocation() const property
	{
		return Cymbal.ActorCenterLocation;
	}
	
	float GetAccelerationMultiplier() const property
	{
		return 1.0f + Acceleration;
	}

	float GetPredictionLag() const property
	{
		if(!Network::IsNetworked())
			return 0.0f;

		float Lag = PlayerCrumbComp.PredictionLag / 3.0f;

		return HasControl() ? 0.0f : Lag;
	}
}
