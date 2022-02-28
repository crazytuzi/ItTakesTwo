import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.CastleAbilityCapability;

class UCastleMageBlinkAbility : UCastleAbilityCapability
{    
    default CapabilityTags.Add(n"AbilityBlink");

    UPROPERTY()
    float Cooldown = 0.6f;
    UPROPERTY()
    float CooldownCurrent = 0.f;

    UPROPERTY()
    bool bBlinkComplete = true;
    UPROPERTY()
    float BlinkDistance = 650;
    UPROPERTY()
    FVector BlinkStartLocation;
    UPROPERTY()
    FVector BlinkEndLocation;
	UPROPERTY()
    float BlinkStepUpHeight = 100.f;

    UPROPERTY()
    FHazeTimeLike MovementTimelike;
    default MovementTimelike.Duration = 0.2;

    UPROPERTY()
    FHazeTimeLike ScaleTimelike;    
    default ScaleTimelike.Duration = 0.2;

    UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

        OwningPlayer = Cast<AHazePlayerCharacter>(Owner);
        MoveComponent = UHazeBaseMovementComponent::Get(Owner);
        CastleComponent = UCastleComponent::Get(Owner);

        MovementTimelike.BindUpdate(this, n"OnMovementTimelikeUpdate");
        ScaleTimelike.BindUpdate(this, n"OnScaleTimelikeUpdate");
        ScaleTimelike.BindFinished(this, n"OnScaleTimelikeFinished");
	}

    UFUNCTION()
    void OnMovementTimelikeUpdate(float CurrentValue)
    {
        FVector UpdatedLocation;
        UpdatedLocation = FMath::Lerp(BlinkStartLocation, BlinkEndLocation, CurrentValue);

		MoveComponent.SetControlledComponentTransform(UpdatedLocation, OwningPlayer.ActorRotation);
        //Owner.SetActorLocation(UpdatedLocation);
    }

    UFUNCTION()
    void OnScaleTimelikeUpdate(float CurrentValue)
    {
        FVector UpdatedScale;
        UpdatedScale = FMath::Lerp(FVector::ZeroVector, FVector::OneVector, CurrentValue);

		OwningPlayer.Mesh.SetWorldScale3D(UpdatedScale);
        //Owner.SetActorScale3D(UpdatedScale);
    }

    UFUNCTION()
    void OnScaleTimelikeFinished()
    {
        bBlinkComplete = true;
    }

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (WasActionStarted(ActionNames::CastleAbilityDash) && CooldownCurrent <= 0.f)
            return EHazeNetworkActivation::ActivateFromControl;
        else
            return EHazeNetworkActivation::DontActivate;       
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (bBlinkComplete)
            return EHazeNetworkDeactivation::DeactivateLocal;
                    
        return EHazeNetworkDeactivation::DontDeactivate;
	}
    
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {
        CooldownCurrent = Cooldown;

        BlinkStartLocation = OwningPlayer.ActorLocation;
        BlinkEndLocation = CalculateBlinkEndLocation();

        MovementTimelike.PlayFromStart();
        ScaleTimelike.PlayFromStart();
		OwningPlayer.AddPlayerInvulnerability(this);
	}

    FVector CalculateBlinkEndLocation()
    {
		FVector BlinkMovement;
		
		if (GetAttributeVector(AttributeVectorNames::MovementDirection).Size() >= 0.1f)
            BlinkMovement = GetAttributeVector(AttributeVectorNames::MovementDirection).GetSafeNormal() * BlinkDistance;
        else
            BlinkMovement = Owner.ActorForwardVector * BlinkDistance;

		// HI TOM
		FVector CurrentBlinkEndLocation = OwningPlayer.ActorLocation + BlinkMovement;

        TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Add(OwningPlayer);
        FHitResult Hit;

        FVector TraceStartLocation; 
        FVector TraceEndLocation;		
	
		TraceStartLocation = CurrentBlinkEndLocation + (FVector::UpVector * BlinkStepUpHeight);
		TraceEndLocation = CurrentBlinkEndLocation;

		System::CapsuleTraceSingle(
            TraceStartLocation, TraceEndLocation,
            OwningPlayer.CapsuleComponent.CapsuleRadius,
            OwningPlayer.CapsuleComponent.CapsuleHalfHeight,
            ETraceTypeQuery::Visibility, false, ActorsToIgnore,
            EDrawDebugTrace::None, Hit, true);

		// If you don't hit anything, blink here;
		if (!Hit.bBlockingHit)
		{
			CurrentBlinkEndLocation = TraceEndLocation;
			return CurrentBlinkEndLocation;
		}	
		else
		{
			// If the end location is not safe
			if (Hit.GetbStartPenetrating())
			{
				TArray<FHitResult> Hits;
					
				TraceStartLocation = OwningPlayer.ActorLocation + (FVector::UpVector * BlinkStepUpHeight);
				TraceEndLocation = BlinkEndLocation + (FVector::UpVector * BlinkStepUpHeight);		

				Trace::CapsuleTraceMultiAllHitsByChannel(TraceStartLocation, TraceEndLocation, OwningPlayer.GetActorQuat(),
					OwningPlayer.CapsuleComponent.CapsuleRadius,
					OwningPlayer.CapsuleComponent.CapsuleHalfHeight,
					ETraceTypeQuery::Visibility, false, ActorsToIgnore,
					Hits);

				for (int Index = (Hits.Num() - 1), Count = Hits.Num(); Index >= 0; --Index)
				{
					FHitResult PlantingHit;
					FVector HitTraceStartLocation = Hits[Index].Location - (TraceEndLocation - TraceStartLocation).GetSafeNormal();
					FVector HitTraceEndLocation = HitTraceStartLocation - (FVector::UpVector * BlinkStepUpHeight);		

					System::CapsuleTraceSingle(
						HitTraceStartLocation, HitTraceEndLocation,
						OwningPlayer.CapsuleComponent.CapsuleRadius,
						OwningPlayer.CapsuleComponent.CapsuleHalfHeight,
						ETraceTypeQuery::Visibility, false, ActorsToIgnore,
						EDrawDebugTrace::None, PlantingHit, true);

					if (!PlantingHit.bStartPenetrating)
					{
						if (PlantingHit.bBlockingHit)
						{
							BlinkEndLocation = PlantingHit.Location - OwningPlayer.CapsuleComponent.RelativeLocation;
							return BlinkEndLocation;
						}
						else 
						{
							BlinkEndLocation = PlantingHit.TraceEnd - OwningPlayer.CapsuleComponent.RelativeLocation;
							return BlinkEndLocation;
						}
					}
				}			
			
				return OwningPlayer.ActorLocation;
			}
			else
			{
				// Blink up a step only
				BlinkEndLocation = Hit.Location - OwningPlayer.CapsuleComponent.RelativeLocation;
				return BlinkEndLocation;
			}			
		}
    }

    UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
    {
        if (CooldownCurrent > 0)
            CooldownCurrent -= DeltaTime;
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		OwningPlayer.RemovePlayerInvulnerability(this);
    }
}
