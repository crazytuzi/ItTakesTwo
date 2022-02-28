import Cake.LevelSpecific.Clockwork.Fishing.RodBase;

// Controls rotation of the fishing stick
class URodStickCapability : UHazeCapability
{
	default CapabilityTags.Add(n"RodStickCapability");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ARodBase RodBase;

	//*** ROTATION AND PITCH VALUES ***//
	FRotator StartingRotation;
	FRotator CastRotation;
	FRotator ThrowCatchRotation;

	float MaxWindUpPitch = 50.f;
	float CastPitch = -15.f;
	float ThrowCatchPitch = 65.f;

	bool bSwitchToStartRotation;

	//*** NETWORKING ***//
	float NetworkTime;
	float NetworkRate = 0.35f;
	float NetworkAcceleration = 2.8f;
	
	FRotator NetNewRotation;
	FHazeAcceleratedRotator AcceleratedNewRotation;

	EFishingState NetFishingState;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		RodBase = Cast<ARodBase>(Owner);

		// StartingRotation = RodBase.RodAnchor.RelativeRotation;
		// CastRotation = RodBase.RodAnchor.RelativeRotation + FRotator(CastPitch, 0.f, 0.f);
		// ThrowCatchRotation = RodBase.RodAnchor.RelativeRotation + FRotator(ThrowCatchPitch, 0.f, 0.f);

		//*** FOR UPDATING ANIMATION INSTEAD ***//
		StartingRotation = FRotator(0.f, 0.f, 0.f);
		CastRotation = StartingRotation + FRotator(CastPitch, 0.f, 0.f);
		ThrowCatchRotation = StartingRotation + FRotator(ThrowCatchPitch, 0.f, 0.f);

		RodBase.RodBaseComp.RodBend = 0.5f;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
	    return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AcceleratedNewRotation.SnapTo(StartingRotation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (HasControl())
		{
			if (RodBase.PlayerComp != nullptr)
			{
				switch (RodBase.PlayerComp.FishingState)
				{
					case EFishingState::Default:
						RodInterpRotation(StartingRotation, 4.5f, DeltaTime);
						RodBending(DeltaTime, 1.f, 0.5f);
						bSwitchToStartRotation = false;
					break;

					case EFishingState::WindingUp:
						RodWindUpRotation(DeltaTime);
						RodBending(DeltaTime, 1.f, 0.5f);
						bSwitchToStartRotation = false;
					break;

					case EFishingState::Casting:
						RodInterpRotation(CastRotation, 5.f, DeltaTime);
						RodBending(DeltaTime, 1.f, 0.2f);
						bSwitchToStartRotation = false;
					break;

					case EFishingState::Catching:
						RodInterpRotation(CastRotation, 6.2f, DeltaTime);

						if (!RodBase.PlayerComp.bCatchIsHere)
							RodBending(DeltaTime, 1.f, 0.4f);
						else
							RodBending(DeltaTime, 1.f, 0.3f);
							
						bSwitchToStartRotation = false;
					break;

					case EFishingState::Reeling:
						RodBending(DeltaTime, 1.f, 0.3f);
					break;

					case EFishingState::ThrowingCatch:
						if (!bSwitchToStartRotation)
							RodInterpRotation(ThrowCatchRotation, 3.5f, DeltaTime);
						else
							RodInterpRotation(StartingRotation, 5.f, DeltaTime);
					break;
				}

				if (NetworkTime <= System::GameTimeInSeconds)
				{
					NetworkTime = System::GameTimeInSeconds + NetworkRate;
					NetSetFishingState(RodBase.PlayerComp.FishingState);
				}
			}
			else
			{
				RodInterpRotation(StartingRotation, 3.5f, DeltaTime);
			}
		}
		else
		{
			if (RodBase.PlayerComp != nullptr)
			{	
				switch (NetFishingState)
				{
					case EFishingState::Default:
						RodInterpRotation(StartingRotation, 4.5f, DeltaTime);
						bSwitchToStartRotation = false;
					break;

					case EFishingState::WindingUp:
						RodWindUpRotation(DeltaTime);
						bSwitchToStartRotation = false;
					break;

					case EFishingState::Casting:
						RodInterpRotation(CastRotation, 5.f, DeltaTime);
						bSwitchToStartRotation = false;
					break;

					case EFishingState::Catching:
						RodInterpRotation(CastRotation, 6.2f, DeltaTime);
						bSwitchToStartRotation = false;
					break;

					case EFishingState::ThrowingCatch:
						if (!bSwitchToStartRotation)
							RodInterpRotation(ThrowCatchRotation, 3.5f, DeltaTime);
						else
							RodInterpRotation(StartingRotation, 5.f, DeltaTime);
					break;
				}
			}
			else
			{
				RodInterpRotation(StartingRotation, 3.5f, DeltaTime);
			}			
		}
	}
	
	void RodBending(float DeltaTime, float InterpSpeed, float TargetBend)
	{
		RodBase.RodBaseComp.RodBend = FMath::FInterpTo(RodBase.RodBaseComp.RodBend, TargetBend, DeltaTime, InterpSpeed);
	}

	void RodWindUpRotation(float DeltaTime)
	{
		float WindUpPercent = RodBase.PlayerComp.StoredCastPower / RodBase.PlayerComp.MaxCastPower;
		float TargetPitch = MaxWindUpPitch * WindUpPercent; 

		//*** FOR UPDATING ANIMATION INSTEAD ***//
		FRotator NewRotAnim = FRotator(TargetPitch, RodBase.RodBaseComp.RodStickRotation.Yaw, RodBase.RodBaseComp.RodStickRotation.Roll);
		FQuat QuatRotAnim = FQuat::Slerp(RodBase.RodBaseComp.RodStickRotation.Quaternion(), NewRotAnim.Quaternion(), 0.5f);
		RodBase.RodBaseComp.RodStickRotation = QuatRotAnim.Rotator();
	}

	void RodInterpRotation(FRotator TargetRotation, float InterpSpeed, float DeltaTime)
	{
		//*** FOR UPDATING ANIMATION INSTEAD ***//
		FRotator NewRotAnim = FMath::RInterpTo(RodBase.RodBaseComp.RodStickRotation, TargetRotation, DeltaTime, InterpSpeed);
		RodBase.RodBaseComp.RodStickRotation = NewRotAnim;

		if (RodBase.PlayerComp != nullptr)
		{
			if (HasControl())
			{
				if(!bSwitchToStartRotation && RodBase.PlayerComp.FishingState == EFishingState::ThrowingCatch)
				{
					float RotDifference = TargetRotation.Pitch - NewRotAnim.Pitch;
					
					if (RotDifference <= 0.025f)
						bSwitchToStartRotation = true;
				}
			}
			else
			{
				if(!bSwitchToStartRotation && NetFishingState == EFishingState::ThrowingCatch)
				{
					float RotDifference = TargetRotation.Pitch - NewRotAnim.Pitch;
					
					if (RotDifference <= 0.025f)
						bSwitchToStartRotation = true;
				}
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetSetFishingState(EFishingState InputFishingState)
	{
		NetFishingState = InputFishingState;
		RodBase.PlayerComp.FishingState = InputFishingState;
	}

	UFUNCTION(NetFunction)
	void NetRotation(FRotator InputRotation)
	{
		NetNewRotation = InputRotation;
	}
}