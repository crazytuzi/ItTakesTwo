import Cake.LevelSpecific.Music.Cymbal.CymbalMovementBaseCapability;
import Cake.LevelSpecific.Music.MusicWeaponTargetingComponent;

/*
	Used for non-auto-aim targets. does not use crumbs to move.
*/

class UCymbalMovementCapability : UCymbalMovementBaseCapability
{
	float DistanceMovedTotal = 0.0f;

	float SpeedCurrent = 0;
	float SpeedTarget = 0;

	FVector _TargetLocation;
	FVector CurrentLocation;
	FVector DeltaMovement;

	float Elapsed = 0;

	float CymbalMovementSpeed = 0.0f;
	bool bAttachToOwner = false;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Super::Setup(SetupParams);
		Cymbal = Cast<ACymbal>(Owner);
		OwningPlayer = Cast<AHazePlayerCharacter>(Cymbal.Owner);
		CymbalComp = UCymbalComponent::Get(OwningPlayer);
		Settings = UCymbalSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!CymbalComp.bStartMoving)
			return EHazeNetworkActivation::DontActivate;

		if(Cymbal.AutoAimTarget != nullptr)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		CurrentRotation = Cymbal.ActorRotation;
		bReturnToOwner = false;
		DistanceMovedTotal = 0.0f;
		_TargetLocation = Cymbal.TargetLocation;
		CurrentLocation = Cymbal.ActorCenterLocation;
		Elapsed = 0;
		SpeedTarget = SpeedCurrent = Settings.MovementSpeed;
		bAttachToOwner = false;

		const float Alpha = _TargetLocation.DistSquared(Owner.ActorCenterLocation) / FMath::Square(Settings.MovementSpeed);
		CymbalMovementSpeed = FMath::EaseOut(Settings.MovementSpeed, Settings.MovementSpeed * 1.5, Alpha, 2.0f);
		CymbalMovement.StartMovement(Owner.ActorCenterLocation, _TargetLocation, Settings.MaximumMovementAngle, CymbalMovementSpeed, IgnoreActors, true, PredictionLag);
		//System::DrawDebugSphere(Owner.ActorCenterLocation, 50, 12, FLinearColor::Green, 5);
		AcceleratedLocation.SnapTo(Owner.ActorCenterLocation);
		LastOffsetVector.SnapTo(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(CymbalComp.bCymbalEquipped)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(IsPlayerDead(OwningPlayer))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(bAttachToOwner)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);
		CymbalComp.bCymbalWasCaught = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		FCymbalMovementOutput Output;

		float RealDeltaTime = DeltaTime * OwningPlayer.ActorTimeDilation;

		if(!bReturnToOwner)
		{
			CymbalMovement.MoveWithBezier(RealDeltaTime, _TargetLocation, Output, Cymbal.bDebugDrawMovement);

			if(CymbalMovement.HasReachedLocation())
			{
				bReturnToOwner = true;
				
				const FVector StartTraceLoc = Output.Location;
				const FVector TraceDir = (CymbalMovement.TargetLocation - CymbalMovement.StartLocation).GetSafeNormal();
				const FVector EndTraceLoc = StartTraceLoc + TraceDir * 100.0f;
				Hit.Reset();
				System::LineTraceSingle(StartTraceLoc, EndTraceLoc, ETraceTypeQuery::Visibility, false, IgnoreActors, EDrawDebugTrace::None, Hit, false);
				if(Hit.bBlockingHit)
				{
					FVector ReflectionVector = FMath::GetReflectionVector(TraceDir, Hit.ImpactNormal);
					UCymbalHitVFXComponent HitVFXComp = nullptr;
					if(Hit.Actor != nullptr)
						HitVFXComp = UCymbalHitVFXComponent::Get(Hit.Actor);
					Cymbal.PlayImpactVFX(ReflectionVector, HitVFXComp);
					PlayCymbalHitSound();
				}
					
				CymbalMovement.ReturnToOwner(Output.Location, OwningPlayer.ActorCenterLocation, Settings.MaximumMovementAngle, CymbalMovementSpeed, IgnoreActors, true, PredictionLag);
				LastOffsetVector.SnapTo(OffsetVector.Value);
				OffsetVector.SnapTo(FVector::ZeroVector);
			}
		}
		else
		{
			CymbalMovement.ReturnWithBezier(RealDeltaTime, OwningPlayer.ActorCenterLocation, Output, Cymbal.bDebugDrawMovement);

			if(CymbalMovement.HasReachedLocation())
			{
				bAttachToOwner = true;

			}
		}

		MoveCymbal(RealDeltaTime, Output);
	}

	void CymbalHitWall()
	{
		bReturnToOwner = true;
		
		if(SpeedCurrent > 0.0f)
			SpeedCurrent = SpeedCurrent * -1.0f;

		if(SpeedTarget > 0.0f)
			SpeedTarget = SpeedTarget * -1.0f;
	}

	void ReturnToOwner()
	{
		if(!bReturnToOwner)
		{
			bReturnToOwner = true;
			SpeedTarget = SpeedCurrent * -1.0f;	// Flip speed right away so we instantly reverse without delay.
		}
	}

	private FVector GetAutoAimLocation() const
	{
		devEnsure(Cymbal.AutoAimTarget != nullptr, "Attempting to get location from auto aim target with no valid pointer.");
		return Cymbal.AutoAimTarget != nullptr ? Cymbal.AutoAimTarget.WorldLocation : FVector::ZeroVector;
	} 

	private FVector GetCymbalLocation() const
	{
		return Cymbal.ActorLocation;
	}

	FVector GetTargetLocation() const
	{
		return bReturnToOwner ? Cymbal.OwnerPlayer.ActorCenterLocation : _TargetLocation;
	}
}
