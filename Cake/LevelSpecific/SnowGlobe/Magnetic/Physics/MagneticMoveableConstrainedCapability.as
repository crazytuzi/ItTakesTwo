import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Physics.MagneticMoveableObjectConstrained;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;

class UMagneticMoveableConstrainedCapability : UHazeCapability
{
	// Internal tick order for the TickGroup, Lowest ticks first.
	default TickGroupOrder = 1;
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	
	UMagnetGenericComponent MagnetComponent;
	AMagneticMoveableObjectConstrained CurrentObject;

	UPROPERTY()
	bool bShouldReverse;

	UPROPERTY()
	float MoveSpeed = 10;

	UPROPERTY()
	float RattleSize = 2;

	UPROPERTY()
	bool DontUsePlayerZOffset = false;

	FTransform StartTransform;
	float CurrentMovementProgress;
	float RattleTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CurrentObject = Cast<AMagneticMoveableObjectConstrained>(Owner);
		MagnetComponent = UMagnetGenericComponent::Get(Owner);
		StartTransform = CurrentObject.Mesh.GetRelativeTransform();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!IsActioning(n"MagneticInteraction"))
			return EHazeNetworkActivation::DontActivate;			

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(n"MagneticInteraction"))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RattleTime = 0;
		bShouldReverse = true;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (bShouldReverse)
		{
			if(CurrentMovementProgress == 0)
			{
				bShouldReverse = true;
				return;
			}
			CurrentMovementProgress = FMath::LerpStable(CurrentMovementProgress, 0.f, DeltaTime * 2);

			if(!IsActive())
			{
				UpdateMeshLocation();
			}
		}

	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (RattleTime < 0.65f)
		{
			RattleTime += DeltaTime;
			UpdateRattleState(DeltaTime);
			RattleTime = FMath::Clamp(RattleTime, 0.f, 0.65f);
		}
		else
		{
			if (PullValue != 0)
			{
				CurrentMovementProgress += GetPullValue() * DeltaTime * MoveSpeed;
			}
		}
		CurrentMovementProgress = FMath::Clamp(CurrentMovementProgress, -1.f, 1.f);

		UpdateMeshLocation();
	}

	void UpdateRattleState(float DeltaTime)
	{
		CurrentMovementProgress += FMath::Sin(RattleTime * 120) * DeltaTime * RattleSize;
	}

	float GetPullValue() property
	{
		TArray<AHazePlayerCharacter> Players;
		MagnetComponent.GetInfluencingPlayers(Players);
		if (Players.Num() > 0)
		{	
			FVector ResultingDirToInfluencers;

			for (AHazePlayerCharacter Player :Players)
			{
				UMagneticPlayerComponent PlayerMagnetComp = UMagneticPlayerComponent::Get(Player);;
				
				EMagnetPolarity Polarity = MagnetComponent.Polarity;

				if(Polarity == EMagnetPolarity::Plus_Red)
				{
					if (PlayerMagnetComp.Polarity == EMagnetPolarity::Plus_Red)
					{
						ResultingDirToInfluencers += CurrentObject.ActorLocation - Player.ActorLocation;
					}

					else if (PlayerMagnetComp.Polarity == EMagnetPolarity::Minus_Blue)
					{
						ResultingDirToInfluencers += Player.ActorLocation - CurrentObject.ActorLocation;	
					}
				}
				else if (Polarity == EMagnetPolarity::Minus_Blue)
				{
					if (PlayerMagnetComp.Polarity == EMagnetPolarity::Plus_Red)
					{
						ResultingDirToInfluencers += Player.ActorLocation - CurrentObject.ActorLocation;	
					}

					else if (PlayerMagnetComp.Polarity == EMagnetPolarity::Minus_Blue)
					{
						ResultingDirToInfluencers += CurrentObject.ActorLocation - Player.ActorLocation;	
					}
				}
			}
			if (DontUsePlayerZOffset)
			{
				ResultingDirToInfluencers.Z = 0;
			}
			
			ResultingDirToInfluencers = ResultingDirToInfluencers / Players.Num();
			ResultingDirToInfluencers.Normalize();

			float DotToForward = ResultingDirToInfluencers.DotProduct(CurrentObject.ForwardArrow.ForwardVector);
			return DotToForward;
		}

		return 0;
	}

	void UpdateMeshLocation()
	{
		FTransform Transform = StartTransform;

		if (CurrentMovementProgress < 0)
		{
			Transform.Blend(StartTransform, CurrentObject.PushLocation.GetRelativeTransform(), FMath::Abs(CurrentMovementProgress));
		}

		if(CurrentMovementProgress > 0)
		{
			Transform.Blend(StartTransform, CurrentObject.PullLocation.GetRelativeTransform(), CurrentMovementProgress);
		}
		
		CurrentObject.Mesh.SetRelativeTransform(Transform);

		if(CurrentMovementProgress == 1 && !CurrentObject.bReachedEnd)
		{
			if (HasControl())
			{
				NetSetHasReachedEnd(true);
			}
		}

		else if (CurrentMovementProgress < 1 && CurrentObject.bReachedEnd)
		{
			if (HasControl())
			{
				NetSetHasReachedEnd(false);
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetSetHasReachedEnd(bool bHasReachedEnd)
	{
		CurrentObject.OnMoveableObjectReachedEnd.Broadcast(bHasReachedEnd, CurrentObject);
		CurrentObject.bReachedEnd = bHasReachedEnd;
	}
}