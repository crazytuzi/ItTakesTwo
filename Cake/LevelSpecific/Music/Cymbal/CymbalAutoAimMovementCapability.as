import Cake.LevelSpecific.Music.Cymbal.CymbalMovementBaseCapability;

class UCymbalAutoAimMovementCapability : UCymbalMovementBaseCapability
{
	USceneComponent CurrentAutoAimTarget;
	
	const float CrumbInterpSpeed = 15000.0f;
	bool bSeekTarget = true;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!CymbalComp.bStartMoving)
			return EHazeNetworkActivation::DontActivate;

		if(Cymbal.AutoAimTarget == nullptr)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		bSeekTarget = true;
		TArray<AActor> _IgnoreActors;
		_IgnoreActors.Add(Game::GetCody());
		_IgnoreActors.Add(Game::GetMay());
		_IgnoreActors.Add(Cymbal.AutoAimTarget.Owner);
		CymbalMovement.StartMovement(Owner.ActorCenterLocation, AutoAimLocation, Settings.MaximumMovementAngle, Settings.MovementSpeed, _IgnoreActors, false, PredictionLag);
		AcceleratedLocation.SnapTo(Owner.ActorCenterLocation);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(CymbalComp.bCymbalEquipped)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Cymbal.AutoAimTarget == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(IsPlayerDead(OwningPlayer))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!bSeekTarget && CymbalMovement.HasReachedLocation())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);
		CurrentAutoAimTarget = Cymbal.AutoAimTarget = nullptr;
		CymbalComp.bCymbalWasCaught = true;

#if !RELEASE
		if(CVar_CymbalDebugDraw.GetInt() == 1)
		{
			System::DrawDebugLine(CymbalLocation, AutoAimLocation, FLinearColor::Green, 3.0f, 6.0f);
		}
#endif // !RELEASE
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		FCymbalMovementOutput Output;

		float RealDeltaTime = DeltaTime * OwningPlayer.ActorTimeDilation;
		
		if(bSeekTarget)
		{
			if(HasAutoAimTarget())
			{
				
				CymbalMovement.MoveWithBezier(RealDeltaTime, AutoAimLocation, Output, Cymbal.bDebugDrawMovement);

				if(CymbalMovement.HasReachedLocation())
				{
					// Generate some data we need for HitInfo.
					UPrimitiveComponent Primitive = UPrimitiveComponent::Get(Cymbal.AutoAimTarget.Owner);
					FVector HitLocation = Cymbal.ActorCenterLocation;

					if(Primitive != nullptr)
						Primitive.GetClosestPointOnCollision(Cymbal.ActorCenterLocation, HitLocation);

					Cymbal.OnCymbalHit(Cymbal.AutoAimTarget, Primitive, HitLocation, Output.Rotation.Vector(), true);

					if(Cymbal.AutoAimTarget.bPlayVFXOnHit)
					{
						FVector FacingDirection = Output.Rotation.Vector().GetSafeNormal() * -1.0f;
						Cymbal.PlayImpactVFX(FacingDirection, UCymbalHitVFXComponent::Get(Cymbal.AutoAimTarget.Owner));
					}
					
					//System::DrawDebugArrow(Output.Location, Output.Location + FacingDirection * 450.0f, 10, FLinearColor::Red, 5, 10);
					
					StartReturnToOwner();
				}
			}
			else
			{
				StartReturnToOwner();
			}
			
		}
		else	// We return to owner.
		{
			CymbalMovement.MoveWithBezier(RealDeltaTime, Cymbal.OwnerPlayer.ActorCenterLocation, Output);
		}

		MoveCymbal(RealDeltaTime, Output);
	}

	FHitResult CreateHitResultFromAutoAimTarget() const
	{
		if(Cymbal.AutoAimTarget == nullptr)
		{
			devEnsure(false, "Attempting to create FHitResult for auto aim with no auto aim.");
			return FHitResult();
		}

		// What we do here to simulate a hit by filling in information required by HandleCymbalHit.
		FHitResult _Hit;
		_Hit.SetActor(Cymbal.AutoAimTarget.Owner);
		_Hit.SetbStartPenetrating(false);
		_Hit.SetBlockingHit(true);
		_Hit.TraceStart = CymbalLocation;
		_Hit.TraceEnd = AutoAimLocation;
		
		// Now awe are attempting to locate any kind of PrimitiveComponent
		UPrimitiveComponent Primitive = Cast<UPrimitiveComponent>(Cymbal.AutoAimTarget.Owner.GetComponentByClass(UPrimitiveComponent::StaticClass()));

		if(Primitive != nullptr)
		{
			Primitive.GetClosestPointOnCollision(CymbalLocation, _Hit.ImpactPoint);
			_Hit.SetComponent(Primitive);
		}
		else
		{
			_Hit.ImpactPoint = AutoAimLocation;
		}
		
		return _Hit;
	}

	FVector GetAutoAimLocation() const property
	{
		return Cymbal.AutoAimTarget.WorldLocation;
	}

	bool HasAutoAimTarget() const
	{
		return Cymbal.AutoAimTarget != nullptr;
	}

	void StartReturnToOwner()
	{
		bSeekTarget = false;
		TArray<AActor> _IgnoreActors = IgnoreActors;

		if(Cymbal.AutoAimTarget != nullptr)
			_IgnoreActors.Add(Cymbal.AutoAimTarget.Owner);

		CymbalMovement.ReturnToOwner(Cymbal.ActorCenterLocation, Cymbal.OwnerPlayer.ActorCenterLocation, Settings.MaximumMovementAngle, Settings.MovementSpeed, _IgnoreActors, false, PredictionLag);
	}
}
