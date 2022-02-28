import Cake.LevelSpecific.Clockwork.Fishing.RodBase;

// Controls location of the line and material qualities
class URodFishLineCapability : UHazeCapability
{
	default CapabilityTags.Add(n"RodFishLineCapability");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	//*** GENERAL SETUP ***//
	ARodBase RodBase;
	EFishingState NetFishingState;

	//*** NETWORKING ***//
	float NetworkTime;
	float NetworkRate = 0.35f;
	float NetworkAcceleratedDefaultTime = 2.8f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		RodBase = Cast<ARodBase>(Owner);
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
	void TickActive(float DeltaTime)
	{	
		if (RodBase.PlayerComp != nullptr)
		{
			if (HasControl())
			{
				switch(RodBase.PlayerComp.FishingState)
				{
					case EFishingState::Default:
						RodBase.Slack = FMath::FInterpTo(RodBase.Slack, RodBase.DefaultSlackTarget, DeltaTime, 0.9f);
						RodBase.Wind = FMath::FInterpTo(RodBase.Wind, RodBase.DefaultWindTarget, DeltaTime, 0.9f);
					break;

					case EFishingState::Casting:
						RodBase.Slack = FMath::FInterpTo(RodBase.Slack, RodBase.NextCastSlackTarget, DeltaTime, 2.3f);
						RodBase.Wind = FMath::FInterpTo(RodBase.Wind, RodBase.AfterCastWindTarget, DeltaTime, 2.3f);
					break;

					case EFishingState::Catching:
						if (!RodBase.PlayerComp.bCatchIsHere)
						{
							RodBase.Slack = FMath::FInterpTo(RodBase.Slack, RodBase.CatchingCastSlackTarget, DeltaTime, 1.1f);
							RodBase.Wind = FMath::FInterpTo(RodBase.Wind, RodBase.AfterCastWindTarget, DeltaTime, 1.1f);
						}
						else
						{
							RodBase.Slack = FMath::FInterpTo(RodBase.Slack, RodBase.ReelSlackTarget, DeltaTime, 2.2f);
							RodBase.Wind = FMath::FInterpTo(RodBase.Wind, 0.f, DeltaTime, 1.1f);
						}

					break;

					case EFishingState::Reeling:
						RodBase.Slack = FMath::FInterpTo(RodBase.Slack, RodBase.ReelSlackTarget, DeltaTime, 2.2f);
						RodBase.Wind = FMath::FInterpTo(RodBase.Wind, RodBase.ReelWindTarget, DeltaTime, 0.6f);
					break;

					case EFishingState::Hauling:
						RodBase.Slack = FMath::FInterpTo(RodBase.Slack, RodBase.DefaultSlackTarget, DeltaTime, 1.1f);
						RodBase.Wind = FMath::FInterpTo(RodBase.Wind, RodBase.DefaultWindTarget, DeltaTime, 1.1f);
					break;

					case EFishingState::HoldingCatch:
						RodBase.Slack = FMath::FInterpTo(RodBase.Slack, RodBase.DefaultSlackTarget, DeltaTime, 1.4f);
						RodBase.Wind = FMath::FInterpTo(RodBase.Wind, RodBase.DefaultWindTarget, DeltaTime, 1.4f);
					break;

					case EFishingState::ThrowingCatch:
						RodBase.Slack = FMath::FInterpTo(RodBase.Slack, RodBase.DefaultSlackTarget, DeltaTime, 1.4f);
						RodBase.Wind = FMath::FInterpTo(RodBase.Wind, RodBase.DefaultWindTarget, DeltaTime, 1.2f);
					break;
				}

				if (NetworkTime <= System::GameTimeInSeconds)
				{
					NetworkTime = System::GameTimeInSeconds + NetworkRate;
					NetOurFishingState(RodBase.PlayerComp.FishingState);
				}

			}
			else
			{
				switch(NetFishingState)
				{
					case EFishingState::Default:
						RodBase.Slack = FMath::FInterpTo(RodBase.Slack, RodBase.DefaultSlackTarget, DeltaTime, 0.9f);
						RodBase.Wind = FMath::FInterpTo(RodBase.Wind, RodBase.DefaultWindTarget, DeltaTime, 0.9f);
					break;

					case EFishingState::Casting:
						RodBase.Slack = FMath::FInterpTo(RodBase.Slack, RodBase.NextCastSlackTarget, DeltaTime, 2.3f);
						RodBase.Wind = FMath::FInterpTo(RodBase.Wind, RodBase.AfterCastWindTarget, DeltaTime, 2.3f);
					break;

					case EFishingState::Catching:
						RodBase.Slack = FMath::FInterpTo(RodBase.Slack, RodBase.CatchingCastSlackTarget, DeltaTime, 1.1f);
						RodBase.Wind = FMath::FInterpTo(RodBase.Wind, RodBase.AfterCastWindTarget, DeltaTime, 1.1f);
					break;

					case EFishingState::Reeling:
						RodBase.Slack = FMath::FInterpTo(RodBase.Slack, RodBase.ReelSlackTarget, DeltaTime, 0.4f);
						RodBase.Wind = FMath::FInterpTo(RodBase.Wind, RodBase.ReelWindTarget, DeltaTime, 0.4f);
					break;

					case EFishingState::Hauling:
						RodBase.Slack = FMath::FInterpTo(RodBase.Slack, RodBase.DefaultSlackTarget, DeltaTime, 1.1f);
						RodBase.Wind = FMath::FInterpTo(RodBase.Wind, RodBase.DefaultWindTarget, DeltaTime, 1.1f);
					break;

					case EFishingState::HoldingCatch:
						RodBase.Slack = FMath::FInterpTo(RodBase.Slack, RodBase.DefaultSlackTarget, DeltaTime, 1.4f);
						RodBase.Wind = FMath::FInterpTo(RodBase.Wind, RodBase.DefaultWindTarget, DeltaTime, 1.4f);
					break;

					case EFishingState::ThrowingCatch:
						RodBase.Slack = FMath::FInterpTo(RodBase.Slack, RodBase.DefaultSlackTarget, DeltaTime, 1.4f);
						RodBase.Wind = FMath::FInterpTo(RodBase.Wind, RodBase.DefaultWindTarget, DeltaTime, 1.2f);
					break;
				}

			}

			RodBase.FishingLineMesh.SetWorldLocation(RodBase.BaseSkeleton.GetSocketLocation(n"RodBallPoint_Socket"));
			RodBase.FishingLineMesh.SetScalarParameterValueOnMaterials(n"Wind", RodBase.Wind);
			RodBase.FishingLineMesh.SetScalarParameterValueOnMaterials(n"Slack", RodBase.Slack);
		}
		else
		{
			RodBase.FishingLineMesh.SetWorldLocation(RodBase.BaseSkeleton.GetSocketLocation(n"RodBallPoint_Socket"));
			RodBase.FishingLineMesh.SetScalarParameterValueOnMaterials(n"Wind", 0.f);
			RodBase.FishingLineMesh.SetScalarParameterValueOnMaterials(n"Slack", 0.f);
		}

		LineFollowMesh();
	}

	UFUNCTION()
	void LineFollowMesh()
	{
		FVector Direction = RodBase.FishingBall.WorldLocation - RodBase.BaseSkeleton.GetSocketLocation(n"RodBallPoint_Socket");
		float Distance = Direction.Size() / 100.f;

		Direction.Normalize();
		FRotator Rotation = FRotator::MakeFromZ(Direction);
		RodBase.FishingLineMesh.SetWorldRotation(Rotation);
		FVector NewScale(RodBase.DefaultLineScale.X, RodBase.DefaultLineScale.Y, Distance);

		RodBase.FishingLineMesh.RelativeScale3D = NewScale;
	}

	UFUNCTION(NetFunction)
	void NetOurFishingState(EFishingState InputFishingState)
	{
		NetFishingState = InputFishingState;
		RodBase.PlayerComp.FishingState = InputFishingState;
	}

}