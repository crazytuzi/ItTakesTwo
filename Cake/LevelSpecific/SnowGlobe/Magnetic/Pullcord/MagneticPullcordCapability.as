import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Pullcord.MagneticPullcordActor;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;

class UMagneticPullcordCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MagnetCapability");
	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

    AMagneticPullcordActor PullcordActor;
    UMagnetGenericComponent MagnetComponent;

	float HandleVelocity = 0.0f;
	float Drag = 2.5f;
	float Acceleration = 10.0f;

	float AddedDistance = 0.0f;

	bool bBackToOriginal = false;
	bool bReachedEnd = false;
	bool bHatchFinished = true;

	bool bDeactivationCalled = false;

	bool bStartTimer = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PullcordActor = Cast<AMagneticPullcordActor>(Owner);
        MagnetComponent = UMagnetGenericComponent::Get(Owner);
		PullcordActor.OnMagneticPullcordHatchFinished.AddUFunction(this, n"OnHatchFinished");
		PullcordActor.OnMagneticPullcordReset.AddUFunction(this, n"ResetPullcord");
		PullcordActor.OnMagneticPullcordStartTimer.AddUFunction(this, n"StartTimer");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (IsActioning(n"MagneticInteraction"))
			return EHazeNetworkActivation::ActivateFromControl;
        else
            return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsActioning(n"MagneticInteraction"))
            return EHazeNetworkDeactivation::DontDeactivate;
		if(!bBackToOriginal)
            return EHazeNetworkDeactivation::DontDeactivate;
		if(PullcordActor.bIsLockedInActivation)
            return EHazeNetworkDeactivation::DontDeactivate;
        else
            return EHazeNetworkDeactivation::DeactivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bBackToOriginal = false;
	}


	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		HandleVelocity = 0.0f;
		PullcordActor.LockedInActivationTimer = 0.0f;
		bReachedEnd = false;
		PullcordActor.bIsLockedInActivation = false;
	}

	UFUNCTION()
	void ResetPullcord()
	{
		bReachedEnd = false;
		PullcordActor.bIsLockedInActivation = false;
		bHatchFinished = false;
		bDeactivationCalled = false;
		
		if (HasControl())
			NetBroadCastOnPullCordHatchOpen();
	}

	UFUNCTION(NetFunction)
	void NetBroadCastOnPullCordHatchOpen()
	{
		PullcordActor.OnMagneticPullcordHatchOpen.Broadcast();
	}

	UFUNCTION(NetFunction)
	void NetBroadCastOnMagneticPullCordDeactivated()
	{
		PullcordActor.OnMagneticPullcordDeactivated.Broadcast();
	}



	UFUNCTION()
	void StartTimer()
	{
		bStartTimer = true;
	}

	UFUNCTION()
	void OnHatchFinished()
	{
		bHatchFinished = true;

		if(!bReachedEnd && MagnetComponent.bIsDisabled)
			NetSetMagneticComponentDisabled(false);
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(HasControl())
		{
			if(PullcordActor.bIsLockedInActivation && !bDeactivationCalled && bStartTimer)
			{
				PullcordActor.LockedInActivationTimer += DeltaTime;
				if(PullcordActor.LockedInActivationTimer >= PullcordActor.LockedInActivationDuration)
				{
					PullcordActor.LockedInActivationTimer = 0.0f;
					NetBroadCastOnMagneticPullCordDeactivated();
					bDeactivationCalled = true;
					bStartTimer = false;
					bHatchFinished = false;
					bReachedEnd = false;
				}
				PullcordActor.SyncLockedInActivationTimer.Value = PullcordActor.LockedInActivationTimer;
				return;
			}
			
			if(!bHatchFinished && !bReachedEnd)
				return;

			float DeltaMovement = 0.0f;

			TArray<AHazePlayerCharacter> InflueningPlayers;
			MagnetComponent.GetInfluencingPlayers(InflueningPlayers);

			if(InflueningPlayers.Num() > 0)
				CalculateForceFromPlayers(DeltaTime);

			HandleVelocity -= HandleVelocity * Drag * DeltaTime;
			DeltaMovement = HandleVelocity * DeltaTime;

			if(InflueningPlayers.Num() <= 0)
				DeltaMovement = CalculateMovementWithoutPlayers(DeltaTime);

			if(InflueningPlayers.Num() >= 0 && (AddedDistance + DeltaMovement) > PullcordActor.Spline.SplineLength && !bReachedEnd)
			{
				DeltaMovement = PullcordActor.Spline.SplineLength - AddedDistance;

				if(InflueningPlayers.Num() > 0)
				{
					NetBroadCastOnMagneticPullCordActivated(InflueningPlayers[0]);
				}
					
				else
				{
					NetBroadCastOnMagneticPullCordActivated(nullptr);
				}

				NetBroadOnMagneticPullcordHatchClose();			
				NetSetMagneticComponentDisabled(true);
				bReachedEnd = true;
			}
			else if((AddedDistance + DeltaMovement) < PullcordActor.ActivatedDistance)
			{
				DeltaMovement = PullcordActor.ActivatedDistance - AddedDistance;
			}

			PullcordActor.HandleMesh.AddRelativeLocation(FVector(DeltaMovement, 0, 0));
			AddedDistance += DeltaMovement;
			PullcordActor.SyncLocalPosition.Value = PullcordActor.HandleMesh.RelativeLocation;

			if(InflueningPlayers.Num() <= 0)
			{
				if(!bReachedEnd && FMath::IsNearlyZero(AddedDistance, 0.1f))
				{
					bBackToOriginal = true;
				}
				else if(bReachedEnd && FMath::IsNearlyEqual(AddedDistance, PullcordActor.ActivatedDistance, 0.1f))
				{
					HandleVelocity = 0.0f;
					PullcordActor.bIsLockedInActivation = true;
				}
			}
		}
		else
		{
			PullcordActor.HandleMesh.SetRelativeLocation(PullcordActor.SyncLocalPosition.Value);
			PullcordActor.LockedInActivationTimer = PullcordActor.SyncLockedInActivationTimer.Value;
		}
	}

	UFUNCTION(NetFunction)
	void NetSetMagneticComponentDisabled(bool bDisabled)
	{
		MagnetComponent.bIsDisabled = bDisabled;
	}

	UFUNCTION(NetFunction)
	void NetBroadCastOnMagneticPullCordActivated(AHazePlayerCharacter Player)
	{
		PullcordActor.OnMagneticPullcordActivated.Broadcast(Player);
	}

	UFUNCTION(NetFunction)
	void NetBroadOnMagneticPullcordHatchClose()
	{
		PullcordActor.OnMagneticPullcordHatchClose.Broadcast();	
	}

	void CalculateForceFromPlayers(float DeltaTime)
	{
		TArray<AHazePlayerCharacter> Players;
		MagnetComponent.GetInfluencingPlayers(Players);
		for(AHazePlayerCharacter Player : Players)
		{
			FVector ToMagnetDir = MagnetComponent.WorldLocation - PullcordActor.ActorLocation;
			FVector ToPlayerDir = Player.ActorLocation - MagnetComponent.WorldLocation;

			FVector Forward = PullcordActor.ActorForwardVector;
			float Force = ToPlayerDir.DotProduct(Forward);

			if(!MagnetComponent.HasOppositePolarity(UMagneticComponent::Get(Player)))
			{
				Force = -Force;
			}
					
			HandleVelocity += Force * Acceleration * DeltaTime;
		}
	}

	float CalculateMovementWithoutPlayers(float DeltaTime)
	{
		float NewDeltaMove = 0.0f;
		if(!bReachedEnd)
		{
			float DeaccelerationSpeed = PullcordActor.ReturnAccelerationSpeed;
			if(AddedDistance > 0)
				DeaccelerationSpeed *= -1;

			HandleVelocity += DeaccelerationSpeed * DeltaTime;
			NewDeltaMove = HandleVelocity * DeltaTime;

			if(AddedDistance > 0 && (AddedDistance + NewDeltaMove) < 0)
			{
				NewDeltaMove = AddedDistance * -1;
			}
			else if(AddedDistance < 0 && (AddedDistance + NewDeltaMove) > 0)
			{
				NewDeltaMove = AddedDistance * -1;
			}
			
		}
		else
		{
			float DeaccelerationSpeed = PullcordActor.ReturnAccelerationSpeed;
			if(AddedDistance > PullcordActor.ActivatedDistance)
				DeaccelerationSpeed *= -1;

			HandleVelocity += DeaccelerationSpeed * DeltaTime;
			NewDeltaMove = HandleVelocity * DeltaTime;

			if(AddedDistance > PullcordActor.ActivatedDistance && (AddedDistance + NewDeltaMove) < PullcordActor.ActivatedDistance)
			{
				NewDeltaMove = PullcordActor.ActivatedDistance - AddedDistance;
			}
			else if(AddedDistance < PullcordActor.ActivatedDistance && (AddedDistance + NewDeltaMove) > PullcordActor.ActivatedDistance)
			{
				NewDeltaMove = PullcordActor.ActivatedDistance - AddedDistance;
			}
		}
		return NewDeltaMove;
	}
}