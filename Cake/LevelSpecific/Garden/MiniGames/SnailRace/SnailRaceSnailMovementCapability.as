import Cake.LevelSpecific.Garden.MiniGames.SnailRace.SnailRaceSnailActor;
class USnailRaceSnailMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SnailRace");
	default CapabilityTags.Add(n"SnailRaceCapability");
	default CapabilityDebugCategory = n"SnailRace";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ASnailRaceSnailActor Snail;
	
	FQuat SnailRotation;

	FHazeAcceleratedFloat Speed;
	FVector Scale;
	FVector Velocity;
	float KnockBackTimer;
	FVector StartDirection;
	UHazeCrumbComponent CrumbComp;
	FHazeFrameMovement FrameMovement;
	
	float MoveSpeedLastFrame = 0;

	bool bDashVocalPlaying = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Snail = Cast<ASnailRaceSnailActor>(Owner);
		Scale = FVector::OneVector;
		CrumbComp = UHazeCrumbComponent::Get(Owner);

		StartDirection = Snail.ActorForwardVector;
	}

	UFUNCTION()
	void UpdateScaleTimelike(float CurValue)
	{
		FVector Scalevector = FVector::OneVector;
		Scalevector.X = CurValue;

		Snail.Body.SetWorldScale3D(Scalevector);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Snail.RidingPlayer != nullptr && IsActioning(n"StartSnailRace"))
		{
			return EHazeNetworkActivation::ActivateUsingCrumb;
		}
		else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Snail.RidingPlayer == nullptr)
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}
		else if (IsActioning(n"StopMoving"))
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}
		else
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetMutuallyExclusive(n"SnailRace", true);
		Speed.SnapTo(0);
		SnailRotation = Snail.ActorRotation.Quaternion();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(n"SnailRace", false);
		ConsumeAction(n"StopMoving");

		if(Snail.RidingPlayer != nullptr)
		{
			Snail.RidingPlayer.PlayerHazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Garden_Minigames_SnailRace_SnailSpeed", 0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateSquish(DeltaTime);
		UpdateVelocity(DeltaTime);
		SetRotationValue(DeltaTime);

		Snail.MoveComponent.Move(FrameMovement);
		CrumbComp.LeaveMovementCrumb();
	}

	void UpdateSquish(float DeltaTime)
	{
		if (HasControl())
		{
			Snail.SqueezeSync.Value = Snail.SquishValue;	
		}
		
		Snail.SquishValue = Snail.SqueezeSync.Value;

		float AudioSquish = Snail.SquishValue;
		AudioSquish -= 0.2f;
		AudioSquish = AudioSquish / 0.8f;
		AudioSquish = 1 - AudioSquish;

		if(Snail.RidingPlayer != nullptr)
		{
			Snail.RidingPlayer.PlayerHazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Garden_Minigames_SnailRace_SnailCharge", AudioSquish);
		}
	}

	void UpdateVelocity(float DeltaTime)
	{
		 FrameMovement = Snail.MoveComponent.MakeFrameMovement(n"MoveSnail");

		if (HasControl())
		{
			if (Snail.SnailBoost > 0)
			{
				Speed.AccelerateTo(2300.f, 0.5f, DeltaTime);
			}
			else
			{
				Speed.AccelerateTo(0, 1.f, DeltaTime);
			}

			Velocity = (Snail.ActorForwardVector * Speed.Value).ConstrainToPlane(Snail.MoveComponent.WorldUp);

			FrameMovement.ApplyDelta(Velocity * DeltaTime);

			if (Snail.MoveComponent.IsAirborne())
			{
				FrameMovement.ApplyGravityAcceleration(FVector::UpVector);
			}
		}
		else
		{
			// Remote, follow crumbs
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMovement.ApplyConsumedCrumbData(ConsumedParams);
		}

		float SnailSpeed = Snail.MoveComponent.ActualVelocity.Size();

		if(Snail.RidingPlayer != nullptr)
		{
			Snail.RidingPlayer.PlayerHazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Garden_Minigames_SnailRace_SnailSpeed", SnailSpeed / 2300.);
		}

		if(!bDashVocalPlaying && SnailSpeed >= 0.9f)
		{
			if (Snail.RidingPlayer != nullptr)
			{
				Snail.RidingPlayer.PlayerHazeAkComp.HazePostEvent(Snail.DashVocalAudioEvent);
			}

			bDashVocalPlaying = true;
		}
		else if(SnailSpeed <= 0.9f)
		{
			bDashVocalPlaying = false;
		}

		FVector SpeedEvail = Snail.MoveComponent.ActualVelocity;
		SpeedEvail.Z = 0;

		MoveSpeedLastFrame = SpeedEvail.Size();
	}

	void SetRotationValue(float DeltaTime)
	{
		if (HasControl())
		{
			if(Snail.DesiredMoveDirection.Size() < 0.2f)
			{
				//Ponder upon life
			}

			else
			{
				FQuat SnailRot = SnailRotation;
				FQuat DesiredSnailRotation = FRotator::MakeFromX(Snail.DesiredMoveDirection.GetSafeNormal()).Quaternion();
				SnailRotation = FQuat::Slerp(SnailRot, DesiredSnailRotation, DeltaTime * 1.5f);
			}

			Snail.MoveComponent.SetTargetFacingRotation(SnailRotation);
			FrameMovement.ApplyTargetRotationDelta();
		}
		
		float RotationSpeed = Snail.MoveComponent.RotationDelta * 10;
		RotationSpeed = FMath::Clamp(RotationSpeed, 0.f, 1.f);

		if (Snail.RidingPlayer != nullptr)
		{
			Snail.RidingPlayer.PlayerHazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Garden_Minigames_SnailRace_SnailRotation", RotationSpeed);
		}
	}
}